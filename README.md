# SIMD Processor Array for Convolutional Neural Networks

This project presents a high-performance **SIMD (Single Instruction, Multiple Data) processor array** designed to accelerate Convolutional Neural Network (CNN) operations on FPGA-based SoCs. The architecture utilizes a systolic array of Processing Elements (PEs) to perform convolution, pooling, and activation functions with high hardware utilization and minimal CPU overhead.

---

## 1. System Architecture

The accelerator is integrated into the Programmable Logic (PL) of a Xilinx Zynq-7000 SoC, coordinated by the ARM Processing System (PS). 



### 1.1 Key Modules
* **Top Controller:** Decodes macro-instructions and orchestrates data movement between buffers and the compute core.
* **Systolic PE Array:** An 8-PE array (PE0-PE7) that processes data in a pipelined, parallel fashion.
* **DMA Engine:** Facilitates high-throughput streaming of input feature maps and weights from DDR memory to the PL via AXI-Stream interfaces.
* **On-Chip Memory:** Features dedicated double-buffered input pixel/weight buffers and an $8 \times 1024$ ifmap register bank to enable efficient data reuse.

---

## 2. Processing Element (PE) Design

The PE is the fundamental computational unit, designed for fixed-point arithmetic. 



* **Convolution:** Utilizes a pipelined multiply-accumulate (MAC) datapath.
* **Pooling:** Employs a comparison-based datapath for max-pooling operations.
* **Dataflow:** Supports systolic-style propagation of pixel values and weights to adjacent PEs.

---

## 3. Instruction Set Architecture (ISA)

The system uses a custom **Macro-Instruction ISA** that abstracts complex CNN layers into single 48-bit (simplified to 34-bit for demo) instructions.

| Instruction | Opcode | Sub-Opcode | Description |
| :--- | :--- | :--- | :--- |
| **CONV** | `00` | `01` | 2D Convolution with kernel sizes $1 \times 1$ to $7 \times 7$. |
| **MAXPOOL** | `01` | `00` | Max-pooling operation. |
| **RELU** | `10` | `00` | Rectified Linear Unit activation. |
| **SIGMOID** | `10` | `01` | Sigmoid activation function. |
| **SOFTMAX** | `10` | `10` | Softmax activation. |

---

## 4. Performance & Resource Utilization

### 4.1 Latency (Clock Cycles) for 32x32 Input
| Operation | Kernel Size | Clock Cycles |
| :--- | :--- | :--- |
| **Convolution** | $1 \times 1$ | 138 |
| **Convolution** | $3 \times 3$ | 1,090 |
| **Convolution** | $7 \times 7$ | 5,106 |
| **MaxPool** | $3 \times 3$ | 125 |
| **ReLU** | N/A | 138 |

### 4.2 FPGA Resources (Zybo Z7-10)
The design was synthesized for the **xc7z010clg400-1** device.
* **Slice LUTs:** ~0.63% (Systolic Input Control).
* **Block RAM:** 3.33% (RAMB18/Tile).
* **DSPs:** 1.25% (DSP48E1).

---

## 5. Image Processing Pipeline
1. **Acquisition:** A $28 \times 28$ grayscale image is received byte-by-byte via UART into DDR memory.
2. **Preprocessing:** The PS executes `im2col` and configures the DMA.
3. **Execution:** Data is sent via MM2S DMA to the PL accelerator.
4. **Output:** Processed results are streamed back to DDR memory via S2MM DMA.



---

## Project Information
* **Course:** EN4021 - Advanced Digital Systems
* **Institution:** University of Moratuwa, Dept. of Electronic & Telecommunication Engineering
* **Team:** Amarathunga D. N., Jayathilaka D. E. U., Pasira I. P. М., Rajapaksha S. D. D. Z.
* **Date:** December 18, 2025
