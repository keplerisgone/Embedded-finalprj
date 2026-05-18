module finalprj_top (
    //ports : DO NOT MODIFY
    input   wire                    i_CLK,
    input   wire                    i_RST_n,

    input   wire                    i_PROC_START,
    output  logic                   o_PROC_DONE,

    input   wire                    S_AXI_ARESETN,
    input   wire    [31:0]          S_AXI_AWADDR,
    input   wire                    S_AXI_AWVALID,
    output  logic                   S_AXI_AWREADY,
    input   wire    [31:0]          S_AXI_WDATA,
    input   wire    [3:0]           S_AXI_WSTRB,
    input   wire                    S_AXI_WVALID,
    output  logic                   S_AXI_WREADY,
    output  wire    [1:0]           S_AXI_BRESP,
    output  logic                   S_AXI_BVALID,
    input   wire                    S_AXI_BREADY,
    input   wire    [31:0]          S_AXI_ARADDR,
    input   wire                    S_AXI_ARVALID,
    output  logic                   S_AXI_ARREADY,
    output  logic   [31:0]          S_AXI_RDATA,
    output  wire    [1:0]           S_AXI_RRESP,
    output  logic                   S_AXI_RVALID,
    input   wire                    S_AXI_RREADY
);



//=========================================================================
// BRAM instance : You can freely configure ports A and B
//=========================================================================

logic   [13:0]      bram_pa_addr;
logic               bram_pa_wr;
logic   [127:0]     bram_pa_wdata;
logic   [127:0]     bram_pa_rdata;
wire                bram_pa_busy;

logic   [13:0]      bram_pb_addr;
logic               bram_pb_wr;
logic   [127:0]     bram_pb_wdata;
logic   [127:0]     bram_pb_rdata;

BRAM_TDP #(
    .INIT_FILE          ("bram_init.txt"            )
) u_bram (
    //Port A - I/O path  (read input matrix, write output matrix) + AXI
    .i_PA_ADDR          (bram_pa_addr               ),
    .i_PA_WR            (bram_pa_wr                 ),
    .i_PA_WDATA         (bram_pa_wdata              ),
    .o_PA_RDATA         (bram_pa_rdata              ),
    .o_PA_BUSY          (bram_pa_busy               ),

    //Port B - weight path  (read only from RTL side)
    .i_PB_ADDR          (bram_pb_addr               ),
    .i_PB_WR            (bram_pb_wr                 ),
    .i_PB_WDATA         (bram_pb_wdata              ),
    .o_PB_RDATA         (bram_pb_rdata              ),

    //AXI4-Lite pass-through : DO NOT MODIFY FROM HERE
    .i_CLK              (i_CLK                      ),
    .i_RST_n            (S_AXI_ARESETN              ),

    .S_AXI_AWADDR       (S_AXI_AWADDR               ),
    .S_AXI_AWVALID      (S_AXI_AWVALID              ),
    .S_AXI_AWREADY      (S_AXI_AWREADY              ),
    .S_AXI_WDATA        (S_AXI_WDATA                ),
    .S_AXI_WSTRB        (S_AXI_WSTRB                ),
    .S_AXI_WVALID       (S_AXI_WVALID               ),
    .S_AXI_WREADY       (S_AXI_WREADY               ),
    .S_AXI_BRESP        (S_AXI_BRESP                ),
    .S_AXI_BVALID       (S_AXI_BVALID               ),
    .S_AXI_BREADY       (S_AXI_BREADY               ),
    .S_AXI_ARADDR       (S_AXI_ARADDR               ),
    .S_AXI_ARVALID      (S_AXI_ARVALID              ),
    .S_AXI_ARREADY      (S_AXI_ARREADY              ),
    .S_AXI_RDATA        (S_AXI_RDATA                ),
    .S_AXI_RRESP        (S_AXI_RRESP                ),
    .S_AXI_RVALID       (S_AXI_RVALID               ),
    .S_AXI_RREADY       (S_AXI_RREADY               )
);



//=========================================================================
// CONTROL instance : Write your own control module
//=========================================================================

CONTROL u_ctrl (
    .i_CLK              (i_CLK                      ),
    .i_RST_n            (i_RST_n                    ),

    .i_PROC_START       (i_PROC_START               ),
    .o_PROC_DONE        (o_PROC_DONE                ),

    .o_PA_ADDR          (bram_pa_addr               ),
    .o_PA_WR            (bram_pa_wr                 ),
    .o_PA_WDATA         (bram_pa_wdata              ),
    .i_PA_RDATA         (bram_pa_rdata              ),
    .i_PA_BUSY          (bram_pa_busy               ),

    .o_PB_ADDR          (bram_pb_addr               ),
    .o_PB_WR            (bram_pb_wr                 ),
    .o_PB_WDATA         (bram_pb_wdata              ),
    .i_PB_RDATA         (bram_pb_rdata              )
);

