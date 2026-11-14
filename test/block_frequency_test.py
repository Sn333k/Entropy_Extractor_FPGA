import sys
import os
import numpy as np
from scipy.stats import chi2

def block_frequency_test(bit_array, block_size=128000):
    """
    Block Frequency Test
    """
    n = len(bit_array)
    num_blocks = n // block_size
    if num_blocks == 0:
        return 0.0
        
    trimmed = bit_array[:num_blocks * block_size]
    blocks = trimmed.reshape((num_blocks, block_size))
    
    pi = np.sum(blocks, axis=1) / block_size
    chi_squared = 4 * block_size * np.sum((pi - 0.5) ** 2)
    
    p_value = 1 - chi2.cdf(chi_squared, num_blocks)
    return p_value

def main():
    filename = sys.argv[1] if len(sys.argv) > 1 else "dane_1.bin"
    
    if not os.path.exists(filename):
        print(f"  -> [Błąd] Plik {filename} nie istnieje.")
        return

    try:
        with open(filename, 'rb') as f:
            raw_data = f.read()
            
        if len(raw_data) == 0:
            print(f"  -> [Błąd] Plik {filename} jest pusty.")
            return

        bit_array = np.unpackbits(np.frombuffer(raw_data, dtype=np.uint8))
        p_val_block = block_frequency_test(bit_array)
        
        print(f"{p_val_block:.5f}")
            
    except Exception as e:
        print(f"  -> [Błąd] {e}")

if __name__ == "__main__":
    main()