`timescale 1ns / 1ps

module ro_freq_measure #(
    parameter int RO_SYNC_STAGES = 4,
    parameter int F_REF_HZ       = 12_000_000,
    parameter int FREQ_SCALE     = 1
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        ro_async,
    input  logic        meas_start,
    input  logic [31:0] gate_cycles,
    output logic        meas_busy,
    output logic        meas_done,
    output logic [31:0] meas_edge_count,
    output logic [31:0] meas_freq_hz
);

  logic [RO_SYNC_STAGES-1:0] ro_chain;
  logic                      edge_rise;
  logic [31:0]               freq_raw;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ro_chain <= '0;
    else ro_chain <= {ro_chain[RO_SYNC_STAGES-2:0], ro_async};
  end

  assign edge_rise = ro_chain[RO_SYNC_STAGES-1] & ~ro_chain[RO_SYNC_STAGES-2];

  typedef enum logic [1:0] {
    ST_IDLE,
    ST_RUN,
    ST_DONE
  } state_t;

  state_t state;

  logic [31:0] timer;
  logic [31:0] edges;
  logic [31:0] gate_latched;

  ro_freq_hz_calc #(
      .F_REF_HZ(F_REF_HZ)
  ) u_hz (
      .gate_cycles(gate_latched),
      .edge_count (edges),
      .freq_hz    (freq_raw)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state           <= ST_IDLE;
      timer           <= '0;
      edges           <= '0;
      meas_busy       <= 1'b0;
      meas_done       <= 1'b0;
      meas_edge_count <= '0;
      gate_latched    <= '0;
    end else begin
      meas_done <= 1'b0;

      unique case (state)
        ST_IDLE: begin
          meas_busy <= 1'b0;
          if (meas_start && (gate_cycles != '0)) begin
            state        <= ST_RUN;
            meas_busy    <= 1'b1;
            timer        <= gate_cycles;
            gate_latched <= gate_cycles;
            edges        <= '0;
          end
        end

        ST_RUN: begin
          if (edge_rise && (edges < 32'h000F_FFFF))
            edges <= edges + 32'd1;

          if (timer <= 32'd1) begin
            state           <= ST_DONE;
            meas_busy       <= 1'b0;
            meas_edge_count <= edges;
          end else begin
            timer <= timer - 32'd1;
          end
        end

        ST_DONE: begin
          meas_done <= 1'b1;
          state     <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

  always_comb begin
    logic [63:0] scaled;
    if (FREQ_SCALE <= 1) begin
      meas_freq_hz = freq_raw;
    end else begin
      scaled = 64'(freq_raw) * 64'(FREQ_SCALE);
      meas_freq_hz = (scaled > 64'hFFFF_FFFF) ? 32'hFFFF_FFFF : 32'(scaled);
    end
  end

endmodule : ro_freq_measure