endmodule

//=========================================================================
// PROCESSING ELEMENT
//=========================================================================

module PE (
    input   wire                    i_CLK,
    input   wire                    i_RST_n,

    input   wire                    i_CLEAR,
    input   wire                    i_MAC_EN,
    input   wire                    i_DRAIN_EN,

    input   wire    signed  [7:0]   i_LEFT,
    input   wire    signed  [7:0]   i_TOP,
    input   wire    signed  [31:0]  i_DRAIN,

    output  logic   signed  [7:0]   o_RIGHT,
    output  logic   signed  [7:0]   o_BOTTOM,
    output  logic   signed  [31:0]  o_DRAIN,
    output  logic   signed  [31:0]  o_ACC
);

logic signed [31:0] acc;
logic signed [15:0] product;

assign product = i_LEFT * i_TOP;
assign o_ACC = acc;

always_ff @(posedge i_CLK) begin
    if(!i_RST_n) begin
        o_RIGHT  <= 8'sd0;
        o_BOTTOM <= 8'sd0;
        o_DRAIN  <= 32'sd0;
        acc      <= 32'sd0;
    end
    else begin
        if(i_CLEAR) begin
            acc <= 32'sd0;
        end
        else if(i_MAC_EN) begin
            acc <= acc + {{16{product[15]}}, product};
        end

        if(i_MAC_EN) begin
            o_RIGHT  <= i_LEFT;
            o_BOTTOM <= i_TOP;
        end

        if(i_DRAIN_EN) begin
            o_DRAIN <= acc;
            acc     <= i_DRAIN;
        end
    end
end

endmodule

//=========================================================================
// POST PROCESSOR
//=========================================================================

module POST_PROCESSOR (
    input   wire                    i_CLK,
    input   wire                    i_RST_n,
    input   wire                    i_EN,

    input   wire    signed  [31:0]  i_ACC,
    input   wire            [31:0]  i_SCALER,

    output  logic   signed  [7:0]   o_DATA,
    output  logic                   o_VALID
);

logic [31:0] relu_value;
logic [63:0] scaled_value;
logic [31:0] rounded_value;

always_comb begin
    relu_value = i_ACC[31] ? 32'd0 : i_ACC[31:0];
    scaled_value = relu_value * i_SCALER;
    rounded_value = (scaled_value + 64'h0000_0000_8000_0000) >> 32;
end

always_ff @(posedge i_CLK) begin
    if(!i_RST_n) begin
        o_DATA  <= 8'sd0;
        o_VALID <= 1'b0;
    end
    else begin
        o_VALID <= i_EN;

        if(i_EN) begin
            if(rounded_value > 32'd127) begin
                o_DATA <= 8'sd127;
            end
            else begin
                o_DATA <= rounded_value[7:0];
            end
        end
    end
end

endmodule


module POST_PROCESSOR_VECTOR #(
    parameter int unsigned SIZE = 16
) (
    input   wire                                i_CLK,
    input   wire                                i_RST_n,
    input   wire                                i_EN,

    input   wire    signed  [(SIZE*32)-1:0]     i_ACC_VEC,
    input   wire            [31:0]              i_SCALER,

    output  logic   signed  [(SIZE*8)-1:0]      o_DATA_VEC,
    output  logic                               o_VALID
);

logic [SIZE-1:0] valid_vec;

genvar lane;

generate
    for(lane = 0; lane < SIZE; lane = lane + 1) begin : gen_post_processors
        POST_PROCESSOR u_post_processor (
            .i_CLK    (i_CLK),
            .i_RST_n  (i_RST_n),
            .i_EN     (i_EN),
            .i_ACC    (i_ACC_VEC[(lane*32) +: 32]),
            .i_SCALER (i_SCALER),
            .o_DATA   (o_DATA_VEC[(lane*8) +: 8]),
            .o_VALID  (valid_vec[lane])
        );
    end
endgenerate

always_comb begin
    o_VALID = valid_vec[0];
end

endmodule

//=========================================================================
// SKEWER
//=========================================================================

module SKEWER #(
    parameter int unsigned SIZE = 16,
    parameter int unsigned WIDTH = 8
) (
    input   wire                                i_CLK,
    input   wire                                i_RST_n,
    input   wire                                i_CLEAR,
    input   wire                                i_EN,

    input   wire    signed  [(SIZE*WIDTH)-1:0]  i_VEC,
    output  logic   signed  [(SIZE*WIDTH)-1:0]  o_VEC
);

