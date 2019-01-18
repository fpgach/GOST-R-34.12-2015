`define BYTE [7:0]

module f1_k_fsm(
    input                   reset_n,
    input                   clk,

    input                   k1_2_valid_s,
    input   [15:0]`BYTE     key1,
    input   [15:0]`BYTE     key2,

    input                   k3_4_valid_s,
    input   [15:0]`BYTE     key3_4,


    output                  ready_s,
    input   [4:0]           addr,
    output  [15:0]`BYTE     kout

);

    reg                     ready_sr = 1'b0;
    reg                     k_we;
    reg     [4:0]           cnt;
    reg     [4:0]           k_addr;
    reg     [15:0]`BYTE     k_din;
    wire    [15:0]`BYTE     kout_w;
    reg     [15:0]`BYTE     kout_r = 128'd0;

    dpram #(.LOG2_L(5)) k_inst(
        .clk            ( clk ),

        .we             ( k_we ),
        .d_a            ( k_addr ),
        .d              ( k_din ),

        .q_a            ( addr ),
        .q              ( kout_w )
    );

    localparam  K1          = 8'h00,
                K1_IDLE     = 8'h01,
                K11         = 8'h02,
                K11_IDLE    = 8'h04,
                K2          = 8'h08,
                K2_IDLE     = 8'h10,
                K12         = 8'h20,
                K12_IDLE    = 8'h40,
                K_LAST      = 8'h80;
    reg     [7:0]   state = K1, state_next;

    always @* begin
        state_next  = state;
        k_we        = 1'b0;
        k_din       = key1;
        k_addr      = cnt;
        case (state)
            default: begin
                case ( {k1_2_valid_s, k3_4_valid_s} )
                    default: begin
                        state_next  = K1;
                        k_we        = 1'b0;
                        k_din       = key1;
                        k_addr      = cnt;
                    end
                    2'b10: begin
                        state_next  = K1_IDLE;
                        k_we        = 1'b1;
                        k_din       = key1;
                        k_addr      = cnt;
                    end
                endcase
            end
            K1_IDLE: begin
                state_next  = K11;
                k_we        = 1'b0;
                k_din       = key1;
                k_addr      = cnt;
            end
            K11: begin
                state_next  = k3_4_valid_s ? K11_IDLE : state;
                k_we        = k3_4_valid_s;
                k_din       = k_addr == 5'd0 ? key1 : key3_4;
                k_addr      = cnt + 5'd10;
            end
            K11_IDLE: begin
                state_next  = K2;
                k_we        = 1'b0;
                k_din       = k_addr == 5'd0 ? key1 : key3_4;
                k_addr      = cnt + 5'd10;
            end
            K2: begin
                state_next  = K2_IDLE;
                k_we        = 1'b1;
                k_din       = key2;
                k_addr      = cnt;
            end
            K2_IDLE: begin
                state_next  = K12;
                k_we        = 1'b0;
                k_din       = key2;
            end
            K12: begin
                state_next  = k3_4_valid_s ? K12_IDLE : state;
                k_we        = k3_4_valid_s;
                k_din       = key3_4;
                k_addr      = cnt + 5'd10;
            end
            K12_IDLE: begin
                state_next  = cnt == 5'd9 ? K_LAST : K1;
                k_we        = 1'b0;
                k_din       = key3_4;
                k_addr      = cnt + 5'd10;
            end


        endcase
    end

    always @ (posedge clk, negedge reset_n)
    if (!reset_n) begin
        state       <= K1;
        cnt         <= 5'd0;
        ready_sr    <= 1'b0;
        kout_r      <= 128'd0;
    end else begin
        state       <= state_next;
        kout_r      <= kout_w;
        ready_sr    <= 1'b0;
        case (state)
            default: begin end

            K11_IDLE, K12_IDLE: begin
                    cnt <= cnt + 1'b1;
            end
            K_LAST: begin
                cnt         <= 5'd0;
                ready_sr    <= 1'b1;
            end
        endcase
    end

    assign  ready_s  = ready_sr;
    assign  kout = kout_r;

endmodule
