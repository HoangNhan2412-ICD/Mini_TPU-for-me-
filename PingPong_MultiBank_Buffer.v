module pp_bram_multibank #(
    parameter ADDR_W = 4,   // Chi?u sâu 16 ??a ch?
    parameter N      = 4,   // S? l??ng Bank song song (t??ng ???ng 4 c?t)
    parameter DATA_W = 8    // ?? r?ng data m?i Bank (8-bit)
)(
    input  wire                   clk,
    input  wire                   rst,           // S?a thành rst (Active-High)

    // Kênh Control
    input  wire                   swap_req,      // L?nh l?t Ping-Pong

    // Kênh Ghi (AXI / DMA)
    input  wire                   wr_req_valid,
    output wire                   wr_data_ready,
    input  wire [ADDR_W-1:0]      wr_addr,
    input  wire [N*DATA_W-1:0]    wr_data,       // Nh?n 32-bit (4 data)

    // Kênh ??c (Skew Controller)
    input  wire                   rd_req_valid,
    output wire                   rd_data_ready,
    input  wire [ADDR_W-1:0]      rd_addr,
    output wire [N*DATA_W-1:0]    rd_data,       // Tr? v? 32-bit (4 data t? 4 Bank)
    output reg                    rd_data_valid
);

    localparam DEPTH = 1 << ADDR_W;

    //========================================================
    // 1. LOGIC L?T PING-PONG (BUFFER A / BUFFER B)
    //========================================================
    reg pp_sel;

    // ??i negedge rst_n thành posedge rst
    always @(posedge clk or posedge rst) begin
        if (rst) begin  // ??i !rst_n thành rst
            pp_sel <= 1'b0;
        end else if (swap_req) begin
            pp_sel <= ~pp_sel;
        end
    end

    assign wr_data_ready = ~swap_req; 
    assign rd_data_ready = ~swap_req;
    
    wire wr_fire = wr_req_valid & wr_data_ready;
    wire rd_fire = rd_req_valid & rd_data_ready;

    // ??i negedge rst_n thành posedge rst
    always @(posedge clk or posedge rst) begin
        if (rst) rd_data_valid <= 1'b0;
        else     rd_data_valid <= rd_fire;
    end

    //========================================================
    // 2. T?O N BRAM SONG SONG (MULTI-BANK) B?NG GENERATE
    //========================================================
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : PARALLEL_BANKS
            reg [DATA_W-1:0] ping_ram [0:DEPTH-1];
            reg [DATA_W-1:0] pong_ram [0:DEPTH-1];
            reg [DATA_W-1:0] bank_rd_data;

            always @(posedge clk) begin
                if (wr_fire) begin
                    if (pp_sel == 1'b0) begin
                        ping_ram[wr_addr] <= wr_data[(i+1)*DATA_W-1 : i*DATA_W];
                    end else begin
                        pong_ram[wr_addr] <= wr_data[(i+1)*DATA_W-1 : i*DATA_W];
                    end
                end
            end

            always @(posedge clk) begin
                if (rd_fire) begin
                    if (pp_sel == 1'b0) begin
                        bank_rd_data <= pong_ram[rd_addr];
                    end else begin
                        bank_rd_data <= ping_ram[rd_addr];
                    end
                end
            end
            
            assign rd_data[(i+1)*DATA_W-1 : i*DATA_W] = bank_rd_data;
        end
    endgenerate

endmodule