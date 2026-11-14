import sys
import os
import numpy as np
from scipy.special import gammaincc

def get_pi(k, abs_x):
    if k == 0:
        return 1.0 - 1.0 / (2.0 * abs_x)
    elif k < 5:
        return (1.0 / (4.0 * (abs_x ** 2))) * ((1.0 - 1.0 / (2.0 * abs_x)) ** (k - 1))
    else:
        return (1.0 / (2.0 * abs_x)) * ((1.0 - 1.0 / (2.0 * abs_x)) ** 4)

def random_excursions_test(bit_array):
    n = len(bit_array)
    if n == 0:
        return 0.0

    converted = np.where(bit_array == 0, -1, 1)
    s = np.concatenate(([0], np.cumsum(converted), [0]))
    
    zero_indices = np.where(s == 0)[0]
    J = len(zero_indices) - 1
    
    if J < 500:
        return 0.0

    states = [-4, -3, -2, -1, 1, 2, 3, 4]
    p_values = []

    for x in states:
        v = np.zeros(6, dtype=int)
        for j in range(J):
            cycle = s[zero_indices[j]:zero_indices[j + 1] + 1]
            count = np.sum(cycle == x)
            if count >= 5:
                v[5] += 1
            else:
                v[count] += 1

        chi_squared = 0.0
        abs_x = abs(x)
        for k in range(6):
            pi_k = get_pi(k, abs_x)
            expected = J * pi_k
            chi_squared += ((v[k] - expected) ** 2) / expected

        p_values.append(gammaincc(2.5, chi_squared / 2.0))

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
        p_val = random_excursions_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()