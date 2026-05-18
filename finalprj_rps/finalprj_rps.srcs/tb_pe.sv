`timescale 1ns/1ps

module tb_pe;

logic clk;
logic rst_n;

logic clear;
logic mac_en;
logic drain_en;

logic signed [7:0]  left_in;
logic signed [7:0]  top_in;
logic signed [31:0] drain_in;

logic signed [7:0]  right_out;
logic signed [7:0]  bottom_out;
logic signed [31:0] drain_out;
logic signed [31:0] acc_out;

PE dut (
    .i_CLK      (clk),
    .i_RST_n    (rst_n),
    .i_CLEAR    (clear),
    .i_MAC_EN   (mac_en),
    .i_DRAIN_EN (drain_en),
    .i_LEFT     (left_in),
    .i_TOP      (top_in),
    .i_DRAIN    (drain_in),
    .o_RIGHT    (right_out),
    .o_BOTTOM   (bottom_out),
    .o_DRAIN    (drain_out),
    .o_ACC      (acc_out)
);

always #5 clk = ~clk;

task automatic check_acc(input signed [31:0] expected);
begin
    #1;
    if(acc_out !== expected) begin
        $display("FAIL acc: expected %0d, got %0d at %0t", expected, acc_out, $time);
        $stop;
    end
end
endtask

task automatic check_shift(input signed [7:0] expected_right, input signed [7:0] expected_bottom);
begin
    #1;
    if(right_out !== expected_right || bottom_out !== expected_bottom) begin
        $display("FAIL shift: expected right=%0d bottom=%0d, got right=%0d bottom=%0d at %0t",
                 expected_right, expected_bottom, right_out, bottom_out, $time);
        $stop;
    end
end
endtask

initial begin
    clk      = 1'b0;
    rst_n    = 1'b0;
    clear    = 1'b0;
    mac_en   = 1'b0;
    drain_en = 1'b0;
    left_in  = 8'sd0;
    top_in   = 8'sd0;
    drain_in = 32'sd0;

    repeat(2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    @(negedge clk);
    clear = 1'b1;
    @(posedge clk);
    @(negedge clk);
    clear = 1'b0;
    @(posedge clk);
    check_acc(32'sd0);

    @(negedge clk);
    left_in = 8'sd2;
    top_in  = 8'sd3;
    mac_en  = 1'b1;
    @(posedge clk);
    @(negedge clk);
    mac_en = 1'b0;
    @(posedge clk);
    check_acc(32'sd6);
    check_shift(8'sd2, 8'sd3);

    @(negedge clk);
    left_in = -8'sd4;
    top_in  = 8'sd5;
    mac_en  = 1'b1;
    @(posedge clk);
    @(negedge clk);
    mac_en = 1'b0;
    @(posedge clk);
    check_acc(-32'sd14);
    check_shift(-8'sd4, 8'sd5);

    @(negedge clk);
    drain_in = 32'sd1234;
    drain_en = 1'b1;
    @(posedge clk);
    @(negedge clk);
    drain_en = 1'b0;
    @(posedge clk);
    #1;

    if(drain_out !== -32'sd14) begin
        $display("FAIL drain_out: expected -14, got %0d at %0t", drain_out, $time);
        $stop;
    end
    check_acc(32'sd1234);

    @(negedge clk);
    clear = 1'b1;
    @(posedge clk);
    @(negedge clk);
    clear = 1'b0;
    @(posedge clk);
    check_acc(32'sd0);

    $display("PE test passed");
    $finish;
end

endmodule
