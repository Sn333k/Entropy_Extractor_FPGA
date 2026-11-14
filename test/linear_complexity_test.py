import sys
import os
import numpy as np
from scipy.special import gammaincc

def berlekamp_massey(block):
    n = len(block)
    c = np.zeros(n, dtype=int)
    b = np.zeros(n, dtype=int)
    c[0] = 1
    b[0] = 1
    L = 0
    m = -1
    for N in range(n):
        d = block[N]
        if L > 0:
            d ^= np.bitwise_xor.reduce(c[1:L + 1] & block[N - 1:N - L - 1:-1])
        if d == 1:
            t = c.copy()
            shift = N - m
            c[shift:n] ^= b[:n - shift]
            if L <= N // 2:
                L = N + 1 - L
                m = N
                b = t
    return L

def linear_complexity_test(bit_array, M=500):
    n = len(bit_array)
    N = n // M
    if N == 0:
        return 0.0

    trimmed = bit_array[:N * M]
    blocks = trimmed.reshape((N, M))

    mu = M / 2.0 + (9.0 + (-1.0) ** (M + 1)) / 36.0 - (M / 3.0 + 2.0 / 9.0) / (2.0 ** M)

    v = np.zeros(7, dtype=int)
    pi = [0.010417, 0.03125, 0.125, 0.5, 0.25, 0.0625, 0.020833]

    for block in blocks:
        L = berlekamp_massey(block)
        T = ((-1.0) ** M) * (L - mu) + 2.0 / 9.0

        if T <= -2.5:
            v[0] += 1
        elif T <= -1.5:
            v[1] += 1
        elif T <= -0.5:
            v[2] += 1
        elif T <= 0.5:
            v[3] += 1
        elif T <= 1.5:
            v[4] += 1
        elif T <= 2.5:
            v[5] += 1
        else:
            v[6] += 1

    chi_squared = 0.0
    for i in range(7):
        chi_squared += ((v[i] - N * pi[i]) ** 2) / (N * pi[i])

    p_value = gammaincc(3.0, chi_squared / 2.0)
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
        p_val = linear_complexity_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()