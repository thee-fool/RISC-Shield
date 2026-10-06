# RISC-Shield SoC — Memory Map & Register Reference

> **Document Revision:** 1.0  
> **Date:** 2026-07-11  
> **Status:** Milestone 1 — Architecture Specification  
> **Applies to:** RISC-Shield RISC-V Edge AI Accelerator SoC

---

## Table of Contents

1. [Overview](#1-overview)  
2. [Global Address Map](#2-global-address-map)  
3. [Address Decoding](#3-address-decoding)  
4. [Bus Protocol](#4-bus-protocol)  
5. [Memory Regions](#5-memory-regions)  
   - 5.1 [Instruction Memory (IMEM)](#51-instruction-memory-imem)  
   - 5.2 [Data SRAM (DMEM)](#52-data-sram-dmem)  
6. [Peripheral Register Maps](#6-peripheral-register-maps)  
   - 6.1 [UART](#61-uart-base-0x2000_0000)  
   - 6.2 [GPIO](#62-gpio-base-0x3000_0000)  
   - 6.3 [Timer](#63-timer-base-0x4000_0000)  
   - 6.4 [CNN Accelerator](#64-cnn-accelerator-base-0x5000_0000)  
   - 6.5 [AES-128 Engine](#65-aes-128-engine-base-0x6000_0000)  
7. [Access Rules & Constraints](#7-access-rules--constraints)  
8. [Revision History](#8-revision-history)  

---

## 1. Overview

The RISC-Shield SoC employs a **flat, memory-mapped I/O** architecture. All peripherals, accelerators, and memory regions are accessed through a unified 32-bit address space. The CPU — a single-issue, in-order RV32I core — issues load/store transactions over a shared internal bus, and a centralized address decoder routes each transaction to the appropriate slave device.

**Key Characteristics:**

| Parameter | Value |
|---|---|
| Address Width | 32 bits |
| Data Width | 32 bits |
| Byte Addressability | Word-aligned only (4-byte boundaries) |
| Endianness | Little-endian |
| Number of Memory Regions | 2 (IMEM, DMEM) |
| Number of Peripherals | 5 (UART, GPIO, Timer, CNN, AES) |
| Bus Topology | Single-master, multi-slave, shared bus |

---

## 2. Global Address Map

The 32-bit address space is partitioned into seven non-overlapping regions. Each region is assigned to the upper nibble of the address (`addr[31:28]`), providing up to 256 MB per region, of which only a small portion is utilized.

| Region | Base Address | End Address | Size | Nibble (`addr[31:28]`) | Description |
|:---|:---|:---|---:|:---:|:---|
| Instruction Memory | `0x0000_0000` | `0x0000_3FFF` | 16 KB | `0x0` | Read-only instruction storage (IMEM) |
| Data SRAM | `0x1000_0000` | `0x1000_3FFF` | 16 KB | `0x1` | Read/write data memory (DMEM) |
| UART | `0x2000_0000` | `0x2000_000F` | 16 B | `0x2` | UART peripheral registers |
| GPIO | `0x3000_0000` | `0x3000_000B` | 12 B | `0x3` | GPIO peripheral registers |
| Timer | `0x4000_0000` | `0x4000_000F` | 16 B | `0x4` | Timer peripheral registers |
| CNN Accelerator | `0x5000_0000` | `0x5000_00FF` | 256 B | `0x5` | CNN accelerator control & data registers |
| AES-128 Engine | `0x6000_0000` | `0x6000_003F` | 64 B | `0x6` | AES-128 encryption engine registers |
| *Reserved* | `0x7000_0000` | `0xFFFF_FFFF` | — | `0x7`–`0xF` | *Unmapped — access causes bus error* |

> [!IMPORTANT]
> Any access to an address outside the defined regions (nibbles `0x7` through `0xF`) will result in an **undefined bus response**. The bus decoder will not assert a `ready` signal, and the CPU pipeline will stall indefinitely. Software must never access reserved regions.

**Visual Address Space Layout:**

```
0xFFFF_FFFF ┌──────────────────────────────────────┐
            │                                      │
            │           RESERVED / UNMAPPED         │
            │                                      │
0x7000_0000 ├──────────────────────────────────────┤
            │  (unused)                            │
0x6000_003F ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
            │  AES-128 Engine  (64 B)              │
0x6000_0000 ├──────────────────────────────────────┤
            │  (unused)                            │
0x5000_00FF ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
            │  CNN Accelerator (256 B)             │
0x5000_0000 ├──────────────────────────────────────┤
            │  (unused)                            │
0x4000_000F ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
            │  Timer           (16 B)              │
0x4000_0000 ├──────────────────────────────────────┤
            │  (unused)                            │
0x3000_000B ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
            │  GPIO            (12 B)              │
0x3000_0000 ├──────────────────────────────────────┤
            │  (unused)                            │
0x2000_000F ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
            │  UART            (16 B)              │
0x2000_0000 ├──────────────────────────────────────┤
            │  (unused)                            │
0x1000_3FFF ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
            │  Data SRAM       (16 KB)             │
0x1000_0000 ├──────────────────────────────────────┤
            │  (unused)                            │
0x0000_3FFF ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
            │  Instruction Mem (16 KB)             │
0x0000_0000 └──────────────────────────────────────┘
```

---

## 3. Address Decoding

### 3.1 Region Selection Logic

The address decoder uses **`addr[31:28]`** (the upper nibble) as the primary region selector. This provides a simple, fixed-priority decode with zero wait states on the decode path.

```
Region Select = addr[31:28]

  0x0  →  Instruction Memory (IMEM)
  0x1  →  Data SRAM          (DMEM)
  0x2  →  UART
  0x3  →  GPIO
  0x4  →  Timer
  0x5  →  CNN Accelerator
  0x6  →  AES-128 Engine
  0x7–0xF → Bus Error (no slave selected)
```

### 3.2 Slave Address Generation

Once a region is selected, the remaining address bits are forwarded to the selected slave as a **local offset**:

| Region | Local Offset Bits Used | Offset Range |
|:---|:---:|:---|
| IMEM | `addr[13:0]` | 14 bits → 16,384 bytes (4,096 words) |
| DMEM | `addr[13:0]` | 14 bits → 16,384 bytes (4,096 words) |
| UART | `addr[3:0]` | 4 bits → 16 bytes (4 registers) |
| GPIO | `addr[3:0]` | 4 bits → 12 bytes (3 registers) |
| Timer | `addr[3:0]` | 4 bits → 16 bytes (4 registers) |
| CNN Accelerator | `addr[7:0]` | 8 bits → 256 bytes (64 registers) |
| AES-128 Engine | `addr[5:0]` | 6 bits → 64 bytes (16 registers) |

### 3.3 Decode Logic (RTL Pseudocode)

```verilog
// Address Decoder — combinational logic
always_comb begin
    // Default: no slave selected
    imem_sel = 1'b0;
    dmem_sel = 1'b0;
    uart_sel = 1'b0;
    gpio_sel = 1'b0;
    timer_sel = 1'b0;
    cnn_sel  = 1'b0;
    aes_sel  = 1'b0;

    case (addr[31:28])
        4'h0: imem_sel  = 1'b1;
        4'h1: dmem_sel  = 1'b1;
        4'h2: uart_sel  = 1'b1;
        4'h3: gpio_sel  = 1'b1;
        4'h4: timer_sel = 1'b1;
        4'h5: cnn_sel   = 1'b1;
        4'h6: aes_sel   = 1'b1;
        default: /* bus_error = 1'b1; */;
    endcase
end
```

---

## 4. Bus Protocol

### 4.1 Signal List

The RISC-Shield SoC uses a **simple valid/ready handshake** bus protocol. All signals are active-high and synchronous to the rising edge of `clk`.

| Signal | Width | Direction | Description |
|:---|:---:|:---|:---|
| `clk` | 1 | Global | System clock |
| `rst_n` | 1 | Global | Active-low synchronous reset |
| `bus_addr` | 32 | Master → Slave | Byte address (must be 4-byte aligned) |
| `bus_wdata` | 32 | Master → Slave | Write data |
| `bus_rdata` | 32 | Slave → Master | Read data |
| `bus_wen` | 1 | Master → Slave | Write enable: `1` = write, `0` = read |
| `bus_valid` | 1 | Master → Slave | Transaction request: master asserts to initiate a transfer |
| `bus_ready` | 1 | Slave → Master | Transaction acknowledge: slave asserts when transfer completes |

### 4.2 Transfer Timing

A transfer completes on the clock edge where **both `bus_valid` and `bus_ready` are asserted simultaneously** (handshake).

**Read Transaction:**

```
        ┌───┐   ┌───┐   ┌───┐   ┌───┐
  clk   ┘   └───┘   └───┘   └───┘   └───
             ╔═══════════╗
  valid ─────╢           ╠───────────────
             ╚═══════════╝
                         ╔═══════╗
  ready ─────────────────╢       ╠───────
                         ╚═══════╝
             ╔═══════════════════╗
  addr  ═════╢  VALID ADDRESS   ╠═══════
             ╚═══════════════════╝
  wen   ─────────── 0 ──────────────────
                         ╔═══════╗
  rdata ═════════════════╢ DATA  ╠═══════
                         ╚═══════╝
                         ▲
                    Handshake: data captured
```

**Write Transaction:**

```
        ┌───┐   ┌───┐   ┌───┐   ┌───┐
  clk   ┘   └───┘   └───┘   └───┘   └───
             ╔═══════════╗
  valid ─────╢           ╠───────────────
             ╚═══════════╝
             ╔═══════════╗
  ready ─────╢           ╠───────────────
             ╚═══════════╝
             ╔═══════════╗
  addr  ═════╢  VALID ADDR  ╠═══════════
             ╚═══════════╝
             ╔═══════════╗
  wdata ═════╢  VALID DATA  ╠═══════════
             ╚═══════════╝
  wen   ─────────── 1 ──────────────────
             ▲
        Handshake: data written
```

### 4.3 Protocol Rules

1. **Master** asserts `bus_valid` along with `bus_addr`, `bus_wdata` (for writes), and `bus_wen`. These signals must remain stable until `bus_ready` is asserted.
2. **Slave** asserts `bus_ready` when it can complete the transaction. For reads, `bus_rdata` must be valid on the same cycle as `bus_ready`.
3. A transfer completes on the rising clock edge where `bus_valid && bus_ready` is true.
4. After completion, `bus_valid` may de-assert or immediately re-assert for a back-to-back transfer.
5. Memory slaves (IMEM, DMEM) respond with **single-cycle latency** (`bus_ready` asserted in the same cycle or next cycle).
6. Peripheral slaves may insert **wait states** by delaying `bus_ready`. The CNN accelerator, for example, may hold `bus_ready` low while a convolution is in progress and a read to `CNN_OUTPUT` is attempted before `CNN_STATUS.done` is set.

---

## 5. Memory Regions

### 5.1 Instruction Memory (IMEM)

| Parameter | Value |
|:---|:---|
| Base Address | `0x0000_0000` |
| End Address | `0x0000_3FFF` |
| Size | 16 KB (4,096 × 32-bit words) |
| Access | **Read-only** from CPU bus |
| Implementation | Single-port ROM or preloaded SRAM |
| Latency | 1 cycle |

- IMEM stores the program binary. It is loaded at synthesis/simulation time (e.g., via `$readmemh` in testbenches or ROM initialization in synthesis).
- The CPU instruction fetch unit reads from this region using the Program Counter (PC).
- **Write accesses to IMEM will be silently ignored** (no bus error, `bus_ready` still asserted, data discarded).
- Address bits `[1:0]` are ignored; all accesses are word-aligned (4-byte aligned).

### 5.2 Data SRAM (DMEM)

| Parameter | Value |
|:---|:---|
| Base Address | `0x1000_0000` |
| End Address | `0x1000_3FFF` |
| Size | 16 KB (4,096 × 32-bit words) |
| Access | **Read/Write** |
| Implementation | Single-port synchronous SRAM |
| Latency | 1 cycle |

- DMEM is used for the program stack, heap, and global/static variables.
- Supports both load (read) and store (write) operations.
- All contents are initialized to `0x0000_0000` on reset.
- Address bits `[1:0]` are ignored; all accesses are word-aligned.

---

## 6. Peripheral Register Maps

### 6.1 UART (Base: `0x2000_0000`)

The UART provides a minimal asynchronous serial interface for debug output and host communication.

#### 6.1.1 Register Summary

| Offset | Address | Name | Access | Width | Reset Value | Description |
|:---:|:---|:---|:---:|:---:|:---:|:---|
| `0x00` | `0x2000_0000` | `UART_TX_DATA` | **W** | 8 bits | `0x00` | Transmit data register |
| `0x04` | `0x2000_0004` | `UART_RX_DATA` | **R** | 8 bits | `0x00` | Receive data register |
| `0x08` | `0x2000_0008` | `UART_STATUS` | **R** | 4 bits | `0x08` | Status register |
| `0x0C` | `0x2000_000C` | `UART_CTRL` | **R/W** | 16 bits | `0x0000` | Control register |

#### 6.1.2 UART_TX_DATA — Transmit Data Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `tx_data` | [7:0] | **W** | `0x00` | Byte to transmit. Writing this register pushes the byte into the TX shift register and initiates serial transmission. |
| *Reserved* | [31:8] | — | `0x000000` | Reserved. Writes are ignored. |

> [!NOTE]
> **Write-only register.** Reading `UART_TX_DATA` returns `0x0000_0000`. Software must check `UART_STATUS.tx_busy` before writing to ensure the transmitter is idle. Writing while `tx_busy == 1` will overwrite the pending byte (undefined behavior).

#### 6.1.3 UART_RX_DATA — Receive Data Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `rx_data` | [7:0] | **R** | `0x00` | Last received byte. Valid only when `UART_STATUS.rx_valid == 1`. Reading this register clears the `rx_valid` flag. |
| *Reserved* | [31:8] | — | `0x000000` | Reserved. Reads return 0. |

> [!NOTE]
> Reading `UART_RX_DATA` has a **side effect**: it clears the `rx_valid` bit in `UART_STATUS`. Software should read the status register first to confirm data availability, then read this register exactly once.

#### 6.1.4 UART_STATUS — Status Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `tx_busy` | [0] | **R** | `0` | `1` = Transmitter is currently sending a byte. `0` = Transmitter is idle and ready to accept new data. |
| `rx_valid` | [1] | **R** | `0` | `1` = A new byte has been received and is available in `UART_RX_DATA`. `0` = No new data available. Cleared when `UART_RX_DATA` is read. |
| `tx_fifo_full` | [2] | **R** | `0` | `1` = TX FIFO is full (if FIFO is implemented; otherwise mirrors `tx_busy`). `0` = TX FIFO has space. |
| `rx_fifo_empty` | [3] | **R** | `1` | `1` = RX FIFO is empty (no data to read). `0` = RX FIFO contains data. |
| *Reserved* | [31:4] | — | `0x0000000` | Reserved. Reads return 0. |

> [!TIP]
> **Typical polling loop for transmit:** Check `tx_busy == 0` (or `tx_fifo_full == 0`) before writing `UART_TX_DATA`.  
> **Typical polling loop for receive:** Check `rx_valid == 1` (or `rx_fifo_empty == 0`) before reading `UART_RX_DATA`.

#### 6.1.5 UART_CTRL — Control Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `tx_en` | [0] | **R/W** | `0` | Transmit enable. `1` = TX path is active. `0` = TX path is disabled (held in idle state). |
| `rx_en` | [1] | **R/W** | `0` | Receive enable. `1` = RX path is active and sampling the serial input. `0` = RX path is disabled. |
| `baud_div` | [15:2] | **R/W** | `0x0000` | Baud rate divisor. The baud rate is derived as: `baud_rate = clk_freq / (baud_div + 1)`. For example, with a 50 MHz clock and `baud_div = 433` (`0x01B1`), the baud rate is ≈ 115200. |
| *Reserved* | [31:16] | — | `0x0000` | Reserved. Writes are ignored; reads return 0. |

**Baud Rate Examples** (assuming 50 MHz system clock):

| Desired Baud Rate | `baud_div` Value | Actual Baud Rate | Error |
|---:|---:|---:|---:|
| 9,600 | 5207 (`0x1457`) | 9,600.6 | +0.006% |
| 19,200 | 2603 (`0x0A2B`) | 19,201.2 | +0.006% |
| 115,200 | 433 (`0x01B1`) | 115,207.4 | +0.006% |
| 921,600 | 53 (`0x0035`) | 925,925.9 | +0.47% |

---

### 6.2 GPIO (Base: `0x3000_0000`)

The GPIO module provides 8 general-purpose digital I/O pins, each independently configurable as input or output.

#### 6.2.1 Register Summary

| Offset | Address | Name | Access | Width | Reset Value | Description |
|:---:|:---|:---|:---:|:---:|:---:|:---|
| `0x00` | `0x3000_0000` | `GPIO_OUT` | **R/W** | 8 bits | `0x00` | Output data register |
| `0x04` | `0x3000_0004` | `GPIO_IN` | **R** | 8 bits | `0x00` | Input data register |
| `0x08` | `0x3000_0008` | `GPIO_DIR` | **R/W** | 8 bits | `0x00` | Direction control register |

#### 6.2.2 GPIO_OUT — Output Data Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `out[7:0]` | [7:0] | **R/W** | `0x00` | Output value for each GPIO pin. Bit *n* drives pin *n* when `GPIO_DIR[n] == 1` (configured as output). When a pin is configured as input (`GPIO_DIR[n] == 0`), the corresponding `out` bit is retained but has no effect on the physical pin. |
| *Reserved* | [31:8] | — | `0x000000` | Reserved. Writes are ignored; reads return 0. |

#### 6.2.3 GPIO_IN — Input Data Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `in[7:0]` | [7:0] | **R** | `0x00` | Sampled value of each GPIO pin. Bit *n* reflects the current logic level on pin *n*, regardless of the direction setting. This is a **live sample** — no latching or buffering. |
| *Reserved* | [31:8] | — | `0x000000` | Reserved. Reads return 0. |

> [!NOTE]
> `GPIO_IN` reflects the instantaneous pin state. For pins configured as outputs, reading `GPIO_IN[n]` returns the actual driven value (useful for verifying output state). Inputs are **not** synchronized — if metastability is a concern, software should read the register twice.

#### 6.2.4 GPIO_DIR — Direction Control Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `dir[7:0]` | [7:0] | **R/W** | `0x00` | Direction control for each GPIO pin. Bit *n*: `1` = **output** (pin driven by `GPIO_OUT[n]`), `0` = **input** (pin is high-impedance, value readable via `GPIO_IN[n]`). |
| *Reserved* | [31:8] | — | `0x000000` | Reserved. Writes are ignored; reads return 0. |

> [!IMPORTANT]
> On reset, all GPIO pins default to **input mode** (`GPIO_DIR = 0x00`). This prevents unintended driving of external circuitry during startup.

---

### 6.3 Timer (Base: `0x4000_0000`)

A 32-bit free-running timer with compare-match capability and optional auto-reload for periodic interrupts.

#### 6.3.1 Register Summary

| Offset | Address | Name | Access | Width | Reset Value | Description |
|:---:|:---|:---|:---:|:---:|:---:|:---|
| `0x00` | `0x4000_0000` | `TIMER_COUNT` | **R/W** | 32 bits | `0x0000_0000` | Current counter value |
| `0x04` | `0x4000_0004` | `TIMER_CMP` | **R/W** | 32 bits | `0x0000_0000` | Compare value |
| `0x08` | `0x4000_0008` | `TIMER_CTRL` | **R/W** | 3 bits | `0x0` | Control register |
| `0x0C` | `0x4000_000C` | `TIMER_STATUS` | **R/W1C** | 1 bit | `0x0` | Status/flag register |

#### 6.3.2 TIMER_COUNT — Counter Value Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `count` | [31:0] | **R/W** | `0x0000_0000` | Current 32-bit counter value. The counter increments by 1 on every rising clock edge when `TIMER_CTRL.enable == 1`. Writing to this register sets the counter to the written value immediately. |

**Behavior:**
- When `enable == 1`, the counter increments every clock cycle: `count <= count + 1`.
- When `count == cmp`, the `TIMER_STATUS.match` flag is set to `1`.
- If `auto_reload == 1` and a match occurs, the counter is reset to `0x0000_0000` on the next clock edge.
- If `auto_reload == 0` and a match occurs, the counter continues to increment (free-running mode).
- Counter wraps from `0xFFFF_FFFF` to `0x0000_0000` naturally (unsigned 32-bit overflow).

#### 6.3.3 TIMER_CMP — Compare Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `cmp` | [31:0] | **R/W** | `0x0000_0000` | 32-bit compare value. When `TIMER_COUNT == TIMER_CMP`, the `match` flag in `TIMER_STATUS` is set. If interrupts are enabled, an interrupt request is also generated. |

> [!WARNING]
> Setting `TIMER_CMP` to `0x0000_0000` while the counter is at zero will immediately trigger a match. Ensure the compare value is set to a meaningful period before enabling the timer.

#### 6.3.4 TIMER_CTRL — Control Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `enable` | [0] | **R/W** | `0` | Timer enable. `1` = counter increments on every clock edge. `0` = counter is frozen (holds its current value). |
| `auto_reload` | [1] | **R/W** | `0` | Auto-reload mode. `1` = counter resets to `0` on compare match (periodic mode). `0` = counter continues incrementing past the match point (one-shot / free-running mode). |
| `irq_en` | [2] | **R/W** | `0` | Interrupt enable. `1` = a compare match generates an interrupt request to the CPU. `0` = no interrupt is generated (flag is still set in `TIMER_STATUS`). |
| *Reserved* | [31:3] | — | `0x00000000` | Reserved. Writes are ignored; reads return 0. |

#### 6.3.5 TIMER_STATUS — Status Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `match` | [0] | **R/W1C** | `0` | Compare match flag. Set to `1` by hardware when `TIMER_COUNT == TIMER_CMP`. Cleared by **writing `1`** to this bit (Write-1-to-Clear). Writing `0` has no effect. This flag remains set until explicitly cleared by software. |
| *Reserved* | [31:1] | — | `0x00000000` | Reserved. Reads return 0; writes are ignored. |

> [!NOTE]
> **R/W1C (Read / Write-1-to-Clear):** To clear the `match` flag, software writes `0x0000_0001` to `TIMER_STATUS`. The hardware interprets the `1` in bit [0] as a clear command. Writing `0x0000_0000` leaves the flag unchanged.

**Typical Timer Setup Sequence:**

```
1. Write TIMER_CMP   ← desired period (e.g., clock_freq / desired_freq)
2. Write TIMER_COUNT ← 0x0000_0000  (start from zero)
3. Write TIMER_CTRL  ← 0x0000_0007  (enable + auto_reload + irq_en)
4. (On interrupt)  Write TIMER_STATUS ← 0x0000_0001  (clear match flag)
```

---

### 6.4 CNN Accelerator (Base: `0x5000_0000`)

A lightweight convolutional neural network accelerator supporting 3×3 convolution and pooling operations on small feature maps. Designed for tinyML inference at the edge.

#### 6.4.1 Register Summary

| Offset | Address | Name | Access | Width | Reset Value | Description |
|:---:|:---|:---|:---:|:---:|:---:|:---|
| `0x00` | `0x5000_0000` | `CNN_CTRL` | R/W | 2 bits | `0x0` | Control register |
| `0x04` | `0x5000_0004` | `CNN_STATUS` | R | 2 bits | `0x0` | Status register |
| `0x08` | `0x5000_0008` | `CNN_CFG0` | R/W | 32 bits | `0x0000_0000` | Input dimension config |
| `0x0C` | `0x5000_000C` | `CNN_CFG1` | R/W | 32 bits | `0x0000_0000` | Operation config |
| `0x10`–`0x34` | `0x5000_0010`–`0x5000_0034` | `CNN_WEIGHT[0..8]` | R/W | 32 bits | `0x0000_0000` | Kernel weight registers |
| `0x38` | `0x5000_0038` | `CNN_BIAS` | R/W | 32 bits | `0x0000_0000` | Bias register |
| `0x40`–`0x7C` | `0x5000_0040`–`0x5000_007C` | `CNN_INPUT[0..15]` | R/W | 32 bits | `0x0000_0000` | Input data registers |
| `0x80`–`0xBC` | `0x5000_0080`–`0x5000_00BC` | `CNN_OUTPUT[0..15]` | R | 32 bits | `0x0000_0000` | Output data registers |
| `0xC0` | `0x5000_00C0` | `CNN_INPUT_LEN` | R/W | 32 bits | `0x0000_0000` | Input word count |
| `0xC4` | `0x5000_00C4` | `CNN_OUTPUT_LEN` | R | 32 bits | `0x0000_0000` | Output word count |

#### 6.4.2 CNN_CTRL — Control Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `start` | [0] | **R/W** | `0` | Write `1` to begin computation. This bit is **auto-clearing** — hardware resets it to `0` after the operation starts. Reading returns `0` unless the start is still being registered. |
| `soft_reset` | [1] | **R/W** | `0` | Write `1` to reset the CNN accelerator to its idle state. Clears all internal state, including output registers. Auto-clearing. |
| *Reserved* | [31:2] | — | `0x00000000` | Reserved. |

> [!WARNING]
> Do **not** assert `start` while `CNN_STATUS.busy == 1`. Starting a new operation before the previous one completes produces undefined results. Always poll `CNN_STATUS.done` or wait for `busy == 0` before issuing a new `start`.

#### 6.4.3 CNN_STATUS — Status Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `busy` | [0] | **R** | `0` | `1` = Accelerator is actively processing. `0` = Idle. |
| `done` | [1] | **R** | `0` | `1` = Last operation completed successfully. Results are available in `CNN_OUTPUT[]`. Cleared when a new `start` is issued or `soft_reset` is asserted. |
| *Reserved* | [31:2] | — | `0x00000000` | Reserved. Reads return 0. |

**State Transitions:**

```
                  start=1                     computation
    IDLE ──────────────────► BUSY ──────────────────────► DONE
  (busy=0, done=0)        (busy=1, done=0)           (busy=0, done=1)
      ▲                                                   │
      │                  soft_reset=1                      │
      └────────────────────────────────────────────────────┘
                          or new start=1
```

#### 6.4.4 CNN_CFG0 — Input Dimension Configuration

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `input_width` | [15:0] | **R/W** | `0x0000` | Width of the input feature map in pixels/elements. Valid range: 1–65535. |
| `input_height` | [31:16] | **R/W** | `0x0000` | Height of the input feature map in pixels/elements. Valid range: 1–65535. |

> [!NOTE]
> For this initial implementation targeting tinyML, practical input dimensions are expected to be small (e.g., 4×4, 8×8). The 16-bit fields provide headroom for future expansion.

#### 6.4.5 CNN_CFG1 — Operation Configuration

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `stride` | [7:0] | **R/W** | `0x00` | Convolution/pooling stride. A value of `0` is treated as stride = 1. |
| `padding` | [15:8] | **R/W** | `0x00` | Number of zero-padding pixels added around the input. `0` = no padding (valid convolution). |
| *Reserved* | [23:16] | — | `0x00` | Reserved for future use. |
| `mode` | [31:24] | **R/W** | `0x00` | Operation mode. `0x00` = 3×3 Convolution, `0x01` = Max Pooling, `0x02`–`0xFF` = Reserved. |

#### 6.4.6 CNN_WEIGHT[0..8] — Kernel Weight Registers

| Register | Offset | Address | Access | Reset | Description |
|:---|:---:|:---|:---:|:---:|:---|
| `CNN_WEIGHT[0]` | `0x10` | `0x5000_0010` | R/W | `0x0000_0000` | Kernel position [0,0] (top-left) |
| `CNN_WEIGHT[1]` | `0x14` | `0x5000_0014` | R/W | `0x0000_0000` | Kernel position [0,1] (top-center) |
| `CNN_WEIGHT[2]` | `0x18` | `0x5000_0018` | R/W | `0x0000_0000` | Kernel position [0,2] (top-right) |
| `CNN_WEIGHT[3]` | `0x1C` | `0x5000_001C` | R/W | `0x0000_0000` | Kernel position [1,0] (middle-left) |
| `CNN_WEIGHT[4]` | `0x20` | `0x5000_0020` | R/W | `0x0000_0000` | Kernel position [1,1] (center) |
| `CNN_WEIGHT[5]` | `0x24` | `0x5000_0024` | R/W | `0x0000_0000` | Kernel position [1,2] (middle-right) |
| `CNN_WEIGHT[6]` | `0x28` | `0x5000_0028` | R/W | `0x0000_0000` | Kernel position [2,0] (bottom-left) |
| `CNN_WEIGHT[7]` | `0x2C` | `0x5000_002C` | R/W | `0x0000_0000` | Kernel position [2,1] (bottom-center) |
| `CNN_WEIGHT[8]` | `0x30` | `0x5000_0030` | R/W | `0x0000_0000` | Kernel position [2,2] (bottom-right) |

**Kernel Layout:**

```
┌─────────────┬─────────────┬─────────────┐
│ WEIGHT[0]   │ WEIGHT[1]   │ WEIGHT[2]   │
│ [0,0]       │ [0,1]       │ [0,2]       │
├─────────────┼─────────────┼─────────────┤
│ WEIGHT[3]   │ WEIGHT[4]   │ WEIGHT[5]   │
│ [1,0]       │ [1,1]       │ [1,2]       │
├─────────────┼─────────────┼─────────────┤
│ WEIGHT[6]   │ WEIGHT[7]   │ WEIGHT[8]   │
│ [2,0]       │ [2,1]       │ [2,2]       │
└─────────────┴─────────────┴─────────────┘
```

Each weight register holds a 32-bit value, interpreted as either:
- **Fixed-point Q16.16** (16 integer bits, 16 fractional bits), or
- **Packed INT8** (four 8-bit signed integers per word) depending on the accelerator's compile-time configuration.

#### 6.4.7 CNN_BIAS — Bias Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `bias` | [31:0] | **R/W** | `0x0000_0000` | Bias value added to the convolution result after the sum-of-products. Same numeric format as the weight registers (Q16.16 or INT8). |

#### 6.4.8 CNN_INPUT[0..15] — Input Feature Map Data

| Register | Offset | Address | Access | Reset |
|:---|:---:|:---|:---:|:---:|
| `CNN_INPUT[0]` | `0x40` | `0x5000_0040` | R/W | `0x0000_0000` |
| `CNN_INPUT[1]` | `0x44` | `0x5000_0044` | R/W | `0x0000_0000` |
| `CNN_INPUT[2]` | `0x48` | `0x5000_0048` | R/W | `0x0000_0000` |
| `CNN_INPUT[3]` | `0x4C` | `0x5000_004C` | R/W | `0x0000_0000` |
| `CNN_INPUT[4]` | `0x50` | `0x5000_0050` | R/W | `0x0000_0000` |
| `CNN_INPUT[5]` | `0x54` | `0x5000_0054` | R/W | `0x0000_0000` |
| `CNN_INPUT[6]` | `0x58` | `0x5000_0058` | R/W | `0x0000_0000` |
| `CNN_INPUT[7]` | `0x5C` | `0x5000_005C` | R/W | `0x0000_0000` |
| `CNN_INPUT[8]` | `0x60` | `0x5000_0060` | R/W | `0x0000_0000` |
| `CNN_INPUT[9]` | `0x64` | `0x5000_0064` | R/W | `0x0000_0000` |
| `CNN_INPUT[10]` | `0x68` | `0x5000_0068` | R/W | `0x0000_0000` |
| `CNN_INPUT[11]` | `0x6C` | `0x5000_006C` | R/W | `0x0000_0000` |
| `CNN_INPUT[12]` | `0x70` | `0x5000_0070` | R/W | `0x0000_0000` |
| `CNN_INPUT[13]` | `0x74` | `0x5000_0074` | R/W | `0x0000_0000` |
| `CNN_INPUT[14]` | `0x78` | `0x5000_0078` | R/W | `0x0000_0000` |
| `CNN_INPUT[15]` | `0x7C` | `0x5000_007C` | R/W | `0x0000_0000` |

Software loads the input feature map tile into these registers before asserting `CNN_CTRL.start`. The number of valid words must be written to `CNN_INPUT_LEN`.

#### 6.4.9 CNN_OUTPUT[0..15] — Output Feature Map Results

| Register | Offset | Address | Access | Reset |
|:---|:---:|:---|:---:|:---:|
| `CNN_OUTPUT[0]` | `0x80` | `0x5000_0080` | R | `0x0000_0000` |
| `CNN_OUTPUT[1]` | `0x84` | `0x5000_0084` | R | `0x0000_0000` |
| `CNN_OUTPUT[2]` | `0x88` | `0x5000_0088` | R | `0x0000_0000` |
| `CNN_OUTPUT[3]` | `0x8C` | `0x5000_008C` | R | `0x0000_0000` |
| `CNN_OUTPUT[4]` | `0x90` | `0x5000_0090` | R | `0x0000_0000` |
| `CNN_OUTPUT[5]` | `0x94` | `0x5000_0094` | R | `0x0000_0000` |
| `CNN_OUTPUT[6]` | `0x98` | `0x5000_0098` | R | `0x0000_0000` |
| `CNN_OUTPUT[7]` | `0x9C` | `0x5000_009C` | R | `0x0000_0000` |
| `CNN_OUTPUT[8]` | `0xA0` | `0x5000_00A0` | R | `0x0000_0000` |
| `CNN_OUTPUT[9]` | `0xA4` | `0x5000_00A4` | R | `0x0000_0000` |
| `CNN_OUTPUT[10]` | `0xA8` | `0x5000_00A8` | R | `0x0000_0000` |
| `CNN_OUTPUT[11]` | `0xAC` | `0x5000_00AC` | R | `0x0000_0000` |
| `CNN_OUTPUT[12]` | `0xB0` | `0x5000_00B0` | R | `0x0000_0000` |
| `CNN_OUTPUT[13]` | `0xB4` | `0x5000_00B4` | R | `0x0000_0000` |
| `CNN_OUTPUT[14]` | `0xB8` | `0x5000_00B8` | R | `0x0000_0000` |
| `CNN_OUTPUT[15]` | `0xBC` | `0x5000_00BC` | R | `0x0000_0000` |

> [!IMPORTANT]
> Output registers are **read-only**. They contain valid data only when `CNN_STATUS.done == 1`. Reading before completion returns stale or intermediate data. The number of valid output words is reported in `CNN_OUTPUT_LEN`.

#### 6.4.10 CNN_INPUT_LEN — Input Word Count

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `input_len` | [31:0] | **R/W** | `0x0000_0000` | Number of valid 32-bit words loaded into the `CNN_INPUT[]` register array (range: 0–16). |

#### 6.4.11 CNN_OUTPUT_LEN — Output Word Count

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `output_len` | [31:0] | **R** | `0x0000_0000` | Number of valid 32-bit words produced in the `CNN_OUTPUT[]` register array. Set by hardware upon operation completion. |

**Typical CNN Operation Sequence:**

```
1. Write CNN_CFG0      ← input dimensions (e.g., 4x4 = 0x0004_0004)
2. Write CNN_CFG1      ← stride=1, padding=0, mode=conv (0x0000_0001)
3. Write CNN_WEIGHT[0..8] ← 3x3 kernel coefficients
4. Write CNN_BIAS      ← bias value
5. Write CNN_INPUT[0..N] ← input feature map tile
6. Write CNN_INPUT_LEN ← number of valid input words
7. Write CNN_CTRL      ← 0x0000_0001 (start)
8. Poll  CNN_STATUS    until done == 1
9. Read  CNN_OUTPUT_LEN ← number of output words
10.Read  CNN_OUTPUT[0..M] ← results
```

---

### 6.5 AES-128 Engine (Base: `0x6000_0000`)

A hardware AES-128 encryption engine implementing the NIST FIPS-197 standard. Encrypts a single 128-bit plaintext block using a 128-bit key.

#### 6.5.1 Register Summary

| Offset | Address | Name | Access | Width | Reset Value | Description |
|:---:|:---|:---|:---:|:---:|:---:|:---|
| `0x00` | `0x6000_0000` | `AES_CTRL` | R/W | 2 bits | `0x0` | Control register |
| `0x04` | `0x6000_0004` | `AES_STATUS` | R | 2 bits | `0x0` | Status register |
| `0x08` | `0x6000_0008` | — | — | — | — | *Reserved* |
| `0x0C` | `0x6000_000C` | — | — | — | — | *Reserved* |
| `0x10` | `0x6000_0010` | `AES_KEY[0]` | R/W | 32 bits | `0x0000_0000` | Key word 0 (MSB) |
| `0x14` | `0x6000_0014` | `AES_KEY[1]` | R/W | 32 bits | `0x0000_0000` | Key word 1 |
| `0x18` | `0x6000_0018` | `AES_KEY[2]` | R/W | 32 bits | `0x0000_0000` | Key word 2 |
| `0x1C` | `0x6000_001C` | `AES_KEY[3]` | R/W | 32 bits | `0x0000_0000` | Key word 3 (LSB) |
| `0x20` | `0x6000_0020` | `AES_PLAIN[0]` | R/W | 32 bits | `0x0000_0000` | Plaintext word 0 (MSB) |
| `0x24` | `0x6000_0024` | `AES_PLAIN[1]` | R/W | 32 bits | `0x0000_0000` | Plaintext word 1 |
| `0x28` | `0x6000_0028` | `AES_PLAIN[2]` | R/W | 32 bits | `0x0000_0000` | Plaintext word 2 |
| `0x2C` | `0x6000_002C` | `AES_PLAIN[3]` | R/W | 32 bits | `0x0000_0000` | Plaintext word 3 (LSB) |
| `0x30` | `0x6000_0030` | `AES_CIPHER[0]` | R | 32 bits | `0x0000_0000` | Ciphertext word 0 (MSB) |
| `0x34` | `0x6000_0034` | `AES_CIPHER[1]` | R | 32 bits | `0x0000_0000` | Ciphertext word 1 |
| `0x38` | `0x6000_0038` | `AES_CIPHER[2]` | R | 32 bits | `0x0000_0000` | Ciphertext word 2 |
| `0x3C` | `0x6000_003C` | `AES_CIPHER[3]` | R | 32 bits | `0x0000_0000` | Ciphertext word 3 (LSB) |

#### 6.5.2 AES_CTRL — Control Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `start` | [0] | **R/W** | `0` | Write `1` to begin AES-128 encryption. Auto-clearing — hardware resets to `0` after the encryption pipeline is initiated. The key and plaintext registers must be fully loaded before asserting start. |
| `soft_reset` | [1] | **R/W** | `0` | Write `1` to reset the AES engine. Clears all internal round state and the ciphertext output registers. Auto-clearing. |
| *Reserved* | [31:2] | — | `0x00000000` | Reserved. |

#### 6.5.3 AES_STATUS — Status Register

| Field | Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---|
| `busy` | [0] | **R** | `0` | `1` = Encryption is in progress (AES rounds are executing). `0` = Engine is idle. |
| `done` | [1] | **R** | `0` | `1` = Encryption completed. Ciphertext is valid in `AES_CIPHER[0..3]`. Cleared when a new `start` is issued or `soft_reset` is asserted. |
| *Reserved* | [31:2] | — | `0x00000000` | Reserved. Reads return 0. |

**State Transitions:**

```
                  start=1                    10 AES rounds
    IDLE ──────────────────► BUSY ──────────────────────────► DONE
  (busy=0, done=0)        (busy=1, done=0)               (busy=0, done=1)
      ▲                                                       │
      │                  soft_reset=1                          │
      └────────────────────────────────────────────────────────┘
                           or new start=1
```

#### 6.5.4 AES_KEY[0..3] — Encryption Key Registers

The 128-bit encryption key is loaded across four 32-bit registers in **big-endian word order** (`KEY[0]` holds the most significant 32 bits).

| Register | Offset | Key Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---:|:---|
| `AES_KEY[0]` | `0x10` | [127:96] | R/W | `0x0000_0000` | Key MSB (bits 127–96) |
| `AES_KEY[1]` | `0x14` | [95:64] | R/W | `0x0000_0000` | Key bits 95–64 |
| `AES_KEY[2]` | `0x18` | [63:32] | R/W | `0x0000_0000` | Key bits 63–32 |
| `AES_KEY[3]` | `0x1C` | [31:0] | R/W | `0x0000_0000` | Key LSB (bits 31–0) |

**Example:** To load the key `0x2B7E1516_28AED2A6_ABF71588_09CF4F3C`:

```
Write 0x6000_0010 ← 0x2B7E1516   // AES_KEY[0] — MSB
Write 0x6000_0014 ← 0x28AED2A6   // AES_KEY[1]
Write 0x6000_0018 ← 0xABF71588   // AES_KEY[2]
Write 0x6000_001C ← 0x09CF4F3C   // AES_KEY[3] — LSB
```

> [!CAUTION]
> **Security Note:** The key registers are readable via the bus. In a production design, key registers should be made write-only or protected by access control logic to prevent key leakage through software reads. The current design prioritizes debug visibility over security.

#### 6.5.5 AES_PLAIN[0..3] — Plaintext Input Registers

The 128-bit plaintext block is loaded across four 32-bit registers in **big-endian word order**.

| Register | Offset | Plaintext Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---:|:---|
| `AES_PLAIN[0]` | `0x20` | [127:96] | R/W | `0x0000_0000` | Plaintext MSB (bits 127–96) |
| `AES_PLAIN[1]` | `0x24` | [95:64] | R/W | `0x0000_0000` | Plaintext bits 95–64 |
| `AES_PLAIN[2]` | `0x28` | [63:32] | R/W | `0x0000_0000` | Plaintext bits 63–32 |
| `AES_PLAIN[3]` | `0x2C` | [31:0] | R/W | `0x0000_0000` | Plaintext LSB (bits 31–0) |

#### 6.5.6 AES_CIPHER[0..3] — Ciphertext Output Registers

The 128-bit ciphertext result is available across four 32-bit registers in **big-endian word order** after encryption completes.

| Register | Offset | Ciphertext Bits | Access | Reset | Description |
|:---|:---:|:---:|:---:|:---:|:---|
| `AES_CIPHER[0]` | `0x30` | [127:96] | R | `0x0000_0000` | Ciphertext MSB (bits 127–96) |
| `AES_CIPHER[1]` | `0x34` | [95:64] | R | `0x0000_0000` | Ciphertext bits 95–64 |
| `AES_CIPHER[2]` | `0x38` | [63:32] | R | `0x0000_0000` | Ciphertext bits 63–32 |
| `AES_CIPHER[3]` | `0x3C` | [31:0] | R | `0x0000_0000` | Ciphertext LSB (bits 31–0) |

> [!IMPORTANT]
> Ciphertext registers are **read-only** and contain valid data only when `AES_STATUS.done == 1`. Reading before completion returns intermediate round data or stale values.

**Typical AES Encryption Sequence:**

```
1. Write AES_KEY[0..3]    ← 128-bit encryption key
2. Write AES_PLAIN[0..3]  ← 128-bit plaintext block
3. Write AES_CTRL         ← 0x0000_0001  (start)
4. Poll  AES_STATUS       until done == 1
5. Read  AES_CIPHER[0..3] ← 128-bit ciphertext result
```

**NIST Test Vector Verification:**

| Parameter | Value |
|:---|:---|
| Key | `0x2B7E1516_28AED2A6_ABF71588_09CF4F3C` |
| Plaintext | `0x3243F6A8_885A308D_313198A2_E0370734` |
| Expected Ciphertext | `0x3925841D_02DC09FB_DC118597_196A0B32` |

---

## 7. Access Rules & Constraints

### 7.1 Alignment Requirements

| Rule | Details |
|:---|:---|
| **Word-aligned access only** | All bus transactions must be to addresses that are **4-byte aligned** (i.e., `addr[1:0] == 2'b00`). |
| **No sub-word access** | Byte and half-word loads/stores are not supported by the bus. The CPU's `LB`, `LH`, `SB`, `SH` instructions must be implemented via read-modify-write sequences in software or hardware byte-lane logic (not included in this initial design). |
| **Misaligned penalty** | Accesses to non-aligned addresses (where `addr[1:0] != 00`) produce **undefined behavior**. The address decoder ignores `addr[1:0]`, effectively rounding down to the nearest word boundary. |

### 7.2 Read/Write Access Enforcement

| Access Type | Behavior on Violation |
|:---|:---|
| **Read-only** register written | Write is silently ignored. `bus_ready` is still asserted. No bus error. |
| **Write-only** register read | Returns `0x0000_0000`. `bus_ready` is still asserted. |
| Access to **reserved** offset within a valid peripheral | Returns `0x0000_0000` on read; write is silently ignored. |
| Access to **unmapped** region (`addr[31:28]` = `0x7`–`0xF`) | No slave responds. `bus_ready` is never asserted. CPU stalls. |

### 7.3 Reset Behavior

| Item | Details |
|:---|:---|
| Reset signal | `rst_n` — active-low, synchronous |
| Reset duration | Minimum 1 clock cycle |
| Register reset values | All registers reset to `0x0000_0000` (see individual register tables for exceptions, e.g., `UART_STATUS` resets with `rx_fifo_empty = 1`) |
| Memory reset | DMEM contents are cleared to `0x0000_0000`. IMEM retains its preloaded program. |
| Peripheral state | All peripherals return to idle state. Ongoing UART transmissions are aborted. Timer counter resets to zero. CNN and AES operations are terminated. |

### 7.4 Concurrent Access

| Scenario | Behavior |
|:---|:---|
| CPU fetch + data access | The CPU uses a **Harvard architecture** internally: instruction fetches go to IMEM, data loads/stores go through the data bus. There is no bus contention between fetch and data. |
| Multiple peripheral access | Only one data bus transaction can be active at a time (single-master bus). No arbitration is needed. |

---

## 8. Revision History

| Rev | Date | Author | Description |
|:---:|:---|:---|:---|
| 1.0 | 2026-07-11 | Dhruv Singla | Initial release — Milestone 1 Architecture Specification |
| 1.1 | 2026-10-06 | Aditya Patel | Rebranded as RISC-Shield SoC; documentation updates |

---

*This document is part of the RISC-Shield RISC-V Edge AI Accelerator SoC project. All register definitions are authoritative for RTL implementation.*
