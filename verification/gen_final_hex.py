# gen_final_hex.py
# Generates the final comprehensive SoC test program.

def u_type(opcode, rd, imm):
    return f"{imm:020b}{rd:05b}{opcode:07b}"

def i_type(opcode, rd, funct3, rs1, imm):
    if imm < 0:
        imm = (1 << 12) + imm
    return f"{imm:012b}{rs1:05b}{funct3:03b}{rd:05b}{opcode:07b}"

def s_type(opcode, funct3, rs1, rs2, imm):
    if imm < 0:
        imm = (1 << 12) + imm
    imm_bin = f"{imm:012b}"
    imm_11_5 = imm_bin[0:7]
    imm_4_0 = imm_bin[7:12]
    return f"{imm_11_5}{rs2:05b}{rs1:05b}{funct3:03b}{imm_4_0}{opcode:07b}"

def b_type(opcode, funct3, rs1, rs2, imm):
    if imm < 0:
        imm = (1 << 13) + imm
    imm_bin = f"{imm:013b}"
    imm_12 = imm_bin[0]
    imm_11 = imm_bin[1]
    imm_10_5 = imm_bin[2:8]
    imm_4_1 = imm_bin[8:12]
    return f"{imm_12}{imm_10_5}{rs2:05b}{rs1:05b}{funct3:03b}{imm_4_1}{imm_11}{opcode:07b}"

