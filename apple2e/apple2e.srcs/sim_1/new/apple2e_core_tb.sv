`timescale 1ns / 1ps

module apple2e_core_tb;

    // Clocks and reset
    logic cpu_clk;   // ~1 MHz
    logic mem_clk;   // 100 MHz
    logic reset;

    // Debug signals
    logic [15:0] cpu_addr;
    logic [7:0]  cpu_di;
    logic        sync;

    // DUT
    apple2e_core dut (
        .cpu_clk  (cpu_clk),
        .mem_clk  (mem_clk),
        .reset    (reset),
        .cpu_addr (cpu_addr),
        .cpu_di   (cpu_di),
        .sync     (sync)
    );

    // 1 MHz CPU clock: period 1000 ns
    initial begin
        cpu_clk = 1'b0;
        forever #500 cpu_clk = ~cpu_clk;  // 500 ns high, 500 ns low
    end

    // 100 MHz memory clock: period 10 ns
    initial begin
        mem_clk = 1'b0;
        forever #5 mem_clk = ~mem_clk;    // 5 ns high, 5 ns low
    end

    // Reset sequence
    initial begin
        reset = 1'b1;
        #2000;              // 2 us reset
        reset = 1'b0;
    end

    // Track first opcode fetch (first Sync after reset)
    bit first_sync_seen = 0;
    logic [15:0] first_pc;
    logic [7:0]  first_op;

    always @(posedge cpu_clk) begin
        if (reset) begin
            first_sync_seen <= 0;
        end
        else if (sync && !first_sync_seen) begin
            first_sync_seen <= 1;
            first_pc <= cpu_addr;
            first_op <= cpu_di;

            $display("[%0t] First opcode fetch: PC = %h, opcode = %h",
                     $time, cpu_addr, cpu_di);

            if (cpu_addr < 16'hC000) begin
                $display("ERROR: First opcode fetch is not in ROM region!");
                $fatal;
            end
        end
    end

    // Optional: log reset vector bytes at $FFFC/$FFFD
    always @(posedge cpu_clk) begin
        if (!reset) begin
            if (cpu_addr == 16'hFFFC) begin
                $display("[%0t] Reset vector low byte @FFFC = %02h",
                         $time, cpu_di);
            end
            if (cpu_addr == 16'hFFFD) begin
                $display("[%0t] Reset vector high byte @FFFD = %02h",
                         $time, cpu_di);
            end
        end
    end

    int sync_count = 0;

    always @(posedge cpu_clk) begin
        if (reset) begin
            sync_count <= 0;
        end else begin
            // Log reset vector reads
            if (cpu_addr == 16'hFFFC)
                $display("[%0t] @FFFC (reset low)  = %02h", $time, cpu_di);
            if (cpu_addr == 16'hFFFD)
                $display("[%0t] @FFFD (reset high) = %02h", $time, cpu_di);

            // Log first N opcode fetches (Sync = opcode fetch on T65)
            if (sync && sync_count < 12) begin
                sync_count++;
                $display("[%0t] SYNC %0d: PC=%04h, opcode=%02h",
                        $time, sync_count, cpu_addr, cpu_di);

                if (sync_count == 12) begin
                    $display("Done capturing first 12 opcodes, finishing sim.");
                    $finish;
                end
            end
        end
    end

    always @(posedge cpu_clk) begin
    if (!t65_R_W_n &&
        cpu_addr >= 16'h0400 && cpu_addr < 16'h0500) begin
        $display("[%0t] WRITE text region: %04h <= %02h",
                 $time, cpu_addr, t65_DO);
    end
    end


    // Stop the sim after some time
    initial begin
        // Run for e.g. 5 ms of CPU time (5000 cycles at 1 MHz)
        #50_000_000;  // 5 ms = 5,000,000 ns

        if (!first_sync_seen) begin
            $display("ERROR: Never saw Sync go high after reset.");
            $fatal;
        end

        $display("Simulation complete. First PC = %h, opcode = %h",
                 first_pc, first_op);
        $finish;
    end

endmodule
