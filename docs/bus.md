# Memory-Mapped Bus Architecture

## Overview

The RISC-Shield SoC uses a custom, lightweight memory-mapped bus interconnect to connect the
RV32I CPU (single bus master) to all peripheral slaves. The bus is intentionally simple —
no AXI, no Wishbone — designed for clarity, minimal gate count, and ease of verification.

The bus uses a **single-master, multiple-slave** topology with centralized address decoding.

---

## Bus Topology

```
                        ┌─────────────────┐
                        │   RV32I CPU     │
                        │   (Master)      │
                        └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    │   Memory-Mapped Bus     │
                    │   (Address Decoder +    │
                    │    Mux/Demux)           │
                    └────────────┬────────────┘
                                 │
          ┌──────────┬───────────┼───────────┬──────────┬──────────┐
          │          │           │           │          │          │
     ┌────┴────┐┌────┴────┐┌────┴────┐┌────┴────┐┌────┴────┐┌────┴────┐
     │  IMEM   ││  SRAM   ││  UART   ││  GPIO   ││  Timer  ││  CNN    │
     │ Slave 0 ││ Slave 1 ││ Slave 2 ││ Slave 3 ││ Slave 4 ││ Slave 5 │
     └─────────┘└─────────┘└─────────┘└─────────┘└─────────┘└────┬────┘
                                                                  │
                                                             ┌────┴────┐
                                                             │  AES    │
                                                             │ Slave 6 │
                                                             └─────────┘
```

---

## Bus Signals

### Master Interface (CPU Side)

| Signal       | Direction   | Width  | Description                                    |
|-------------|-------------|--------|------------------------------------------------|
| `bus_addr`  | Master → Bus | 32-bit | Address of the target register/memory location |
| `bus_wdata` | Master → Bus | 32-bit | Write data from master                         |
| `bus_wen`   | Master → Bus | 1-bit  | Write enable (1 = write, 0 = read)             |
| `bus_valid` | Master → Bus | 1-bit  | Master asserts to indicate a valid transaction |
| `bus_rdata` | Bus → Master | 32-bit | Read data returned to master                   |
| `bus_ready` | Bus → Master | 1-bit  | Slave asserts when transaction is complete     |

### Slave Interface (Peripheral Side)

Each slave sees the same bus signals, but directly from the bus interconnect:

| Signal        | Direction    | Width  | Description                                  |
|--------------|-------------|--------|----------------------------------------------|
| `slv_addr`   | Bus → Slave | 32-bit | Address (full 32-bit, slave uses lower bits) |
| `slv_wdata`  | Bus → Slave | 32-bit | Write data                                   |
| `slv_wen`    | Bus → Slave | 1-bit  | Write enable                                 |
| `slv_valid`  | Bus → Slave | 1-bit  | Slave is selected for this transaction       |
| `slv_rdata`  | Slave → Bus | 32-bit | Read data from slave                         |
| `slv_ready`  | Slave → Bus | 1-bit  | Slave transaction complete                   |

---

## Address Decoding

Address decoding uses the upper nibble `addr[31:28]` to select the target slave:

| `addr[31:28]` | Slave Selected     | Address Range                  |
|----------------|--------------------|---------------------------------|
| `4'h0`         | Instruction Memory | `0x0000_0000` – `0x0FFF_FFFF` |
| `4'h1`         | Data SRAM          | `0x1000_0000` – `0x1FFF_FFFF` |
| `4'h2`         | UART               | `0x2000_0000` – `0x2FFF_FFFF` |
| `4'h3`         | GPIO               | `0x3000_0000` – `0x3FFF_FFFF` |
| `4'h4`         | Timer              | `0x4000_0000` – `0x4FFF_FFFF` |
| `4'h5`         | CNN Accelerator    | `0x5000_0000` – `0x5FFF_FFFF` |
| `4'h6`         | AES-128 Engine     | `0x6000_0000` – `0x6FFF_FFFF` |
| Others         | (No slave — fault) | —                               |

> **Note:** Each slave only uses the lower address bits relevant to its register space.
> For example, the UART uses `addr[3:0]` to select among its 4 registers.
> The SRAM uses `addr[13:0]` to address 16 KB (4096 words × 4 bytes).

### Address Decoder Verilog Pseudocode

```verilog
// Address decoder selects the active slave based on addr[31:28]
always @(*) begin
    slv_sel = 7'b0000000;  // Default: no slave selected
    case (bus_addr[31:28])
        4'h0: slv_sel = 7'b0000001;  // Instruction Memory
        4'h1: slv_sel = 7'b0000010;  // SRAM
        4'h2: slv_sel = 7'b0000100;  // UART
        4'h3: slv_sel = 7'b0001000;  // GPIO
        4'h4: slv_sel = 7'b0010000;  // Timer
        4'h5: slv_sel = 7'b0100000;  // CNN Accelerator
        4'h6: slv_sel = 7'b1000000;  // AES Engine
        default: slv_sel = 7'b0000000;
    endcase
end
```

---

## Bus Transaction Protocol

### Simple Handshake

The bus uses a minimal **valid/ready** handshake:

1. **Master asserts** `bus_valid` along with `bus_addr`, `bus_wdata`, and `bus_wen`.
2. The **address decoder** routes the transaction to the selected slave.
3. The **slave processes** the transaction (read or write).
4. The **slave asserts** `slv_ready` when complete, providing `slv_rdata` for reads.
5. The **bus routes** `slv_ready` back to the master as `bus_ready`, and `slv_rdata` as `bus_rdata`.
6. **Master deasserts** `bus_valid` to end the transaction.

