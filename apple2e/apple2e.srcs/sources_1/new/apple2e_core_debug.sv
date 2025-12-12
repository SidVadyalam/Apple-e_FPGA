`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Simple core wrapper for simulation:
//   - Single 100 MHz clock
//   - Divide-down CPU clock
//   - T65 (65C02 mode)
//   - apple2_mmu
//   - 64 KB BRAM (blk_mem_gen_64k)
//   - No video, no USB, no clk_wiz, no HDMI
// -----------------------------------------------------------------------------
module apple2_core_debug (
    input  logic Clk,          // "board" clock, e.g. 100 MHz
    input  logic reset_ah      // active-high reset
);

    // -------------------------------------------------------------------------
    // CPU clock: divide board clock down a bit so waveforms are readable
    // -------------------------------------------------------------------------
    logic cpu_clk;
    logic [3:0] cpu_div;

    always_ff @(posedge Clk or posedge reset_ah) begin
        if (reset_ah) begin
            cpu_div <= 4'd0;
            cpu_clk <= 1'b0;
        end else begin
            cpu_div <= cpu_div + 4'd1;
            if (cpu_div == 4'd9) begin  // divide by 20 -> 5 MHz if Clk=100 MHz
                cpu_div <= 4'd0;
                cpu_clk <= ~cpu_clk;
            end
        end
    end

    // -------------------------------------------------------------------------
    // T65 65C02 core
    // -------------------------------------------------------------------------
    logic        t65_res_n;
    logic        t65_R_W_n;
    logic [23:0] t65_A;
    logic [7:0]  t65_DI;
    logic [7:0]  t65_DO;

    // Exposed for testbench
    logic t65_Sync, t65_EF, t65_MF, t65_XF, t65_ML_n;
    logic t65_VP_n, t65_VDA, t65_VPA;

    logic [15:0] cpu_addr;
    assign cpu_addr = t65_A[15:0];

    assign t65_res_n = ~reset_ah;

    T65 u_t65 (
        .Mode   (2'b01),      // your 65C02 mode
        .Res_n  (t65_res_n),
        .Clk    (cpu_clk),
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

    // -------------------------------------------------------------------------
    // MMU + BRAM
    // -------------------------------------------------------------------------
    wire        cpu_we   = (t65_R_W_n == 1'b0);
    wire [7:0]  cpu_di_mmu;
    wire [15:0] mem_addr;
    wire [7:0]  mem_din;
    wire        mem_we;
    wire [7:0]  mem_dout;

    // For now, no keyboard input in this simple debug core
    wire [7:0] dummy_ascii  = 8'h00;
    wire       dummy_valid  = 1'b0;

    apple2_mmu mmu (
        .clk         (cpu_clk),
        .reset       (reset_ah),

        // CPU side
        .cpu_addr    (cpu_addr),
        .cpu_do      (t65_DO),
        .cpu_we      (cpu_we),
        .cpu_di      (cpu_di_mmu),

        // Memory side
        .mem_addr    (mem_addr),
        .mem_din     (mem_din),
        .mem_we      (mem_we),
        .mem_dout    (mem_dout),

        // Keyboard ASCII (none in this test)
        .ascii_in    (dummy_ascii),
        .ascii_valid (dummy_valid)
    );

    assign t65_DI = cpu_di_mmu;

    // 64 KB BRAM, initialized from your enhanced //e 64K .coe
    blk_mem_gen_64k u_mem64k (
        .clka  (Clk),
        .ena   (1'b1),
        .wea   (mem_we),
        .addra (mem_addr),
        .dina  (mem_din),
        .douta (mem_dout),

        // Unused port B in this core
        .clkb  (1'b0),
        .enb   (1'b0),
        .web   (1'b0),
        .addrb (16'h0000),
        .dinb  (8'h00),
        .doutb ()
    );

endmodule
