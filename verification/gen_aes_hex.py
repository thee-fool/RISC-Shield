# gen_aes_hex.py
# Generates a hex file for the instruction memory to test the AES-128 Engine

def u_type(opcode, rd, imm):
    # imm is 20 bits
    return f"{imm:020b}{rd:05b}{opcode:07b}"

def i_type(opcode, rd, funct3, rs1, imm):
    # imm is 12 bits, handle negative
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
    # imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode
    imm_12 = imm_bin[0]
    imm_11 = imm_bin[1]
    imm_10_5 = imm_bin[2:8]
    imm_4_1 = imm_bin[8:12]
    return f"{imm_12}{imm_10_5}{rs2:05b}{rs1:05b}{funct3:03b}{imm_4_1}{imm_11}{opcode:07b}"

def assemble():
    instrs = []
    
    # Register mapping:
    # x0 = zero
    # x1 = AES Base Address (0x6000_0000)
    # x2 = Data memory base (0x1000_0000)
    
    # 0: LUI x1, 0x60000
    instrs.append(u_type(0x37, 1, 0x60000))
    # 1: LUI x2, 0x10000
    instrs.append(u_type(0x37, 2, 0x10000))
    
    # Load Key: 2b7e1516
    instrs.append(u_type(0x37, 3, 0x2b7e1))
    instrs.append(i_type(0x13, 3, 0, 3, 0x516))
    
    # Load Key: 28aed2a6
    instrs.append(u_type(0x37, 4, 0x28aed))
    instrs.append(i_type(0x13, 4, 0, 4, 0x2a6))
    
    # Load Key: abf71588
    instrs.append(u_type(0x37, 5, 0xabf71))
    instrs.append(i_type(0x13, 5, 0, 5, 0x588))
    
    # Load Key: 09cf4f3c
    instrs.append(u_type(0x37, 6, 0x09cf5))
    instrs.append(i_type(0x13, 6, 0, 6, -0xc4))
    
    # Store Key
    instrs.append(s_type(0x23, 2, 1, 3, 0x10))
    instrs.append(s_type(0x23, 2, 1, 4, 0x14))
    instrs.append(s_type(0x23, 2, 1, 5, 0x18))
    instrs.append(s_type(0x23, 2, 1, 6, 0x1C))
    
    # Load Plaintext: 3243f6a8
    instrs.append(u_type(0x37, 7, 0x3243f))
    instrs.append(i_type(0x13, 7, 0, 7, 0x6a8))
    
    # Load Plaintext: 885a308d
    instrs.append(u_type(0x37, 8, 0x885a3))
    instrs.append(i_type(0x13, 8, 0, 8, 0x08d))
    
    # Load Plaintext: 313198a2
    instrs.append(u_type(0x37, 9, 0x3131a))
    instrs.append(i_type(0x13, 9, 0, 9, -0x75e))
    
    # Load Plaintext: e0370734
    instrs.append(u_type(0x37, 10, 0xe0370))
    instrs.append(i_type(0x13, 10, 0, 10, 0x734))
    
    # Store Plaintext
    instrs.append(s_type(0x23, 2, 1, 7, 0x20))
    instrs.append(s_type(0x23, 2, 1, 8, 0x24))
    instrs.append(s_type(0x23, 2, 1, 9, 0x28))
    instrs.append(s_type(0x23, 2, 1, 10, 0x2C))
    
    # Start AES
    instrs.append(i_type(0x13, 11, 0, 0, 1))
    instrs.append(s_type(0x23, 2, 1, 11, 0x00))
    
    # Polling Loop
    # 26: LW x12, 0x04(x1)
    instrs.append(i_type(0x03, 12, 2, 1, 0x04))
    # 27: ANDI x12, x12, 2
    instrs.append(i_type(0x13, 12, 7, 12, 2))
    # 28: BEQ x12, x0, -8
    instrs.append(b_type(0x63, 0, 12, 0, -8))
    
    # Read Ciphertext
    instrs.append(i_type(0x03, 3, 2, 1, 0x30))
    instrs.append(i_type(0x03, 4, 2, 1, 0x34))
    instrs.append(i_type(0x03, 5, 2, 1, 0x38))
    instrs.append(i_type(0x03, 6, 2, 1, 0x3C))
    
    # Store to SRAM
    instrs.append(s_type(0x23, 2, 2, 3, 0x00))
    instrs.append(s_type(0x23, 2, 2, 4, 0x04))
    instrs.append(s_type(0x23, 2, 2, 5, 0x08))
    instrs.append(s_type(0x23, 2, 2, 6, 0x0C))
    
    # Infinite Loop (PC = 37 * 4 = 148 = 0x94)
    instrs.append(b_type(0x63, 0, 0, 0, 0))
    
    hex_lines = []
    for instr in instrs:
        hex_val = hex(int(instr, 2))[2:].zfill(8)
        hex_lines.append(hex_val)
    return hex_lines

if __name__ == "__main__":
    hex_data = assemble()
    with open("aes_program.hex", "w") as f:
        for i, h in enumerate(hex_data):
            f.write(f"{h} // {i}\n")
    
    # Fill remaining memory to 1024 words
    with open("aes_program.hex", "a") as f:
        for i in range(len(hex_data), 1024):
            f.write("00000000\n")
    
    print("Generated aes_program.hex successfully.")
