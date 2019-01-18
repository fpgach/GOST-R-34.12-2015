`define BYTE [7:0]
// _    _    _    _    _    _    _    _    _    _    _    _    _
//| \__| \__| \__| \__| \__| \__| \__| \__| \__| \__| \__| \__| \_____CLK
//            ____
//___________|    \__________________________________________________VALID_S
//________________                                    _______________
//                \__________________________________|               READY
//                                ____                ____
//_______________________________|    \______________|    \_________ READY_S

module f1_ls_fsm(
    input                   reset_n,
    input                   clk,

    input                   skey_valid_s,
    input   [31:0]`BYTE     skey,

    input                   valid_s,
    input   [15:0]`BYTE     kin,
    input   [15:0]`BYTE     din,

    output                  ready_s,
    output  [15:0]`BYTE     dout_key1,
    output  [15:0]`BYTE     key2,

    output                  pre_ready_s,
    output                  ready

);
    reg     [15:0]`BYTE     dout_key1_r = 128'd0, key2_r = 128'd0,
                            tmp_key1_r = 128'd0, tmp_key2_r = 128'd0;
    reg                     ready_sr = 1'b0, pre_ready_sr = 1'b0,
                            ready_r = 1'b0;

    reg                     ls_valid_s;
    reg     [15:0]`BYTE     ls_din;
    wire                    ls_pre_ready_s, ls_ready_s;
    wire    [15:0]`BYTE     ls_dout;



    f1_ls    ls(
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .valid_s        ( ls_valid_s ),
        .din            ( ls_din ),
        // .din            ( 128'h99bb99ff99bb99ffffffffffffffffff ),

        .pre_ready_s    ( ls_pre_ready_s ),
        .ready_s        ( ls_ready_s ),
        .dout           ( ls_dout )
    );


    reg     [7:0]           c_addr = 8'd0;
    wire    [15:0]`BYTE     c_dout;
    lrom #(.FILE("CTable.txt")) c (
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .addr           ( c_addr ),
        .dat            ( c_dout )
    );


    localparam  IDLE            = 8'h00,
                K1_IDLE         = 8'h01,
                K               = 8'h02,
                K_IDLE          = 8'h04,
                K_LAST          = 8'h08,


                ENC1_IDLE       = 8'h10,
                ENC             = 8'h20,
                ENC_IDLE        = 8'h40,
                ENC_LAST        = 8'h80;
                //
                // ENC_IDLE        = 8'h10,
                // ENC             = 8'h20,
                // ENC_LAST        = 8'h40;

                // LS_ENC_FIRST    = 8'h08,
                // LS_ENC          = 8'h10,
                // LS_ENC_LAST = 8'h10;

    reg     [7:0]   state = IDLE, state_next;

    always @* begin
        state_next  = state;
        ls_valid_s  = 1'b0;
        ls_din      = skey[31:16] ^ c_dout;
        case (state)
            default: begin
                case ( {skey_valid_s, valid_s} )
                    default: begin
                        state_next  = IDLE;
                        ls_valid_s  = 1'b0;
                        ls_din      = skey[31:16] ^ c_dout;
                    end
                    2'b10, 2'b11: begin
                        state_next  = K1_IDLE;
                        ls_din      = skey[31:16] ^ c_dout;
                        ls_valid_s  = 1'b1;
                    end
                    2'b01: begin
                        state_next  = ENC1_IDLE;
                        ls_din      = din ^ kin;
                        ls_valid_s  = 1'b1;
                    end

                endcase
            end
            K1_IDLE: begin
                state_next  = K;
                ls_din      = skey[31:16] ^ c_dout;
                ls_valid_s  = ls_ready_s;
            end
            K: begin
                state_next  = ls_ready_s ? K_IDLE : state;
                ls_din      = ls_dout ^ c_dout ^ tmp_key2_r;
                ls_valid_s  = ls_ready_s;

            end
            K_IDLE: begin
                ls_din      = ls_dout ^ c_dout ^ tmp_key2_r;
                ls_valid_s  = ls_ready_s;
                case (c_addr)
                    default:
                        state_next  = K;
                    8'd32:
                        state_next  = K_LAST;
                endcase

            end
            K_LAST, ENC_LAST: begin
                state_next  = ls_ready_s ? IDLE : state;
                ls_din      = skey[31:16] ^ c_dout;
                ls_valid_s  = 1'b0;
            end

            ENC1_IDLE: begin
                state_next  = ENC;
                ls_din      = din ^ kin;
                ls_valid_s  = ls_ready_s;

            end
            ENC: begin
                state_next  = ls_ready_s ? ENC_IDLE : state;
                ls_din      = ls_dout ^ kin;
                ls_valid_s  = ls_ready_s;
            end
            ENC_IDLE: begin
                ls_din      = ls_dout ^ kin;
                ls_valid_s  = ls_ready_s;
                case (c_addr)
                    default:
                        state_next  = ENC;
                    8'd9: begin
                        state_next  = ENC_LAST;
                    end
                endcase

            end
            ENC_LAST: begin

            end
        endcase
    end

    always @ (posedge clk, negedge reset_n)
    if (!reset_n) begin
        state           <= IDLE;
        c_addr          <= 8'd0;
        // cnt             <= 8'd0;
        dout_key1_r     <= 128'd0;
        key2_r          <= 128'd0;
        ready_sr        <= 1'b0;
        pre_ready_sr    <= 1'b0;
        ready_r         <= 1'b0;

        tmp_key1_r      <= 128'd0;
        tmp_key2_r      <= 128'd0;

    end else begin
        state           <= state_next;
        ready_sr        <= 1'b0;
        pre_ready_sr    <= 1'b0;
        ready_r         <= 1'b0;

        case (state)
            default: begin
                // cnt     <= 8'd0;
                c_addr          <= 8'd0;
                case ( {skey_valid_s, valid_s} )
                    default: begin
                        ready_r         <= 1'b1;
                    end
                    2'b10, 2'b11: begin
                        dout_key1_r     <= skey[31:16];
                        key2_r          <= skey[15:0];
                        tmp_key1_r      <= skey[31:16];
                        tmp_key2_r      <= skey[15:0];

                        ready_sr        <= 1'b1;
                        c_addr          <= c_addr + 1'b1;
                    end
                    2'b01: begin;
                        dout_key1_r     <= din;
                        key2_r          <= kin;
                        c_addr          <= c_addr + 1'b1;
                    end
                endcase
            end
            K1_IDLE: begin end
            K_IDLE: begin
                tmp_key1_r  <= ls_dout ^ tmp_key2_r;
                tmp_key2_r  <= tmp_key1_r;
            end
            K: if (ls_ready_s) begin
                c_addr      <= c_addr + 1'b1;
                case (c_addr)
                    default: begin end
                    8'd8, 8'd16, 8'd24, 8'd32: begin
                        dout_key1_r     <= ls_dout ^ tmp_key2_r;
                        key2_r          <= tmp_key1_r;
                        ready_sr        <= 1'b1;
                    end
                endcase
            end

            K_LAST: if (ls_ready_s) begin
                tmp_key1_r      <= 128'd0;
                tmp_key2_r      <= 128'd0;
                dout_key1_r     <= ls_dout ^ tmp_key2_r;
                key2_r          <= tmp_key1_r;
                c_addr          <= 8'd0;
                ready_r         <= 1'b1;
                ready_sr        <= 1'b1;
            end

            ENC1_IDLE, ENC_IDLE: begin end
            ENC: if (ls_ready_s) begin
                c_addr          <= c_addr + 1'b1;
                ready_sr        <= 1'b1;
            end


            ENC_LAST: begin
                dout_key1_r     <= ls_dout ^ kin;
                ready_sr        <= state_next == IDLE;
                ready_r         <= state_next == IDLE;
                c_addr          <= 8'd0;
            end



        endcase
    end

    assign ready_s      = ready_sr;
    assign ready        = ready_r;
    assign pre_ready_s  = pre_ready_sr;
    assign dout_key1    = dout_key1_r;
    assign key2         = key2_r;


endmodule
