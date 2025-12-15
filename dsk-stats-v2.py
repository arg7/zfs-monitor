#!/usr/bin/env python3
import sys
import argparse

BLOCK_SIZE = 512
WINDOW_SIZE = 64 * 1024  # 64 KiB

def is_header_line(parts):
    try:
        float(parts[0])
        return False
    except (ValueError, IndexError):
        return True

def main():
    parser = argparse.ArgumentParser(description='Count disk ops adjacent within 64K and sum bytes.')
    parser.add_argument('-f', '--filter-type', help='Filter by TYPE (e.g., R, W, WSM)')
    args = parser.parse_args()

    ops = []  # list of (start, end, bytes)

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) < 8:
            continue
        if is_header_line(parts):
            continue

        try:
            typ = parts[3]
            if args.filter_type and typ != args.filter_type:
                continue

            block = int(parts[5])
            nbytes = int(parts[6])
            start = block * BLOCK_SIZE
            end = start + nbytes
            ops.append((start, end, nbytes))
        except (ValueError, IndexError):
            continue

    if not ops:
        print("No valid operations found.", file=sys.stderr)
        return

    # Sort by start offset
    ops.sort(key=lambda x: x[0])

    total_bytes = sum(op[2] for op in ops)
    adjacent_bytes = 0
    adjacent_count = 0
    window_start_idx = 0

    for i in range(1, len(ops)):
        curr_start, _, curr_bytes = ops[i]
        # Slide window start forward until within 64K
        while window_start_idx < i:
            _, prev_end, _ = ops[window_start_idx]
            if prev_end < curr_start - WINDOW_SIZE:
                window_start_idx += 1
            else:
                break
        if window_start_idx < i:
            adjacent_count += 1
            adjacent_bytes += curr_bytes

    print(f"Filter: {'any' if not args.filter_type else repr(args.filter_type)}")
    print(f"Total operations: {len(ops)}")
    print(f"Total bytes: {total_bytes}")
    print(f"Adjacent operations (within 64K of prior): {adjacent_count}")
    print(f"Adjacent bytes: {adjacent_bytes}")

if __name__ == '__main__':
    main()

