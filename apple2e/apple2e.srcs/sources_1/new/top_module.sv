`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2025 09:28:45 AM
// Design Name: 
// Module Name: top_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_module(
        input logic Clk,
        input logic reset_rtl_0,
        
        //USB signals
        input logic [0:0] gpio_usb_int_tri_i,
        output logic gpio_usb_rst_tri_o,
        input logic usb_spi_miso,
        output logic usb_spi_mosi,
        output logic usb_spi_sclk,
        output logic usb_spi_ss,

        //UART
        input logic uart_rtl_0_rxd,
        output logic uart_rtl_0_txd,

        //HDMI
        output logic hdmi_tmds_clk_n,
        output logic hdmi_tmds_clk_p,
        output logic [2:0]hdmi_tmds_data_n,
        output logic [2:0]hdmi_tmds_data_p,

        //HEX displays
        output logic [7:0] hex_segA,
        output logic [3:0] hex_gridA,
        output logic [7:0] hex_segB,
        output logic [3:0] hex_gridB,

        //debug
        output logic led
    );

    logic [31:0] keycode0_gpio, keycode1_gpio;

    logic reset_ah;
    
    assign reset_ah = reset_rtl_0;

    hex_driver HexA (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[31:28], keycode0_gpio[27:24], keycode0_gpio[23:20], keycode0_gpio[19:16]}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );
    
    // hex_driver HexB (
    //     .clk(Clk),
    //     .reset(reset_ah),
    //     .in({keycode0_gpio[15:12], keycode0_gpio[11:8], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
    //     .hex_seg(hex_segB),
    //     .hex_grid(hex_gridB)
    // );
    hex_driver HexB (
        .clk(Clk),
        .reset(reset_ah),
        .in({ cpu_addr[15:12], cpu_addr[11:8], cpu_addr[7:4], cpu_addr[3:0] }),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );

    mb_usb mb_block_i (
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
    logic clk_125MHz, clk_25MHz, clk_12_5MHz, locked;

    clk_wiz_0 clk_wiz (
        .clk_out1(clk_125MHz),
        .clk_out2(clk_25MHz),
        .clk_out3(clk_12_5MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );

    logic clk_50MHz;
    // Generate 50 MHz clock from 100 MHz input
    always_ff @(posedge clk_125MHz) begin
        if (reset_ah) begin
            clk_50MHz <= 1'b1;
        end else begin
            clk_50MHz <= ~clk_50MHz;
        end
    end

    logic cpu_clk;
    logic [2:0] clk_counter;
    logic [23:0] counter;
    always_ff @(posedge clk_12_5MHz or posedge reset_ah) begin
        if (reset_ah) begin
            clk_counter <= 3'b0;
            cpu_clk <= 1'b0;
            counter <= 24'b0;
        end else begin
            clk_counter <= clk_counter + 3'b001;
            if (clk_counter == 3'b101) begin
                cpu_clk <= ~cpu_clk;
                clk_counter <= 3'b0;
                counter <= counter + 24'b1;
            end
        end
    end

    assign led = counter[23];

    logic t65_res_n;
    assign t65_res_n = ~reset_ah & locked;

    // -------------------------------------------------------------------------
    // T65 CPU
    // -------------------------------------------------------------------------
    logic        t65_R_W_n;
    logic [23:0] t65_A;
    logic [7:0]  t65_DI;
    logic [7:0]  t65_DO;

    // Unused T65 outputs (for now)
    logic t65_Sync, t65_EF, t65_MF, t65_XF, t65_ML_n;
    logic t65_VP_n, t65_VDA, t65_VPA;

    // 16-bit address used for memory
    logic [15:0] cpu_addr;
    assign cpu_addr = t65_A[15:0];

    // Instantiate T65 in 6502 mode
    T65 u_t65 (
        .Mode   (2'b00),      // 6502 mode
        .Res_n  (t65_res_n),  // active-low reset
        .Clk    (cpu_clk),
        .Rdy    (1'b1),       // no wait states

        .Abort_n(1'b1),
        .IRQ_n  (1'b1),       // no IRQ yet
        .NMI_n  (1'b1),       // no NMI yet
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
    // 64 KB Block RAM via Block Memory Generator
    //   0x0000–0xCFFF : RAM
    //   0xD000–0xFFFF : ROM (read-only via .coe init)
    //   0xC000        : keyboard MMIO (overrides BRAM read)
    // -------------------------------------------------------------------------
    wire cpu_write  = (t65_R_W_n == 1'b0);
    wire ram_region = (cpu_addr < 16'hC000);       // 0x0000–0xBFFF
    wire rom_region = (cpu_addr >= 16'hC000);      // 0xC000–0xFFFF
    wire kb_region  = (cpu_addr == 16'hC000);        // keyboard register

    wire [0:0] bram_we;
    assign bram_we = (cpu_write && ram_region && !kb_region) ? 1'b1 : 1'b0;

    wire [7:0] bram_dout;

    // NOTE: ensure this module name matches your generated IP
    blk_mem_gen_64k u_mem64k (
        //CPU Port
        .clka  (Clk),
        .ena   (1'b1),
        .wea   (bram_we),
        .addra (cpu_addr),
        .dina  (t65_DO),
        .douta (bram_dout),
        //Video Port
        .clkb(clk_25MHz),
        .enb(1'b1),
        .web(1'b0),
        .addrb(vram_addr),
        .dinb(8'h00),
        .doutb(vram_data)

    );

    // T65 data input mux: keyboard MMIO vs BRAM
    always_comb begin
        if (kb_region) begin
            // Simple memory-mapped keyboard: lower byte of keycode0
            t65_DI = keycode0_gpio[7:0];
        end else begin
            t65_DI = bram_dout;
        end
    end


    logic [9:0] drawX, drawY;
    logic hsync, vsync, vde;

    logic [3:0] red, green, blue;
    logic [15:0] vram_addr;
    logic [7:0] vram_data;

    apple2_video_simple video_unit (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .drawX(drawX),
        .drawY(drawY),
        .active_nblank(vde),

        .vram_addr(vram_addr),
        .vram_data(vram_data),

        .red(red),
        .green(green),
        .blue(blue)
    );

    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );

endmodule
