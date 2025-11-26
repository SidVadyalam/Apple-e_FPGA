module apple2_video_simple (
    input  logic        pixel_clk,
    input  logic        reset,

    input  logic [9:0]  drawX,
    input  logic [9:0]  drawY,
    input  logic        active_nblank,

    // Port B of main memory
    output logic [15:0] vram_addr,
    input  logic [7:0]  vram_data,

    // Pixel outputs (4:4:4)
    output logic [3:0]  red,
    output logic [3:0]  green,
    output logic [3:0]  blue
);


    // localparam int CHAR_W     = 8;
    // localparam int CHAR_H     = 8;
    // localparam logic [15:0] TEXT_BASE = 16'h0400; // Apple text page 1

    // -----------------------------------------------------------------------
    // Stage 0 (combinational): derive char cell & VRAM address for *next* pixel
    // -----------------------------------------------------------------------
    logic        display_next;
    logic [5:0]  col_next;        // 0..39
    logic [4:0]  row_next;        // 0..23
    logic [2:0]  x_in_cell_next;  // 0..7
    logic [2:0]  y_in_cell_next;  // 0..7
    logic [15:0] vram_addr_next;

    //Apple II text layout
    // addr = $0400 + (row & 7)*$80 + (row >> 3)*40 + col
    logic [2:0] row_in_block;
    logic [1:0] block;
    logic [15:0] text_addr_next;

    localparam int TEXT_COLS      = 40;
    localparam int TEXT_ROWS      = 24;
    localparam int CHAR_W         = 8;
    localparam int CHAR_H         = 8;
    localparam int H_VISIBLE      = 640;
    localparam int V_VISIBLE      = 480;
    localparam int TEXT_PIX_W     = TEXT_COLS * CHAR_W;  // 320
    localparam int TEXT_PIX_H     = TEXT_ROWS * CHAR_H;  // 192
    localparam int H_MARGIN       = (H_VISIBLE - TEXT_PIX_W) / 2; // 160
    localparam int V_MARGIN       = (V_VISIBLE - TEXT_PIX_H) / 2; // 144
    localparam logic [15:0] TEXT_BASE = 16'h0400;

    always_comb begin
        // Default
        display_next   = 1'b0;
        col_next       = '0;
        row_next       = '0;
        x_in_cell_next = '0;
        y_in_cell_next = '0;
        vram_addr_next = 16'h0000;

        // Only care about active video
        if (active_nblank) begin
            // Check if current pixel is inside the 40x24 text window
            if (drawX >= H_MARGIN && drawX < (H_MARGIN + TEXT_PIX_W) &&
                drawY >= V_MARGIN && drawY < (V_MARGIN + TEXT_PIX_H)) begin

                // Convert to text-local coordinates
                logic [9:0] localX = drawX - H_MARGIN;
                logic [9:0] localY = drawY - V_MARGIN;

                col_next       = localX[9:3];   // /8, 0..39
                row_next       = localY[9:3];   // /8, 0..23
                x_in_cell_next = localX[2:0];   // 0..7
                y_in_cell_next = localY[2:0];   // 0..7

                display_next   = 1'b1;

                // Apple II layout:
                // addr = $0400 + (row & 7)*$80 + (row >> 3)*40 + col
                row_in_block   = row_next[2:0]; // row % 8
                block          = row_next[4:3]; // row / 8

                text_addr_next = TEXT_BASE
                            + {row_in_block, 7'd0}   // (row % 8) * $80
                            + block * 16'd40         // (row / 8) * 40
                            + col_next;              // column

                vram_addr_next = text_addr_next;
            end
        end
    end


    // always_comb begin
    //     // Character cell coordinates
    //     col_next       = drawX[9:3];  // /8
    //     row_next       = drawY[9:3];  // /8
    //     x_in_cell_next = drawX[2:0];  // 0..7
    //     y_in_cell_next = drawY[2:0];  // 0..7

    //     // Only display in 40x24 region inside active video
    //     display_next = active_nblank &&
    //                    (col_next < 6'd40) &&
    //                    (row_next < 5'd24);

    //     row_in_block = row_next[2:0];      // row % 8
    //     block        = row_next[4:3];      // row / 8

    //     text_addr_next = TEXT_BASE
    //                     + {row_in_block, 7'd0}    // (row % 8) * $80
    //                     + block * 16'd40        // (row / 8) * 40
    //                     + col_next;             // column

    //     if (display_next) begin
    //         vram_addr_next = text_addr_next;
    //     end else begin
    //         // Off-screen or blanking: don't care address
    //         vram_addr_next = 16'h0000;
    //     end
    // end

    // -----------------------------------------------------------------------
    // Stage 1: register address & char cell position; feed BRAM
    // -----------------------------------------------------------------------
    logic        display_s1;
    logic        active_s1;
    logic [2:0]  x_in_cell_s1;
    logic [2:0]  y_in_cell_s1;

    always_ff @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            vram_addr    <= 16'h0000;
            display_s1   <= 1'b0;
            active_s1    <= 1'b0;
            x_in_cell_s1 <= 3'd0;
            y_in_cell_s1 <= 3'd0;
        end else begin
            vram_addr    <= vram_addr_next;
            display_s1   <= display_next;
            active_s1    <= active_nblank;
            x_in_cell_s1 <= x_in_cell_next;
            y_in_cell_s1 <= y_in_cell_next;
        end
    end

    // -----------------------------------------------------------------------
    // Stage 2: BRAM data → char ROM, latch for final pixel
    // -----------------------------------------------------------------------
    logic        display_s2;
    logic        active_s2;
    logic [2:0]  x_in_cell_s2;
    logic [2:0]  y_in_cell_s2;
    logic [7:0]  char_code;
    logic [2:0]  glyph_row;
    logic [7:0]  glyph_bits;

    always_ff @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            display_s2   <= 1'b0;
            active_s2    <= 1'b0;
            x_in_cell_s2 <= 3'd0;
            y_in_cell_s2 <= 3'd0;
            char_code    <= 8'h20; // space
            glyph_row    <= 3'd0;
        end else begin
            display_s2   <= display_s1;
            active_s2    <= active_s1;
            x_in_cell_s2 <= x_in_cell_s1;
            y_in_cell_s2 <= y_in_cell_s1;

            // BRAM data for address from previous cycle
            char_code    <= vram_data;
            glyph_row    <= y_in_cell_s1[2:0];  // 0..7
        end
    end

    // Character ROM lookup: 256 chars * 8 rows
    char_rom font_rom (
        .char_code(char_code),
        .row      (glyph_row),
        .bits     (glyph_bits)
    );

    // -----------------------------------------------------------------------
    // Final pixel on/off and RGB output
    // -----------------------------------------------------------------------
    logic pixel_on;

    always_comb begin
        if (display_s2) begin
            // MSB = leftmost pixel
            pixel_on = glyph_bits[x_in_cell_s2];
        end else begin
            pixel_on = 1'b0;
        end
    end

    always_ff @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            red   <= 4'h0;
            green <= 4'h0;
            blue  <= 4'h0;
        end else if (!active_s2) begin
            // Outside active video region: black
            red   <= 4'h0;
            green <= 4'h0;
            blue  <= 4'h0;
        end else if (pixel_on && display_s2) begin
            // White text on black
            red   <= 4'hF;
            green <= 4'hF;
            blue  <= 4'hF;
        end else begin
            red   <= 4'h0;
            green <= 4'h0;
            blue  <= 4'h0;
        end
    end

endmodule
