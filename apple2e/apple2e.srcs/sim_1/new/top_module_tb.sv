`timescale 1ns / 1ps

module top_module_tb;

    // --------------------------------------------------------------------
    // Top-level I/O signals
    // --------------------------------------------------------------------
    logic Clk;
    logic reset_rtl_0;

    // USB
    logic [0:0] gpio_usb_int_tri_i;
    logic       gpio_usb_rst_tri_o;
    logic       usb_spi_miso;
    logic       usb_spi_mosi;
    logic       usb_spi_sclk;
    logic       usb_spi_ss;

    // UART
    logic uart_rtl_0_rxd;
    logic uart_rtl_0_txd;

    // HDMI
    logic hdmi_tmds_clk_n;
    logic hdmi_tmds_clk_p;
    logic [2:0] hdmi_tmds_data_n;
    logic [2:0] hdmi_tmds_data_p;

    // HEX
    logic [7:0] hex_segA;
    logic [3:0] hex_gridA;
    logic [7:0] hex_segB;
    logic [3:0] hex_gridB;

    // --------------------------------------------------------------------
    // DUT instance
    // --------------------------------------------------------------------
    top_module dut (
        .Clk              (Clk),
        .reset_rtl_0      (reset_rtl_0),

        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .usb_spi_miso     (usb_spi_miso),
        .usb_spi_mosi     (usb_spi_mosi),
        .usb_spi_sclk     (usb_spi_sclk),
        .usb_spi_ss       (usb_spi_ss),

        .uart_rtl_0_rxd   (uart_rtl_0_rxd),
        .uart_rtl_0_txd   (uart_rtl_0_txd),

        .hdmi_tmds_clk_n  (hdmi_tmds_clk_n),
        .hdmi_tmds_clk_p  (hdmi_tmds_clk_p),
        .hdmi_tmds_data_n (hdmi_tmds_data_n),
        .hdmi_tmds_data_p (hdmi_tmds_data_p),

        .hex_segA         (hex_segA),
        .hex_gridA        (hex_gridA),
        .hex_segB         (hex_segB),
        .hex_gridB        (hex_gridB)
    );

    // --------------------------------------------------------------------
    // Clock & reset
    // --------------------------------------------------------------------

    // 100 MHz board clock (10 ns period)
    initial begin
        Clk = 1'b0;
        forever #5 Clk = ~Clk;
    end

    // Simple reset: assert for 1 us, then deassert
    initial begin
        reset_rtl_0 = 1'b1;
        #1000;                 // 1 us
        reset_rtl_0 = 1'b0;
    end

    // --------------------------------------------------------------------
    // Constant stimulus for unused inputs
    // --------------------------------------------------------------------
    initial begin
        gpio_usb_int_tri_i = 1'b0;  // no USB interrupt
        usb_spi_miso       = 1'b1;  // idle high or whatever
        uart_rtl_0_rxd     = 1'b1;  // UART idle high
    end

    // --------------------------------------------------------------------
    // Simple CPU/boot monitor
    //  - watches T65 reset deassert
    //  - prints reset vector bytes (@FFFC/FFFD)
    //  - logs first few opcode fetches (Sync=1)
    // --------------------------------------------------------------------

    int   sync_count = 0;

    // Shorthand for internal signals
    wire [15:0] cpu_addr = dut.cpu_addr;
    wire [7:0]  cpu_di   = dut.t65_DI;
    wire        cpu_clk  = dut.cpu_clk;
    wire        cpu_sync = dut.t65_Sync;
    wire        cpu_resn = dut.t65_res_n;

    always @(posedge cpu_clk) begin
        if (!cpu_resn) begin
            // still in reset, do nothing
        end else begin
            // Log reset vector bytes when fetched
            if (cpu_addr == 16'hFFFC)
                $display("[%0t] @FFFC (reset low)  = %02h", $time, cpu_di);
            if (cpu_addr == 16'hFFFD)
                $display("[%0t] @FFFD (reset high) = %02h", $time, cpu_di);

            // Log first N opcode fetches (T65 Sync = opcode fetch)
            if (cpu_sync && sync_count < 16) begin
                sync_count++;
                $display("[%0t] SYNC %0d: PC=%04h, opcode=%02h",
                         $time, sync_count, cpu_addr, cpu_di);
            end
        end
    end

    // --------------------------------------------------------------------
    // Stop the sim after a while
    // --------------------------------------------------------------------
    initial begin
        // Let it run ~5 ms of real time
        #5_000_000;  // 5 ms at 1 ns units

        $display("Simulation finished. sync_count = %0d", sync_count);
        $finish;
    end

endmodule
