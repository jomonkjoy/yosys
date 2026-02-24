// Simple 8-bit synchronous counter with synchronous reset
// Target: sky130 PDK, 100 MHz clock

module counter #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst_n,   // active-low synchronous reset
    input  wire             en,      // count enable
    output reg  [WIDTH-1:0] count,
    output wire             overflow // pulses when counter wraps
);

    assign overflow = (count == {WIDTH{1'b1}}) & en;

    always @(posedge clk) begin
        if (!rst_n)
            count <= {WIDTH{1'b0}};
        else if (en)
            count <= count + 1'b1;
    end

endmodule
