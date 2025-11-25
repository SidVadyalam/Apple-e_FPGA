module clockdiv(
    input logic clk_in,
    input logic reset,
    output logic clk_out
);
    logic [16:0] counter;

    always_ff @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 2'b0;
        end else begin
            counter <= counter + 2'b1;
        end
    end 
    assign clk_out = counter[16];
endmodule