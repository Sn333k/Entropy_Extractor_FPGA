import sys
import os
import numpy as np
from scipy.special import gammaincc

def phi(bit_array, m):
    n = len(bit_array)
    if m == 0:
        return 0.0
    padded = np.concatenate([bit_array, bit_array[:m - 1]])
    counts = np.zeros(2 ** m, dtype=int)
    
    powers = 2 ** np.arange(m - 1, -1, -1)
    windows = np.lib.stride_tricks.sliding_window_view(padded, m)
    indices = windows @ powers
    counts = np.bincount(indices, minlength=2 ** m)
    
    probs = counts / n
    non_zero = probs[probs > 0]
    return float(np.sum(non_zero * np.log(non_zero)))

def approximate_entropy_test(bit_array, m=10):
    n = len(bit_array)
    if n < 2 ** (m + 1):
        return 0.0

    phi_m = phi(bit_array, m)
    phi_m1 = phi(bit_array, m + 1)

    ap_en = phi_m - phi_m1
    chi_squared = 2.0 * n * (np.log(2) - ap_en)

    p_value = gammaincc(2 ** (m - 1), chi_squared / 2.0)
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
        p_val = approximate_entropy_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()