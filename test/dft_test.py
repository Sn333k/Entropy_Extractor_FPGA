import sys
import os
import numpy as np
from scipy.special import erfc

def dft_test(bit_array):
    n = len(bit_array)
    if n == 0:
        return 0.0

    converted = np.where(bit_array == 0, -1.0, 1.0)
    
    f_transform = np.fft.fft(converted)
    
    m = np.abs(f_transform[:n // 2])
    
    t = np.sqrt(np.log(1 / 0.05) * n)
    
    n0 = 0.95 * (n / 2)
    
    n1 = np.sum(m < t)
    
    d = (n1 - n0) / np.sqrt(n * 0.95 * 0.05 / 4)
    
    p_value = erfc(abs(d) / np.sqrt(2))
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
        p_val = dft_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()