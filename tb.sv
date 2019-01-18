`timescale 1ns/1ps
`define BYTE [7:0]
`define NUMBER_OF_TESTS 1
module tb;

reg    [0:`NUMBER_OF_TESTS-1][0:19][15:0]`BYTE   IT_KEYS = {
    128'h8899aabbccddeeff0011223344556677,
    128'hfedcba98765432100123456789abcdef,
    128'hdb31485315694343228d6aef8cc78c44,
    128'h3d4553d8e9cfec6815ebadc40a9ffd04,
    128'h57646468c44a5e28d3e59246f429f1ac,
    128'hbd079435165c6432b532e82834da581b,
    128'h51e640757e8745de705727265a0098b1,
    128'h5a7925017b9fdd3ed72a91a22286f984,
    128'hbb44e25378c73123a5f32f73cdb6e517,
    128'h72e9dd7416bcf45b755dbaa88e4a4043,

    128'h8899aabbccddeeff0011223344556677,
    128'h37edf507f2090627477c10b396f35a31,
    128'hd06f4094f860830093d749cd38939216,
    128'he60fce12efb4465985875cbea0201d6e,
    128'h0246e0941e5f725e8f57fa98a85835d7,
    128'hfb6f7bd4f50a029a654c028fda4f03a6,
    128'h413d8ed7755fc2b684ac1d5fed62a238,
    128'h311fd692c433761e785581d108df5ef4,
    128'h69d180f40653b3cc3974647955e68328,
    128'h5a6c415bef3ff261e070f0d7e87f3b02
};

reg     [0:`NUMBER_OF_TESTS-1][15:0]`BYTE    PLAIN_TEXT = {
    128'h1122334455667700ffeeddccbbaa9988
};

reg     [0:`NUMBER_OF_TESTS-1][15:0]`BYTE    CIPHERED_TEXT = {
    128'h7f679d90bebc24305a468d42b9d4edcd
};

reg     [0:`NUMBER_OF_TESTS-1][31:0]`BYTE    SECRET_KEY = {
    256'h8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef
};



function void check_ram_wr(int it, reg[4:0] addr, reg[15:0]`BYTE dat);
    //$display("%d", $time);
    if (IT_KEYS[it][addr] != dat) begin
        $display("ADDR: %0d --FAIL", addr);
        $display("ADDR: %0d", addr);
        $display("DAT : %0h", dat);
        $display("EXP : %0h", IT_KEYS[it][addr]);
        $stop();
    end
endfunction

function void check_ciphered(int it, reg[15:0]`BYTE dat);
    if (CIPHERED_TEXT[it] != dat) begin
        $display("INPUT TEXT: %0h", PLAIN_TEXT[it]);
        $display("DOUT: %0h", dat);
        $display("EXT : %0h", PLAIN_TEXT[it]);
        $stop();

    end
endfunction

function void check_plain_text(int it, reg[15:0]`BYTE dat);
    if (PLAIN_TEXT[it] != dat) begin
        $display("INPUT TEXT: %0h", CIPHERED_TEXT[it]);
        $display("DOUT: %0h", dat);
        $display("EXT : %0h", PLAIN_TEXT[it]);
        $stop();

    end
endfunction


reg     clk, reset_n;
initial begin
    clk = 0;
    #5;
    forever #(10/2) clk = ~clk;
end
initial begin
    reset_n = 0;
    repeat(5) @(posedge clk);
    reset_n = 1;
end


reg                     skey_valid_s, valid_s, encrypt_decrypt_n;
reg     [15:0]`BYTE     din;
reg     [31:0]`BYTE     skey;
integer                 i;

