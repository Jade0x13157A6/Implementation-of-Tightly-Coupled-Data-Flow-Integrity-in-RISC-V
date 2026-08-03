`timescale 1ns/1ps

module cam_4x32 (
  input  logic        clk_i,
  input  logic        rstn_i,

  input  logic        write_en_i,
  input  logic [1:0]  write_addr_i,
  input  logic [31:0] write_data_i,

  input  logic [31:0] search_data_i,

  output logic [3:0]  match_vector_o,
  output logic        match_o,
  output logic        miss_o
);

  logic [31:0] entries_q [0:3];
  logic [3:0] valid_q;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      valid_q <= '0;

      for (int unsigned i = 0; i < 4; i++) begin
        entries_q[i] <= '0;
      end
    end else if (write_en_i) begin
      entries_q[write_addr_i] <= write_data_i;
      valid_q[write_addr_i]   <= 1'b1;
    end
  end

  always_comb begin
    match_vector_o = '0;

    for (int unsigned i = 0; i < 4; i++) begin
      match_vector_o[i] =
          valid_q[i] && (entries_q[i] == search_data_i);
    end
  end

  assign match_o = |match_vector_o;
  assign miss_o  = !match_o;

endmodule : cam_4x32
