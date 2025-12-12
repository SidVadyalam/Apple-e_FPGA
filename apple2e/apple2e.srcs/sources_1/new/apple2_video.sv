// Modes (from MMU soft switches):
//   text_mode   = 1 => text only (40x24)
//   text_mode   = 0, hires_mode = 0 => lores (40x24, simplified 16-color)
//   text_mode   = 0, hires_mode = 1 => hires (280x192, monochrome+color)
//   mixed_mode  = 1 in HIRES => top = graphics, bottom 4 rows = text
//   page_select = 0 => PAGE1, 1 => PAGE2
//
// Memory usage (single 64K BRAM, read via port B):
//   Text/Lo-Res Page1: $0400-$07FF
//   Text/Lo-Res Page2: $0800-$0BFF
//   HGR Page1:         $2000-$3FFF
//   HGR Page2:         $4000-$5FFF
module apple2_video (
    input  logic        pixel_clk,
    input  logic        reset,

    input  logic [9:0]  drawX,
    input  logic [9:0]  drawY,
    input  logic        active_nblank,

    // Mode controls (from MMU soft switches)
    input  logic        text_mode,    // 1 = text only
    input  logic        hires_mode,   // 1 = HGR (ignored if text_mode=1)
    input  logic        page_select,  // 0 = PAGE1, 1 = PAGE2
    input  logic        mixed_mode,   // 1 = mixed text/graphics

    // Port B of main memory (64K BRAM)
    output logic [15:0] vram_addr,
    input  logic [7:0]  vram_data,

    // Pixel outputs (4:4:4 RGB)
    output logic [3:0]  red,
    output logic [3:0]  green,
    output logic [3:0]  blue
);

    localparam int H_VISIBLE = 640;
    localparam int V_VISIBLE = 480;
    // TEXT / LORES: 40x24, 8x8 blocks
    localparam int TEXT_COLS     = 40;
    localparam int TEXT_ROWS     = 24;
    localparam int CHAR_W        = 8;
    localparam int CHAR_H        = 8;
    localparam int TEXT_PIX_W    = TEXT_COLS * CHAR_W;   // 320
    localparam int TEXT_PIX_H    = TEXT_ROWS * CHAR_H;   // 192
    localparam int TEXT_H_MARGIN = (H_VISIBLE - TEXT_PIX_W) / 2; // 160
    localparam int TEXT_V_MARGIN = (V_VISIBLE - TEXT_PIX_H) / 2; // 144

    // HIRES: 280x192, scaled 2x2 => 560x384
    localparam int HGR_W        = 280;
    localparam int HGR_H        = 192;
    localparam int HGR_PIX_W    = HGR_W * 2;          // 560
    localparam int HGR_PIX_H    = HGR_H * 2;          // 384
    localparam int HGR_H_MARGIN = (H_VISIBLE - HGR_PIX_W) / 2; // 40
    localparam int HGR_V_MARGIN = (V_VISIBLE - HGR_PIX_H) / 2; // 48

    // Mixed mode: bottom 4 text rows = 32 HGR scanlines
    localparam int MIXED_TEXT_ROWS    = 4;
    localparam int MIXED_TEXT_START   = TEXT_ROWS - MIXED_TEXT_ROWS; // 20
    localparam int MIXED_GFX_H        = HGR_H - (MIXED_TEXT_ROWS * CHAR_H); // 192-32=160

    // Base addresses
    localparam logic [15:0] TEXT_BASE_PAGE1 = 16'h0400;
    localparam logic [15:0] TEXT_BASE_PAGE2 = 16'h0800;
    localparam logic [15:0] HGR_BASE_PAGE1  = 16'h2000;
    localparam logic [15:0] HGR_BASE_PAGE2  = 16'h4000;

    // Modes internally
    typedef enum logic [1:0] {
        MODE_NONE  = 2'b00,
        MODE_TEXT  = 2'b01,
        MODE_LORES = 2'b10,
        MODE_HIRES = 2'b11
    } mode_t;

    // Stage 0 - combinational: window checks, coordinate and address generation
    mode_t      mode_next;
    logic       display_next;
    logic [15:0] vram_addr_next;

    // Text/lores coordinates (centered 320x192)
    logic       in_text_window;
    logic [9:0] localX_t, localY_t;
    logic [5:0] txt_col_next;
    logic [4:0] txt_row_next;
    logic [2:0] x_in_cell_next;
    logic [2:0] y_in_cell_next;

    // HGR coordinates (centered 560x384)
    logic       in_hgr_window;
    logic [9:0] localX_h, localY_h;
    logic [8:0] hgr_x_next;   // 0..279
    logic [7:0] hgr_y_next;   // 0..191
    logic [5:0] hgr_col_next; // 0..39
    logic [2:0] hgr_bit_next; // 0..6
    logic       hgr_even_next;

    // Address intermediates
    logic [2:0] row_in_block;
    logic [1:0] block;
    logic [15:0] text_addr_next;
    logic [15:0] hgr_addr_next;

    // Mixed-mode helper (vertical)
    logic [7:0] mixed_y_rel;

    // Bases
    logic [15:0] text_base;
    logic [15:0] hgr_base;

    assign text_base = page_select ? TEXT_BASE_PAGE2 : TEXT_BASE_PAGE1;
    assign hgr_base  = page_select ? HGR_BASE_PAGE2  : HGR_BASE_PAGE1;

    always_comb begin
        mode_next       = MODE_NONE;
        display_next    = 1'b0;
        vram_addr_next  = 16'h0000;

        in_text_window  = 1'b0;
        in_hgr_window   = 1'b0;

        localX_t        = 10'd0;
        localY_t        = 10'd0;
        localX_h        = 10'd0;
        localY_h        = 10'd0;

        txt_col_next    = 6'd0;
        txt_row_next    = 5'd0;
        x_in_cell_next  = 3'd0;
        y_in_cell_next  = 3'd0;

        hgr_x_next      = 9'd0;
        hgr_y_next      = 8'd0;
        hgr_col_next    = 6'd0;
        hgr_bit_next    = 3'd0;
        hgr_even_next   = 1'b0;

        row_in_block    = 3'd0;
        block           = 2'd0;
        text_addr_next  = 16'h0000;
        hgr_addr_next   = 16'h0000;

        mixed_y_rel     = 8'd0;

        // TEXT / LORES window (320x192 centered)
        if (active_nblank &&
            drawX >= TEXT_H_MARGIN &&
            drawX <  TEXT_H_MARGIN + TEXT_PIX_W &&
            drawY >= TEXT_V_MARGIN &&
            drawY <  TEXT_V_MARGIN + TEXT_PIX_H) begin

            in_text_window = 1'b1;
            localX_t       = drawX - TEXT_H_MARGIN;
            localY_t       = drawY - TEXT_V_MARGIN;

            // Basic text coordinates (used by text + lores)
            txt_col_next   = localX_t[9:3]; // /8
            txt_row_next   = localY_t[9:3]; // /8
            x_in_cell_next = localX_t[2:0];
            y_in_cell_next = localY_t[2:0];
        end


        // HGR window (280x192 scaled 2x2 to 560x384 centered)

        if (active_nblank &&
            drawX >= HGR_H_MARGIN &&
            drawX <  HGR_H_MARGIN + HGR_PIX_W &&
            drawY >= HGR_V_MARGIN &&
            drawY <  HGR_V_MARGIN + HGR_PIX_H) begin

            in_hgr_window = 1'b1;
            localX_h      = drawX - HGR_H_MARGIN;
            localY_h      = drawY - HGR_V_MARGIN;

            // 2x2 scaling: divide by 2
            hgr_x_next    = localX_h[9:1]; // 0..279
            hgr_y_next    = localY_h[9:1]; // 0..191
            hgr_even_next = ~hgr_x_next[0];

            if (hgr_x_next < HGR_W && hgr_y_next < HGR_H) begin
                // 280 pixels => 40 columns, 7 pixels/column
                hgr_col_next = hgr_x_next / 7; // 0..39
                hgr_bit_next = hgr_x_next % 7; // 0..6

                // Apple II HGR address mapping
                hgr_addr_next = hgr_base
                              + ({hgr_y_next[2:0], 10'b0})         // (y&7)*1024
                              + ({5'b0, hgr_y_next[5:3], 7'b0})    // ((y>>3)&7)*128
                              + (hgr_y_next[7:6] * 16'h28)         // (y>>6)*40
                              + hgr_col_next;                      // column
            end
        end

        // Mode selection and address generation

        // TEXT-ONLY mode
        if (text_mode) begin
            if (in_text_window &&
                txt_col_next < TEXT_COLS &&
                txt_row_next < TEXT_ROWS) begin

                mode_next    = MODE_TEXT;
                display_next = 1'b1;

                row_in_block   = txt_row_next[2:0];
                block          = txt_row_next[4:3];
                text_addr_next = text_base
                               + {row_in_block, 7'd0}   // row_in_block*128
                               + (block * 16'd40)       // block*40
                               + txt_col_next;

                vram_addr_next = text_addr_next;
            end

        // GRAPHICS MODES
        end else begin
            // HIRES mode
            if (hires_mode) begin
                // Mixed mode: top = HIRES graphics, bottom 4 rows = TEXT
                // Text rows 20..23 live in HGR lines 160..191
                if (mixed_mode &&
                    in_hgr_window &&
                    hgr_x_next < HGR_W &&
                    hgr_y_next < HGR_H &&
                    (hgr_y_next >= MIXED_GFX_H)) begin

                    mode_next    = MODE_TEXT;
                    display_next = 1'b1;

                    // Horizontal mapping: 280 HGR pixels -> 40 cols
                    // (7 pixels/column)
                    txt_col_next   = hgr_col_next;  // 0..39
                    x_in_cell_next = hgr_bit_next;  // 0..6 (glyph bit)

                    // Vertical mapping: HGR lines 160..191 -> text rows 20..23
                    // (8 HGR lines per text row)
                    mixed_y_rel    = hgr_y_next - MIXED_GFX_H;      // 0..31
                    txt_row_next   = MIXED_TEXT_START + mixed_y_rel[7:3]; // /8
                    y_in_cell_next = mixed_y_rel[2:0];

                    if (txt_col_next < TEXT_COLS && txt_row_next < TEXT_ROWS) begin
                        row_in_block   = txt_row_next[2:0];
                        block          = txt_row_next[4:3];
                        text_addr_next = text_base
                                       + {row_in_block, 7'd0}   // row_in_block*128
                                       + (block * 16'd40)       // block*40
                                       + txt_col_next;

                        vram_addr_next = text_addr_next;
                    end else begin
                        display_next   = 1'b0;
                    end

                // HIRES graphics region
                end else if (in_hgr_window &&
                             hgr_x_next < HGR_W &&
                             hgr_y_next < HGR_H &&
                             (!mixed_mode || (hgr_y_next < MIXED_GFX_H))) begin

                    mode_next      = MODE_HIRES;
                    display_next   = 1'b1;
                    vram_addr_next = hgr_addr_next;
                end

            // LORES mode
            end else begin
                if (in_text_window &&
                    txt_col_next < TEXT_COLS &&
                    txt_row_next < TEXT_ROWS) begin

                    if (mixed_mode && (txt_row_next >= MIXED_TEXT_START)) begin
                        // Bottom 4 rows = TEXT
                        mode_next    = MODE_TEXT;
                        display_next = 1'b1;
                    end else begin
                        // Regular lores (40x24)
                        mode_next    = MODE_LORES;
                        display_next = 1'b1;
                    end

                    row_in_block   = txt_row_next[2:0];
                    block          = txt_row_next[4:3];
                    text_addr_next = text_base
                                   + {row_in_block, 7'd0}
                                   + (block * 16'd40)
                                   + txt_col_next;

                    vram_addr_next = text_addr_next;
                end
            end
        end
    end

    // Stage 1 - register address & primary control (drives BRAM)
    mode_t     mode_s1;
    logic      display_s1;
    logic      active_s1;

    logic [2:0] x_in_cell_s1;
    logic [2:0] y_in_cell_s1;

    logic [2:0] hgr_bit_s1;
    logic       hgr_even_s1;

    always_ff @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            vram_addr    <= 16'h0000;
            mode_s1      <= MODE_NONE;
            display_s1   <= 1'b0;
            active_s1    <= 1'b0;
            x_in_cell_s1 <= 3'd0;
            y_in_cell_s1 <= 3'd0;
            hgr_bit_s1   <= 3'd0;
            hgr_even_s1  <= 1'b0;
        end else begin
            vram_addr    <= vram_addr_next;
            mode_s1      <= mode_next;
            display_s1   <= display_next;
            active_s1    <= active_nblank;
            x_in_cell_s1 <= x_in_cell_next;
            y_in_cell_s1 <= y_in_cell_next;
            hgr_bit_s1   <= hgr_bit_next;
            hgr_even_s1  <= hgr_even_next;
        end
    end

    // Stage 2 - BRAM data → per-mode decode (latched)
    mode_t     mode_s2;
    logic      display_s2;
    logic      active_s2;

    // TEXT glyph
    logic [7:0] char_code_s2;
    logic [2:0] glyph_row_s2;
    logic [7:0] glyph_bits_s2;
    logic [2:0] x_in_cell_s2;
    logic [2:0] y_in_cell_s2; 

    // LORES color nibble
    logic [3:0] lores_color_s2;

    // HIRES color context
    logic [7:0] hgr_byte_s2;
    logic [2:0] hgr_bit_s2;
    logic       hgr_even_s2;
    logic       hgr_pixel_s2;

    always_ff @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            mode_s2        <= MODE_NONE;
            display_s2     <= 1'b0;
            active_s2      <= 1'b0;
            char_code_s2   <= 8'h20;
            glyph_row_s2   <= 3'd0;
            x_in_cell_s2   <= 3'd0;
            y_in_cell_s2   <= 3'd0;
            lores_color_s2 <= 4'h0;
            hgr_byte_s2    <= 8'h00;
            hgr_bit_s2     <= 3'd0;
            hgr_even_s2    <= 1'b0;
            hgr_pixel_s2   <= 1'b0;
        end else begin
            mode_s2      <= mode_s1;
            display_s2   <= display_s1;
            active_s2    <= active_s1;
            x_in_cell_s2 <= x_in_cell_s1;
            y_in_cell_s2 <= y_in_cell_s1;

            case (mode_s1)
                MODE_TEXT: begin
                    char_code_s2 <= vram_data;
                    glyph_row_s2 <= y_in_cell_s1;
                end

                MODE_LORES: begin
                    // Simple lores model: 4 scanlines per nibble
                    if (y_in_cell_s1 < 4)
                        lores_color_s2 <= vram_data[3:0];
                    else
                        lores_color_s2 <= vram_data[7:4];
                end

                MODE_HIRES: begin
                    hgr_byte_s2  <= vram_data;
                    hgr_bit_s2   <= hgr_bit_s1;
                    hgr_even_s2  <= hgr_even_s1;
                    hgr_pixel_s2 <= vram_data[hgr_bit_s1];
                end

                default: begin
                    hgr_pixel_s2 <= 1'b0;
                end
            endcase
        end
    end

    // Character ROM
    char_rom font_rom (
        .char_code(char_code_s2),
        .row      (glyph_row_s2),
        .bits     (glyph_bits_s2)
    );

    // Lores color lookup
    function automatic [11:0] lores_color_to_rgb (input [3:0] c);
        case (c)
            4'h0: lores_color_to_rgb = 12'h000; // black
            4'h1: lores_color_to_rgb = 12'h800; // dark red
            4'h2: lores_color_to_rgb = 12'h008; // dark blue/greenish
            4'h3: lores_color_to_rgb = 12'h808;
            4'h4: lores_color_to_rgb = 12'h080; // green
            4'h5: lores_color_to_rgb = 12'h444; // gray
            4'h6: lores_color_to_rgb = 12'h048;
            4'h7: lores_color_to_rgb = 12'h88F;
            4'h8: lores_color_to_rgb = 12'h840;
            4'h9: lores_color_to_rgb = 12'hF80; // orange-ish
            4'hA: lores_color_to_rgb = 12'h0F0; // bright green
            4'hB: lores_color_to_rgb = 12'hF4F;
            4'hC: lores_color_to_rgb = 12'hFF0; // yellow
            4'hD: lores_color_to_rgb = 12'h0FF; // cyan
            4'hE: lores_color_to_rgb = 12'hFFF; // white
            4'hF: lores_color_to_rgb = 12'hFFF; // white
            default: lores_color_to_rgb = 12'h000;
        endcase
    endfunction

    // Final pixel combiner with HGR color according to manual-like rules
    logic [11:0] rgb;
    logic [3:0] r_out, g_out, b_out;
    logic [7:0] b;
    logic left_on, right_on;
    logic has_neighbor_on;
    logic palette1; // bit7: 0=purple/green, 1=blue/orange

    always_comb begin
        r_out = 4'h0;
        g_out = 4'h0;
        b_out = 4'h0;

        if (!active_s2) begin
            r_out = 4'h0;
            g_out = 4'h0;
            b_out = 4'h0;
        end else begin
            case (mode_s2)
                // TEXT (white on black)
                MODE_TEXT: begin
                    if (display_s2 && glyph_bits_s2[x_in_cell_s2]) begin
                        r_out = 4'hF;
                        g_out = 4'hF;
                        b_out = 4'hF;
                    end
                end

                // LORES
                MODE_LORES: begin
                    if (display_s2) begin                    
                        rgb   = lores_color_to_rgb(lores_color_s2);
                        r_out = rgb[11:8];
                        g_out = rgb[7:4];
                        b_out = rgb[3:0];
                    end
                end

                // HIRES with simple color artifacting approximation
                MODE_HIRES: begin
                    if (display_s2 && hgr_pixel_s2) begin
                        b              = hgr_byte_s2;
                        palette1       = b[7];

                        // Neighbor bits within the same byte
                        left_on        = (hgr_bit_s2 > 0) ? b[hgr_bit_s2-1] : 1'b0;
                        right_on       = (hgr_bit_s2 < 6) ? b[hgr_bit_s2+1] : 1'b0;
                        has_neighbor_on= left_on | right_on;

                        if (has_neighbor_on) begin
                            // Adjacent columns on -> white
                            r_out = 4'hF;
                            g_out = 4'hF;
                            b_out = 4'hF;
                        end else begin
                            // Single pixel: color depends on column parity and bit7
                            if (hgr_even_s2) begin
                                // Even columns: purple/blue
                                if (!palette1) begin
                                    // purple
                                    r_out = 4'h8;
                                    g_out = 4'h0;
                                    b_out = 4'h8;
                                end else begin
                                    // blue
                                    r_out = 4'h0;
                                    g_out = 4'h0;
                                    b_out = 4'hF;
                                end
                            end else begin
                                // Odd columns: green/orange
                                if (!palette1) begin
                                    // green
                                    r_out = 4'h0;
                                    g_out = 4'hF;
                                    b_out = 4'h0;
                                end else begin
                                    // orange
                                    r_out = 4'hF;
                                    g_out = 4'h8;
                                    b_out = 4'h0;
                                end
                            end
                        end
                    end
                end

                default: begin
                    r_out = 4'h0;
                    g_out = 4'h0;
                    b_out = 4'h0;
                end
            endcase
        end
    end

    // Output registers
    always_ff @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            red   <= 4'h0;
            green <= 4'h0;
            blue  <= 4'h0;
        end else begin
            red   <= r_out;
            green <= g_out;
            blue  <= b_out;
        end
    end

endmodule
