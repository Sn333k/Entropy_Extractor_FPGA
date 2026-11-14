import sys
import os
import numpy as np
from scipy.stats import chi2

def overlapping_template_test(bit_array, m=9):
    n = len(bit_array)
    if n < 1000000:
        M = 1032
        N = n // M
    else:
        M = 1032
        N = 968

    if N == 0:
        return 0.0

    trimmed = bit_array[:N * M]
    blocks = trimmed.reshape((N, M))
    
    lambda_val = (M - m + 1) / (2 ** m)
    eta = lambda_val / 2.0
    
    pi = [0.148, 0.403, 0.249, 0.105, 0.030, 0.065]
    v = np.zeros(6, dtype=int)

    template = np.ones(m, dtype=int)

    for block in blocks:
        count = 0
        for i in range(M - m + 1):
            if np.array_equal(block[i:i + m], template):
                count += 1
        
        if count == 0:
            v[0] += 1
        elif count == 1:
            v[1] += 1
        elif count == 2:
            v[2] += 1
        elif count == 3:
            v[3] += 1
        elif count == 4:
            v[4] += 1
        else:
            v[5] += 1

    chi_squared = 0.0
    for i in range(6):
        chi_squared += ((v[i] - N * pi[i]) ** 2) / (N * pi[i])

    p_value = 1 - chi2.cdf(chi_squared, 5)
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
        p_val = overlapping_template_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()