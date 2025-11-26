// Simple character ROM: 256 chars, 8 rows per char, 8 bits per row
module char_rom (
    input  logic [7:0] char_code,   // character code from text RAM
    input  logic [2:0] row,         // which row of the glyph (0..7)
    output logic [7:0] bits         // 8 pixels for that row, MSB = left
);

    localparam int NUM_CHARS       = 256;
    localparam int ROWS_PER_CHAR   = 8;
    localparam int ROM_DEPTH       = NUM_CHARS * ROWS_PER_CHAR; // 2048
    localparam int ADDR_WIDTH      = $clog2(ROM_DEPTH);          // 11

    // Flat ROM: char-major, then row
    logic [7:0] rom [0:ROM_DEPTH-1];

    // Initialize from hex file: one byte per line
    // e.g. font.mem placed in project sources
    initial begin
        $readmemh("font.mem", rom);
    end

    logic [ADDR_WIDTH-1:0] addr;

    always_comb begin
        // addr = char_code * 8 + row
        // Concatenation does that: {char_code, row} == (char_code << 3) | row
        addr = {char_code, row};
        bits = rom[addr];
    end

endmodule
