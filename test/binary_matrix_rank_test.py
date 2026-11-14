import sys
import os
import numpy as np
from scipy.stats import chi2

def matrix_rank(matrix, M, Q):
    m = matrix.copy()
    rank = 0
    i = 0
    j = 0
    while i < M and j < Q:
        pivot = -1
        for r in range(i, M):
            if m[r, j] == 1:
                pivot = r
                break
        if pivot == -1:
            j += 1
            continue
        if pivot != i:
            m[[i, pivot]] = m[[pivot, i]]
        for r in range(i + 1, M):
            if m[r, j] == 1:
                m[r] ^= m[i]
        rank += 1
        i += 1
        j += 1
    return rank

def binary_matrix_rank_test(bit_array):
    n = len(bit_array)
    M = 32
    Q = 32
    block_size = M * Q
    num_blocks = n // block_size
    if num_blocks == 0:
        return 0.0

    trimmed = bit_array[:num_blocks * block_size]
    blocks = trimmed.reshape((num_blocks, M, Q))

    full_rank = 0
    rank_minus_one = 0
    other_rank = 0

    for block in blocks:
        r = matrix_rank(block, M, Q)
        if r == M:
            full_rank += 1
        elif r == M - 1:
            rank_minus_one += 1
        else:
            other_rank += 1

    p32 = 0.2888
    p31 = 0.5776
    po = 0.1336

    chi_squared = ((full_rank - num_blocks * p32) ** 2) / (num_blocks * p32) + \
                  ((rank_minus_one - num_blocks * p31) ** 2) / (num_blocks * p31) + \
                  ((other_rank - num_blocks * po) ** 2) / (num_blocks * po)

    p_value = 1 - chi2.cdf(chi_squared, 2)
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
        p_val = binary_matrix_rank_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()