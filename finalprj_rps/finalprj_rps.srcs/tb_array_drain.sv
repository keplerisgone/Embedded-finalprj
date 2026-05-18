`timescale 1ns/1ps

module tb_array_drain;

localparam int unsigned SIZE = 2;
localparam int unsigned WIDTH = 8;

logic clk;
logic rst_n;
logic clear;
logic mac_en;
logic drain_en;

logic signed [(SIZE*WIDTH)-1:0]       left_raw_vec;
logic signed [(SIZE*WIDTH)-1:0]       top_raw_vec;
logic signed [(SIZE*WIDTH)-1:0]       left_skewed_vec;
logic signed [(SIZE*WIDTH)-1:0]       top_skewed_vec;
logic signed [(SIZE*32)-1:0]          drain_in_vec;
logic signed [(SIZE*32)-1:0]          drain_out_vec;
logic signed [(SIZE*SIZE*32)-1:0]     acc_vec;

SKEWER #(.SIZE(SIZE), .WIDTH(WIDTH)) u_left_skewer (
    .i_CLK(clk), .i_RST_n(rst_n), .i_CLEAR(clear), .i_EN(mac_en),
    .i_VEC(left_raw_vec), .o_VEC(left_skewed_vec)
);

SKEWER #(.SIZE(SIZE), .WIDTH(WIDTH)) u_top_skewer (
    .i_CLK(clk), .i_RST_n(rst_n), .i_CLEAR(clear), .i_EN(mac_en),
    .i_VEC(top_raw_vec), .o_VEC(top_skewed_vec)
);

SYSTOLIC_ARRAY #(.SIZE(SIZE)) u_array (
    .i_CLK       (clk),
    .i_RST_n     (rst_n),
    .i_CLEAR     (clear),
    .i_MAC_EN    (mac_en),
    .i_DRAIN_EN  (drain_en),
    .i_LEFT_VEC  (left_skewed_vec),
    .i_TOP_VEC   (top_skewed_vec),
    .i_DRAIN_VEC (drain_in_vec),
    .o_RIGHT_VEC (),
    .o_BOTTOM_VEC(),
    .o_DRAIN_VEC (drain_out_vec),
    .o_ACC_VEC   (acc_vec)
);

always #5 clk = ~clk;

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

task automatic step_mac(input logic signed [7:0] left0,
                        input logic signed [7:0] left1,
                        input logic signed [7:0] top0,
                        input logic signed [7:0] top1);
begin
    @(negedge clk);
    set_left(left0, left1);
    set_top(top0, top1);
    mac_en = 1'b1;
    drain_en = 1'b0;
    @(posedge clk);
end
endtask

task automatic step_drain(input logic signed [31:0] exp0,
                          input logic signed [31:0] exp1);
begin
    @(negedge clk);
    mac_en = 1'b0;
    drain_en = 1'b1;
    drain_in_vec = '0;
    @(posedge clk);
    #1;

    if(drain_out_vec[(0*32) +: 32] !== exp0 ||
       drain_out_vec[(1*32) +: 32] !== exp1) begin
        $display("FAIL drain: expected {%0d,%0d}, got {%0d,%0d} at %0t",
                 exp0, exp1,
                 drain_out_vec[(0*32) +: 32],
                 drain_out_vec[(1*32) +: 32],
                 $time);
        $stop;
    end
end
endtask

initial begin
    clk          = 1'b0;
    rst_n        = 1'b0;
    clear        = 1'b0;
    mac_en       = 1'b0;
    drain_en     = 1'b0;
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

    // A = [[1, 2], [3, 4]], B = [[5, 6], [7, 8]]
    step_mac(8'sd1, 8'sd3, 8'sd5, 8'sd6);
    step_mac(8'sd2, 8'sd4, 8'sd7, 8'sd8);
    step_mac(8'sd0, 8'sd0, 8'sd0, 8'sd0);
    step_mac(8'sd0, 8'sd0, 8'sd0, 8'sd0);
    step_mac(8'sd0, 8'sd0, 8'sd0, 8'sd0);

    step_drain(32'sd43, 32'sd50);
    step_drain(32'sd19, 32'sd22);

    @(negedge clk);
    drain_en = 1'b0;
    @(posedge clk);

    $display("ARRAY drain test passed");
    $finish;
end

endmodule
