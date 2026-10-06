# RISC-Shield SoC — RISC-V Edge AI + Crypto System-on-Chip

![Language](https://img.shields.io/badge/HDL-Verilog--2005-blue)
![ISA](https://img.shields.io/badge/ISA-RV32I-orange)
![Simulator](https://img.shields.io/badge/sim-Icarus%20Verilog-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

**RISC-Shield** is a small System-on-Chip written in Verilog. It puts a custom single-cycle RISC-V CPU, standard peripherals, a CNN inference accelerator, and an AES-128 encryption engine on one memory-mapped bus. The CPU controls every block by reading and writing fixed addresses, the same way commercial edge-AI and IoT microcontrollers work.



---

## Block Diagram

```text
                    ┌──────────────────────────────┐
                    │      RV32I CPU (single-cycle) │
                    └───────────────┬──────────────┘
                                    │  valid / ready bus
                    ┌───────────────┴──────────────┐
                    │  Bus Decoder  (addr[31:28])   │
                    └─┬─────┬─────┬─────┬─────┬────┬┘
                      │     │     │     │     │    │
                   IMEM  DMEM  UART  GPIO  TIMER  CNN   AES-128
                   16KB  16KB                    accel  engine
```

## Features

| Block | Highlights |
|---|---|
| **RV32I CPU** | Single-cycle, 32-bit, full base integer ISA (R/I/S/B/U/J formats) |
| **Interconnect** | Simple valid/ready handshake bus, upper-nibble address decoding |
| **CNN Accelerator** | 4×4 MAC array, 3×3 convolution, ReLU, 2×2 max-pool, Q16.16 fixed point |
| **AES-128 Engine** | Iterative 10-round encryption, on-the-fly key expansion, verified against FIPS-197 |
| **UART** | Configurable baud rate, 16× oversampled receiver, loopback-tested |
| **GPIO** | 8 bidirectional pins with 2-stage input synchronizers |
| **Timer** | 32-bit up-counter with compare match and auto-reload |

## Memory Map

| Region | Base | End | Description |
|---|---|---|---|
| Instruction Memory | `0x0000_0000` | `0x0000_3FFF` | 16 KB program memory |
| Data SRAM | `0x1000_0000` | `0x1000_3FFF` | 16 KB read/write data |
| UART | `0x2000_0000` | `0x2000_000F` | Control, status, TX/RX data |
| GPIO | `0x3000_0000` | `0x3000_000B` | Direction, input, output |
| Timer | `0x4000_0000` | `0x4000_000F` | Counter, compare, control |
| CNN Accelerator | `0x5000_0000` | `0x5000_00FF` | Control, weights, bias, data |
| AES-128 Engine | `0x6000_0000` | `0x6000_003F` | Control, key, plaintext, ciphertext |

Full register-level details: [`docs/memory_map.md`](docs/memory_map.md).

## Repository Layout

```text
RISC-Shield-SoC/
├── rtl/
│   ├── top/            # soc_top.v, bus_decoder.v
│   ├── cpu/            # RV32I datapath, ALU, control unit, register file, ...
│   ├── memory/         # Data SRAM
│   ├── peripherals/    # uart/, gpio/, timer/
│   └── accelerators/   # cnn/, aes/
├── verification/       # Testbenches, Python hex generators, test programs
└── docs/               # Architecture, CPU, bus, memory map, peripherals, CNN, AES
```

## Getting Started

**Requirements:** [Icarus Verilog](https://steveicarus.github.io/iverilog/) and Python 3. GTKWave is optional, for viewing waveforms.

Run the full-system integration test:

```bash
cd verification
python gen_final_hex.py
iverilog -o tb_soc_final.vvp \
  ../rtl/top/*.v ../rtl/cpu/*.v ../rtl/memory/*.v \
  ../rtl/peripherals/uart/*.v ../rtl/peripherals/gpio/*.v ../rtl/peripherals/timer/*.v \
  ../rtl/accelerators/cnn/*.v ../rtl/accelerators/aes/*.v \
  tb_soc_final.v
vvp tb_soc_final.vvp
```

Expected output:

```text
========================================
FINAL SoC INTEGRATION TEST RESULTS
========================================
PASS: GPIO Configuration (OE=0x0F, OUT=0x0A)
PASS: UART Loopback (Data=0xA5)
PASS: CNN Inference (Output=7.0)
PASS: AES-128 Encryption (Output matches FIPS 197)
========================================
TEST COMPLETED.
```

### Other testbenches

| Testbench | What it checks |
|---|---|
| `tb_alu.v`, `tb_register_file.v` | CPU building blocks |
| `tb_cpu.v` | CPU executing a test program |
| `tb_aes.v` / `tb_soc_aes.v` | AES engine standalone / driven by the CPU |
| `tb_cnn.v` / `tb_soc_cnn.v` | CNN accelerator standalone / driven by the CPU |
| `tb_soc_peripherals.v` | UART, GPIO, and Timer through the bus |
| `tb_soc_top.v`, `tb_soc_final.v` | Full-SoC integration |

## Roadmap

- [x] RV32I single-cycle CPU
- [x] Memory-mapped bus and data SRAM
- [x] UART, GPIO, Timer
- [x] AES-128 encryption engine
- [x] CNN inference accelerator
- [x] Full SoC integration and verification
- [ ] FPGA synthesis and on-board demo
- [ ] AES decryption mode
- [ ] Interrupt controller wired to the CPU
- [ ] Pipelined (5-stage) CPU variant

## Documentation

- [Architecture overview](docs/architecture.md)
- [CPU](docs/cpu.md) · [Bus](docs/bus.md) · [Memory map](docs/memory_map.md)
- [Peripherals](docs/peripherals.md) · [CNN accelerator](docs/cnn_accelerator.md) · [AES-128](docs/aes128.md)



## License

MIT. See [LICENSE](LICENSE).
