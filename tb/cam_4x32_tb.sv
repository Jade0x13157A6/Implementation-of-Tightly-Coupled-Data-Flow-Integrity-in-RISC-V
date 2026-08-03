`timescale 1ns/1ps
module cam_4x32_tb;

  logic        clk_i;
  logic        rstn_i;
  logic        write_en_i;
  logic [1:0]  write_addr_i;
  logic [31:0] write_data_i;
  logic [31:0] search_data_i;

  logic [3:0] match_vector_o;
  logic       match_o;
  logic       miss_o;

  // Device under test
  cam_4x32 dut (
    .clk_i          (clk_i),
    .rstn_i         (rstn_i),
    .write_en_i     (write_en_i),
    .write_addr_i   (write_addr_i),
    .write_data_i   (write_data_i),
    .search_data_i  (search_data_i),
    .match_vector_o (match_vector_o),
    .match_o        (match_o),
    .miss_o         (miss_o)
  );

  // Generate a clock with a period of 10 ns
  always #5 clk_i = ~clk_i;

  // Write one value into the CAM
  task automatic write_entry(
    input logic [1:0]  address,
    input logic [31:0] data
  );
    begin
      @(negedge clk_i);

      write_en_i   = 1'b1;
      write_addr_i = address;
      write_data_i = data;

      @(negedge clk_i);

      write_en_i = 1'b0;
    end
  endtask

  // Search for a value and check all result signals
  task automatic check_search(
    input logic [31:0] search_value,
    input logic [3:0]  expected_vector
  );
    logic expected_match;

    begin
      expected_match = |expected_vector;
      search_data_i  = search_value;

      #1;

      if (match_vector_o !== expected_vector) begin
        $fatal(
          1,
          "search=0x%08h expected_vector=%b actual_vector=%b",
          search_value,
          expected_vector,
          match_vector_o
        );
      end

      if (match_o !== expected_match) begin
        $fatal(
          1,
          "search=0x%08h expected_match=%b actual_match=%b",
          search_value,
          expected_match,
          match_o
        );
      end

      if (miss_o !== !expected_match) begin
        $fatal(
          1,
          "search=0x%08h expected_miss=%b actual_miss=%b",
          search_value,
          !expected_match,
          miss_o
        );
      end

      $display(
        "PASS: search=0x%08h vector=%b match=%b miss=%b",
        search_value,
        match_vector_o,
        match_o,
        miss_o
      );
    end
  endtask

  initial begin
    clk_i         = 1'b0;
    rstn_i        = 1'b0;
    write_en_i    = 1'b0;
    write_addr_i  = 2'b00;
    write_data_i  = 32'b0;
    search_data_i = 32'b0;

    // Generate a waveform file
    $dumpfile("build/cam_4x32_tb.vcd");
    $dumpvars(0, cam_4x32_tb);

    // Hold reset for two clock cycles
    repeat (2) @(posedge clk_i);

    @(negedge clk_i);
    rstn_i = 1'b1;

    // Test 1: an empty CAM must produce a miss
    check_search(32'h00000000, 4'b0000);

    // Fill all four entries
    write_entry(2'd0, 32'h12345678);
    write_entry(2'd1, 32'hAAAAAAAA);
    write_entry(2'd2, 32'hDEADBEEF);
    write_entry(2'd3, 32'h00000005);

    // Test 2: match each entry
    check_search(32'h12345678, 4'b0001);
    check_search(32'hAAAAAAAA, 4'b0010);
    check_search(32'hDEADBEEF, 4'b0100);
    check_search(32'h00000005, 4'b1000);

    // Test 3: search for an absent value
    check_search(32'hFFFFFFFF, 4'b0000);

    // Test 4: two entries contain the same value
    write_entry(2'd3, 32'hAAAAAAAA);
    check_search(32'hAAAAAAAA, 4'b1010);

    // Test 5: overwrite entry 1
    write_entry(2'd1, 32'hCAFEBABE);
    check_search(32'hAAAAAAAA, 4'b1000);
    check_search(32'hCAFEBABE, 4'b0010);

    // Test 6: reset invalidates all entries
    @(negedge clk_i);
    rstn_i = 1'b0;

    #1;
    check_search(32'hCAFEBABE, 4'b0000);

    $display("All CAM tests passed.");
    $finish;
  end

endmodule : cam_4x32_tb
