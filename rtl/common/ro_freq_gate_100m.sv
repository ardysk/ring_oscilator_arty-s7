`timescale 1ns / 1ps

module ro_freq_gate_100m #(
    parameter int F_REF_HZ    = 100_000_000,
    parameter int GATE_CYCLES = 100_000
) (
    input  logic        clk_ref,
    input  logic        rst_n,
    input  logic        ref_locked,
    input  logic        ro_async,
    input  logic        meas_start,
    output logic        meas_busy,
    output logic        meas_done,
    output logic [31:0] meas_edge_count,
    output logic [31:0] meas_freq_hz
);

  (* KEEP = "TRUE" *) logic ro_s0, ro_s1, ro_s2;
  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      ro_s0 <= 1'b0;
      ro_s1 <= 1'b0;
      ro_s2 <= 1'b0;
    end else begin
      ro_s0 <= ro_async;
      ro_s1 <= ro_s0;
      ro_s2 <= ro_s1;
    end
  end

  logic edge_rise;
  assign edge_rise = ro_s1 & ~ro_s2;

  (* KEEP = "TRUE" *) logic gate_ref;
  (* KEEP = "TRUE" *) logic gate_ro_ff0, gate_ro_ff1;

  always_ff @(posedge ro_async or negedge rst_n) begin
    if (!rst_n) begin
      gate_ro_ff0 <= 1'b0;
      gate_ro_ff1 <= 1'b0;
    end else begin
      gate_ro_ff0 <= gate_ref;
      gate_ro_ff1 <= gate_ro_ff0;
    end
  end

  typedef enum logic [1:0] { ST_IDLE, ST_RUN, ST_DONE } state_t;
  state_t state;

  logic [31:0] timer;
  logic [31:0] edges;
  logic [63:0] freq_num;

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      state           <= ST_IDLE;
      timer           <= '0;
      edges           <= '0;
      gate_ref        <= 1'b0;
      meas_busy       <= 1'b0;
      meas_done       <= 1'b0;
      meas_edge_count <= '0;
      meas_freq_hz    <= '0;
    end else begin
      meas_done <= 1'b0;

      unique case (state)
        ST_IDLE: begin
          meas_busy <= 1'b0;
          gate_ref  <= 1'b0;
          if (meas_start && ref_locked) begin
            state     <= ST_RUN;
            meas_busy <= 1'b1;
            gate_ref  <= 1'b1;
            timer     <= GATE_CYCLES[31:0];
            edges     <= '0;
          end
        end

        ST_RUN: begin
          if (edge_rise) edges <= edges + 32'd1;
          if (timer <= 32'd1) begin
            state           <= ST_DONE;
            gate_ref        <= 1'b0;
            meas_busy       <= 1'b0;
            meas_edge_count <= edges;
          end else begin
            timer <= timer - 32'd1;
          end
        end

        ST_DONE: begin
          freq_num = 64'(edges) * 64'(F_REF_HZ);
          if (GATE_CYCLES != 0)
            meas_freq_hz <= freq_num / GATE_CYCLES[31:0];
          meas_done <= 1'b1;
          state     <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

endmodule
