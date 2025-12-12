
//   $C000 : read key data (bit 7 = strobe, bits 6..0 = ASCII[6:0])
//   $C010-$C01F : any access clears strobe
module apple2_keyboard (
    input  logic       clk,
    input  logic       reset,

    // From USB/HID side: 7-bit ASCII + 1-cycle strobe
    input  logic [7:0] ascii_in,        // ASCII, use [6:0]
    input  logic       ascii_valid,     // pulse when new key arrives

    // From CPU side
    input  logic       cpu_read_c000,   // read of $C000 (mostly for completeness)
    input  logic       cpu_clear_strobe,// any access to $C010-$C01F (R or W)

    // Data back to CPU when reading $C000
    output logic [7:0] cpu_data
);

    logic [6:0] key_latch;   // 7-bit ASCII
    logic       key_strobe;  // bit 7 (latched "key waiting" flag)

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            key_latch  <= 7'd0;
            key_strobe <= 1'b0;
        end else begin
            // Latch new key from USB side
            if (ascii_valid && ascii_in != 8'h00) begin
                key_latch  <= ascii_in[6:0];
                key_strobe <= 1'b1;
            end

            // Any access to $C010-$C01F clears the strobe
            if (cpu_clear_strobe) begin
                key_strobe <= 1'b0;
            end
        end
    end

    // What the CPU sees at $C000
    always_comb begin
        cpu_data = {key_strobe, key_latch};
    end

endmodule
