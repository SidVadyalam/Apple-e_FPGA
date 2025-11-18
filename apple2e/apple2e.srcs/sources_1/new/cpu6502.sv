
module cpu6502(
    input logic clk,
    input logic reset,
    input logic [15:0] AB,
    input logic [7:0] DI,
    output logic [7:0] DO,
    output logic WE,
    input logic IRQ,
    input logic NMI,
    output logic RDY   
);

 // T65 wires
    logic        R_W_n;
    logic [23:0] A_bus;
    logic [7:0]  DO_bus;
    logic [7:0]  DI_bus;

    // Unused T65 outputs (for now)
    logic Sync, EF, MF, XF, ML_n, VP_n, VDA, VPA;

    // Map DI/DO
    assign DI_bus = DI;
    assign DO     = DO_bus;

    // Address: only 16 bits used in 6502 mode
    assign AB = A_bus[15:0];

    // WE is the natural 6502 style (1 = write)
    // T65 gives us R_W_n: 1 = READ, 0 = WRITE
    assign WE = (R_W_n == 1'b0);

    // Instantiate the VHDL T65 core.
    // Vivado treats std_logic_vector like 1-bit/packed vectors, so
    // direct connection from logic is fine.
    T65 u_t65 (
        .Mode   (2'b00),        // "00" => 6502 mode
        .Res_n  (~reset),       // T65 reset is active-low
        .Clk    (clk),
        .Rdy    (RDY),

        .Abort_n(1'b1),         // not used
        .IRQ_n  (~IRQ),         // cpu6502: IRQ active-high -> T65: active-low
        .NMI_n  (~NMI),         // same for NMI
        .SO_n   (1'b1),         // not used by Apple II typically

        .R_W_n  (R_W_n),
        .Sync   (Sync),
        .EF     (EF),
        .MF     (MF),
        .XF     (XF),
        .ML_n   (ML_n),
        .VP_n   (VP_n),
        .VDA    (VDA),
        .VPA    (VPA),

        .A      (A_bus),
        .DI     (DI_bus),
        .DO     (DO_bus)
    );

endmodule
