import sys

def parse_vcd(filename):
    with open(filename, 'r') as f:
        # Search for the variable ID of registers[1] and registers[3]
        lines = f.readlines()
        
    for i, line in enumerate(lines[:1000]):
        if 'registers' in line or 'x1' in line or 'x3' in line:
            print(line.strip())

if __name__ == '__main__':
    parse_vcd('waveforms/tb_soc_aes.vcd')
