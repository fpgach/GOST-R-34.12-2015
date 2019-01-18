`define BYTE [7:0]
module f1_ls_inv(
    input                   reset_n,
    input                   clk,

    input                   valid_s,
    input   [15:0]`BYTE     din,

    output                  pre_ready_s,
    output                  ready_s,
    output   [15:0]`BYTE    dout

);
    wire    [15:0][15:0]`BYTE   lstable_val;


    reg     [15:0]`BYTE         tmp_r = 128'd0;
    reg     [15:0]`BYTE         din_r = 128'd0;
    reg     [15:0]`BYTE         dout_r = 128'd0;
    reg                         pre_ready_sr = 1'b0, ready_sr = 1'b0;


    localparam  IDLE    = 4'd0,
                ADDR    = 4'h1,
                ST0     = 4'd2,
                ST1     = 4'd3,
                ST2     = 4'd4,
                ST3     = 4'd5;
    reg     [3:0] state = IDLE, state_next;
    always @* begin
        state_next = state;
        case (state)
            default:
                    state_next = valid_s ? ADDR: IDLE;
            ADDR:   state_next = ST0;
            ST0:    state_next = ST1;
            ST1:    state_next = ST2;
            ST2:    state_next = ST3;
        endcase
    end


    always @ (posedge clk, negedge reset_n)
    if (!reset_n) begin
        state           <= IDLE;
        tmp_r           <= 128'd0;
        din_r           <= 128'd0;
        dout_r          <= 128'd0;
        pre_ready_sr    <= 1'b0;
        ready_sr        <= 1'b0;
    end else begin
        state   <= state_next;

        case (state_next)
            default: begin  end
            ADDR:    din_r   <= din;

        endcase

        case (state)
            default: begin
                pre_ready_sr    <= 1'b0;
                ready_sr        <= 1'b0;
            end
            ST0: begin
                tmp_r           <= lstable_val[3] ^ lstable_val[2] ^
                    lstable_val[1]  ^ lstable_val[0];
                pre_ready_sr    <= 1'b0;
                ready_sr        <= 1'b0;
            end
            ST1: begin
                tmp_r           <= tmp_r ^ lstable_val[7]  ^ lstable_val[6] ^
                    lstable_val[5]  ^ lstable_val[4];
                pre_ready_sr    <= 1'b0;
                ready_sr        <= 1'b0;
            end
            ST2: begin
                tmp_r           <= tmp_r ^ lstable_val[11] ^ lstable_val[10] ^
                    lstable_val[9]  ^ lstable_val[8];
                pre_ready_sr    <= 1'b1;
                ready_sr        <= 1'b0;
            end
            ST3: begin
                dout_r          <= tmp_r ^ lstable_val[15] ^ lstable_val[14] ^
                    lstable_val[13] ^ lstable_val[12];
                pre_ready_sr    <= 1'b0;
                ready_sr        <= 1'b1;
            end
        endcase
    end

    assign pre_ready_s  = pre_ready_sr;
    assign ready_s      = ready_sr;
    assign dout         = dout_r;

    lrom #(.FILE("LSTable_0_inv.txt")) lstable_0 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[15] ),
        .dat            ( lstable_val[15] )
    );

    lrom #(.FILE("LSTable_1_inv.txt")) lstable_1 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[14] ),
        .dat            ( lstable_val[14] )
    );

    lrom #(.FILE("LSTable_2_inv.txt")) lstable_2 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[13] ),
        .dat            ( lstable_val[13] )
    );

    lrom #(.FILE("LSTable_3_inv.txt")) lstable_3 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[12] ),
        .dat            ( lstable_val[12] )
    );

    lrom #(.FILE("LSTable_4_inv.txt")) lstable_4 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[11] ),
        .dat            ( lstable_val[11] )
    );

    lrom #(.FILE("LSTable_5_inv.txt")) lstable_5 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[10] ),
        .dat            ( lstable_val[10] )
    );

    lrom #(.FILE("LSTable_6_inv.txt")) lstable_6 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[9] ),
        .dat            ( lstable_val[9] )
    );

    lrom #(.FILE("LSTable_7_inv.txt")) lstable_7 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[8] ),
        .dat            ( lstable_val[8] )
    );

    lrom #(.FILE("LSTable_8_inv.txt")) lstable_8 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[7] ),
        .dat            ( lstable_val[7] )
    );

    lrom #(.FILE("LSTable_9_inv.txt")) lstable_9 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[6] ),
        .dat            ( lstable_val[6] )
    );

    lrom #(.FILE("LSTable_10_inv.txt")) lstable_10 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[5] ),
        .dat            ( lstable_val[5] )
    );

    lrom #(.FILE("LSTable_11_inv.txt")) lstable_11 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[4] ),
        .dat            ( lstable_val[4] )
    );

    lrom #(.FILE("LSTable_12_inv.txt")) lstable_12 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[3] ),
        .dat            ( lstable_val[3] )
    );

    lrom #(.FILE("LSTable_13_inv.txt")) lstable_13 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[2] ),
        .dat            ( lstable_val[2] )
    );

    lrom #(.FILE("LSTable_14_inv.txt")) lstable_14 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[1] ),
        .dat            ( lstable_val[1] )
    );

    lrom #(.FILE("LSTable_15_inv.txt")) lstable_15 (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( din_r[0] ),
        .dat            ( lstable_val[0] )
    );



endmodule
