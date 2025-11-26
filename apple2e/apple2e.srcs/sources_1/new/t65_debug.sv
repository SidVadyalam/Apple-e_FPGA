`timescale 1ns / 1ps

module t65_debug (
    input  logic Clk,
    input  logic reset_rtl_0
);

    // Active-high reset
    logic reset_ah;
    assign reset_ah = reset_rtl_0;

    // -------------------------------------------------------------------------
    // Clocking wizard (unchanged)
    // -------------------------------------------------------------------------
    logic clk_125MHz, clk_25MHz, clk_12_5MHz, locked;

    clk_wiz_0 clk_wiz (
        .clk_out1(clk_125MHz),
        .clk_out2(clk_25MHz),
        .clk_out3(clk_12_5MHz),
        .reset   (reset_ah),
        .locked  (locked),
        .clk_in1 (Clk)
    );

    // -------------------------------------------------------------------------
    // CPU clock divider from 12.5 MHz (unchanged)
    // -------------------------------------------------------------------------
    logic cpu_clk;
    logic [2:0] clk_counter;

    always_ff @(posedge clk_12_5MHz or posedge reset_ah) begin
        if (reset_ah) begin
            clk_counter <= 3'b0;
            cpu_clk     <= 1'b0;
        end else begin
            clk_counter <= clk_counter + 3'b001;
            if (clk_counter == 3'b101) begin
                cpu_clk     <= ~cpu_clk;   // ~1 MHz CPU
                clk_counter <= 3'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // T65 CPU
    // -------------------------------------------------------------------------
    logic        t65_res_n;
    assign t65_res_n = ~reset_ah & locked;

    logic        t65_R_W_n;
    logic [23:0] t65_A;
    logic [7:0]  t65_DI;
    logic [7:0]  t65_DO;

    // Expose for testbench
    logic t65_Sync, t65_EF, t65_MF, t65_XF, t65_ML_n;
    logic t65_VP_n, t65_VDA, t65_VPA;

    logic [15:0] cpu_addr;
    assign cpu_addr = t65_A[15:0];

    T65 u_t65 (
        .Mode   (2'b00),      // 6502 mode
        .Res_n  (t65_res_n),  // active-low reset
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
    // 64 KB Block RAM
    //   0x0000–0xBFFF : RAM
    //   0xC000–0xFFFF : ROM (via .coe init)
    // -------------------------------------------------------------------------
    wire cpu_write  = (t65_R_W_n == 1'b0);
    wire ram_region = (cpu_addr < 16'hC000);       // 0x0000–0xBFFF

    wire [0:0] bram_we;
    assign bram_we = (cpu_write && ram_region) ? 1'b1 : 1'b0;

    wire [7:0] bram_dout;

    // Video-side VRAM signals
    logic [15:0] vram_addr;
    logic [7:0]  vram_data;

    blk_mem_gen_64k u_mem64k (
        // CPU Port (A) – 100 MHz board clock
        .clka  (Clk),
        .ena   (1'b1),
        .wea   (bram_we),
        .addra (cpu_addr),
        .dina  (t65_DO),
        .douta (bram_dout),

        // Video Port (B) – 25 MHz pixel clock
        .clkb  (clk_25MHz),
        .enb   (1'b1),
        .web   (1'b0),
        .addrb (vram_addr),
        .dinb  (8'h00),
        .doutb (vram_data)
    );

    // Data into CPU: pure BRAM in this sim top
    always_comb begin
        t65_DI = bram_dout;
    end

    // -------------------------------------------------------------------------
    // VGA controller + Apple II video
    // -------------------------------------------------------------------------
    logic [9:0] drawX, drawY;
    logic       hsync, vsync, vde;

    logic [3:0] red, green, blue;

    vga_controller vga (
        .pixel_clk    (clk_25MHz),
        .reset        (reset_ah),
        .hs           (hsync),
        .vs           (vsync),
        .active_nblank(vde),
        .drawX        (drawX),
        .drawY        (drawY)
    );

    apple2_video_simple video_unit (
        .pixel_clk    (clk_25MHz),
        .reset        (reset_ah),
        .drawX        (drawX),
        .drawY        (drawY),
        .active_nblank(vde),

        .vram_addr    (vram_addr),
        .vram_data    (vram_data),

        .red          (red),
        .green        (green),
        .blue         (blue)
    );

endmodule
