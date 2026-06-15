`timescale 1ns / 1ps

module tune_cmd_uart (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] uart_data,
    input  logic       uart_valid,
    output logic [9:0] tune_out
);
  typedef enum logic [0:0] {
    IDLE,
    ACC
  } st_t;

  st_t st;
  logic [11:0] acc;
  int unsigned ndig;

  function automatic logic is_hex_digit(input logic [7:0] ch);
    return (
        (ch >= 8'h30 && ch <= 8'h39) ||
        (ch >= 8'ha && ch <= 8'hf) ||
        (ch >= 8'hA && ch <= 8'hF));
  endfunction

  function automatic logic [3:0] ascii_hex_lut(input logic [7:0] ch);
    if (ch >= 8'h30 && ch <= 8'h39)
      return logic [3:0](ch - 8'h30);
    else if (ch >= 8'ha && ch <= 8'hf)
      return logic [3:0](ch - 8'ha + 4'd10);
    else if (ch >= 8'hA && ch <= 8'hF)
      return logic [3:0](ch - 8'hA + 4'd10);
    else
      return 4'h0;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st      <= IDLE;
      acc     <= '0;
      ndig    <= '0;
      tune_out <= 10'h0;
    end else if (uart_valid) begin
      if (uart_data == 8'h0D || uart_data == 8'h0A) begin
        if (st == ACC) tune_out <= 10'(acc & 12'h3FF);
        st       <= IDLE;
        acc      <= '0;
        ndig     <= '0;
      end else begin
        unique case (st)
          IDLE: begin
            if (uart_data == 8'h74 || uart_data == 8'h54) begin
              st      <= ACC;
              acc     <= '0;
              ndig    <= '0;
            end
          end

          ACC: begin
            if (is_hex_digit(uart_data) && ndig < 3) begin
              acc <= (acc << 4) | (12'(ascii_hex_lut(uart_data)));
              ndig <= ndig + 1;
            end else begin
              st   <= IDLE;
              acc  <= '0;
              ndig <= '0;
            end
          end

          default: st <= IDLE;
        endcase
      end
    end
  end
endmodule : tune_cmd_uart