### Timing Diagram

```
            ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐
  clk       │   │   │   │   │   │   │   │   │   │
         ───┘   └───┘   └───┘   └───┘   └───┘   └───

              ┌───────────────────┐
  bus_valid   │                   │
         ─────┘                   └───────────────

              ┌───────────────────┐
  bus_addr    │  VALID ADDRESS    │
         ─────┘                   └───────────────

              ┌───────────────────┐
  bus_wen     │   0 (read)        │
         ─────┘                   └───────────────

                          ┌───────┐
  bus_ready               │       │
         ─────────────────┘       └───────────────

                          ┌───────┐
  bus_rdata               │ DATA  │
         ─────────────────┘       └───────────────
```

### Single-Cycle Slaves

For the single-cycle CPU design, most slaves respond in the **same clock cycle** (combinational
read path). The `ready` signal is typically tied high for simple peripherals. This means:

- **SRAM reads**: Combinational (single-cycle). `ready` = 1 always.
- **UART/GPIO/Timer**: Register reads are combinational. `ready` = 1 always.
- **CNN/AES**: May require multiple cycles. `ready` is deasserted while busy, stalling the CPU.

> **Important:** For the single-cycle CPU, the `ready` signal is used to stall the PC update.
> If `bus_ready` = 0, the CPU holds the current instruction and does not advance.

---

## Read/Write Data Multiplexer

The bus interconnect includes a read-data multiplexer that selects the returning read data
based on which slave is currently selected:

```verilog
// Read data mux — selects rdata from the active slave
always @(*) begin
    bus_rdata = 32'h0000_0000;
    case (bus_addr[31:28])
        4'h0: bus_rdata = imem_rdata;
        4'h1: bus_rdata = sram_rdata;
        4'h2: bus_rdata = uart_rdata;
        4'h3: bus_rdata = gpio_rdata;
        4'h4: bus_rdata = timer_rdata;
        4'h5: bus_rdata = cnn_rdata;
        4'h6: bus_rdata = aes_rdata;
        default: bus_rdata = 32'hDEAD_BEEF;  // Bus fault indicator
    endcase
end
```

---

## SRAM Arbitration

The SRAM controller is shared between the CPU and the CNN Accelerator. A simple priority
arbiter grants access:

| Priority | Requester       | Notes                                    |
|----------|-----------------|------------------------------------------|
| 1 (High) | CNN Accelerator | Granted during active inference          |
| 2 (Low)  | CPU             | Default owner; stalled during CNN access |

### Arbitration Protocol

1. When the CNN accelerator is **idle**, the CPU has full SRAM access.
2. When the CNN accelerator is **active** and needs SRAM, it asserts `cnn_sram_req`.
3. The arbiter grants SRAM to the CNN accelerator and asserts `cpu_sram_wait`.
4. The CPU stalls any SRAM transactions until `cpu_sram_wait` is deasserted.
5. Once the CNN accelerator completes its SRAM burst, it deasserts `cnn_sram_req`.

> **Note:** In the initial implementation (Milestone 5), the CNN accelerator uses its own
> internal register file for weights and inputs, so SRAM arbitration is only needed if we
> extend the design to support DMA-style data movement.

---

## Modules

### bus_interconnect.v

The top-level bus interconnect module:

```
Inputs:
    clk, rst_n
    // Master interface
    bus_addr[31:0], bus_wdata[31:0], bus_wen, bus_valid
    // Slave read data and ready signals (from each slave)
    imem_rdata[31:0], imem_ready
    sram_rdata[31:0], sram_ready
    uart_rdata[31:0], uart_ready
    gpio_rdata[31:0], gpio_ready
    timer_rdata[31:0], timer_ready
    cnn_rdata[31:0], cnn_ready
    aes_rdata[31:0], aes_ready

Outputs:
    bus_rdata[31:0], bus_ready
    // Slave select, address, data, control (to each slave)
    slv_addr[31:0], slv_wdata[31:0], slv_wen
    imem_valid, sram_valid, uart_valid, gpio_valid
    timer_valid, cnn_valid, aes_valid
```

### sram_arbiter.v

Simple priority arbiter for shared SRAM access:

```
Inputs:
    clk, rst_n
    cpu_sram_req, cpu_sram_addr[31:0], cpu_sram_wdata[31:0], cpu_sram_wen
    cnn_sram_req, cnn_sram_addr[31:0], cnn_sram_wdata[31:0], cnn_sram_wen

Outputs:
    sram_addr[31:0], sram_wdata[31:0], sram_wen, sram_valid
    cpu_sram_grant, cnn_sram_grant
    sram_rdata[31:0]  // Forwarded from SRAM to both requesters
```

---

## Design Constraints

| Constraint                    | Value                                     |
|------------------------------|-------------------------------------------|
| Data bus width               | 32 bits                                   |
| Address bus width            | 32 bits                                   |
| Number of slaves             | 7                                         |
| Address alignment            | Word-aligned (4-byte boundary)            |
| Maximum slaves               | 16 (4-bit decode field allows expansion)  |
| Bus clock                    | Same as CPU clock (single domain)         |
| Latency (simple peripherals) | 1 cycle (combinational read)              |
| Latency (CNN/AES)            | Variable (handshake-based stall)          |

---

## Future Extensibility

The 4-bit address decode field (`addr[31:28]`) allows up to 16 slaves. Reserved address
ranges `0x7000_0000` through `0xF000_0000` can be used for future peripherals such as:

- SPI controller
- I2C controller  
- Interrupt controller
- DMA controller
- Debug interface
