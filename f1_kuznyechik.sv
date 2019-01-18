`define BYTE    [7:0]
// _    _    _    _    _    _    _    _    _    _    _    _    _
//| \__| \__| \__| \__| \__| \__| \__| \__| \__| \__| \__| \__| \_____CLK
//            ____                ____
//___________|    \______________|    \______________________________VALID_S
//________________                ____                _______________
//                \______________|    \______________|               READY
//                                ____                ____
//_______________________________|    \______________|    \_________ READY_S
//use valid strobe to catch data in
//use ready strobe to fix data out
module f1_kuznyechik(
    input                   reset_n,
    input                   clk,

    output                  ready,

    input                   skey_valid_s,
    input   [31:0]`BYTE     skey,

    output                  skey_ready_s,

    input                   valid_s,
    input                   encrypt_decrypt_n,
    input   [15:0]`BYTE     din,

    output                  ready_s,
    output  [15:0]`BYTE     dout
);

    reg                     ready_sr = 1'b0, skey_ready_sr = 1'b0,
                            ready_r = 1'b0;
    reg     [15:0]`BYTE     dout_r = 128'd0;
    reg     [4:0]           k_addr = 5'd0;


    reg                     s_normal_inverse_n;
    reg                     ls_valid_s, s_key_valid_s, s_dat_valid_s, ls_inv_valid_s,
                            k_valid_s;
    reg     [15:0]`BYTE     ls_inv_din, s_din;

    wire                    ls_ready, ls_ready_s, s_ready_s, ls_inv_ready_s,
                            k_ready_s;
    wire    [15:0]`BYTE     key1, key2, key3_4, s_dout, key_out;

    f1_ls_fsm   ls(
        .reset_n            ( reset_n ),
        .clk                ( clk ),

        .skey_valid_s       ( skey_valid_s & ready ),
        .skey               ( skey ),


        .valid_s            ( ls_valid_s ),
        .kin                ( key_out ),
        .din                ( din ),


        .ready_s            ( ls_ready_s ),
        .dout_key1          ( key1 ),
        .key2               ( key2 ),

        .pre_ready_s        (  ),
        .ready              ( ls_ready )
    );


    f1_s_fsm   s(
        .reset_n            ( reset_n ),
        .clk                ( clk ),

        .key_valid_s       ( s_key_valid_s ),
        .key1              ( key1 ),
        .key2              ( key2 ),


        .valid_s            ( s_dat_valid_s ),
        .normal_inverse_n   ( s_normal_inverse_n ),
        .din                ( s_din ),


        .ready_s            ( s_ready_s ),
        .dout               ( s_dout ),
        .pre_ready_s        (  ),
        .ready              (  )
);

    f1_ls_inv    ls_inv(
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .valid_s        ( ls_inv_valid_s ),
        .din            ( ls_inv_din ),

        .ready_s        ( ls_inv_ready_s ),
        .dout           ( key3_4 ),

        .pre_ready_s    (  )
    );



    f1_k_fsm    k(
        .reset_n        ( reset_n ),
        .clk            ( clk ),

        .k1_2_valid_s   ( k_valid_s ),
        .key1           ( key1 ),
        .key2           ( key2 ),

        .k3_4_valid_s   ( ls_inv_ready_s ),
        .key3_4         ( key3_4 ),

        .ready_s        ( k_ready_s ),
        .addr           ( k_addr ),
        .kout           ( key_out )

    );






    localparam  IDLE        = 8'h00,
                KEY         = 8'h01,
                KEY_ENC     = 8'h02,
                KEY_DEC     = 8'h04,
                ENC         = 8'h08,
                DEC1        = 8'h10,
                DEC2        = 8'h20,
                DEC3        = 8'h40,
                DEC4        = 8'h80;
    reg     [8:0]   state = IDLE, state_next;

    always @* begin
        state_next      = state;

        ls_valid_s          = 1'b0;
        s_key_valid_s       = 1'b0;
        s_dat_valid_s       = 1'b0;
        s_normal_inverse_n  = 1'b1;
        ls_inv_valid_s      = 1'b0;
        k_valid_s           = 1'b0;


        ls_inv_din      = s_dout;
        s_din           = din;

        case (state)
            default: begin
                s_key_valid_s       = 1'b0;
                ls_inv_valid_s      = 1'b0;
                s_normal_inverse_n  = 1'b1;
                k_valid_s           = 1'b0;
                ls_inv_din          = s_dout;
                s_din               = din;

                case ( {skey_valid_s, valid_s, encrypt_decrypt_n} )
                    default: begin
                        state_next      = IDLE;
                        ls_valid_s      = 1'b0;
                        s_dat_valid_s   = 1'b0;

                    end
                    3'b100, 3'b101: begin
                        state_next      = KEY;
                        ls_valid_s      = 1'b1;
                        s_dat_valid_s   = 1'b0;
                    end
                    3'b111: begin
                        state_next      = KEY_ENC;
                        ls_valid_s      = 1'b1;
                        s_dat_valid_s   = 1'b0;
                    end
                    3'b110: begin
                        state_next      = KEY_DEC;
                        ls_valid_s      = 1'b1;
                        s_dat_valid_s   = 1'b0;
                    end
                    3'b011: begin
                        state_next      = ENC;
                        ls_valid_s      = 1'b1;
                        s_dat_valid_s   = 1'b0;
                    end
                    3'b010: begin
                        state_next      = DEC1;
                        ls_valid_s      = 1'b0;
                        s_dat_valid_s   = 1'b1;
                    end
                endcase
            end
            KEY: begin
                state_next          = k_ready_s ? IDLE : state;

                ls_valid_s          = 1'b0;
                s_key_valid_s       = ls_ready_s;
                s_dat_valid_s       = 1'b0;
                s_normal_inverse_n  = 1'b1;
                ls_inv_valid_s      = s_ready_s;
                k_valid_s           = ls_ready_s;

                ls_inv_din          = s_dout;
                s_din               = din;
            end
            KEY_ENC: begin
                state_next          = k_ready_s ? ENC : state;

                ls_valid_s          = k_ready_s;
                s_key_valid_s       = ls_ready_s;
                s_dat_valid_s       = 1'b0;
                s_normal_inverse_n  = 1'b1;
                ls_inv_valid_s      = s_ready_s;
                k_valid_s           = ls_ready_s;

                ls_inv_din          = s_dout;
                s_din               = din;
            end
            KEY_DEC: begin
                state_next          = k_ready_s ? DEC1 : state;

                ls_valid_s          = 1'b0;
                s_key_valid_s       = ls_ready_s;
                s_dat_valid_s       = k_ready_s;
                s_normal_inverse_n  = 1'b1;
                ls_inv_valid_s      = s_ready_s;
                k_valid_s           = ls_ready_s;

                ls_inv_din          = s_dout;
                s_din               = din;
            end
            ENC: begin
                state_next          = ls_ready && ls_ready_s ? IDLE : state;

                ls_valid_s          = 1'b0;
                s_key_valid_s       = 1'b0;
                s_dat_valid_s       = 1'b0;
                s_normal_inverse_n  = 1'b1;
                ls_inv_valid_s      = 1'b0;
                k_valid_s           = 1'b0;

                ls_inv_din          = s_dout;
                s_din               = din;
            end

            DEC1: begin
                state_next          = s_ready_s ? DEC2 : state;

                ls_valid_s          = 1'b0;
                s_key_valid_s       = 1'b0;
                s_dat_valid_s       = 1'b0;
                s_normal_inverse_n  = 1'b1;
                ls_inv_valid_s      = s_ready_s;
                k_valid_s           = 1'b0;
                ls_inv_din          = s_dout;
                s_din               = din;
            end


            DEC2: begin
                state_next          = k_addr == 8'd11 && ls_inv_ready_s ? DEC3 : state;

                ls_valid_s          = 1'b0;
                s_key_valid_s       = 1'b0;
                s_dat_valid_s       = k_addr == 8'd11 & ls_inv_ready_s;
                s_normal_inverse_n  = 1'b0;
                ls_inv_valid_s      = k_addr != 8'd11 & ls_inv_ready_s;
                k_valid_s           = 1'b0;
                ls_inv_din          = key3_4 ^ key_out;
                s_din               = key3_4 ^ key_out;
            end
            DEC3: begin
                state_next          = s_ready_s ? IDLE : state;

                ls_valid_s          = 1'b0;
                s_key_valid_s       = 1'b0;
                s_dat_valid_s       = 1'b0;
                s_normal_inverse_n  = 1'b0;
                ls_inv_valid_s      = 1'b0;
                k_valid_s           = 1'b0;
                ls_inv_din          = s_dout;
                s_din               = key3_4 ^ key_out;


            end

        endcase

    end

    always @ (posedge clk, negedge reset_n)
    if (!reset_n) begin
        state           <= IDLE;
        skey_ready_sr   <= 1'b0;
        ready_r         <= 1'b0;
        ready_sr        <= 1'b0;
        dout_r          <= 128'd0;
        k_addr          <= 5'd0;
    end else begin
        state           <= state_next;
        skey_ready_sr   <= 1'b0;
        ready_r         <= 1'b0;
        ready_sr        <= 1'b0;
        case (state)
            IDLE: begin
                ready_r         <= state_next == IDLE;
                k_addr          <= state_next == ENC ? 5'd1 : 5'd0;
            end
            KEY: begin
                ready_r         <= k_ready_s;
                skey_ready_sr   <= k_ready_s;
            end
            KEY_ENC: if(k_ready_s) begin
                skey_ready_sr   <= 1'b1;
                k_addr          <= k_addr + 1'b1;
            end
            KEY_DEC: if(k_ready_s) begin
                skey_ready_sr   <= 1'b1;
            end
            ENC: if (ls_ready_s) begin
                k_addr          <= k_addr + 1'b1;
                if (ls_ready) begin
                    ready_sr        <= 1'b1;
                    ready_r         <= 1'b1;
                    dout_r          <= key1;
                end
            end
            DEC1: begin

                if (ls_inv_ready_s)
                    k_addr  <= k_addr - 1'b1;
                else
                    k_addr  <= 8'd19;
            end
            DEC2: if (ls_inv_ready_s) begin
                k_addr  <= k_addr - 1'b1;
            end
            DEC3: if (s_ready_s) begin
                ready_sr        <= 1'b1;
                ready_r         <= 1'b1;
                dout_r  <= s_dout ^ key_out;

            end


        endcase
    end



    assign skey_ready_s     = skey_ready_sr;
    assign ready            = ready_r;
    assign ready_s          = ready_sr;
    assign dout             = dout_r;

endmodule
