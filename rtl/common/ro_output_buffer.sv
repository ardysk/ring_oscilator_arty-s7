`timescale 1ns / 1ps

module ro_output_buffer (
    input  logic clk,
    input  logic rst_n,
    input  logic ro_in,
    output logic ro_out
);

  logic ro_buf;

  BUFGCE u_bufgce (
      .I (ro_in),
      .CE(1'b1),
      .O (ro_buf)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ro_out <= 1'b0;
    else        ro_out <= ro_buf;
  end

endmodule : ro_output_buffer
