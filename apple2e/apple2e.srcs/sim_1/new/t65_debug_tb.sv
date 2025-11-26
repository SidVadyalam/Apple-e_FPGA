`timescale 1ns / 1ps

module t65_debug_tb;

    logic Clk;
    logic reset_rtl_0;

    // DUT
    t65_debug dut (
        .Clk         (Clk),
        .reset_rtl_0 (reset_rtl_0)
    );

    // 100 MHz board clock (10 ns period)
    initial begin
        Clk = 1'b0;
        forever #1 Clk = ~Clk;
    end

    // Reset: assert for 2 us, then deassert
    initial begin
        reset_rtl_0 = 1'b1;
        #2000;                 // 2 us
        reset_rtl_0 = 1'b0;
    end

    // --------------------------------------------------------------------
    // CPU boot monitor: watch reset vector + first opcodes
    // --------------------------------------------------------------------
    int   sync_count = 0;

    // Shorthands into DUT internals
    wire        cpu_clk  = dut.cpu_clk;
    wire        cpu_resn = dut.t65_res_n;
    wire [15:0] cpu_addr = dut.cpu_addr;
    wire [7:0]  cpu_di   = dut.t65_DI;
    wire        cpu_sync = dut.t65_Sync;

    always @(posedge cpu_clk) begin
        if (!cpu_resn) begin
            sync_count <= 0;
        end else begin
            // Log reset vector bytes
            if (cpu_addr == 16'hFFFC)
                $display("[%0t] @FFFC (reset low)  = %02h", $time, cpu_di);
            if (cpu_addr == 16'hFFFD)
                $display("[%0t] @FFFD (reset high) = %02h", $time, cpu_di);

            // Log first N opcode fetches (Sync=1)
            if (cpu_sync && sync_count < 16) begin
                sync_count++;
                $display("[%0t] SYNC %0d: PC=%04h, opcode=%02h",
                         $time, sync_count, cpu_addr, cpu_di);
            end
        end
    end

    // --------------------------------------------------------------------
    // Stop the sim after some time
    // --------------------------------------------------------------------
    initial begin
        #10_000_000;  // 5 ms of sim time
        $display("Simulation finished. sync_count = %0d", sync_count);
        $finish;
    end

endmodule
