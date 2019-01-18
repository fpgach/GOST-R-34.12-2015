`define BYTE    [7:0]
// _    _    _    _    _    _    _    _    _    _    _    _    _
//| \__| \__| \__| \__| \__| \__| \__| \__| \__| \__| \__| \__| \_____CLK
//            ____                ____
//___________|    \______________|    \______________________________VALID_S
//________________                ____                _______________
//                \______________|    \______________|               READY
//                                ____                ____
//_______________________________|    \______________|    \_________ READY_S
module f1_s_fsm(
    input                   reset_n,
    input                   clk,

    input                   key_valid_s,
    input   [15:0]`BYTE     key1,
    input   [15:0]`BYTE     key2,

    input                   valid_s,
    input                   normal_inverse_n,
    input   [15:0]`BYTE     din,

    output                  ready_s,
    output  [15:0]`BYTE     dout,

    output                  pre_ready_s,
    output                  ready

);
    reg     [15:0]`BYTE     key_out_r = 128'd0;
    reg                     ready_sr = 1'b0, pre_ready_sr = 1'b0,
                            ready_r = 1'b0;

    reg                     s_valid_s;
    reg     [15:0]`BYTE     s_din;

    wire                    s_pre_ready_s, s_ready_s;
    wire    [15:0]`BYTE     s_dout;


    f1_s s(
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .valid_s        ( s_valid_s ),
        .pi_inverse_n   ( normal_inverse_n ),
        .din            ( s_din ),

        .pre_ready_s    ( s_pre_ready_s ),
        .ready_s        ( s_ready_s ),
        .dout           ( s_dout )
    );

    localparam  IDLE        = 8'h00,
                K1_IDLE     = 8'h01,
                K2          = 8'h02,
                K2_IDLE     = 8'h04,
                K_LAST      = 8'h08,
                ENC_DEC     = 8'h10;
    reg     [7:0] state = IDLE, state_next;

    always @* begin
        state_next  = state;
        s_valid_s   = 1'b0;
        s_din       = key1;
        case (state)
            default: begin
                case ( {key_valid_s, valid_s} )
                    default: begin
                        state_next  = IDLE;
                        s_valid_s   = 1'b0;
                        s_din       = key1;
                    end
                    2'b10, 2'b11: begin
                        state_next  = K1_IDLE;
                        s_valid_s   = 1'b1;
                        s_din       = key1;
                    end
                    2'b01: begin
                        state_next  = ENC_DEC;
                        s_valid_s   = 1'b1;
                        s_din       = din;
                    end
                endcase
            end

            K1_IDLE: begin
                state_next  = s_ready_s ? K2 : state;
                s_valid_s   = 1'b0;
                s_din       = key1;
            end
            K2: begin
                state_next  = K2_IDLE;
                s_valid_s   = 1'b1;
                s_din       = key2;
            end
            K2_IDLE: begin
                state_next  = s_ready_s ? K_LAST : state;
                s_valid_s   = 1'b0;
                s_din       = key2;
            end
            K_LAST: begin
                state_next  = IDLE;
                s_valid_s   = 1'b0;
                s_din       = key1;
            end
            ENC_DEC: begin
                state_next  = s_ready_s ? IDLE : state;
                s_valid_s   = 1'b0;
                s_din       = din;
            end
        endcase
    end

    always @ (posedge clk, negedge reset_n)
    if (!reset_n) begin
        state           <= IDLE;
        key_out_r       <= 128'd0;
        ready_sr        <= 1'b0;
        pre_ready_sr    <= 1'b0;
        ready_r         <= 1'b0;


    end else begin
        state           <= state_next;
        ready_sr        <= 1'b0;
        pre_ready_sr    <= 1'b0;
        ready_r         <= 1'b0;
        case (state)
            default: begin
                ready_r     <= 1'b1;
            end
            K1_IDLE, K2_IDLE: begin
                pre_ready_sr    <= state_next == K_LAST;
            end
            K2: begin
                ready_sr        <= 1'b1;
                key_out_r       <= s_dout;
            end
            K_LAST: begin
                ready_r         <= 1'b1;
                ready_sr        <= 1'b1;
                key_out_r       <= s_dout;
            end

            ENC_DEC: begin
                pre_ready_sr    <= state_next == K_LAST;
                ready_r         <= s_ready_s;
                ready_sr        <= s_ready_s;
                key_out_r       <= s_dout;
            end


        endcase
    end

        assign dout         = key_out_r;
        assign ready_s      = ready_sr;
        assign pre_ready_s  = pre_ready_sr;
        assign ready        = ready_r;



endmodule