logic signed [WIDTH-1:0] delay_line [0:SIZE-1][0:SIZE-1];

genvar lane;

generate
    for(lane = 0; lane < SIZE; lane = lane + 1) begin : gen_skew_lanes
        always_ff @(posedge i_CLK) begin
            if(!i_RST_n) begin
                for(int i = 0; i < SIZE; i = i + 1) begin
                    delay_line[lane][i] <= '0;
                end
                o_VEC[(lane*WIDTH) +: WIDTH] <= '0;
            end
            else if(i_CLEAR) begin
                for(int i = 0; i < SIZE; i = i + 1) begin
                    delay_line[lane][i] <= '0;
                end
                o_VEC[(lane*WIDTH) +: WIDTH] <= '0;
            end
            else if(i_EN) begin
                delay_line[lane][0] <= i_VEC[(lane*WIDTH) +: WIDTH];

                for(int i = 1; i < SIZE; i = i + 1) begin
                    delay_line[lane][i] <= delay_line[lane][i-1];
                end

                if(lane == 0) begin
                    o_VEC[(lane*WIDTH) +: WIDTH] <= i_VEC[(lane*WIDTH) +: WIDTH];
                end
                else begin
                    o_VEC[(lane*WIDTH) +: WIDTH] <= delay_line[lane][lane-1];
                end
            end
        end
    end
endgenerate

endmodule

//=========================================================================
// 16x16 SYSTOLIC ARRAY
//=========================================================================

module SYSTOLIC_ARRAY #(
    parameter int unsigned SIZE = 16
) (
    input   wire                                    i_CLK,
    input   wire                                    i_RST_n,

    input   wire                                    i_CLEAR,
    input   wire                                    i_MAC_EN,
    input   wire                                    i_DRAIN_EN,

    input   wire    signed  [(SIZE*8)-1:0]          i_LEFT_VEC,
    input   wire    signed  [(SIZE*8)-1:0]          i_TOP_VEC,
    input   wire    signed  [(SIZE*32)-1:0]         i_DRAIN_VEC,

    output  logic   signed  [(SIZE*8)-1:0]          o_RIGHT_VEC,
    output  logic   signed  [(SIZE*8)-1:0]          o_BOTTOM_VEC,
    output  logic   signed  [(SIZE*32)-1:0]         o_DRAIN_VEC,
    output  logic   signed  [(SIZE*SIZE*32)-1:0]    o_ACC_VEC
);

logic signed [7:0]  left_to_right [0:SIZE-1][0:SIZE];
logic signed [7:0]  top_to_bottom [0:SIZE][0:SIZE-1];
logic signed [31:0] acc           [0:SIZE-1][0:SIZE-1];
logic signed [31:0] drain_out     [0:SIZE-1][0:SIZE-1];

genvar row;
genvar col;

generate
    for(row = 0; row < SIZE; row = row + 1) begin : gen_array_rows
        assign left_to_right[row][0] = i_LEFT_VEC[(row*8) +: 8];
        assign o_RIGHT_VEC[(row*8) +: 8] = left_to_right[row][SIZE];

        for(col = 0; col < SIZE; col = col + 1) begin : gen_array_cols
            if(row == 0) begin : gen_top_inputs
                assign top_to_bottom[0][col] = i_TOP_VEC[(col*8) +: 8];
            end

            if(row == 0) begin : gen_top_row_pe
                PE u_pe (
                    .i_CLK      (i_CLK),
                    .i_RST_n    (i_RST_n),
                    .i_CLEAR    (i_CLEAR),
                    .i_MAC_EN   (i_MAC_EN),
                    .i_DRAIN_EN (i_DRAIN_EN),
                    .i_LEFT     (left_to_right[row][col]),
                    .i_TOP      (top_to_bottom[row][col]),
                    .i_DRAIN    (i_DRAIN_VEC[(col*32) +: 32]),
                    .o_RIGHT    (left_to_right[row][col+1]),
                    .o_BOTTOM   (top_to_bottom[row+1][col]),
                    .o_DRAIN    (drain_out[row][col]),
                    .o_ACC      (acc[row][col])
                );
            end
            else begin : gen_inner_pe
                PE u_pe (
                    .i_CLK      (i_CLK),
                    .i_RST_n    (i_RST_n),
                    .i_CLEAR    (i_CLEAR),
                    .i_MAC_EN   (i_MAC_EN),
                    .i_DRAIN_EN (i_DRAIN_EN),
                    .i_LEFT     (left_to_right[row][col]),
                    .i_TOP      (top_to_bottom[row][col]),
                    .i_DRAIN    (acc[row-1][col]),
                    .o_RIGHT    (left_to_right[row][col+1]),
                    .o_BOTTOM   (top_to_bottom[row+1][col]),
                    .o_DRAIN    (drain_out[row][col]),
                    .o_ACC      (acc[row][col])
                );
            end

            assign o_ACC_VEC[((row*SIZE + col)*32) +: 32] = acc[row][col];

            if(row == SIZE-1) begin : gen_bottom_outputs
                assign o_BOTTOM_VEC[(col*8) +: 8] = top_to_bottom[SIZE][col];
                assign o_DRAIN_VEC[(col*32) +: 32] = drain_out[row][col];
            end
        end
    end
