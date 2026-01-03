# SIMD Processor Array for Convolutional Neural Networks

[cite_start]This project presents a high-performance **SIMD (Single Instruction, Multiple Data) processor array** designed to accelerate Convolutional Neural Network (CNN) operations on FPGA-based SoCs[cite: 341, 410]. [cite_start]The architecture utilizes a systolic array of Processing Elements (PEs) to perform convolution, pooling, and activation functions with high hardware utilization and minimal CPU overhead[cite: 355, 418].

---

## 1. System Architecture

[cite_start]The accelerator is integrated into the Programmable Logic (PL) of a Xilinx Zynq-7000 SoC, coordinated by the ARM Processing System (PS)[cite: 410, 411, 576].



### 1.1 Key Modules
* [cite_start]**Top Controller:** Decodes macro-instructions and orchestrates data movement between buffers and the compute core[cite: 414].
* [cite_start]**Systolic PE Array:** An 8-PE array (PE0-PE7) that processes data in a pipelined, parallel fashion[cite: 569, 572].
* [cite_start]**DMA Engine:** Facilitates high-throughput streaming of input feature maps and weights from DDR memory to the PL via AXI-Stream interfaces[cite: 412, 1039].
* [cite_start]**On-Chip Memory:** Features dedicated double-buffered input pixel/weight buffers and an $8 \times 1024$ ifmap register bank to enable efficient data reuse[cite: 381, 382, 413].

---

## 2. Processing Element (PE) Design

[cite_start]The PE is the fundamental computational unit, designed for fixed-point arithmetic[cite: 431, 432].



* [cite_start]**Convolution:** Utilizes a pipelined multiply-accumulate (MAC) datapath[cite: 432].
* [cite_start]**Pooling:** Employs a comparison-based datapath for max-pooling operations[cite: 432].
* [cite_start]**Dataflow:** Supports systolic-style propagation of pixel values and weights to adjacent PEs[cite: 433].

---

## 3. Instruction Set Architecture (ISA)

[cite_start]The system uses a custom **Macro-Instruction ISA** that abstracts complex CNN layers into single 48-bit (simplified to 34-bit for demo) instructions[cite: 350, 351, 356].

| Instruction | Opcode | Sub-Opcode | Description |
| :--- | :--- | :--- | :--- |
| **CONV** | `00` | `01` | [cite_start]2D Convolution with kernel sizes $1 \times 1$ to $7 \times 7$[cite: 349, 625]. |
| **MAXPOOL** | `01` | `00` | [cite_start]Max-pooling operation[cite: 349]. |
| **RELU** | `10` | `00` | [cite_start]Rectified Linear Unit activation[cite: 349]. |
| **SIGMOID** | `10` | `01` | [cite_start]Sigmoid activation function[cite: 349]. |
| **SOFTMAX** | `10` | `10` | [cite_start]Softmax activation[cite: 349]. |

---

## 4. Performance & Resource Utilization

### 4.1 Latency (Clock Cycles) for 32x32 Input
| Operation | Kernel Size | Clock Cycles |
| :--- | :--- | :--- |
| **Convolution** | $1 \times 1$ | [cite_start]138 [cite: 1026] |
| **Convolution** | $3 \times 3$ | [cite_start]1,090 [cite: 1026] |
| **Convolution** | $7 \times 7$ | [cite_start]5,106 [cite: 1026] |
| **MaxPool** | $3 \times 3$ | [cite_start]125 [cite: 1028] |
| **ReLU** | N/A | [cite_start]138 [cite: 1029] |

### 4.2 FPGA Resources (Zybo Z7-10)
[cite_start]The design was synthesized for the **xc7z010clg400-1** device[cite: 579].
* [cite_start]**Slice LUTs:** ~0.63% (Systolic Input Control)[cite: 582].
* [cite_start]**Block RAM:** 3.33% (RAMB18/Tile)[cite: 590].
* [cite_start]**DSPs:** 1.25% (DSP48E1)[cite: 597, 620].

---

## 5. Image Processing Pipeline
1. [cite_start]**Acquisition:** A $28 \times 28$ grayscale image is received byte-by-byte via UART into DDR memory[cite: 1051].
2. [cite_start]**Preprocessing:** The PS executes `im2col` and configures the DMA[cite: 1044].
3. [cite_start]**Execution:** Data is sent via MM2S DMA to the PL accelerator[cite: 1052, 1053].
4. [cite_start]**Output:** Processed results are streamed back to DDR memory via S2MM DMA[cite: 1062].



---

## Project Information
* [cite_start]**Course:** EN4021 - Advanced Digital Systems[cite: 340].
* [cite_start]**Institution:** University of Moratuwa, Dept. of Electronic & Telecommunication Engineering[cite: 334, 336].
* [cite_start]**Team:** Amarathunga D. N., Jayathilaka D. E. U., Pasira I. P. М., Rajapaksha S. D. D. Z.[cite: 342].
* [cite_start]**Date:** December 18, 2025[cite: 345].
