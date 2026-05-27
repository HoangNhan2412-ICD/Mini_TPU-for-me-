module BBR #(
    parameter ADDR_W = 4,   
    parameter N      = 4,   
    parameter DATA_W = 8,   
    parameter MAC_W  = 32   
)(
    input  wire                   clk,
    input  wire                   rst, // S?a thành rst

    // Các c?ng ?i?u khi?n l?t Bank
    input  wire                   swap_req_A,
    input  wire                   swap_req_B,
    input  wire                   swap_req_C,

    // Giao ti?p AXI
    input  wire                   axi_wrA_req_valid,
    output wire                   axi_wrA_data_ready,
    input  wire [ADDR_W-1:0]      axi_wrA_addr,
    input  wire [N*DATA_W-1:0]    axi_wrA_data,      

    input  wire                   axi_wrB_req_valid,
    output wire                   axi_wrB_data_ready,
    input  wire [ADDR_W-1:0]      axi_wrB_addr,
    input  wire [N*DATA_W-1:0]    axi_wrB_data,      

    input  wire                   axi_rdC_req_valid,
    output wire                   axi_rdC_data_ready,
    input  wire [ADDR_W-1:0]      axi_rdC_addr,
    output wire [N*MAC_W-1:0]     axi_rdC_data,      
    output wire                   axi_rdC_data_valid,

    // Giao ti?p Datapath
    input  wire                   skew_rdA_req_valid,
    output wire                   skew_rdA_data_ready,
    input  wire [ADDR_W-1:0]      skew_rdA_addr,
    output wire [N*DATA_W-1:0]    skew_rdA_data,     
    output wire                   skew_rdA_data_valid,

    input  wire                   skew_rdB_req_valid,
    output wire                   skew_rdB_data_ready,
    input  wire [ADDR_W-1:0]      skew_rdB_addr,
    output wire [N*DATA_W-1:0]    skew_rdB_data,     
    output wire                   skew_rdB_data_valid,

    input  wire                   sa_wrC_req_valid,
    output wire                   sa_wrC_data_ready,
    input  wire [ADDR_W-1:0]      sa_wrC_addr,
    input  wire [N*MAC_W-1:0]     sa_wrC_data        
);

    // Instantiate Buffer A
    pp_bram_multibank #(
        .ADDR_W(ADDR_W),
        .N(N),
        .DATA_W(DATA_W) 
    ) buffer_A (
        .clk             (clk),
        .rst             (rst), // C?p nh?t c?ng rst
        .swap_req        (swap_req_A),
        .wr_req_valid    (axi_wrA_req_valid),
        .wr_data_ready   (axi_wrA_data_ready),
        .wr_addr         (axi_wrA_addr),
        .wr_data         (axi_wrA_data),
        .rd_req_valid    (skew_rdA_req_valid),
        .rd_data_ready   (skew_rdA_data_ready),
        .rd_addr         (skew_rdA_addr),
        .rd_data         (skew_rdA_data),
        .rd_data_valid   (skew_rdA_data_valid)
    );

    // Instantiate Buffer B
    pp_bram_multibank #(
        .ADDR_W(ADDR_W),
        .N(N),
        .DATA_W(DATA_W) 
    ) buffer_B (
        .clk             (clk),
        .rst             (rst), // C?p nh?t c?ng rst
        .swap_req        (swap_req_B),
        .wr_req_valid    (axi_wrB_req_valid),
        .wr_data_ready   (axi_wrB_data_ready),
        .wr_addr         (axi_wrB_addr),
        .wr_data         (axi_wrB_data),
        .rd_req_valid    (skew_rdB_req_valid),
        .rd_data_ready   (skew_rdB_data_ready),
        .rd_addr         (skew_rdB_addr),
        .rd_data         (skew_rdB_data),
        .rd_data_valid   (skew_rdB_data_valid)
    );

    // Instantiate Buffer C
    pp_bram_multibank #(
        .ADDR_W(ADDR_W),
        .N(N),
        .DATA_W(MAC_W)  
    ) buffer_C (
        .clk             (clk),
        .rst             (rst), // C?p nh?t c?ng rst
        .swap_req        (swap_req_C),
        .wr_req_valid    (sa_wrC_req_valid),
        .wr_data_ready   (sa_wrC_data_ready),
        .wr_addr         (sa_wrC_addr),
        .wr_data         (sa_wrC_data),
        .rd_req_valid    (axi_rdC_req_valid),
        .rd_data_ready   (axi_rdC_data_ready),
        .rd_addr         (axi_rdC_addr),
        .rd_data         (axi_rdC_data),
        .rd_data_valid   (axi_rdC_data_valid)
    );

endmodule