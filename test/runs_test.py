import sys
import os
import numpy as np
from scipy.special import erfc

def runs_test(bit_array):
    """
    Runs Test
    """
    n = len(bit_array)
    if n == 0:
        return 0.0

    pi = np.sum(bit_array) / n
    v_n = 1 + np.sum(bit_array[:-1] != bit_array[1:])
    numerator = abs(v_n - 2 * n * pi * (1 - pi))
    denominator = 2 * np.sqrt(2 * n) * pi * (1 - pi)
    
    if denominator == 0:
        return 0.0

    s_obs = numerator / denominator
    p_value = erfc(s_obs)
    
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
        p_val = runs_test(bit_array)
        print(f"{p_val:.5f}")
        sys.exit(0)       
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()