endgenerate

endmodule


//=========================================================================
// CONTROLLER: You can save it as a separate file
//=========================================================================

module CONTROL (
    /* CLOCK AND RESET */
    input   wire                    i_CLK,
    input   wire                    i_RST_n,

    input   wire                    i_PROC_START,
    output  logic                   o_PROC_DONE,

    output  logic   [13:0]          o_PA_ADDR,
    output  logic                   o_PA_WR,
    output  logic   [127:0]         o_PA_WDATA,
    input   wire    [127:0]         i_PA_RDATA,
    input   wire                    i_PA_BUSY,

    output  logic   [13:0]          o_PB_ADDR,
    output  logic                   o_PB_WR,
    output  logic   [127:0]         o_PB_WDATA,
    input   wire    [127:0]         i_PB_RDATA
);

//=========================================================================
// Basic useful parameters
//=========================================================================

localparam int unsigned TOTAL_LAYERS = 4;
localparam int unsigned BATCH_SIZE = 16;
localparam int unsigned SYSTOLIC_SIZE = 16;
localparam int unsigned LAYER1_K_TILES = 48;
localparam int unsigned LAYER1_OUT_TILES = 8;

localparam int unsigned W_DIMS [TOTAL_LAYERS][2] = '{
//   ROWS  COLS
    '{128,  768},
    '{128,  128},
    '{128,  128},
    '{16,   128}
};

function automatic int unsigned calc_idim(int unsigned layer, dim);
    if(dim == 0)       return BATCH_SIZE;         //ROWS: always the batch size
    else begin                                    //COLS: input features for this layer
        if(layer == 0) return W_DIMS[0][1];       //   | first layer: matches W COLS
        else           return W_DIMS[layer-1][0]; //   | subsequent layers: prev W ROWS
    end
endfunction

localparam int unsigned I_DIMS [TOTAL_LAYERS+1][2] = '{
//   ROWS            COLS
    '{calc_idim(0,0), calc_idim(0,1)},  //{16, 768}
    '{calc_idim(1,0), calc_idim(1,1)},  //{16, 128}
    '{calc_idim(2,0), calc_idim(2,1)},  //{16, 128}
    '{calc_idim(3,0), calc_idim(3,1)},  //{16, 128}
    '{calc_idim(4,0), calc_idim(4,1)}   //{16, 16}
};

//weight base address
localparam int unsigned W_BADDR [TOTAL_LAYERS] = '{
    32'h0000_0000,
    32'h0000_1800,
    32'h0000_1C00,
    32'h0000_2000
};

//input base address
localparam int unsigned I_BADDR [TOTAL_LAYERS] = '{
    32'h0000_2400,
    32'h0000_2700,
    32'h0000_2780,
    32'h0000_2800
};

//output base address
localparam int unsigned O_BADDR [TOTAL_LAYERS] = '{
    I_BADDR[1],
    I_BADDR[2],
    I_BADDR[3],
    32'h0000_2880
};

/*
    M1 = 0.00036199 x 2^32
    M2 = 0.00143881 x 2^32
    M3 = 0.01956364 x 2^32
    M4 = 1.00000000 x 2^32
*/
localparam int unsigned PP_SCALER [TOTAL_LAYERS] = '{
    32'h0017_B92F,
    32'h005E_4B3A,
    32'h0502_1F6A,
    32'hFFFF_FFFF //roughly 1.0
};

typedef enum logic [3:0] {
    CTRL_IDLE,
    CTRL_READ_ADDR,
    CTRL_WAIT_READ,
    CTRL_CAPTURE,
    CTRL_ARRAY_CLEAR,
    CTRL_FEED_ARRAY,
    CTRL_FLUSH_ARRAY,
    CTRL_LATCH_ACC,
    CTRL_PP_APPLY,
    CTRL_PP_WRITE,
    CTRL_DONE
} ctrl_state_e;

ctrl_state_e state;

logic proc_start_d;

logic [127:0] debug_pa_first_word;
logic [127:0] debug_pb_first_word;
logic signed [(SYSTOLIC_SIZE*SYSTOLIC_SIZE*32)-1:0] debug_acc_vec;

