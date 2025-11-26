`timescale 1ns / 1ps

module apple2e_core(
    input  logic        cpu_clk,   // ~1 MHz
    input  logic        mem_clk,   // 100 MHz
    input  logic        reset,     // active high

    output logic [15:0] cpu_addr,  // address bus (for debug)
    output logic [7:0]  cpu_di,    // data into CPU (for debug)
    output logic        sync       // opcode fetch indicator
);

    // ----------------------------------------------------------------
    // T65 CPU signals
    // ----------------------------------------------------------------
    logic        t65_R_W_n;
    logic [23:0] t65_A;
    logic [7:0]  t65_DO;
    logic [7:0]  t65_DI;

    logic t65_Sync, t65_EF, t65_MF, t65_XF, t65_ML_n;
    logic t65_VP_n, t65_VDA, t65_VPA;

    assign cpu_addr = t65_A[15:0];
    assign cpu_di   = t65_DI;
    assign sync     = t65_Sync;

    // T65 reset is active-low
    logic t65_res_n;
    assign t65_res_n = ~reset;

    // ----------------------------------------------------------------
    // T65 instance (6502 mode)
    // ----------------------------------------------------------------
    T65 u_t65 (
        .Mode    (2'b00),     // 6502
        .Res_n   (t65_res_n),
        .Clk     (cpu_clk),
        .Rdy     (1'b1),      // no wait states yet

        .Abort_n (1'b1),
        .IRQ_n   (1'b1),
        .NMI_n   (1'b1),
        .SO_n    (1'b1),

        .R_W_n   (t65_R_W_n),
        .Sync    (t65_Sync),
        .EF      (t65_EF),
        .MF      (t65_MF),
        .XF      (t65_XF),
        .ML_n    (t65_ML_n),
        .VP_n    (t65_VP_n),
        .VDA     (t65_VDA),
        .VPA     (t65_VPA),

        .A       (t65_A),
        .DI      (t65_DI),
        .DO      (t65_DO)
    );

    // ----------------------------------------------------------------
    // 64 KB BRAM (apple2e_64k.coe already loaded in IP)
    //   0x0000–0xBFFF : RAM (R/W)
    //   0xC000–0xFFFF : ROM (from apple2e.rom)
    // ----------------------------------------------------------------
    wire        cpu_write  = (t65_R_W_n == 1'b0);
    wire [15:0] a16        = cpu_addr;

    wire ram_region = (a16 < 16'hC000);   // 0x0000–0xBFFF
    wire rom_region = (a16 >= 16'hC000);  // 0xC000–0xFFFF

    wire [0:0] bram_we;
    assign bram_we = (cpu_write && ram_region) ? 1'b1 : 1'b0;

    wire [7:0] bram_dout;

    // NOTE: clka is mem_clk (100 MHz), T65 runs on cpu_clk (~1 MHz)
    blk_mem_gen_64k u_mem64k (
        .clka  (mem_clk),
        .ena   (1'b1),
        .wea   (bram_we),
        .addra (a16),
        .dina  (t65_DO),
        .douta (bram_dout)
    );

    // Data to CPU: for now just straight from BRAM (no keyboard MMIO etc.)
    always_comb begin
        t65_DI = bram_dout;
    end

endmodule
