`timescale 1ns/1ps

module tb_control_bram_read;

logic clk;
logic rst_n;
logic proc_start;
logic proc_done;

logic s_axi_aresetn;
logic [31:0] s_axi_awaddr;
logic s_axi_awvalid;
logic s_axi_awready;
logic [31:0] s_axi_wdata;
logic [3:0]  s_axi_wstrb;
logic s_axi_wvalid;
logic s_axi_wready;
logic [1:0] s_axi_bresp;
logic s_axi_bvalid;
logic s_axi_bready;
logic [31:0] s_axi_araddr;
logic s_axi_arvalid;
logic s_axi_arready;
logic [31:0] s_axi_rdata;
logic [1:0] s_axi_rresp;
logic s_axi_rvalid;
logic s_axi_rready;

localparam logic [127:0] EXPECT_WEIGHT_WORD = 128'h122417241b19151d1c0cfcf1f5fafefd;
localparam logic [127:0] EXPECT_INPUT_WORD  = 128'hfafcfcfdf7f6f9f8f7fbfefcf9f9fafa;

finalprj_top dut (
    .i_CLK          (clk),
    .i_RST_n        (rst_n),
    .i_PROC_START   (proc_start),
    .o_PROC_DONE    (proc_done),
    .S_AXI_ARESETN  (s_axi_aresetn),
    .S_AXI_AWADDR   (s_axi_awaddr),
    .S_AXI_AWVALID  (s_axi_awvalid),
    .S_AXI_AWREADY  (s_axi_awready),
    .S_AXI_WDATA    (s_axi_wdata),
    .S_AXI_WSTRB    (s_axi_wstrb),
    .S_AXI_WVALID   (s_axi_wvalid),
    .S_AXI_WREADY   (s_axi_wready),
    .S_AXI_BRESP    (s_axi_bresp),
    .S_AXI_BVALID   (s_axi_bvalid),
    .S_AXI_BREADY   (s_axi_bready),
    .S_AXI_ARADDR   (s_axi_araddr),
    .S_AXI_ARVALID  (s_axi_arvalid),
    .S_AXI_ARREADY  (s_axi_arready),
    .S_AXI_RDATA    (s_axi_rdata),
    .S_AXI_RRESP    (s_axi_rresp),
    .S_AXI_RVALID   (s_axi_rvalid),
    .S_AXI_RREADY   (s_axi_rready)
);

always #5 clk = ~clk;

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    proc_start = 1'b0;
    s_axi_aresetn = 1'b0;
    s_axi_awaddr = 32'd0;
    s_axi_awvalid = 1'b0;
    s_axi_wdata = 32'd0;
    s_axi_wstrb = 4'd0;
    s_axi_wvalid = 1'b0;
    s_axi_bready = 1'b1;
    s_axi_araddr = 32'd0;
    s_axi_arvalid = 1'b0;
    s_axi_rready = 1'b1;

    repeat(3) @(posedge clk);
    rst_n = 1'b1;
    s_axi_aresetn = 1'b1;

    @(negedge clk);
    proc_start = 1'b1;
    @(negedge clk);
    proc_start = 1'b0;

    wait(proc_done === 1'b1);
    #1;

    if(dut.u_ctrl.debug_pa_first_word !== EXPECT_INPUT_WORD) begin
        $display("FAIL Port A input word: expected %032h, got %032h",
                 EXPECT_INPUT_WORD, dut.u_ctrl.debug_pa_first_word);
        $stop;
    end

    if(dut.u_ctrl.debug_pb_first_word !== EXPECT_WEIGHT_WORD) begin
        $display("FAIL Port B weight word: expected %032h, got %032h",
                 EXPECT_WEIGHT_WORD, dut.u_ctrl.debug_pb_first_word);
        $stop;
    end

    $display("CONTROL BRAM read test passed");
    $finish;
end

endmodule
