`timescale 1ns / 1ps

module csr_ro_axi_lite #(
    parameter int C_S_AXI_ADDR_WIDTH = 16,
    parameter int RO_BANKS            = 16,
    parameter int RO_BANK_SEL_W        = (RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS)
) (
    input logic s_axi_aclk,
    input logic s_axi_aresetn,

    input  logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  logic [                     2:0] s_axi_awprot,
    input  logic                         s_axi_awvalid,
    output logic                         s_axi_awready,

    input  logic [31:0] s_axi_wdata,
    input  logic [ 3:0] s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    output logic [ 1:0] s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    input  logic [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  logic [                     2:0] s_axi_arprot,
    input  logic                         s_axi_arvalid,
    output logic                         s_axi_arready,

    output logic [31:0] s_axi_rdata,
    output logic [ 1:0] s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    output logic                         csr_ro_en,
    output logic [                     11:0] csr_tune_sel,
    output logic [                      2:0] csr_freq_sel,
    output logic [RO_BANK_SEL_W-1:0] csr_ro_bank_sel,
    output logic                         csr_bank_manual,
    output logic                         csr_div_manual,
    output logic                         csr_div_bypass,
    output logic [                     31:0] csr_half_edges,
    output logic                         csr_meas_pulse,
    output logic                         csr_meas_arm,
    (* DONT_TOUCH = "yes" *)
    output logic [                     31:0] csr_meas_gate_cycles,

    input logic                             i_meas_busy,
    input logic                             i_meas_done,
    input logic                             i_meas_ring_done,
    input logic [                     31:0] i_meas_edge_count,
    input logic [                     31:0] i_meas_freq_hz,
    input logic [                     31:0] i_meas_ring_edge_count,
    input logic [                     31:0] i_meas_ring_freq_hz,
    input logic                             i_pll_locked,
    input logic [RO_BANK_SEL_W-1:0]         i_bank_active,
    input logic [RO_BANK_SEL_W-1:0]         i_bank_auto,
    input logic                             i_div_bypass,
    input logic [                     31:0] i_half_edges,
    input logic [                     15:0] i_f_pred_khz,

    output logic [                     15:0] csr_target_khz
);

  logic [31:0] reg_ctrl, reg_freq, reg_tune, reg_gate;
  logic [RO_BANK_SEL_W-1:0] reg_bank;
  logic [15:0] reg_target;
  logic [31:0] reg_half_edges;
  logic        reg_div_bypass;
  logic        div_manual;
  logic        sticky_done;
  logic        sticky_ring;
  logic        sticky_out;
  logic        meas_arm_d;
  logic        bank_manual;
  logic [31:0] reg_edges_snap;
  logic [31:0] reg_edges_ring_snap;
  logic [31:0] reg_freq_hz_snap;
  logic [31:0] reg_freq_ring_snap;
  logic        meas_done_out_d;
  logic        meas_done_ring_d;
  logic        seen_out;
  logic        seen_ring;

  wire [3:0] wi = s_axi_awaddr[5:2];

  assign csr_meas_pulse =
      s_axi_awready & s_axi_wready & s_axi_awvalid & s_axi_wvalid & (wi == 4'd0) &
      s_axi_wdata[1];

  assign csr_bank_manual = bank_manual;
  assign csr_div_manual  = div_manual;
  assign csr_div_bypass  = div_manual ? reg_div_bypass : i_div_bypass;
  assign csr_half_edges  = div_manual ? reg_half_edges : i_half_edges;

  always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_awready <= 1'b1;
      s_axi_wready  <= 1'b1;
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= 2'b00;
      reg_ctrl      <= '0;
      reg_freq      <= '0;
      reg_tune      <= '0;
      reg_gate      <= 32'd60_000;
      reg_bank      <= '0;
      reg_target    <= 16'd100;
      reg_half_edges <= 16'd1;
      reg_div_bypass <= 1'b0;
      div_manual    <= 1'b0;
      sticky_done   <= 1'b0;
      sticky_ring   <= 1'b0;
      sticky_out    <= 1'b0;
      meas_arm_d    <= 1'b0;
      bank_manual   <= 1'b0;
      reg_edges_snap <= '0;
      reg_edges_ring_snap <= '0;
      reg_freq_hz_snap <= '0;
      reg_freq_ring_snap <= '0;
      meas_done_out_d  <= 1'b0;
      meas_done_ring_d <= 1'b0;
      seen_out         <= 1'b0;
      seen_ring        <= 1'b0;
    end else begin
      meas_arm_d <= reg_ctrl[1];

      if (reg_ctrl[1] & ~meas_arm_d) begin
        sticky_done <= 1'b0;
        sticky_ring <= 1'b0;
        sticky_out  <= 1'b0;
        seen_out    <= 1'b0;
        seen_ring   <= 1'b0;
      end

      meas_done_out_d  <= i_meas_done;
      meas_done_ring_d <= i_meas_ring_done;

      if (i_meas_done & ~meas_done_out_d) begin
        reg_edges_snap   <= i_meas_edge_count;
        reg_freq_hz_snap <= i_meas_freq_hz;
        seen_out         <= 1'b1;
        sticky_out       <= 1'b1;
      end
      if (i_meas_ring_done & ~meas_done_ring_d) begin
        reg_edges_ring_snap <= i_meas_ring_edge_count;
        reg_freq_ring_snap  <= i_meas_ring_freq_hz;
        seen_ring           <= 1'b1;
        sticky_ring         <= 1'b1;
      end
      if (sticky_ring & sticky_out)
        sticky_done <= 1'b1;

      if (s_axi_bvalid & s_axi_bready) s_axi_bvalid <= 1'b0;
      if (s_axi_awready & s_axi_wready & s_axi_awvalid & s_axi_wvalid) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bvalid  <= 1'b1;
        unique case (wi)
          4'd0: begin
            reg_ctrl[0] <= s_axi_wdata[0];
            reg_ctrl[1] <= s_axi_wdata[1];
          end
          4'd1: reg_freq[2:0] <= s_axi_wdata[2:0];
          4'd2: reg_tune[11:0] <= s_axi_wdata[11:0];
          4'd3: reg_gate <= s_axi_wdata;
          4'd4: begin
            if (s_axi_wdata[1]) begin
              sticky_done <= 1'b0;
              sticky_ring <= 1'b0;
              sticky_out  <= 1'b0;
              seen_out    <= 1'b0;
              seen_ring   <= 1'b0;
            end
          end
          4'd7: begin
            if (RO_BANKS > 1) begin
              reg_bank <= (s_axi_wdata < RO_BANKS) ? s_axi_wdata[RO_BANK_SEL_W-1:0] : '0;
              bank_manual <= 1'b1;
            end
          end
          4'd9: begin
            if (s_axi_wdata >= 32'd1 && s_axi_wdata <= 32'd65535) begin
              reg_target <= s_axi_wdata[15:0];
            end
          end
          4'd13: begin
            reg_half_edges <= s_axi_wdata;
            div_manual     <= 1'b1;
          end
          4'd15: begin
            if (s_axi_wdata[2]) div_manual <= 1'b0;
            else begin
              reg_div_bypass <= s_axi_wdata[1];
              if (s_axi_wdata[0]) div_manual <= 1'b1;
            end
          end
          default: ;
        endcase
      end else if (~s_axi_awready & ~s_axi_wready & ~s_axi_bvalid) begin
        s_axi_awready <= 1'b1;
        s_axi_wready  <= 1'b1;
      end
    end
  end

  always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_arready <= 1'b1;
      s_axi_rvalid  <= 1'b0;
      s_axi_rdata   <= '0;
      s_axi_rresp   <= 2'b00;
    end else begin
      if (s_axi_rvalid & s_axi_rready) begin
        s_axi_rvalid  <= 1'b0;
        s_axi_arready <= 1'b1;
      end else if (s_axi_arready & s_axi_arvalid & ~s_axi_rvalid) begin
        s_axi_arready <= 1'b0;
        s_axi_rvalid  <= 1'b1;
        s_axi_rresp   <= 2'b00;
        unique case (s_axi_araddr[5:2])
          4'd0:  s_axi_rdata <= {31'd0, reg_ctrl[0]};
          4'd1:  s_axi_rdata <= {29'd0, reg_freq[2:0]};
          4'd2:  s_axi_rdata <= {20'd0, reg_tune[11:0]};
          4'd3:  s_axi_rdata <= reg_gate;
          /* STATUS: [0]=busy [1]=done [2]=ring_done [3]=out_done (matches sw/v1_uart/ro_regs.h) */
          4'd4:  s_axi_rdata <= {28'd0, sticky_out, sticky_ring, sticky_done, i_meas_busy};
          4'd5:  s_axi_rdata <= {31'd0, i_pll_locked};
          4'd6:  s_axi_rdata <= reg_edges_snap;
          4'd7:  s_axi_rdata <= {{(32 - RO_BANK_SEL_W) {1'b0}}, i_bank_active};
          4'd8:  s_axi_rdata <= reg_freq_hz_snap;
          4'd9:  s_axi_rdata <= {16'd0, reg_target};
          4'd10: s_axi_rdata <= reg_freq_ring_snap;
          4'd11: s_axi_rdata <= reg_edges_ring_snap;
          4'd12: s_axi_rdata <= {16'd0, i_f_pred_khz};
          4'd13: s_axi_rdata <= reg_half_edges;
          4'd14: s_axi_rdata <= {{(32 - RO_BANK_SEL_W - 3) {1'b0}},
                                 div_manual,
                                 i_bank_auto,
                                 csr_bank_manual,
                                 csr_div_bypass};
          4'd15: s_axi_rdata <= {28'd0, div_manual, reg_div_bypass, 2'd0};
          default: s_axi_rdata <= 32'h0;
        endcase
      end
    end
  end

  assign csr_meas_arm         = reg_ctrl[1];
  assign csr_ro_en            = reg_ctrl[0];
  assign csr_tune_sel         = reg_tune[11:0];
  assign csr_freq_sel         = reg_freq[2:0];
  assign csr_ro_bank_sel      = reg_bank;
  assign csr_meas_gate_cycles = reg_gate;
  assign csr_target_khz       = reg_target;

endmodule
