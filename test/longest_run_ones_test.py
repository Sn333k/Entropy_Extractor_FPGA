import sys
import os
import numpy as np
from scipy.stats import chi2

def longest_run_ones_test(bit_array):
    n = len(bit_array)
    if n < 128:
        return 0.0

    if n < 6272:
        M = 8
        K = 3
        v_values = [1, 2, 3, 4]
        pi_values = [0.21484375, 0.3671875, 0.23046875, 0.1875]
    elif n < 750000:
        M = 128
        K = 5
        v_values = [4, 5, 6, 7, 8, 9]
        pi_values = [0.11740357, 0.24295595, 0.24936348, 0.17517706, 0.10270107, 0.11239884]
    else:
        M = 10000
        K = 6
        v_values = [10, 11, 12, 13, 14, 15, 16]
        pi_values = [0.088236, 0.209233, 0.248328, 0.193043, 0.120888, 0.067512, 0.072758]

    num_blocks = n // M
    if num_blocks == 0:
        return 0.0

    blocks = bit_array[:num_blocks * M].reshape((num_blocks, M))
    
    v_counts = np.zeros(len(v_values), dtype=int)
    
    for block in blocks:
        max_run = 0
        current_run = 0
        for bit in block:
            if bit == 1:
                current_run += 1
                if current_run > max_run:
                    max_run = current_run
            else:
                current_run = 0
        
        if M == 8:
            if max_run <= 1: v_counts[0] += 1
            elif max_run == 2: v_counts[1] += 1
            elif max_run == 3: v_counts[2] += 1
            else: v_counts[3] += 1
        elif M == 128:
            if max_run <= 4: v_counts[0] += 1
            elif max_run == 5: v_counts[1] += 1
            elif max_run == 6: v_counts[2] += 1
            elif max_run == 7: v_counts[3] += 1
            elif max_run == 8: v_counts[4] += 1
            else: v_counts[5] += 1
        else:
            if max_run <= 10: v_counts[0] += 1
            elif max_run == 11: v_counts[1] += 1
            elif max_run == 12: v_counts[2] += 1
            elif max_run == 13: v_counts[3] += 1
            elif max_run == 14: v_counts[4] += 1
            elif max_run == 15: v_counts[5] += 1
            else: v_counts[6] += 1

    chi_squared = 0.0
    for i in range(len(v_values)):
        expected = num_blocks * pi_values[i]
        chi_squared += ((v_counts[i] - expected) ** 2) / expected

    p_value = 1 - chi2.cdf(chi_squared, K)
    return float(p_value)

def main():
    if len(sys.argv) < 2:
        sys.exit(1)
        
    filename = sys.argv[1]
    if not os.path.exists(filename):
        sys.exit(1)

    try:
        with open(filename, 'rb') as f:
            raw_data = f.read()
        if len(raw_data) == 0:
            sys.exit(1)

        bit_array = np.unpackbits(np.frombuffer(raw_data, dtype=np.uint8))
        p_val = longest_run_ones_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()