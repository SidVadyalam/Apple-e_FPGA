// t65_debug.sv
module t65_debug (
    input  logic clk_cpu,
    input logic clk_mem,
    input  logic reset_n,    // active low
    output logic [15:0] dbg_addr,
    output logic [7:0]  dbg_di,
    output logic [7:0]  dbg_do,
    output logic        dbg_we,
    output logic        dbg_sync
);

    // T65 signals
    logic        t65_R_W_n;
    logic [23:0] t65_A;
    logic [7:0]  t65_DI;
    logic [7:0]  t65_DO;
    logic        t65_Sync, t65_EF, t65_MF, t65_XF, t65_ML_n;
    logic        t65_VP_n, t65_VDA, t65_VPA;

    logic [15:0] cpu_addr;
    assign cpu_addr = t65_A[15:0];

    T65 u_t65 (
        .Mode   (2'b00),
        .Res_n  (reset_n),
        .Clk    (clk_cpu),
        .Rdy    (1'b1),

        .Abort_n(1'b1),
        .IRQ_n  (1'b1),
        .NMI_n  (1'b1),
        .SO_n   (1'b1),

        .R_W_n  (t65_R_W_n),
        .Sync   (t65_Sync),
        .EF     (t65_EF),
        .MF     (t65_MF),
        .XF     (t65_XF),
        .ML_n   (t65_ML_n),
        .VP_n   (t65_VP_n),
        .VDA    (t65_VDA),
        .VPA    (t65_VPA),

        .A      (t65_A),
        .DI     (t65_DI),
        .DO     (t65_DO)
    );

    // BRAM IP: 64K, initialized with t65_smoke_64k.coe
    wire cpu_write = (t65_R_W_n == 1'b0);
    wire [0:0] bram_we = cpu_write ? 1'b1 : 1'b0;
    wire [7:0] bram_dout;

    blk_mem_gen_64k u_mem64k (
        .clka  (clk_mem),
        .ena   (1'b1),
        .wea   (bram_we),
        .addra (cpu_addr),
        .dina  (t65_DO),
        .douta (bram_dout)
    );

    // No MMIO here; pure RAM/ROM test
    assign t65_DI = bram_dout;

    // Debug exports
    assign dbg_addr = cpu_addr;
    assign dbg_di   = t65_DI;
    assign dbg_do   = t65_DO;
    assign dbg_we   = cpu_write;
    assign dbg_sync = t65_Sync;

endmodule
