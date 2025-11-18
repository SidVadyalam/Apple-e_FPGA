// t_65_debug_tb.sv
`timescale 1ns/1ps

module t65_debug_tb;

    logic clk_mem;
    logic clk_cpu;
    logic reset_n;

    logic [15:0] dbg_addr;
    logic [7:0]  dbg_di;
    logic [7:0]  dbg_do;
    logic        dbg_we;
    logic        dbg_sync;

    // Clock: 10 ns period => 100 MHz
    initial clk_mem = 0;
    always #5 clk_mem = ~clk_mem;

    logic [6:0] clk_div;
    always_ff @(posedge clk_mem or negedge reset_n) begin
        if (!reset_n) begin
            clk_div <= 7'b0;
            clk_cpu <= 1'b0;
        end else begin
            if(clk_div == 7'd99) begin
                clk_cpu <= ~clk_cpu;
                clk_div <= 7'b0;
            end else begin
                clk_div <= clk_div + 7'b1;
            end
        end
    end

    // Reset: assert for a bit at start
    initial begin
        reset_n = 0;
        #200;
        reset_n = 1;
    end

    t65_debug dut (
        .clk_cpu      (clk_cpu),
        .clk_mem      (clk_mem),
        .reset_n  (reset_n),
        .dbg_addr (dbg_addr),
        .dbg_di   (dbg_di),
        .dbg_do   (dbg_do),
        .dbg_we   (dbg_we),
        .dbg_sync (dbg_sync)
    );

    // Monitor opcode fetches (Sync=1 means opcode fetch)
    always @(posedge clk_cpu) begin
        if (reset_n && dbg_sync) begin
            $display("%0t: FETCH @ %h = %h (we=%0d)",
                     $time, dbg_addr, dbg_di, dbg_we);
        end
    end

    always @(posedge clk_cpu) begin
    if (reset_n && dbg_we) begin
        $display("%0t: WRITE @ %h = %h",
                 $time, dbg_addr, dbg_do);
    end
end

    // Run for some time then stop
    initial begin
        #500000;   // adjust as needed
        $finish;
    end

endmodule
