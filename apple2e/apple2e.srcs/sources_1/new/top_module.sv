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
        input logic uart_rxd,
        output logic uart_txd,

        //HEX displays
        output logic [7:0] hex_segA,
        output logic [3:0] hex_gridA,
        output logic [7:0] hex_segB,
        output logic [3:0] hex_gridB
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
    
    hex_driver HexB (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[15:12], keycode0_gpio[11:8], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
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

    logic cpu_clk;
    logic [2:0] clk_counter;
    always_ff @(posedge clk_12_5MHz) begin
        if (reset_ah) begin
            clk_counter <= 3'b0;
            cpu_clk <= 1'b0;
        end else begin
            clk_counter <= clk_counter + 3'b001;
            if (clk_counter == 3'b101) begin
                cpu_clk <= ~cpu_clk;
                clk_counter <= 3'b0;
            end
        end
    end

    logic [9:0] drawX, drawY;
    logic hsync, vsync, vde;
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );

endmodule
