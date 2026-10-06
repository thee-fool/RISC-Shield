import sys

def emit_lui(rd, imm):
    return f"{((imm & 0xFFFFF) << 12) | (rd << 7) | 0x37:08x}"

def emit_addi(rd, rs1, imm):
    return f"{((imm & 0xFFF) << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x13:08x}"

def emit_sw(rs2, rs1, imm):
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F
    return f"{(imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12) | (imm_4_0 << 7) | 0x23:08x}"

def emit_lw(rd, rs1, imm):
    return f"{((imm & 0xFFF) << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x03:08x}"

def emit_beq(rs1, rs2, imm):
    imm_12 = (imm >> 12) & 0x1
    imm_11 = (imm >> 11) & 0x1
    imm_10_5 = (imm >> 5) & 0x3F
    imm_4_1 = (imm >> 1) & 0xF
    return f"{(imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (0 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | 0x63:08x}"

def emit_andi(rd, rs1, imm):
    return f"{((imm & 0xFFF) << 20) | (rs1 << 15) | (7 << 12) | (rd << 7) | 0x13:08x}"

instructions = [
    emit_lw(1, 0, 136),      # lw x1, 136(x0) -> 0x50000000
    emit_lw(2, 0, 140),      # lw x2, 140(x0) -> 0x00010000
]
for i in range(9):
    instructions.append(emit_sw(2, 1, 0x14 + i*4)) # sw x2, offset(x1)

for i in range(16):
    instructions.append(emit_sw(2, 1, 0x40 + i*4)) # sw x2, offset(x1)

instructions.append(emit_addi(3, 0, 1))          # x3 = 1
instructions.append(emit_sw(3, 1, 0))            # sw x3, 0(x1) -> start CNN

instructions.append(emit_lw(4, 1, 4))            # loop: lw x4, 4(x1)
instructions.append(emit_andi(4, 4, 2))          # andi x4, x4, 2
instructions.append(emit_beq(4, 0, -8 & 0x1FFE)) # beq x4, x0, loop (-8 offset)

instructions.append(emit_lw(5, 1, 0x80))         # lw x5, 0x80(x1) -> result
instructions.append(emit_beq(0, 0, 0))           # done: beq x0, x0, done

# Pad to 32 instructions (128 bytes)
while len(instructions) < 32:
    instructions.append("00000000")

# Add constants
instructions.append("50000000") # offset 128
instructions.append("00010000") # offset 132

with open("test_cnn.hex", "w") as f:
    for instr in instructions:
        f.write(instr + "\n")