task TEST1;
//
// TEST1: test itaration keys update
//
    valid_s = 0;
    din = 0;
    skey = 0;
    skey_valid_s = 0;
    encrypt_decrypt_n = 0;

    fork

        begin

            for(i = 0; i < `NUMBER_OF_TESTS; i = i + 1) begin
                    @(posedge clk);
                        skey = SECRET_KEY[i];
                        skey_valid_s = 1'b1;
                        encrypt_decrypt_n = 0;
                    @(posedge clk);
                        skey_valid_s = 1'b0;
                    @(posedge uut.ready);

                    // @(posedge clk);
                        skey = SECRET_KEY[i];
                        skey_valid_s = 1'b1;
                        encrypt_decrypt_n = 1;
                    @(posedge clk);
                        skey_valid_s = 1'b0;
                    @(posedge uut.ready);


                end
        end

        forever begin
            @(posedge uut.k.k_we) check_ram_wr(i, uut.k.k_addr, uut.k.k_din);
        end

    join_any
    disable fork;
    $display("TEST1 --PASS");
endtask

task TEST2;
//
// TEST2: key+encrypt, encrypt
//
    valid_s = 0;
    din = 0;
    skey = 0;
    skey_valid_s = 0;
    encrypt_decrypt_n = 0;

    fork
        begin
        // number of input vectors
            for(i = 0; i < `NUMBER_OF_TESTS; i = i + 1) begin
                // number of encrypt variants
                    @(posedge clk);
                        skey = SECRET_KEY[i];
                        skey_valid_s = 1;
                        din = PLAIN_TEXT;
                        valid_s = 1;
                        encrypt_decrypt_n = 1;
                    @(posedge clk);
                        skey_valid_s = 0;
                        valid_s = 0;
                    @(posedge uut.ready);

                    // @(posedge clk);
                        skey = 0;
                        skey_valid_s = 0;
                        din = PLAIN_TEXT;
                        valid_s = 1;
                        encrypt_decrypt_n = 1;
                    @(posedge clk);
                        skey_valid_s = 0;
                        valid_s = 0;
                    @(posedge uut.ready);
            end
        end

        forever begin
            @(posedge uut.k.k_we) check_ram_wr(i, uut.k.k_addr, uut.k.k_din);
        end

        forever begin
            @(posedge uut.ready) check_ciphered(i, uut.dout);
        end

    join_any
    disable fork;
    $display("TEST2 --PASS");
endtask

task TEST3;
//
// TEST3: keys+decrypt, decrypt
//
    valid_s = 0;
    din = 0;
    skey = 0;
    skey_valid_s = 0;
    encrypt_decrypt_n = 0;



    fork
        begin

            for(i = 0; i < `NUMBER_OF_TESTS; i = i + 1) begin

                    @(posedge clk);
                        skey = SECRET_KEY[i];
                        skey_valid_s = 1;
                        valid_s = 1;
                        din = CIPHERED_TEXT;
                        encrypt_decrypt_n = 0;
                    @(posedge clk);
                        skey_valid_s = 0;
                        valid_s = 0;
                    @(posedge uut.ready);


                    // @(posedge clk);
                        skey = 0;
                        skey_valid_s = 0;
                        valid_s = 1;
                        din = CIPHERED_TEXT;
                        encrypt_decrypt_n = 0;
                    @(posedge clk);
                        skey_valid_s = 0;
                        valid_s = 0;
                    @(posedge uut.ready);
            end
        end

        forever begin
            @(posedge uut.k.k_we) check_ram_wr(i, uut.k.k_addr, uut.k.k_din);
        end

        forever begin
            @(posedge uut.ready) check_plain_text(i, uut.dout);
        end

    join_any
    disable fork;
    $display("TEST3 --PASS");
endtask


int test_num = 0;
initial begin: TESTS

    @(posedge reset_n);

    test_num = 1;
    TEST1();

    test_num = 2;
    TEST2();

    test_num = 3;
    TEST3();

end




    f1_kuznyechik   uut(
        .reset_n            ( reset_n ),
        .clk                ( clk ),

        .ready              ( ready ),

        .skey_valid_s       ( skey_valid_s ),
        .skey               ( skey ),
        .skey_ready_s       (  ),

        .encrypt_decrypt_n  ( encrypt_decrypt_n ),
        .valid_s            ( valid_s ),
        .din                ( din ),

        .ready_s            (  ),
        .dout               (  )

    );

endmodule
