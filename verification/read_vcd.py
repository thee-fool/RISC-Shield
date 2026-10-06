import sys

def parse_vcd(filename):
    with open(filename, 'r') as f:
        for _ in range(50000): # Just scan the first 50k lines
            line = f.readline()
            if not line:
                break
            if 'registers[1]' in line or 'x1' in line:
                print(line.strip())

if __name__ == '__main__':
    parse_vcd('waveforms/tb_soc_aes.vcd')
