import sys
import os
import numpy as np
from scipy.stats import norm

def compute_p_value(n, z):
    if z == 0:
        return 0.0
    sqrt_n = np.sqrt(n)
    
    start1 = int(np.floor((-n / z + 1.0) / 4.0))
    end1 = int(np.floor((n / z - 1.0) / 4.0))
    sum1 = 0.0
    for k in range(start1, end1 + 1):
        sum1 += norm.cdf(((4 * k + 1) * z) / sqrt_n) - norm.cdf(((4 * k - 1) * z) / sqrt_n)
        
    start2 = int(np.floor((-n / z - 3.0) / 4.0))
    end2 = int(np.floor((n / z - 1.0) / 4.0))
    sum2 = 0.0
    for k in range(start2, end2 + 1):
        sum2 += norm.cdf(((4 * k + 3) * z) / sqrt_n) - norm.cdf(((4 * k + 1) * z) / sqrt_n)
        
    return float(1.0 - sum1 + sum2)

def cumulative_sums_test(bit_array):
    n = len(bit_array)
    if n == 0:
        return 0.0

    converted = np.where(bit_array == 0, -1, 1)
    
    s_forward = np.cumsum(converted)
    z_forward = np.max(np.abs(s_forward))
    p_forward = compute_p_value(n, z_forward)
    
    s_backward = np.cumsum(converted[::-1])
    z_backward = np.max(np.abs(s_backward))
    p_backward = compute_p_value(n, z_backward)
    
    return float(min(p_forward, p_backward))

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
        p_val = cumulative_sums_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()