import numpy as np

# -----------------------------
# Generate random image & kernel
# -----------------------------
image = (np.random.rand(128, 128) * 255).astype(np.uint8)
kernel = (np.random.rand(3, 3) * 255).astype(np.uint8)

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

# -----------------------------
# Save all files
# -----------------------------
save_coe("image.coe", image)
save_coe("kernel.coe", kernel)
save_coe("result.coe", output)

print("Generated image.coe, kernel.coe, result.coe")