logic signed [7:0] input_tile  [0:SYSTOLIC_SIZE-1][0:SYSTOLIC_SIZE-1];
logic signed [7:0] weight_tile [0:SYSTOLIC_SIZE-1][0:SYSTOLIC_SIZE-1];

logic [4:0] tile_read_idx;
logic [4:0] feed_idx;
logic [5:0] k_tile_idx;
logic [3:0] out_tile_idx;
logic [5:0] flush_count;
logic [4:0] post_row_idx;

logic signed [(SYSTOLIC_SIZE*8)-1:0] left_raw_vec;
logic signed [(SYSTOLIC_SIZE*8)-1:0] top_raw_vec;
logic signed [(SYSTOLIC_SIZE*8)-1:0] left_skewed_vec;
logic signed [(SYSTOLIC_SIZE*8)-1:0] top_skewed_vec;
logic signed [(SYSTOLIC_SIZE*32)-1:0] drain_in_vec;
logic signed [(SYSTOLIC_SIZE*32)-1:0] drain_out_vec;
logic signed [(SYSTOLIC_SIZE*SYSTOLIC_SIZE*32)-1:0] acc_vec;
logic signed [(SYSTOLIC_SIZE*32)-1:0] pp_acc_vec;
logic signed [(SYSTOLIC_SIZE*8)-1:0] pp_data_vec;
logic pp_valid;

wire proc_start_pulse = i_PROC_START & ~proc_start_d;
wire array_clear = (state == CTRL_ARRAY_CLEAR) && (k_tile_idx == 6'd0);
wire array_mac_en = (state == CTRL_FEED_ARRAY) || (state == CTRL_FLUSH_ARRAY);

SKEWER #(
    .SIZE(SYSTOLIC_SIZE),
    .WIDTH(8)
) u_input_skewer (
    .i_CLK   (i_CLK),
    .i_RST_n (i_RST_n),
    .i_CLEAR (array_clear),
    .i_EN    (array_mac_en),
    .i_VEC   (left_raw_vec),
    .o_VEC   (left_skewed_vec)
);

SKEWER #(
    .SIZE(SYSTOLIC_SIZE),
    .WIDTH(8)
) u_weight_skewer (
    .i_CLK   (i_CLK),
    .i_RST_n (i_RST_n),
    .i_CLEAR (array_clear),
    .i_EN    (array_mac_en),
    .i_VEC   (top_raw_vec),
    .o_VEC   (top_skewed_vec)
);

SYSTOLIC_ARRAY #(
    .SIZE(SYSTOLIC_SIZE)
) u_systolic_array (
    .i_CLK       (i_CLK),
    .i_RST_n     (i_RST_n),
    .i_CLEAR     (array_clear),
    .i_MAC_EN    (array_mac_en),
    .i_DRAIN_EN  (1'b0),
    .i_LEFT_VEC  (left_skewed_vec),
    .i_TOP_VEC   (top_skewed_vec),
    .i_DRAIN_VEC (drain_in_vec),
    .o_RIGHT_VEC (),
    .o_BOTTOM_VEC(),
    .o_DRAIN_VEC (drain_out_vec),
    .o_ACC_VEC   (acc_vec)
);

POST_PROCESSOR_VECTOR #(
    .SIZE(SYSTOLIC_SIZE)
) u_post_processor_vector (
    .i_CLK      (i_CLK),
    .i_RST_n    (i_RST_n),
    .i_EN       (state == CTRL_PP_APPLY),
    .i_ACC_VEC  (pp_acc_vec),
    .i_SCALER   (PP_SCALER[0]),
    .o_DATA_VEC (pp_data_vec),
    .o_VALID    (pp_valid)
);

always_comb begin
    pp_acc_vec = '0;
    for(int lane = 0; lane < SYSTOLIC_SIZE; lane = lane + 1) begin
        pp_acc_vec[(lane*32) +: 32] = acc_vec[((post_row_idx*SYSTOLIC_SIZE + lane)*32) +: 32];
    end
end