def assemble():
    instrs = []
    
    # x1  = UART Base (0x20000)
    # x2  = GPIO Base (0x30000)
    # x3  = CNN Base (0x50000)
    # x4  = AES Base (0x60000)
    # x5  = Data SRAM Base (0x10000)
    # x31 = Global Status Word (accumulates pass/fail flags)

    # Init bases
    instrs.append(u_type(0x37, 1, 0x20000))
    instrs.append(u_type(0x37, 2, 0x30000))
    instrs.append(u_type(0x37, 3, 0x50000))
    instrs.append(u_type(0x37, 4, 0x60000))
    instrs.append(u_type(0x37, 5, 0x10000))
    instrs.append(i_type(0x13, 31, 0, 0, 0)) # x31 = 0

    # ==========================
    # 1. GPIO Test
    # ==========================
    # GPIO_DIR (0x08) = 0x0F (lower 4 bits output)
    instrs.append(i_type(0x13, 6, 0, 0, 0x0F))
    instrs.append(s_type(0x23, 2, 2, 6, 0x08))
    # GPIO_OUT (0x00) = 0x0A
    instrs.append(i_type(0x13, 6, 0, 0, 0x0A))
    instrs.append(s_type(0x23, 2, 2, 6, 0x00))
    # Read back GPIO_IN (0x04) -> assume loopback or external wiring makes IN == OUT for lower 4 bits
    # Actually, tb_soc_final will assert this externally, we'll just continue.
    
    # ==========================
    # 2. UART Loopback Test
    # ==========================
    # UART_CTRL (0x0C) = 0x000B (Enable TX/RX, Divisor = 2) -> Div=2, RxE=1, TxE=1 = 2<<2 | 1<<1 | 1 = 8 | 2 | 1 = 0x0B
    instrs.append(i_type(0x13, 6, 0, 0, 0x0B))
    instrs.append(s_type(0x23, 2, 1, 6, 0x0C))
    # UART_TX_DATA (0x00) = 0xA5
    instrs.append(i_type(0x13, 6, 0, 0, 0xA5))
    instrs.append(s_type(0x23, 2, 1, 6, 0x00))
    # Wait for RX Valid: Poll UART_STATUS (0x08) bit 1
    # L1: LW x6, 0x08(x1)
    instrs.append(i_type(0x03, 6, 2, 1, 0x08))
    # ANDI x7, x6, 2
    instrs.append(i_type(0x13, 7, 7, 6, 2))
    # BEQ x7, x0, -8 (L1)
    instrs.append(b_type(0x63, 0, 7, 0, -8))
    # Read UART_RX_DATA (0x04)
    instrs.append(i_type(0x03, 6, 2, 1, 0x04))
    # Store to SRAM[0]
    instrs.append(s_type(0x23, 2, 5, 6, 0x00))

    # ==========================
    # 3. CNN Test (Small computation)
    # ==========================
    # Weights: just set W0 = 1.0 (0x00010000)
    instrs.append(u_type(0x37, 6, 0x00010)) # W0
    instrs.append(s_type(0x23, 2, 3, 6, 0x10))
    instrs.append(i_type(0x13, 6, 0, 0, 0)) # W1..W8
    for off in range(0x14, 0x34, 4):
        instrs.append(s_type(0x23, 2, 3, 6, off))
    # Bias = 2.0 (0x00020000)
    instrs.append(u_type(0x37, 6, 0x00020))
    instrs.append(s_type(0x23, 2, 3, 6, 0x38))
    # Inputs: IN0 = 5.0 (0x00050000)
    instrs.append(u_type(0x37, 6, 0x00050))
    instrs.append(s_type(0x23, 2, 3, 6, 0x40))
    # CFG0: 1x1 input = 0x0001_0001
    instrs.append(u_type(0x37, 6, 0x00010))
    instrs.append(i_type(0x13, 6, 0, 6, 1))
    instrs.append(s_type(0x23, 2, 3, 6, 0x08))
    # CFG1: Mode 0 (Conv)
    instrs.append(i_type(0x13, 6, 0, 0, 0))
    instrs.append(s_type(0x23, 2, 3, 6, 0x0C))
    # Start CNN (CTRL = 1)
    instrs.append(i_type(0x13, 6, 0, 0, 1))
    instrs.append(s_type(0x23, 2, 3, 6, 0x00))
    # Poll CNN Status (0x04) bit 1
    # L2: LW x6, 0x04(x3)
    instrs.append(i_type(0x03, 6, 2, 3, 0x04))
    # ANDI x7, x6, 2
    instrs.append(i_type(0x13, 7, 7, 6, 2))
    # BEQ x7, x0, -8 (L2)
    instrs.append(b_type(0x63, 0, 7, 0, -8))
    # Read CNN OUT0 (0x80)
    instrs.append(i_type(0x03, 6, 2, 3, 0x80))
    # Store to SRAM[1] (Offset 4)
    instrs.append(s_type(0x23, 2, 5, 6, 0x04))

    # ==========================
    # 4. AES Test
    # ==========================
    # Same key and plaintext as before
    # Key: 2b7e1516 28aed2a6 abf71588 09cf4f3c
    instrs.append(u_type(0x37, 6, 0x2b7e1))
    instrs.append(i_type(0x13, 6, 0, 6, 0x516))
    instrs.append(s_type(0x23, 2, 4, 6, 0x10))

    instrs.append(u_type(0x37, 6, 0x28aed))
    instrs.append(i_type(0x13, 6, 0, 6, 0x2a6))
    instrs.append(s_type(0x23, 2, 4, 6, 0x14))

    instrs.append(u_type(0x37, 6, 0xabf71))
    instrs.append(i_type(0x13, 6, 0, 6, 0x588))
    instrs.append(s_type(0x23, 2, 4, 6, 0x18))

    instrs.append(u_type(0x37, 6, 0x09cf5))
    instrs.append(i_type(0x13, 6, 0, 6, -0xc4))
    instrs.append(s_type(0x23, 2, 4, 6, 0x1C))

    # Plaintext: 3243f6a8 885a308d 313198a2 e0370734
    instrs.append(u_type(0x37, 6, 0x3243f))
    instrs.append(i_type(0x13, 6, 0, 6, 0x6a8))
    instrs.append(s_type(0x23, 2, 4, 6, 0x20))

    instrs.append(u_type(0x37, 6, 0x885a3))
    instrs.append(i_type(0x13, 6, 0, 6, 0x08d))
    instrs.append(s_type(0x23, 2, 4, 6, 0x24))

    instrs.append(u_type(0x37, 6, 0x3131a))
    instrs.append(i_type(0x13, 6, 0, 6, -0x75e))
    instrs.append(s_type(0x23, 2, 4, 6, 0x28))

    instrs.append(u_type(0x37, 6, 0xe0370))
    instrs.append(i_type(0x13, 6, 0, 6, 0x734))
    instrs.append(s_type(0x23, 2, 4, 6, 0x2C))

    # Start AES
    instrs.append(i_type(0x13, 6, 0, 0, 1))
    instrs.append(s_type(0x23, 2, 4, 6, 0x00))

    # Poll AES Status (0x04) bit 1
    # L3: LW x6, 0x04(x4)
    instrs.append(i_type(0x03, 6, 2, 4, 0x04))
    # ANDI x7, x6, 2
    instrs.append(i_type(0x13, 7, 7, 6, 2))
    # BEQ x7, x0, -8 (L3)
    instrs.append(b_type(0x63, 0, 7, 0, -8))

    # Read Ciphertext and Store to SRAM[2..5]
    instrs.append(i_type(0x03, 6, 2, 4, 0x30))
    instrs.append(s_type(0x23, 2, 5, 6, 0x08))

    instrs.append(i_type(0x03, 6, 2, 4, 0x34))
    instrs.append(s_type(0x23, 2, 5, 6, 0x0C))

    instrs.append(i_type(0x03, 6, 2, 4, 0x38))
    instrs.append(s_type(0x23, 2, 5, 6, 0x10))

    instrs.append(i_type(0x03, 6, 2, 4, 0x3C))
    instrs.append(s_type(0x23, 2, 5, 6, 0x14))
    
    # Store a magic completion word (0xDEADBEEF) at SRAM[6]
    instrs.append(u_type(0x37, 6, 0xdeadc))
    instrs.append(i_type(0x13, 6, 0, 6, -0x111))
    instrs.append(s_type(0x23, 2, 5, 6, 0x18))

    # Infinite loop
    instrs.append(b_type(0x63, 0, 0, 0, 0))

    hex_lines = []
    for instr in instrs:
        hex_val = hex(int(instr, 2))[2:].zfill(8)
        hex_lines.append(hex_val)
    return hex_lines

if __name__ == "__main__":
    hex_data = assemble()
    with open("final_program.hex", "w") as f:
        for i, h in enumerate(hex_data):
            f.write(f"{h} // {i}\n")
    
    # Fill remaining memory to 1024 words
    with open("final_program.hex", "a") as f:
        for i in range(len(hex_data), 1024):
            f.write("00000000\n")
    
    print("Generated final_program.hex successfully.")
