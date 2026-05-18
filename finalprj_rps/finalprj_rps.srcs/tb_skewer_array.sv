`timescale 1ns/1ps

module tb_skewer_array;

localparam int unsigned SIZE = 2;
localparam int unsigned WIDTH = 8;

logic clk;
logic rst_n;
logic clear;
logic en;

logic signed [(SIZE*WIDTH)-1:0]       left_raw_vec;
logic signed [(SIZE*WIDTH)-1:0]       top_raw_vec;
logic signed [(SIZE*WIDTH)-1:0]       left_skewed_vec;
logic signed [(SIZE*WIDTH)-1:0]       top_skewed_vec;
logic signed [(SIZE*32)-1:0]          drain_in_vec;
logic signed [(SIZE*WIDTH)-1:0]       right_vec;
logic signed [(SIZE*WIDTH)-1:0]       bottom_vec;
logic signed [(SIZE*32)-1:0]          drain_out_vec;
logic signed [(SIZE*SIZE*32)-1:0]     acc_vec;

SKEWER #(
    .SIZE(SIZE),
    .WIDTH(WIDTH)
) u_left_skewer (
    .i_CLK   (clk),
    .i_RST_n (rst_n),
    .i_CLEAR (clear),
    .i_EN    (en),
    .i_VEC   (left_raw_vec),
    .o_VEC   (left_skewed_vec)
);

SKEWER #(
    .SIZE(SIZE),
    .WIDTH(WIDTH)
) u_top_skewer (
    .i_CLK   (clk),
    .i_RST_n (rst_n),
    .i_CLEAR (clear),
    .i_EN    (en),
    .i_VEC   (top_raw_vec),
    .o_VEC   (top_skewed_vec)
);

SYSTOLIC_ARRAY #(
    .SIZE(SIZE)
) u_array (
    .i_CLK       (clk),
    .i_RST_n     (rst_n),
    .i_CLEAR     (clear),
    .i_MAC_EN    (en),
    .i_DRAIN_EN  (1'b0),
    .i_LEFT_VEC  (left_skewed_vec),
    .i_TOP_VEC   (top_skewed_vec),
    .i_DRAIN_VEC (drain_in_vec),
    .o_RIGHT_VEC (right_vec),
    .o_BOTTOM_VEC(bottom_vec),
    .o_DRAIN_VEC (drain_out_vec),
    .o_ACC_VEC   (acc_vec)
);

always #5 clk = ~clk;

function automatic logic signed [31:0] get_acc(input int row, input int col);
begin
    get_acc = acc_vec[((row*SIZE + col)*32) +: 32];
end
endfunction

task automatic set_left(input logic signed [7:0] row0,
                        input logic signed [7:0] row1);
begin
    left_raw_vec[(0*WIDTH) +: WIDTH] = row0;
    left_raw_vec[(1*WIDTH) +: WIDTH] = row1;
end
endtask

task automatic set_top(input logic signed [7:0] col0,
                       input logic signed [7:0] col1);
begin
    top_raw_vec[(0*WIDTH) +: WIDTH] = col0;
    top_raw_vec[(1*WIDTH) +: WIDTH] = col1;
end
endtask

task automatic step(input logic signed [7:0] left0,
                    input logic signed [7:0] left1,
                    input logic signed [7:0] top0,
                    input logic signed [7:0] top1);
begin
    @(negedge clk);
    set_left(left0, left1);
    set_top(top0, top1);
    en = 1'b1;
    @(posedge clk);
end
endtask

task automatic check_acc(input int row, input int col, input logic signed [31:0] expected);
    logic signed [31:0] actual;
begin
    #1;
    actual = get_acc(row, col);
    if(actual !== expected) begin
        $display("FAIL C%0d%0d: expected %0d, got %0d at %0t",
                 row, col, expected, actual, $time);
        $stop;
    end
end
endtask

initial begin
    clk          = 1'b0;
    rst_n        = 1'b0;
    clear        = 1'b0;
    en           = 1'b0;
    left_raw_vec = '0;
    top_raw_vec  = '0;
    drain_in_vec = '0;

    repeat(2) @(posedge clk);
    rst_n = 1'b1;

    @(negedge clk);
    clear = 1'b1;
    @(posedge clk);
    @(negedge clk);
    clear = 1'b0;

    // Raw, unskewed matrix streams:
    // A rows over k: cycle0=[a00,a10], cycle1=[a01,a11]
    // B cols over k: cycle0=[b00,b01], cycle1=[b10,b11]
    //
    // A = [[1, 2], [3, 4]]
    // B = [[5, 6], [7, 8]]
    // C = [[19, 22], [43, 50]]
    step(8'sd1, 8'sd3, 8'sd5, 8'sd6);
    step(8'sd2, 8'sd4, 8'sd7, 8'sd8);
    step(8'sd0, 8'sd0, 8'sd0, 8'sd0);
    step(8'sd0, 8'sd0, 8'sd0, 8'sd0);
    step(8'sd0, 8'sd0, 8'sd0, 8'sd0);

    @(negedge clk);
    en = 1'b0;
    set_left(8'sd0, 8'sd0);
    set_top(8'sd0, 8'sd0);
    @(posedge clk);

    check_acc(0, 0, 32'sd19);
    check_acc(0, 1, 32'sd22);
    check_acc(1, 0, 32'sd43);
    check_acc(1, 1, 32'sd50);

    $display("SKEWER + SYSTOLIC_ARRAY SIZE=2 test passed");
    $finish;
end

endmodule
