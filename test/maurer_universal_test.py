import sys
import os
import numpy as np
from scipy.special import erfc

def maurer_universal_test(bit_array):
    n = len(bit_array)
    
    if n < 387840:
        L = 6
        Q = 640
        K = 3840
        expected_value = 5.2177052
        variance = 2.954
    elif n < 904960:
        L = 7
        Q = 1280
        K = 5632
        expected_value = 6.1962507
        variance = 3.125
    elif n < 2068480:
        L = 8
        Q = 2560
        K = 10240
        expected_value = 7.1836656
        variance = 3.238
    elif n < 4654080:
        L = 9
        Q = 5120
        K = 19456
        expected_value = 8.1764248
        variance = 3.311
    elif n < 10342400:
        L = 10
        Q = 10240
        K = 30720
        expected_value = 9.1723243
        variance = 3.356
    elif n < 22753280:
        L = 11
        Q = 20480
        K = 61440
        expected_value = 10.170032
        variance = 3.384
    elif n < 49643520:
        L = 12
        Q = 40960
        K = 114688
        expected_value = 11.168765
        variance = 3.401
    elif n < 107560960:
        L = 13
        Q = 81920
        K = 208896
        expected_value = 12.168070
        variance = 3.410
    elif n < 231669760:
        L = 14
        Q = 163840
        K = 417792
        expected_value = 13.167693
        variance = 3.416
    elif n < 496435200:
        L = 15
        Q = 327680
        K = 835584
        expected_value = 14.167488
        variance = 3.419
    else:
        L = 16
        Q = 655360
        K = 1673216
        expected_value = 15.167379
        variance = 3.421

    total_blocks = Q + K
    if n < total_blocks * L:
        return 0.0

    bit_string = "".join(str(b) for b in bit_array[:total_blocks * L])
    
    table = {}
    for i in range(Q):
        block = bit_string[i * L : (i + 1) * L]
        val = int(block, 2)
        table[val] = i + 1

    sum_val = 0.0
    for i in range(Q, Q + K):
        block = bit_string[i * L : (i + 1) * L]
        val = int(block, 2)
        last_seen = table.get(val, 0)
        sum_val += np.log2((i + 1) - last_seen)
        table[val] = i + 1

    fn = sum_val / K
    c = 0.7 - 0.8 / L + (4.0 + 32.0 / L) * (K ** (-3.0 / L)) / 15.0
    sigma = c * np.sqrt(variance / K)
    
    stat = abs((fn - expected_value) / (np.sqrt(2) * sigma))
    p_value = erfc(stat)
    
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
        p_val = maurer_universal_test(bit_array)
        
        print(f"{p_val:.5f}")
        sys.exit(0)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()