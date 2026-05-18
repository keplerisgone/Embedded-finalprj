`timescale 1ns/1ps

module tb_skewer;

localparam int unsigned SIZE = 4;
localparam int unsigned WIDTH = 8;

logic clk;
logic rst_n;
logic clear;
logic en;

logic signed [(SIZE*WIDTH)-1:0] in_vec;
logic signed [(SIZE*WIDTH)-1:0] out_vec;

SKEWER #(
    .SIZE(SIZE),
    .WIDTH(WIDTH)
) dut (
    .i_CLK   (clk),
    .i_RST_n (rst_n),
    .i_CLEAR (clear),
    .i_EN    (en),
    .i_VEC   (in_vec),
    .o_VEC   (out_vec)
);

always #5 clk = ~clk;

task automatic set_vec(input logic signed [7:0] v0,
                       input logic signed [7:0] v1,
                       input logic signed [7:0] v2,
                       input logic signed [7:0] v3);
begin
    in_vec[(0*WIDTH) +: WIDTH] = v0;
    in_vec[(1*WIDTH) +: WIDTH] = v1;
    in_vec[(2*WIDTH) +: WIDTH] = v2;
    in_vec[(3*WIDTH) +: WIDTH] = v3;
end
endtask

task automatic check_vec(input logic signed [7:0] e0,
                         input logic signed [7:0] e1,
                         input logic signed [7:0] e2,
                         input logic signed [7:0] e3);
begin
    #1;
    if(out_vec[(0*WIDTH) +: WIDTH] !== e0 ||
       out_vec[(1*WIDTH) +: WIDTH] !== e1 ||
       out_vec[(2*WIDTH) +: WIDTH] !== e2 ||
       out_vec[(3*WIDTH) +: WIDTH] !== e3) begin
        $display("FAIL out: expected {%0d,%0d,%0d,%0d}, got {%0d,%0d,%0d,%0d} at %0t",
                 e0, e1, e2, e3,
                 out_vec[(0*WIDTH) +: WIDTH],
                 out_vec[(1*WIDTH) +: WIDTH],
                 out_vec[(2*WIDTH) +: WIDTH],
                 out_vec[(3*WIDTH) +: WIDTH],
                 $time);
        $stop;
    end
end
endtask

task automatic step(input logic signed [7:0] v0,
                    input logic signed [7:0] v1,
                    input logic signed [7:0] v2,
                    input logic signed [7:0] v3);
begin
    @(negedge clk);
    set_vec(v0, v1, v2, v3);
    en = 1'b1;
    @(posedge clk);
end
endtask

initial begin
    clk    = 1'b0;
    rst_n  = 1'b0;
    clear  = 1'b0;
    en     = 1'b0;
    in_vec = '0;

    repeat(2) @(posedge clk);
    rst_n = 1'b1;

    @(negedge clk);
    clear = 1'b1;
    @(posedge clk);
    @(negedge clk);
    clear = 1'b0;

    step(8'sd10, 8'sd20, 8'sd30, 8'sd40);
    check_vec(8'sd10, 8'sd0,  8'sd0,  8'sd0);

    step(8'sd11, 8'sd21, 8'sd31, 8'sd41);
    check_vec(8'sd11, 8'sd20, 8'sd0,  8'sd0);

    step(8'sd12, 8'sd22, 8'sd32, 8'sd42);
    check_vec(8'sd12, 8'sd21, 8'sd30, 8'sd0);

    step(8'sd13, 8'sd23, 8'sd33, 8'sd43);
    check_vec(8'sd13, 8'sd22, 8'sd31, 8'sd40);

    $display("SKEWER SIZE=4 test passed");
    $finish;
end

endmodule
