`define BYTE [7:0]

module dpram #(
    parameter               LOG2_L = 4
)(
    input                   clk,

    input                   we,
    input   [LOG2_L-1:0]    d_a,
    input   [15:0]`BYTE     d,

    input   [LOG2_L-1:0]    q_a,
    output  [15:0]`BYTE     q
);
    reg    [127:0]         mem[0:(2**LOG2_L)-1];
    integer i;
    initial begin
        for (i = 0; i < 2**LOG2_L; i = i + 1)
            mem[i] = 128'd0;
    end
    assign                 q = mem[q_a];
    always @(posedge clk)
        if (we)
            mem[d_a] <= d;

endmodule
