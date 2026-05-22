`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Pham Vo Hoang Nhan
// 
// Create Date: 05/10/2026
// Design Name: Mini TPU - Memory Subsystem
// Module Name: FDDR
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Fake DDR memory model with AXI-Stream interface and CAS latency simulation
// 
//////////////////////////////////////////////////////////////////////////////////

module FDDR #(
    parameter       data_width  = 64,      
    parameter       latency     = 20,
    parameter       addr_width  = 16,
    parameter       mem_size    = 65536,
    parameter       len_width   = 8,
    parameter       w_base      = 0,
    parameter       a_base      = 16384,
    parameter       c_base      = 32768
)
(
    // Request interface (Command)
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    req_valid,
    output logic                    req_ready,
    input  logic [addr_width-1:0]   req_addr,
    input  logic [len_width-1:0]    req_numberBurst,

    // Stream interface (AXI-Stream)
    output logic                    data_valid,
    input  logic                    data_ready,
    output logic [data_width-1:0]   data,
    output logic                    data_last
);

    logic [data_width-1:0]      mem [0:mem_size-1];
    logic [$clog2(latency)-1:0] latency_cnt;
    logic [len_width-1:0]       burst_cnt;
    logic [len_width-1:0]       numberBurst_reg;
    logic [addr_width-1:0]      addr_reg;

    typedef enum logic [1:0] {
        Idle  = 2'b00,
        Wait  = 2'b01,
        Trans = 2'b10
    } state_t;

    state_t state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state           <= Idle;
            req_ready       <= 1'b1;  // ready to push instruction
            data_valid      <= 1'b0;
            data_last       <= 1'b0;
            data            <= '0;
            burst_cnt       <= '0;
            latency_cnt     <= '0;
            numberBurst_reg <= '0;
            addr_reg        <= '0;
        end else begin
            case (state)
                Idle: begin
                    req_ready  <= 1'b1;
                    data_valid <= 1'b0;
                    data_last  <= 1'b0;
                    
                    if (req_valid && req_ready) begin
                        req_ready       <= 1'b0;
                        numberBurst_reg <= req_numberBurst;
                        addr_reg        <= req_addr;
                        burst_cnt       <= '0;
                        latency_cnt     <= '0;
                        state           <= Wait;
                    end
                end

                Wait: begin
                    latency_cnt <= latency_cnt + 1;
                    
                    if (latency_cnt == latency - 1) begin
                        data       <= mem[addr_reg];
                        data_valid <= 1'b1;
                        burst_cnt  <= burst_cnt + 1;
                        
     
                        if (numberBurst_reg == 1)
                            data_last <= 1'b1;
                        
                        state <= Trans;
                    end
                end

                Trans: begin
                    
                    if (data_valid && data_ready) begin
                        
                        if (burst_cnt == numberBurst_reg) begin
                            //done fetching phase
                            data_valid <= 1'b0;
                            data_last  <= 1'b0;
                            req_ready  <= 1'b1;
                            state      <= Idle;
                        end else begin
                            //fetch next data
                            data      <= mem[addr_reg + burst_cnt];
                            burst_cnt <= burst_cnt + 1;
                            
                            //turn on last read push last number out
                            if (burst_cnt == numberBurst_reg - 1)
                                data_last <= 1'b1;
                        end
                    end
                end

                default: state <= Idle;
            endcase
        end
    end

endmodule