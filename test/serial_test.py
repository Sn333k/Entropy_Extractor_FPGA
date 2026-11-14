import sys
import os
import numpy as np
from scipy.special import gammaincc

def psi_sq(bit_array, m):
    if m == 0:
        return 0.0
    n = len(bit_array)
    padded = np.concatenate([bit_array, bit_array[:m - 1]])
    counts = np.zeros(2 ** m, dtype=int)
    
    powers = 2 ** np.arange(m - 1, -1, -1)
    for i in range(n):
        idx = int(np.dot(padded[i:i + m], powers))
        counts[idx] += 1
        
    return (2 ** m / n) * np.sum(counts ** 2) - n

def serial_test(bit_array, m=2):
    n = len(bit_array)
    if n < 2 ** m:
        return 0.0

    psi_m = psi_sq(bit_array, m)
    psi_m1 = psi_sq(bit_array, m - 1)
    psi_m2 = psi_sq(bit_array, m - 2)

    del1 = psi_m - psi_m1
    del2 = psi_m - 2 * psi_m1 + psi_m2

    p_value1 = gammaincc(2 ** (m - 2), del1 / 2.0)
    p_value2 = gammaincc(2 ** (m - 3), del2 / 2.0)

    return float(min(p_value1, p_value2))

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
        p_val = serial_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()