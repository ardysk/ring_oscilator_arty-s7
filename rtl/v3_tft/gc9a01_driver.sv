// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Controller for the GC9A01 round TFT display over SPI (240x240).
// Handles reset, initialization sequence, and drawing measured frequency text.
// Part of the archived V3 TFT branch only.

`timescale 1ns / 1ps

module gc9a01_driver #(
    parameter int REFRESH_CYCLES = 12_000_000  // ~1 s @ 12 MHz
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] freq_hz,
    input  logic [8:0]  target_mhz,
    output logic        tft_sck,
    output logic        tft_mosi,
    output logic        tft_cs_n,
    output logic        tft_dc,
    output logic        tft_rst_n,
    output logic        busy
);

  localparam int CHAR_W  = 8;
  localparam int CHAR_H  = 12;
  localparam int NUM_CH  = 14;
  localparam int LINE1_Y = 96;
  localparam int LINE2_Y = 118;
  localparam int TEXT_X  = 36;

  logic spi_start, spi_busy, spi_done;
  logic [7:0] spi_tx;
  logic [7:0] init_rom [0:19];
  logic [5:0] init_idx;
  logic [17:0] pixel_cnt;
  logic [31:0] last_freq;
  logic [31:0] refresh_cnt;
  logic [7:0]  line1 [0:NUM_CH-1];
  logic [7:0]  line2 [0:NUM_CH-1];

  spi_master #(
      .CLK_DIV(8)
  ) u_spi (
      .clk(clk), .rst_n(rst_n), .start(spi_start), .tx_data(spi_tx),
      .busy(spi_busy), .done(spi_done),
      .sck(tft_sck), .mosi(tft_mosi)
  );

  typedef enum logic [2:0] {
    ST_RESET,
    ST_INIT,
    ST_WIN,
    ST_RAMWR,
    ST_PIXEL,
    ST_IDLE
  } st_t;

  st_t state;
  logic [23:0] rst_cnt;

  initial begin
    init_rom[0]  = 8'hFE; init_rom[1]  = 8'hEF;
    init_rom[2]  = 8'hEB; init_rom[3]  = 8'h14;
    init_rom[4]  = 8'h84; init_rom[5]  = 8'h40;
    init_rom[6]  = 8'h8A; init_rom[7]  = 8'h00;
    init_rom[8]  = 8'h8B; init_rom[9]  = 8'h00;
    init_rom[10] = 8'h8C; init_rom[11] = 8'h00;
    init_rom[12] = 8'h8E; init_rom[13] = 8'hFF;
    init_rom[14] = 8'h3A; init_rom[15] = 8'h05;
    init_rom[16] = 8'h36; init_rom[17] = 8'h00;
    init_rom[18] = 8'h11;
    init_rom[19] = 8'h29;
  end

  function automatic logic [7:0] chr_at(input logic [7:0] arr [0:NUM_CH-1], input int idx);
    if (idx < 0 || idx >= NUM_CH) return 8'h20;
    return arr[idx];
  endfunction

  function automatic logic glyph_bit(input logic [7:0] ch, input int cx, input int cy);
    logic [7:0] row;
    row = 8'h00;
    unique case (ch)
      "0": unique case (cy)
          0: row = 8'h3C;
          1: row = 8'h66;
          2: row = 8'h6E;
          3: row = 8'h76;
          4: row = 8'h66;
          5: row = 8'h66;
          6: row = 8'h66;
          7: row = 8'h3C;
          default: row = 8'h00;
        endcase
      "1": unique case (cy)
          0, 1, 2: row = 8'h18;
          3: row = 8'h38;
          default: row = 8'h18;
        endcase
      "2": unique case (cy)
          0: row = 8'h3C;
          1: row = 8'h66;
          2: row = 8'h06;
          3: row = 8'h1C;
          4: row = 8'h30;
          5: row = 8'h60;
          6: row = 8'h66;
          7: row = 8'h7E;
          default: row = 8'h00;
        endcase
      "3": unique case (cy)
          0: row = 8'h3C;
          1: row = 8'h66;
          2, 3: row = 8'h0C;
          4: row = 8'h1C;
          5, 6: row = 8'h06;
          7: row = 8'h3C;
          default: row = 8'h00;
        endcase
      "4": unique case (cy)
          0: row = 8'h0C;
          1: row = 8'h1C;
          2: row = 8'h2C;
          3: row = 8'h4C;
          4: row = 8'h7E;
          5, 6, 7: row = 8'h0C;
          default: row = 8'h00;
        endcase
      "5": unique case (cy)
          0: row = 8'h7E;
          1: row = 8'h60;
          2: row = 8'h7C;
          3: row = 8'h06;
          4, 5: row = 8'h06;
          6: row = 8'h66;
          7: row = 8'h3C;
          default: row = 8'h00;
        endcase
      "6": unique case (cy)
          0: row = 8'h1C;
          1: row = 8'h30;
          2: row = 8'h60;
          3: row = 8'h7C;
          4, 5: row = 8'h66;
          6: row = 8'h66;
          7: row = 8'h3C;
          default: row = 8'h00;
        endcase
      "7": unique case (cy)
          0: row = 8'h7E;
          1, 2, 3, 4, 5, 6, 7: row = 8'h06;
          default: row = 8'h00;
        endcase
      "8": unique case (cy)
          0, 7: row = 8'h3C;
          1, 2, 5, 6: row = 8'h66;
          3, 4: row = 8'h3C;
          default: row = 8'h00;
        endcase
      "9": unique case (cy)
          0: row = 8'h3C;
          1, 2: row = 8'h66;
          3: row = 8'h3E;
          4, 5, 6: row = 8'h06;
          7: row = 8'h3C;
          default: row = 8'h00;
        endcase
      ".": if (cy == 10) row = 8'h60; else row = 8'h00;
      " ": row = 8'h00;
      "F", "f": unique case (cy)
          0: row = 8'h7F;
          1, 2, 3, 4, 5, 6, 7: row = 8'h40;
          default: row = 8'h00;
        endcase
      "H", "h": unique case (cy)
          0, 1, 2, 3, 4, 5, 6, 7: row = 8'h66;
          3, 4: row = 8'h7E;
          default: row = 8'h00;
        endcase
      "O", "o": unique case (cy)
          0, 7: row = 8'h3C;
          1, 2, 5, 6: row = 8'h66;
          default: row = 8'h00;
        endcase
      "U", "u": unique case (cy)
          0, 1, 2, 3, 4, 5: row = 8'h66;
          6, 7: row = 8'h3C;
          default: row = 8'h00;
        endcase
      "T", "t": unique case (cy)
          0: row = 8'h7E;
          1, 2, 3, 4, 5, 6, 7: row = 8'h18;
          default: row = 8'h00;
        endcase
      "z", "Z": unique case (cy)
          0: row = 8'h7E;
          1, 2: row = 8'h06;
          3: row = 8'h1C;
          4: row = 8'h30;
          5, 6: row = 8'h60;
          7: row = 8'h7E;
          default: row = 8'h00;
        endcase
      "k", "K": unique case (cy)
          0, 1, 2, 3, 4, 5, 6, 7: row = 8'h42;
          3: row = 8'h6C;
          4: row = 8'h78;
          5: row = 8'h6C;
          6: row = 8'h66;
          default: row = 8'h00;
        endcase
      "M": unique case (cy)
          0, 1, 2, 3, 4, 5, 6, 7: row = 8'h42;
          1: row = 8'h63;
          2: row = 8'h66;
          3: row = 8'h5A;
          4: row = 8'h5A;
          5: row = 8'h66;
          6: row = 8'h63;
          default: row = 8'h00;
        endcase
      default: row = 8'h00;
    endcase
    return row[7-cx];
  endfunction

  function automatic logic text_pixel(
      input logic [8:0] px,
      input logic [8:0] py,
      input logic [7:0] arr [0:NUM_CH-1],
      input int       base_y
  );
    int ci;
    int lx;
    int ly;
    logic [7:0] ch;
    if (py < base_y || py >= base_y + CHAR_H)
      return 1'b0;
    if (px < TEXT_X || px >= TEXT_X + NUM_CH * CHAR_W)
      return 1'b0;
    ci = (px - TEXT_X) / CHAR_W;
    lx = (px - TEXT_X) % CHAR_W;
    ly = py - base_y;
    ch = chr_at(arr, ci);
    return glyph_bit(ch, lx, ly);
  endfunction

  function automatic logic [15:0] pixel_rgb(
      input logic [8:0] px,
      input logic [8:0] py,
      input logic [7:0] l1 [0:NUM_CH-1],
      input logic [7:0] l2 [0:NUM_CH-1]
  );
    if (text_pixel(px, py, l1, LINE1_Y) || text_pixel(px, py, l2, LINE2_Y))
      pixel_rgb = 16'hFFFF;
    else
      pixel_rgb = 16'h0010;
  endfunction

  always_comb begin
    int          i;
    logic [31:0] v;
    logic [31:0] val;
    logic [7:0]  unit0;
    logic [7:0]  unit1;
    logic [3:0]  digs [0:7];

    for (i = 0; i < NUM_CH; i++) begin
      line1[i] = 8'h20;
      line2[i] = 8'h20;
    end
    line1[0] = "f";
    line1[1] = " ";
    line1[2] = "O";
    line1[3] = "U";
    line1[4] = "T";

    if (freq_hz >= 32'd1_000_000) begin
      val   = (freq_hz + 32'd500) / 32'd1_000_000;
      unit0 = "M";
      unit1 = "z";
    end else if (freq_hz >= 32'd1000) begin
      val   = (freq_hz + 32'd500) / 32'd1000;
      unit0 = "k";
      unit1 = "z";
    end else begin
      val   = freq_hz;
      unit0 = "H";
      unit1 = "z";
    end

    if (val > 32'd99_999_999)
      val = 32'd99_999_999;

    v = val;
    for (i = 0; i < 8; i++) begin
      digs[i] = 4'(v % 10);
      v       = v / 10;
    end
    for (i = 0; i < 8; i++)
      line2[i] = 8'h30 + digs[7 - i];
    line2[8]  = " ";
    line2[9]  = unit0;
    line2[10] = unit1;
  end

  logic [15:0] pix_color;
  logic [8:0]    pix_x;
  logic [8:0]    pix_y;

  assign pix_x = 9'(pixel_cnt / 18'd2 % 18'd240);
  assign pix_y = 9'(pixel_cnt / 18'd480);
  assign pix_color = pixel_rgb(pix_x, pix_y, line1, line2);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= ST_RESET;
      tft_rst_n  <= 1'b0;
      tft_cs_n   <= 1'b1;
      tft_dc     <= 1'b0;
      spi_start  <= 1'b0;
      spi_tx     <= 8'h00;
      init_idx   <= '0;
      pixel_cnt  <= '0;
      rst_cnt    <= '0;
      last_freq  <= '0;
      refresh_cnt<= '0;
      busy       <= 1'b1;
    end else begin
      spi_start <= 1'b0;

      unique case (state)
        ST_RESET: begin
          tft_rst_n <= 1'b0;
          tft_cs_n  <= 1'b1;
          if (rst_cnt >= 24'd500_000) begin
            tft_rst_n <= 1'b1;
            if (rst_cnt >= 24'd1_000_000) begin
              state   <= ST_INIT;
              init_idx<= '0;
              rst_cnt <= '0;
            end
          end
          rst_cnt <= rst_cnt + 24'd1;
        end

        ST_INIT: begin
          tft_cs_n <= 1'b0;
          tft_dc   <= 1'b0;
          busy     <= 1'b1;
          if (!spi_busy && !spi_start) begin
            if (init_idx < 6'd20) begin
              spi_tx    <= init_rom[init_idx];
              spi_start <= 1'b1;
              init_idx  <= init_idx + 6'd1;
            end else begin
              state     <= ST_WIN;
              pixel_cnt <= '0;
            end
          end
        end

        ST_WIN: begin
          tft_dc <= 1'b0;
          busy   <= 1'b1;
          if (!spi_busy && !spi_start) begin
            unique case (pixel_cnt)
              0: begin spi_tx <= 8'h2A; spi_start <= 1'b1; end
              1: begin tft_dc <= 1'b1; spi_tx <= 8'h00; spi_start <= 1'b1; end
              2: begin spi_tx <= 8'h00; spi_start <= 1'b1; end
              3: begin spi_tx <= 8'h00; spi_start <= 1'b1; end
              4: begin spi_tx <= 8'hEF; spi_start <= 1'b1; end
              5: begin tft_dc <= 1'b0; spi_tx <= 8'h2B; spi_start <= 1'b1; end
              6: begin tft_dc <= 1'b1; spi_tx <= 8'h00; spi_start <= 1'b1; end
              7: begin spi_tx <= 8'h00; spi_start <= 1'b1; end
              8: begin spi_tx <= 8'h00; spi_start <= 1'b1; end
              9: begin spi_tx <= 8'hEF; spi_start <= 1'b1; end
              10: begin tft_dc <= 1'b0; spi_tx <= 8'h2C; spi_start <= 1'b1; end
              default: begin
                state     <= ST_RAMWR;
                pixel_cnt <= '0;
              end
            endcase
            if (pixel_cnt <= 10) pixel_cnt <= pixel_cnt + 18'd1;
          end
        end

        ST_RAMWR: begin
          tft_dc <= 1'b1;
          busy   <= 1'b1;
          if (!spi_busy && !spi_start) begin
            state     <= ST_PIXEL;
            pixel_cnt <= '0;
          end
        end

        ST_PIXEL: begin
          tft_dc <= 1'b1;
          busy   <= 1'b1;
          if (!spi_busy && !spi_start) begin
            if (pixel_cnt[0] == 0)
              spi_tx <= pix_color[15:8];
            else
              spi_tx <= pix_color[7:0];
            spi_start <= 1'b1;
            if (pixel_cnt >= 18'd115199) begin
              state      <= ST_IDLE;
              last_freq  <= freq_hz;
              refresh_cnt<= '0;
              tft_cs_n   <= 1'b1;
            end
            pixel_cnt <= pixel_cnt + 18'd1;
          end
        end

        ST_IDLE: begin
          busy <= 1'b0;
          refresh_cnt <= refresh_cnt + 32'd1;
          if (freq_hz != last_freq || refresh_cnt >= 32'(REFRESH_CYCLES)) begin
            state     <= ST_WIN;
            pixel_cnt <= '0;
            tft_cs_n  <= 1'b0;
            busy      <= 1'b1;
          end
        end

        default: state <= ST_RESET;
      endcase
    end
  end

endmodule : gc9a01_driver
