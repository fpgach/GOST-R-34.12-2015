module  lrom #(
    parameter FILE = "",
    parameter W = 128
)(
    input           reset_n,
    input           clk,

    input   [7:0]   addr,
    output  [W-1:0] dat

);
    reg     [W-1:0]  memory[0:255];
    initial begin
        if (FILE != "") begin
            $readmemh(FILE, memory);
        end
    end

    reg     [W-1:0]  r_dat = {W{1'b0}};
    always @(posedge clk, negedge reset_n)
    if (!reset_n) begin
        r_dat <= {W{1'b0}};
    end else begin
        r_dat <= memory[addr];
    end

    assign dat = r_dat;

endmodule
