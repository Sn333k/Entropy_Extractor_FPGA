import sys
import os
import numpy as np
from scipy.stats import chi2

def non_overlapping_template_test(bit_array, template=None, m=9):
    if template is None:
        template = np.array([1, 1, 1, 1, 1, 1, 1, 1, 1], dtype=int)
        #template = np.array([0, 0, 0], dtype=int)

    
    
    n = len(bit_array)
    m = len(template)
    
    N = 8
    M = n // N
    if M == 0:
        return 0.0

    W = 0
    mu = (M - m + 1) / (2 ** m)
    var = M * ((1 / (2 ** m)) - ((2 * m - 1) / (2 ** (2 * m))))

    chi_squared = 0.0

    for i in range(N):
        block = bit_array[i * M : (i + 1) * M]
        count = 0
        j = 0
        while j <= M - m:
            if np.array_equal(block[j:j + m], template):
                count += 1
                j += m
            else:
                j += 1
        
        chi_squared += ((count - mu) ** 2) / var

    p_value = 1 - chi2.cdf(chi_squared, N)
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
        p_val = non_overlapping_template_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()