always_ff @(posedge i_CLK) begin
    if(!i_RST_n) begin
        o_PROC_DONE <= 1'b0;
        o_PA_ADDR   <= 14'd0;
        o_PA_WR     <= 1'b0;
        o_PA_WDATA  <= 128'd0;
        o_PB_ADDR   <= 14'd0;
        o_PB_WR     <= 1'b0;
        o_PB_WDATA  <= 128'd0;
        proc_start_d <= 1'b0;
        state        <= CTRL_IDLE;
        debug_pa_first_word <= 128'd0;
        debug_pb_first_word <= 128'd0;
        debug_acc_vec <= '0;
        tile_read_idx <= 5'd0;
        feed_idx      <= 5'd0;
        k_tile_idx    <= 6'd0;
        out_tile_idx  <= 4'd0;
        flush_count   <= 6'd0;
        post_row_idx  <= 5'd0;
        left_raw_vec  <= '0;
        top_raw_vec   <= '0;
        drain_in_vec  <= '0;
    end
    else begin
        proc_start_d <= i_PROC_START;
        o_PROC_DONE <= 1'b0;
        o_PA_WR     <= 1'b0;
        o_PB_WR     <= 1'b0;
        o_PA_WDATA  <= 128'd0;
        o_PB_WDATA  <= 128'd0;

        case(state)
            CTRL_IDLE: begin
                if(proc_start_pulse) begin
                    tile_read_idx <= 5'd0;
                    k_tile_idx <= 6'd0;
                    out_tile_idx <= 4'd0;
                    state <= CTRL_READ_ADDR;
                end
            end

            CTRL_READ_ADDR: begin
                if(!i_PA_BUSY) begin
                    o_PA_ADDR <= I_BADDR[0][13:0] + (k_tile_idx * SYSTOLIC_SIZE) + tile_read_idx;
                    o_PB_ADDR <= W_BADDR[0][13:0] + (((out_tile_idx * LAYER1_K_TILES) + k_tile_idx) * SYSTOLIC_SIZE) + tile_read_idx;
                    state <= CTRL_WAIT_READ;
                end
            end

            CTRL_WAIT_READ: begin
                state <= CTRL_CAPTURE;
            end

            CTRL_CAPTURE: begin
                for(int col = 0; col < SYSTOLIC_SIZE; col = col + 1) begin
                    input_tile[tile_read_idx][col]  <= i_PA_RDATA[(col*8) +: 8];
                    weight_tile[tile_read_idx][col] <= i_PB_RDATA[(col*8) +: 8];
                end

                if(tile_read_idx == 5'd0) begin
                    debug_pa_first_word <= i_PA_RDATA;
                    debug_pb_first_word <= i_PB_RDATA;
                end

                if(tile_read_idx == SYSTOLIC_SIZE-1) begin
                    state <= CTRL_ARRAY_CLEAR;
                end
                else begin
                    tile_read_idx <= tile_read_idx + 5'd1;
                    state <= CTRL_READ_ADDR;
                end
            end

            CTRL_ARRAY_CLEAR: begin
                feed_idx <= 5'd0;
                flush_count <= 6'd0;
                drain_in_vec <= '0;

                for(int lane = 0; lane < SYSTOLIC_SIZE; lane = lane + 1) begin
                    left_raw_vec[(lane*8) +: 8] <= input_tile[lane][0];
                    top_raw_vec[(lane*8) +: 8]  <= weight_tile[lane][0];
                end

                state <= CTRL_FEED_ARRAY;
            end

            CTRL_FEED_ARRAY: begin
                if(feed_idx == SYSTOLIC_SIZE-1) begin
                    left_raw_vec <= '0;
                    top_raw_vec <= '0;
                    flush_count <= 6'd0;
                    state <= CTRL_FLUSH_ARRAY;
                end
                else begin
                    feed_idx <= feed_idx + 5'd1;

                    for(int lane = 0; lane < SYSTOLIC_SIZE; lane = lane + 1) begin
                        left_raw_vec[(lane*8) +: 8] <= input_tile[lane][feed_idx + 5'd1];
                        top_raw_vec[(lane*8) +: 8]  <= weight_tile[lane][feed_idx + 5'd1];
                    end
                end
            end

            CTRL_FLUSH_ARRAY: begin
                left_raw_vec <= '0;
                top_raw_vec <= '0;

                if(flush_count == (2*SYSTOLIC_SIZE-2)) begin
                    state <= CTRL_LATCH_ACC;
                end
                else begin
                    flush_count <= flush_count + 6'd1;
                end
            end

            CTRL_LATCH_ACC: begin
                if(k_tile_idx == LAYER1_K_TILES-1) begin
                    debug_acc_vec <= acc_vec;
                    post_row_idx <= 5'd0;
                    state <= CTRL_PP_APPLY;
                end
                else begin
                    k_tile_idx <= k_tile_idx + 6'd1;
                    tile_read_idx <= 5'd0;
                    state <= CTRL_READ_ADDR;
                end
            end

            CTRL_PP_APPLY: begin
                state <= CTRL_PP_WRITE;
            end

            CTRL_PP_WRITE: begin
                if(!i_PA_BUSY && pp_valid) begin
                    o_PA_ADDR  <= O_BADDR[0][13:0] + (out_tile_idx * SYSTOLIC_SIZE) + post_row_idx;
                    o_PA_WDATA <= pp_data_vec;
                    o_PA_WR    <= 1'b1;

                    if(post_row_idx == SYSTOLIC_SIZE-1) begin
                        if(out_tile_idx == LAYER1_OUT_TILES-1) begin
                            state <= CTRL_DONE;
                        end
                        else begin
                            out_tile_idx <= out_tile_idx + 4'd1;
                            k_tile_idx <= 6'd0;
                            tile_read_idx <= 5'd0;
                            state <= CTRL_READ_ADDR;
                        end
                    end
                    else begin
                        post_row_idx <= post_row_idx + 5'd1;
                        state <= CTRL_PP_APPLY;
                    end
                end
            end

            CTRL_DONE: begin
                o_PROC_DONE <= 1'b1;
                state <= CTRL_IDLE;
            end

            default: begin
                state <= CTRL_IDLE;
            end
        endcase
    end
end

endmodule























//=========================================================================
// AXI BRAM MODULE : DO NOT MODIFY
//=========================================================================

module BRAM_TDP #(
    parameter INIT_FILE = "bram_init.txt"
)(
    input   wire                i_CLK,
    input   wire                i_RST_n,
 
    //---- Port A : RTL read / write ----
    input   wire    [13:0]      i_PA_ADDR,
    input   wire                i_PA_WR,
    input   wire    [127:0]     i_PA_WDATA,
    output  logic   [127:0]     o_PA_RDATA,
    output  wire                o_PA_BUSY,      //AXI owns port A this cycle
 
    //---- Port B : RTL read / write ----
    input   wire    [13:0]      i_PB_ADDR,
    input   wire                i_PB_WR,
    input   wire    [127:0]     i_PB_WDATA,
    output  logic   [127:0]     o_PB_RDATA,
 
    //---- AXI4-Lite Slave (32-bit data) ----
    input   wire    [31:0]      S_AXI_AWADDR,
    input   wire                S_AXI_AWVALID,
    output  logic               S_AXI_AWREADY,
    input   wire    [31:0]      S_AXI_WDATA,
    input   wire    [3:0]       S_AXI_WSTRB,
    input   wire                S_AXI_WVALID,
    output  logic               S_AXI_WREADY,
    output  wire    [1:0]       S_AXI_BRESP,
    output  logic               S_AXI_BVALID,
    input   wire                S_AXI_BREADY,
    input   wire    [31:0]      S_AXI_ARADDR,
    input   wire                S_AXI_ARVALID,
    output  logic               S_AXI_ARREADY,
    output  logic   [31:0]      S_AXI_RDATA,
    output  wire    [1:0]       S_AXI_RRESP,
    output  logic               S_AXI_RVALID,
    input   wire                S_AXI_RREADY
);
 
assign S_AXI_BRESP = 2'b00;   //OKAY
assign S_AXI_RRESP = 2'b00;
 
 
//=========================================================================
// Memory array  (Vivado byte-write-enable inference pattern)
//=========================================================================
 
(* ram_style = "block" *)
logic [127:0] mem [0:(1<<14)-1];
 
initial $readmemh(INIT_FILE, mem);
 
 
//=========================================================================
// AXI4-Lite write channel FSM
//=========================================================================
 
logic        aw_fire, w_fire;
logic [13:0] axi_waddr;
logic [1:0]  axi_wlane;
logic        axi_wr_pending;     //write data captured, issue to port A
logic [15:0] axi_wbe;            //byte-write-enable (16 bytes)
logic [127:0] axi_wdata_128;     //write data spread to 128-bit
 
assign aw_fire = S_AXI_AWVALID & S_AXI_AWREADY;
assign w_fire  = S_AXI_WVALID  & S_AXI_WREADY;
 
always_ff @(posedge i_CLK) begin
    if (!i_RST_n) begin
        S_AXI_AWREADY  <= 1'b1;
        S_AXI_WREADY   <= 1'b1;
        S_AXI_BVALID   <= 1'b0;
        axi_wr_pending  <= 1'b0;
    end
    else begin
        //Accept AW
        if (aw_fire) begin
            axi_waddr     <= S_AXI_AWADDR[17:4];
            axi_wlane     <= S_AXI_AWADDR[3:2];
            S_AXI_AWREADY <= 1'b0;
        end
 
        //Accept W
        if (w_fire) begin
            S_AXI_WREADY <= 1'b0;
        end
 
        //Both AW and W received -> issue write next cycle
        if ((!S_AXI_AWREADY || aw_fire) && (!S_AXI_WREADY || w_fire)
            && !axi_wr_pending && !S_AXI_BVALID) begin
 
            logic [1:0] lane;
            lane = aw_fire ? S_AXI_AWADDR[3:2] : axi_wlane;
 
            //Build byte-enable and data vectors
            axi_wbe       <= '0;
            axi_wdata_128 <= '0;
            for (int i = 0; i < 4; i++) begin
                axi_wbe      [lane*4 + i] <= S_AXI_WSTRB[i];
                axi_wdata_128[(lane*4 + i)*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
            end
            axi_wr_pending <= 1'b1;
        end
 
        //Write has been issued to BRAM -> respond
        if (axi_wr_pending) begin
            axi_wr_pending <= 1'b0;
            S_AXI_BVALID   <= 1'b1;
        end
 
        //B handshake complete
        if (S_AXI_BVALID && S_AXI_BREADY) begin
            S_AXI_BVALID  <= 1'b0;
            S_AXI_AWREADY <= 1'b1;
            S_AXI_WREADY  <= 1'b1;
        end
    end
end
 
 
//=========================================================================
// AXI4-Lite read channel FSM
//=========================================================================
 
logic        axi_rd_pending;
logic        axi_rd_wait;    // extra pipeline stage: holds address while waiting for BRAM registered output
logic [13:0] axi_raddr;
logic [1:0]  axi_rlane;
 
always_ff @(posedge i_CLK) begin
    if (!i_RST_n) begin
        S_AXI_ARREADY  <= 1'b1;
        S_AXI_RVALID   <= 1'b0;
        axi_rd_pending <= 1'b0;
        axi_rd_wait    <= 1'b0;
    end
    else begin
        //Accept AR
        if (S_AXI_ARVALID && S_AXI_ARREADY) begin
            axi_raddr      <= S_AXI_ARADDR[17:4];
            axi_rlane      <= S_AXI_ARADDR[3:2];
            S_AXI_ARREADY  <= 1'b0;
            axi_rd_pending <= 1'b1;
        end
 
        // Stage 1 ?? axi_rd_pending: axi_raddr is now driving pa_addr.
        // The BRAM address input is stable; its registered output (o_PA_RDATA)
        // will reflect this address only AFTER the next rising edge.
        // Do NOT capture o_PA_RDATA here ?? it still holds the previous address's data.
        if (axi_rd_pending) begin
            axi_rd_pending <= 1'b0;
            axi_rd_wait    <= 1'b1;   // wait one more cycle for BRAM latency
        end
 
        // Stage 2 ?? axi_rd_wait: o_PA_RDATA now holds valid data for axi_raddr.
        // Capture it and assert RVALID.
        if (axi_rd_wait) begin
            axi_rd_wait    <= 1'b0;
            S_AXI_RVALID   <= 1'b1;
            case (axi_rlane)
                2'd0: S_AXI_RDATA <= o_PA_RDATA[ 31:  0];
                2'd1: S_AXI_RDATA <= o_PA_RDATA[ 63: 32];
                2'd2: S_AXI_RDATA <= o_PA_RDATA[ 95: 64];
                2'd3: S_AXI_RDATA <= o_PA_RDATA[127: 96];
            endcase
        end
 
        //R handshake complete
        if (S_AXI_RVALID && S_AXI_RREADY) begin
            S_AXI_RVALID  <= 1'b0;
            S_AXI_ARREADY <= 1'b1;
        end
    end
end
 
 
//=========================================================================
// Port A mux : AXI has absolute priority over RTL read
//=========================================================================
 
wire        pa_axi_active = axi_wr_pending | axi_rd_pending | axi_rd_wait;
assign      o_PA_BUSY     = pa_axi_active;
 
wire [13:0] pa_addr = pa_axi_active ? (axi_wr_pending ? axi_waddr : axi_raddr)
                                    : i_PA_ADDR;
 
//=========================================================================
// Port A : BRAM read + byte-write  (Vivado inference pattern)
//=========================================================================
 
always_ff @(posedge i_CLK) begin
    //Byte-granularity write (AXI - absolute priority)
    if (axi_wr_pending) begin
        for (int i = 0; i < 16; i++) begin
            if (axi_wbe[i])
                mem[pa_addr][i*8 +: 8] <= axi_wdata_128[i*8 +: 8];
        end
    end
    //Full-width write (RTL - only when AXI is idle)
    else if (i_PA_WR && !pa_axi_active) begin
        mem[pa_addr] <= i_PA_WDATA;
    end
    //Synchronous read (always - read-first mode)
    o_PA_RDATA <= mem[pa_addr];
end
 
 
//=========================================================================
// Port B : BRAM read / write  (RTL only)
//=========================================================================
 
always_ff @(posedge i_CLK) begin
    if (i_PB_WR) begin
        mem[i_PB_ADDR] <= i_PB_WDATA;
    end
    o_PB_RDATA <= mem[i_PB_ADDR];
end
 
 
endmodule
