import sys
import os
import numpy as np
from scipy.special import erfc

def random_excursions_variant_test(bit_array):
    n = len(bit_array)
    if n == 0:
        return 0.0

    converted = np.where(bit_array == 0, -1, 1)
    s = np.concatenate(([0], np.cumsum(converted), [0]))
    
    zero_indices = np.where(s == 0)[0]
    J = len(zero_indices) - 1
    
    if J < 500:
        return 0.0

    states = [-9, -8, -7, -6, -5, -4, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    p_values = []

    for x in states:
        count = np.sum(s == x)
        numerator = abs(count - J)
        denominator = np.sqrt(2.0 * J * (4.0 * abs(x) - 2.0))
        if denominator == 0:
            p_val = 0.0
        else:
            p_val = erfc(numerator / denominator)
        p_values.append(p_val)

    return float(min(p_values))

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
        p_val = random_excursions_variant_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()