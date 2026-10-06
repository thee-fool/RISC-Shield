`timescale 1ns/1ps

module tb_aes ();

    reg clk;
    reg rst_n;
    
    reg  [31:0] bus_addr;
    reg  [31:0] bus_wdata;
    reg         bus_wen;
    reg         bus_valid;
    
    wire [31:0] bus_rdata;
    wire        bus_ready;

    // Instantiate AES-128 Engine
    aes_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata),
        .bus_wen(bus_wen),
        .bus_valid(bus_valid),
        .bus_rdata(bus_rdata),
        .bus_ready(bus_ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task for bus write
    task bus_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            #1; // Delay to avoid race conditions
            bus_addr = addr;
            bus_wdata = data;
            bus_wen = 1'b1;
            bus_valid = 1'b1;
            
            // Wait for ready
            @(posedge clk);
            while (!bus_ready) @(posedge clk);
            
            #1;
            bus_valid = 1'b0;
            bus_wen = 1'b0;
        end
    endtask

    // Task for bus read
    task bus_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            #1;
            bus_addr = addr;
            bus_wen = 1'b0;
            bus_valid = 1'b1;
            
            // Wait for ready
            @(posedge clk);
            while (!bus_ready) @(posedge clk);
            
            data = bus_rdata;
            #1;
            bus_valid = 1'b0;
        end
    endtask

    reg [31:0] read_val;
    reg [127:0] cipher_result;

    initial begin
        $dumpfile("waveforms/tb_aes.vcd");
        $dumpvars(0, tb_aes);

        // Initialize
        clk = 0;
        rst_n = 0;
        bus_addr = 0;
        bus_wdata = 0;
        bus_wen = 0;
        bus_valid = 0;

        #20;
        rst_n = 1;
        #20;

        // Test Vector 1 (FIPS 197 Appendix B)
        // Plaintext: 32 43 f6 a8 88 5a 30 8d 31 31 98 a2 e0 37 07 34
        // Key:       2b 7e 15 16 28 ae d2 a6 ab f7 15 88 09 cf 4f 3c
        // Expected Ciphertext: 39 25 84 1d 02 dc 09 fb dc 11 85 97 19 6a 0b 32

        // Write Key (AES_KEY[0..3] at 0x10..0x1C)
        $display("Writing Key...");
        bus_write(32'h6000_0010, 32'h2b7e1516);
        bus_write(32'h6000_0014, 32'h28aed2a6);
        bus_write(32'h6000_0018, 32'habf71588);
        bus_write(32'h6000_001C, 32'h09cf4f3c);

        // Write Plaintext (AES_PLAIN[0..3] at 0x20..0x2C)
        $display("Writing Plaintext...");
        bus_write(32'h6000_0020, 32'h3243f6a8);
        bus_write(32'h6000_0024, 32'h885a308d);
        bus_write(32'h6000_0028, 32'h313198a2);
        bus_write(32'h6000_002C, 32'he0370734);

        // Start AES (AES_CTRL at 0x00)
        $display("Starting AES...");
        bus_write(32'h6000_0000, 32'h0000_0001);

        // Poll Status (AES_STATUS at 0x04)
        $display("Polling Status...");
        read_val = 0;
        while ((read_val & 32'h0000_0002) == 0) begin
            bus_read(32'h6000_0004, read_val);
            $display("Read Status: %h", read_val);
            #10;
        end

        // Read Ciphertext (AES_CIPHER[0..3] at 0x30..0x3C)
        bus_read(32'h6000_0030, read_val); cipher_result[127:96] = read_val;
        bus_read(32'h6000_0034, read_val); cipher_result[95:64] = read_val;
        bus_read(32'h6000_0038, read_val); cipher_result[63:32] = read_val;
        bus_read(32'h6000_003C, read_val); cipher_result[31:0] = read_val;

        $display("Expected: 3925841d02dc09fbdc118597196a0b32");
        $display("Actual:   %h", cipher_result);

        if (cipher_result == 128'h3925841d02dc09fbdc118597196a0b32) begin
            $display("PASS: AES-128 Encryption successful!");
        end else begin
            $display("FAIL: AES-128 Encryption failed!");
        end

        #100;
        $finish;
    end

    // Timeout
    initial begin
        #50000;
        $display("FAIL: Timeout");
        $finish;
    end

endmodule
