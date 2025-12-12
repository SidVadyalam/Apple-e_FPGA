
// Apple //e "64K-only" MMU
// CPU view:
//   0000–BFFF : RAM (read/write)
//   C000      : keyboard latch
//   C010–C01F : keyboard strobe clear (side effect only, returns 0)
//   C000–C0FF : I/O space; reads = 0, writes ignored
//   C100–FFFF : ROM (in the single 64K BRAM)

module apple2_mmu (
    input  logic        reset,

    // CPU side
    input logic         cpu_valid,
    input  logic [15:0] cpu_addr,
    input  logic [7:0]  cpu_do,
    input  logic        cpu_we,      // 1 = write, 0 = read
    output logic [7:0]  cpu_di,

    // Memory (single 64K BRAM)
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_din,
    output logic        mem_we,
    input  logic [7:0]  mem_dout,

    // Keyboard side runs on fast I/O clock
    input  logic        clk_io,
    input  logic [7:0]  ascii_in,
    input  logic        ascii_valid,

    // Video mode outputs (soft switches)
    output logic        text_mode,     // 1 = TEXT, 0 = graphics
    output logic        hires_mode,    // 1 = HIRES, 0 = LORES (when text_mode == 0)
    output logic        page_select,    // 0 = PAGE1 ($0400 / $2000), 1 = PAGE2 ($0800 / $4000)
    output logic        mixed_mode     // 1 = graphics + 4 lines text
);
    // Address regions
    logic addr_is_c000        = (cpu_addr == 16'hC000);
    logic addr_in_c010_to_01F = (cpu_addr[15:4] == 12'hC01);
    logic c0xx_region         = (cpu_addr[15:8] == 8'hC0);
    logic ram_region          = (cpu_addr < 16'hC000);   // 0000–BFFF

    // Keyboard latch @ C000
    logic [7:0] kb_data_out;

    // Any access to C010–C01F clears the strobe
    logic cpu_clear_strobe = addr_in_c010_to_01F;
    logic cpu_read_c000    = addr_is_c000 && !cpu_we;

    apple2_keyboard u_kb (
        .clk             (clk_io),        // 100 MHz domain
        .reset           (reset),

        .ascii_in        (ascii_in),
        .ascii_valid     (ascii_valid),

        .cpu_read_c000   (cpu_read_c000),
        .cpu_clear_strobe(cpu_clear_strobe),

        .cpu_data        (kb_data_out)
    );

    // Video soft switches
    always_ff @(posedge clk_io or posedge reset) begin
        if (reset) begin
            text_mode   <= 1'b1; // come up in TEXT
            hires_mode  <= 1'b0; // LORES by default if graphics
            page_select <= 1'b0; // PAGE1 by default
            mixed_mode  <= 1'b0;
        end else begin
            if(cpu_valid && c0xx_region) begin
                unique case (cpu_addr)
                    16'hC050: text_mode   <= 1'b0;         // GRAPHICS
                    16'hC051: text_mode   <= 1'b1;         // TEXT
                    16'hC052: mixed_mode  <= 1'b0; // MIXEDOFF - full screen graphics
                    16'hC053: mixed_mode  <= 1'b1; // MIXEDON  - graphics + 4 lines text
                    16'hC054: page_select <= 1'b0;         // PAGE1
                    16'hC055: page_select <= 1'b1;         // PAGE2
                    16'hC056: hires_mode  <= 1'b0;         // LORES
                    16'hC057: hires_mode  <= 1'b1;         // HIRES
                    default: ; // no change
                endcase
            end
        end
    end


    // Write path: only to RAM
    always_comb begin
        mem_addr = cpu_addr;
        mem_din  = cpu_do;

        if (cpu_we && ram_region && !addr_is_c000) begin
            mem_we = 1'b1;
        end else begin
            mem_we = 1'b0;
        end
    end

    // Read path: choose BRAM vs I/O
    always_comb begin
        // Default to BRAM data (RAM/ROM)
        cpu_di = mem_dout;

        if (!cpu_we) begin
            if (addr_is_c000) begin
                // Keyboard registers
                cpu_di = kb_data_out;

            end else if (addr_in_c010_to_01F) begin
                // C010–C01F: clear strobe only, return 0
                cpu_di = 8'h00;

            end else if (c0xx_region) begin
                // Any other C0xx read: present 0
                // → ROM sees "no aux, no banked memory"
                cpu_di = 8'h00;

            end else begin
                // 0000–BFFF (RAM) or C100–FFFF (ROM) via BRAM
                cpu_di = mem_dout;
            end
        end
    end

endmodule
