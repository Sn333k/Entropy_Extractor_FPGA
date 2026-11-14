import sys
import os
import numpy as np
from scipy.special import erfc

def frequency_monobit_test(bit_array):
    """
    Frequency monobit test
    """
    n = len(bit_array)
    converted = np.where(bit_array == 0, -1, 1)
    s_n = np.sum(converted)
    
    s_obs = abs(s_n) / np.sqrt(n)
    p_value = erfc(s_obs / np.sqrt(2))
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
        p_val_mono = frequency_monobit_test(bit_array)
        
        print(f"{p_val_mono:.5f}")
    except Exception:
        print("  ERR  ")
            
    except Exception as e:
        print(f"  -> [Błąd] {e}")

if __name__ == "__main__":
    main()