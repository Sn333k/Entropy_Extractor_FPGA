import sys
import os
import time
import numpy as np
from scipy.special import gammaincc


def berlekamp_massey(block) -> int:
    n = len(block)
    c = 1
    b = 1
    L = 0
    m = -1
    rev_block = 0

    for N in range(n):
        bit = int(block[N])
        rev_block = (rev_block << 1) | bit

        d = bit
        if L > 0:
            overlap = (c >> 1) & (rev_block >> 1) & ((1 << L) - 1)
            d ^= overlap.bit_count() & 1

        if d == 1:
            t = c
            shift = N - m
            c ^= b << shift
            if L <= N // 2:
                L = N + 1 - L
                m = N
                b = t
    return L


def linear_complexity_test(bit_array, M=500, debug=True):
    t0 = time.perf_counter()
    n = len(bit_array)
    N = n // M
    if N == 0:
        if debug:
            print("N==0", file=sys.stderr)
        return 0.0

    trimmed = bit_array[: N * M]
    blocks = trimmed.reshape((N, M))

    mu = M / 2.0 + (9.0 + (-1.0) ** (M + 1)) / 36.0 - (M / 3.0 + 2.0 / 9.0) / (2.0 ** M)

    v = np.zeros(7, dtype=int)
    pi = [0.010417, 0.03125, 0.125, 0.5, 0.25, 0.0625, 0.020833]
    total_L = 0

    for block in blocks:
        L = berlekamp_massey(block)
        total_L += L
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

    p_value = float(gammaincc(3.0, chi_squared / 2.0))

    if debug:
        elapsed = time.perf_counter() - t0
        labels = [
            "T <= -2.5",
            "-2.5 < T <= -1.5",
            "-1.5 < T <= -0.5",
            "-0.5 < T <= 0.5",
            "0.5 < T <= 1.5",
            "1.5 < T <= 2.5",
            "T > 2.5",
        ]
        print(f"n={n}, N={N}, M={M}, mu={mu:.4f}, średnie L={total_L / N:.4f}", file=sys.stderr)
        for idx, label in enumerate(labels):
            expected = N * pi[idx]
            diff = v[idx] - expected
            print(f"  v[{idx}] ({label:<16}): v={v[idx]}, oczekiwane={expected:.2f} (różnica={diff:+.2f})", file=sys.stderr)
        print(f"chi2={chi_squared:.4f} (czas: {elapsed:.2f}s)", file=sys.stderr)

    return p_value


def main():
    if len(sys.argv) < 2:
        sys.exit(1)

    filename = sys.argv[1]
    if not os.path.exists(filename):
        sys.exit(1)

    try:
        with open(filename, "rb") as f:
            raw_data = f.read()
        if len(raw_data) == 0:
            sys.exit(1)

        bit_array = np.unpackbits(np.frombuffer(raw_data, dtype=np.uint8))
        p_val = linear_complexity_test(bit_array, M=500, debug=True)

        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception as exc:
        print(f"Błąd: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()