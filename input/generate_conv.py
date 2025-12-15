import numpy as np

# -----------------------------
# Generate random image & kernel
# -----------------------------
image = (np.random.rand(32, 32) * 15).astype(np.uint8)
kernel = (np.random.rand(3, 3) * 15).astype(np.uint8)

# -----------------------------
# Perform VALID convolution
# -----------------------------
H, W = image.shape
KH, KW = kernel.shape

out_h = H - KH + 1   # 126
out_w = W - KW + 1   # 126

output = np.zeros((out_h, out_w), dtype=np.uint32)

for i in range(out_h):
    for j in range(out_w):
        output[i, j] = np.sum(image[i:i+KH, j:j+KW] * kernel)

# -----------------------------
# im2col transformation for systolic array
# Each kernel window becomes a column
# Shape: (KH*KW, out_h*out_w) = (9, 15876)
# Memory layout: each address contains pixels for one row across all windows
# -----------------------------
def im2col(img, kh, kw):
    """
    Transform image to column format for systolic array.
    Each 3x3 kernel window is stored as a column.
    
    Output shape: (kh*kw, num_windows)
    - Rows: kernel elements (e.g., 9 for 3x3)
    - Columns: each convolution window position
    
    Memory storage: column-major order so each memory address
    contains consecutive pixels from the same kernel position
    across different windows.
    """
    h, w = img.shape
    oh = h - kh + 1
    ow = w - kw + 1
    num_windows = oh * ow
    
    # Create im2col matrix: (kh*kw) x (num_windows)
    col = np.zeros((kh * kw, num_windows), dtype=img.dtype)
    
    idx = 0
    for i in range(oh):
        for j in range(ow):
            # Extract the kernel window and flatten it
            window = img[i:i+kh, j:j+kw].flatten()
            col[:, idx] = window
            idx += 1
    
    return col

# Generate im2col format for image
image_im2col = im2col(image, KH, KW)
print(f"im2col shape: {image_im2col.shape}")
print(f"  - Rows (kernel size): {image_im2col.shape[0]} (KH*KW = {KH}*{KW})")
print(f"  - Cols (windows): {image_im2col.shape[1]} (out_h*out_w = {out_h}*{out_w})")

# -----------------------------
# Function to export .coe
# -----------------------------
def save_coe(filename, array):
    with open(filename, "w") as f:
        f.write("memory_initialization_radix=10;\n")
        f.write("memory_initialization_vector=\n")

        flat = array.flatten()

        for idx, val in enumerate(flat):
            if idx == len(flat) - 1:
                f.write(f"{int(val)};")
            else:
                f.write(f"{int(val)},\n")

def save_coe_im2col(filename, col_array):
    """
    Save im2col format in column-major order.
    Each memory address contains consecutive pixels from the same 
    kernel position across different windows (stored as columns).
    
    Memory layout:
    - Address 0: col[0,0], col[0,1], col[0,2], ... (first element of all windows)
    - Address 1: col[1,0], col[1,1], col[1,2], ... (second element of all windows)
    - ...
    
    This allows feeding consecutive pixels to systolic array rows.
    """
    with open(filename, "w") as f:
        f.write("memory_initialization_radix=10;\n")
        f.write("memory_initialization_vector=\n")
        
        # Column-major order: iterate columns first, then rows
        # This stores each kernel window as consecutive memory locations
        kh_kw, num_windows = col_array.shape
        total = kh_kw * num_windows
        
        count = 0
        for col in range(num_windows):  # Each window (column)
            for row in range(kh_kw):     # Each kernel element (row)
                val = col_array[row, col]
                if count == total - 1:
                    f.write(f"{int(val)};")
                else:
                    f.write(f"{int(val)},\n")
                count += 1

def save_mem_im2col_64bit(filename, col_array):
    """
    Save im2col format as .mem file for Verilog $readmemh.
    Packs 8 bytes (8-bit each) into each 64-bit word.
    
    Each 64-bit word contains 8 consecutive pixels from a kernel window.
    Format: DATA7:DATA6:DATA5:DATA4:DATA3:DATA2:DATA1:DATA0 (little endian)
    
    Memory layout for systolic array:
    - Address 0: pixels 0-7 of window 0
    - Address 1: pixel 8 of window 0 + pixels 0-6 of window 1
    - etc.
    
    For 3x3 kernel (9 pixels per window):
    - ~9 pixels per window, packed into 64-bit words
    """
    with open(filename, "w") as f:
        f.write("// Memory initialization file for BRAM (64-bit width)\n")
        f.write("// Format: $readmemh compatible\n")
        f.write("// Each line is a 64-bit word containing 8 x 8-bit pixels\n")
        f.write("// im2col format: kernel windows stored consecutively\n\n")
        
        kh_kw, num_windows = col_array.shape
        
        # Flatten in column-major order (each window's pixels consecutively)
        flat_data = []
        for col in range(num_windows):
            for row in range(kh_kw):
                flat_data.append(col_array[row, col])
        
        # Pack into 64-bit words (8 bytes per word)
        addr = 0
        for i in range(0, len(flat_data), 8):
            # Get 8 bytes (pad with 0 if needed)
            chunk = flat_data[i:i+8]
            while len(chunk) < 8:
                chunk.append(0)
            
            # Pack as little-endian: DATA0 at bits [7:0], DATA7 at bits [63:56]
            word = 0
            for j, val in enumerate(chunk):
                word |= (int(val) & 0xFF) << (j * 8)
            
            f.write(f"@{addr:04X} {word:016X}\n")
            addr += 1
        
        f.write(f"\n// Total addresses: {addr}\n")
        f.write(f"// Total pixels: {len(flat_data)}\n")
        f.write(f"// Windows: {num_windows}, Pixels per window: {kh_kw}\n")
    
    return addr  # Return number of addresses used

# -----------------------------
# Save all files
# -----------------------------
# Save image in im2col format (column-major: each kernel window stored consecutively)
save_coe_im2col("image.coe", image_im2col)
num_bram_addr = save_mem_im2col_64bit("image.mem", image_im2col)
save_coe("kernel.coe", kernel)
save_coe("result.coe", output)

print("\nGenerated files:")
print("  - image.coe: im2col format (column-major)")
print(f"    Each memory block of {KH*KW} addresses contains one kernel window")
print(f"    Total windows: {out_h * out_w}")
print("  - image.mem: Verilog $readmemh compatible (64-bit packed)")
print(f"    BRAM addresses used: {num_bram_addr}")
print("  - kernel.coe: flattened kernel")
print("  - result.coe: convolution result")
