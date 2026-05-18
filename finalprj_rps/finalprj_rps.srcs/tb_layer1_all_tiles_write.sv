`timescale 1ns/1ps

module tb_layer1_all_tiles_write;

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

task automatic check_word(input logic [13:0] addr, input logic [127:0] expected);
    logic [127:0] actual;
begin
    actual = dut.u_bram.mem[addr];
    if(actual !== expected) begin
        $display("FAIL mem[%04h]: expected %032h, got %032h", addr, expected, actual);
        $stop;
    end
end
endtask

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

    check_word(14'h2700, 128'h000300000000001300000c0000000002);
    check_word(14'h270f, 128'h0000000000000000000000000000000b);
    check_word(14'h2710, 128'h01000000000000000000000000000000);
    check_word(14'h2770, 128'h00000000000000000000000000000000);
    check_word(14'h277f, 128'h000005000000000d0000000000000000);

    $display("LAYER1 ALL TILES WRITE test passed");
    $finish;
end

endmodule
