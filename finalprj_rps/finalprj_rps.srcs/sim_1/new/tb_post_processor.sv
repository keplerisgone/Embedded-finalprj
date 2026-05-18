`timescale 1ns/1ps

module tb_post_processor;

logic clk;
logic rst_n;
logic en;

logic signed [31:0] acc;
logic [31:0] scaler;
logic signed [7:0] data;
logic valid;

POST_PROCESSOR dut (
    .i_CLK    (clk),
    .i_RST_n  (rst_n),
    .i_EN     (en),
    .i_ACC    (acc),
    .i_SCALER (scaler),
    .o_DATA   (data),
    .o_VALID  (valid)
);

always #5 clk = ~clk;

task automatic step(input logic signed [31:0] acc_value,
                    input logic [31:0] scaler_value,
                    input logic signed [7:0] expected);
begin
    @(negedge clk);
    acc = acc_value;
    scaler = scaler_value;
    en = 1'b1;
    @(posedge clk);
    #1;

    if(!valid) begin
        $display("FAIL valid: expected 1 at %0t", $time);
        $stop;
    end

    if(data !== expected) begin
        $display("FAIL data: acc=%0d scaler=0x%08h expected %0d, got %0d at %0t",
                 acc_value, scaler_value, expected, data, $time);
        $stop;
    end
end
endtask

initial begin
    clk    = 1'b0;
    rst_n  = 1'b0;
    en     = 1'b0;
    acc    = 32'sd0;
    scaler = 32'd0;

    repeat(2) @(posedge clk);
    rst_n = 1'b1;

    // Negative accumulations are clamped by ReLU.
    step(-32'sd10, 32'hFFFF_FFFF, 8'sd0);

    // M ~= 1.0, small positive values should remain unchanged.
    step(32'sd42, 32'hFFFF_FFFF, 8'sd42);

    // 0.5 scaling with round-to-nearest: 5 * 0.5 = 2.5 -> 3.
    step(32'sd5, 32'h8000_0000, 8'sd3);

    // Saturation after scaling.
    step(32'sd300, 32'hFFFF_FFFF, 8'sd127);

    @(negedge clk);
    en = 1'b0;
    @(posedge clk);
    #1;

    if(valid !== 1'b0) begin
        $display("FAIL valid: expected 0 when disabled at %0t", $time);
        $stop;
    end

    $display("POST_PROCESSOR test passed");
    $finish;
end

endmodule
