import os
import numpy as np
from scipy.special import erfc

def frequency_monobit_test(bit_array):
    """
    Monobit Test
    """
    # Zamieniamy bity 0 na -1, a 1 na 1
    n = len(bit_array)
    converted = np.where(bit_array == 0, -1, 1)
    s_n = np.sum(converted)
    
    s_obs = abs(s_n) / np.sqrt(n)
    p_value = erfc(s_obs / np.sqrt(2))
    return p_value

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
    
    from scipy.stats import chi2
    p_value = 1 - chi2.cdf(chi_squared, num_blocks)
    return p_value

def analyze_randomness():
    print("Analiza losowości\n")
    
    for i in range(1, 11):
        filename = f"dane_{i}.bin"
        
        if not os.path.exists(filename):
            print(f"[Pomijam] Plik {filename} nie istnieje.")
            continue
            
        print("="*60)
        print(f" ANALIZA PLIKU: {filename}")
        print("="*60)
        
        try:
            with open(filename, 'rb') as f:
                raw_data = f.read()
                
            if len(raw_data) == 0:
                print(f"Plik {filename} jest pusty.")
                continue

            bit_array = np.unpackbits(np.frombuffer(raw_data, dtype=np.uint8))
            
            print(f"Wczytano: {len(raw_data)} bajtów ({len(bit_array)} bitów).")
            
            p_val_mono = frequency_monobit_test(bit_array)
            print(f"1. Test Częstotliwości (Monobit):")
            print(f"   -> p-value = {p_val_mono:.6f}")
            if p_val_mono >= 0.01:
                print("   -> WYNIK: POZYTYWNY (Losowy, p >= 0.01)")
            else:
                print("   -> WYNIK: ODRZUCONY (Nielosowy, p < 0.01)")
                
            p_val_block = block_frequency_test(bit_array)
            print(f"2. Test Częstotliwości w Blokach:")
            print(f"   -> p-value = {p_val_block:.6f}")
            if p_val_block >= 0.01:
                print("   -> WYNIK: POZYTYWNY (Losowy, p >= 0.01)")
            else:
                print("   -> WYNIK: ODRZUCONY (Nielosowy, p < 0.01)")
            print("\n")
                
        except Exception as e:
            print(f"[Błąd] Wystąpił problem podczas analizy pliku {filename}: {e}")

if __name__ == "__main__":
    analyze_randomness()