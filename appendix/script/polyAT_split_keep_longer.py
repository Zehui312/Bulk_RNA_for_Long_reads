#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
polyAT_split_keep_longer.py

Goal
----
For each FASTQ read:
1) Search for a poly-A or poly-T run (A{min_run,} or T{min_run,}) anywhere in the read.
2) If found, split the read into LEFT and RIGHT fragments around that run.
3) Keep the longer fragment (tie -> keep LEFT by default).
4) Repeat the same search+split+keep on the remaining fragment for a fixed number of rounds
   (default: 2 rounds), stopping early if no match is found.

Quality strings are trimmed in sync with the sequence.
Supports FASTQ and FASTQ.GZ.
"""

import re
import sys
import gzip
import argparse
from typing import Tuple, Iterator


def opengz(path: str, mode: str = "rt"):
    """Open plain text or gzipped text file based on filename extension."""
    if path.endswith(".gz"):
        return gzip.open(path, mode)
    return open(path, mode)


def fastq_iter(handle) -> Iterator[Tuple[str, str, str, str]]:
    """
    Iterate over FASTQ records from a text stream.

    Yields:
        (header, seq, plus_line, qual)

    FASTQ format (4 lines per record):
        @read_id
        SEQUENCE
        +
        QUALITY
    """
    while True:
        header = handle.readline()
        if not header:
            return  # EOF
        seq = handle.readline()
        plus = handle.readline()
        qual = handle.readline()
        if not qual:
            raise ValueError("Incomplete FASTQ record at end of file (file may be truncated).")

        yield header.rstrip("\n"), seq.rstrip("\n"), plus.rstrip("\n"), qual.rstrip("\n")


def split_keep_longer(seq: str, qual: str, m: re.Match) -> Tuple[str, str]:
    """
    Split seq/qual by the matched region and keep the longer fragment.

    The match spans [start:end] in the sequence.
    LEFT fragment  = seq[:start]
    RIGHT fragment = seq[end:]

    Returns:
        (kept_seq, kept_qual)

    Tie-breaking:
        If lengths are equal, keep LEFT by default.
    """
    start, end = m.start(), m.end()

    left_seq = seq[:start]
    right_seq = seq[end:]

    left_qual = qual[:start]
    right_qual = qual[end:]

    # Keep the longer fragment. If equal, keep left.
    if len(right_seq) > len(left_seq):
        return right_seq, right_qual
    else:
        return left_seq, left_qual


def trim_polyAT_rounds(
    seq: str,
    qual: str,
    pattern: re.Pattern,
    rounds: int = 2,
    min_len: int = 0,
) -> Tuple[str, str, int]:
    """
    Apply "find polyA/polyT -> split -> keep longer" iteratively.

    Args:
        seq, qual: input read sequence and quality string
        pattern: compiled regex for polyA/polyT, e.g. (A{12,}|T{12,})
        rounds: maximum number of iterations (default 2)
        min_len: if >0, enforce minimum kept fragment length;
                 if kept fragment becomes shorter than min_len, set read to empty.

    Returns:
        (new_seq, new_qual, cuts_done)

    Notes:
        - We always take the FIRST match found by regex.search().
        - We stop early if no match is found.
    """
    cuts = 0

    for _ in range(rounds):
        m = pattern.search(seq)
        if not m:
            break  # no more polyA/polyT run found

        # split around the match and keep longer fragment
        seq, qual = split_keep_longer(seq, qual, m)
        cuts += 1

        # If requested, drop fragments that are too short
        if min_len and len(seq) < min_len:
            seq, qual = "", ""
            break

    return seq, qual, cuts


def main():
    parser = argparse.ArgumentParser(
        description="Find polyA/polyT runs, split reads, keep the longer fragment, repeat for N rounds."
    )
    parser.add_argument("-i", "--input", required=True, help="Input FASTQ/FASTQ.GZ")
    parser.add_argument("-o", "--output", required=True, help="Output FASTQ/FASTQ.GZ")

    parser.add_argument(
        "--min-run",
        type=int,
        default=12,
        help="Minimum run length for polyA/polyT to be considered (default: 12).",
    )
    parser.add_argument(
        "--rounds",
        type=int,
        default=2,
        help="Maximum number of split/keep iterations per read (default: 2).",
    )
    parser.add_argument(
        "--min-len",
        type=int,
        default=0,
        help="Minimum length of the kept fragment; if below, read becomes empty (default: 0 = no limit).",
    )
    parser.add_argument(
        "--drop-empty",
        action="store_true",
        help="Drop reads that become empty after processing.",
    )
    args = parser.parse_args()

    if args.min_run < 1:
        parser.error("--min-run must be >= 1")
    if args.rounds < 1:
        parser.error("--rounds must be >= 1")

    # Regex to match polyA or polyT runs anywhere in the read
    # Example: min_run=12 -> (A{12,}|T{12,})
    pattern = re.compile(rf"(A{{{args.min_run},}}|T{{{args.min_run},}})")

    # Basic counters for a quick summary
    total = kept = dropped = 0
    cut0 = cut1 = cut2plus = 0

    with opengz(args.input, "rt") as fin, opengz(args.output, "wt") as fout:
        for header, seq, plus, qual in fastq_iter(fin):
            total += 1

            # FASTQ requires seq and qual to have the same length
            if len(seq) != len(qual):
                raise ValueError(f"Sequence and quality lengths differ for read: {header}")

            new_seq, new_qual, cuts = trim_polyAT_rounds(
                seq, qual, pattern, rounds=args.rounds, min_len=args.min_len
            )

            # Update stats
            if cuts == 0:
                cut0 += 1
            elif cuts == 1:
                cut1 += 1
            else:
                cut2plus += 1

            # Optionally drop empty reads
            if args.drop_empty and len(new_seq) == 0:
                dropped += 1
                continue

            kept += 1

            # Write FASTQ record back out
            fout.write(f"{header}\n{new_seq}\n{plus}\n{new_qual}\n")

    # Print summary to stderr (so stdout stays clean if you redirect output)
    sys.stderr.write(
        "[Done]\n"
        f"  Total reads:   {total}\n"
        f"  Kept reads:    {kept}\n"
        f"  Dropped empty: {dropped}\n"
        f"  Cuts=0:        {cut0}\n"
        f"  Cuts=1:        {cut1}\n"
        f"  Cuts>=2:       {cut2plus}\n"
        f"  Params: min_run={args.min_run}, rounds={args.rounds}, min_len={args.min_len}\n"
    )


if __name__ == "__main__":
    main()
