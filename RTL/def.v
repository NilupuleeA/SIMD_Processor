`ifndef _DEF_V
`define _DEF_V

// Common definitions
`define DATA_WIDTH 8    // A data is a 16-bit fixed-point number
`define WORD_WIDTH 64   // A word in global buffer has 8 of data
`define ADDR_WIDTH 12    // Global buffer has 4096 entries
`define OUTPUT_LAT 2     // Latency to the output when the batch ends

// Data positions in a word (little endian)
`define DATA7 63:56
`define DATA6 55:48
`define DATA5 47:40
`define DATA4 39:32
`define DATA3 31:24
`define DATA2 23:16
`define DATA1 15:7
`define DATA0 7:0

// Simulation definitions
`define GBUFF_ADDR_BEGIN 12'h000  // Simulate only 256 entries (3840~4095)
`define GBUFF_ADDR_END   12'hfff

`endif
