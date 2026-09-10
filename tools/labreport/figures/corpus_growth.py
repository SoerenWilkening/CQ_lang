#!/usr/bin/env python3
"""Measure the lit-fixture and e2e-golden corpus size at the last commit of every
commit date in `git log`, straight from `git ls-tree` -- never from a doc.

Writes a pgfplots-readable table:

    date        commit  fixtures  goldens

one row per distinct author date (the last commit of that day). Usage:

    tools/labreport/figures/corpus_growth.py docs/labreport/figures/NNN/corpus_growth.dat

Lab-report figures are sealed with their session (docs/labreport/README.md), so
each session that wants this plot regenerates it into its OWN figures/NNN/ dir.
"""
import subprocess
import sys


def git(*args: str) -> str:
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def count(commit: str, path: str, suffix: str) -> int:
    names = git("ls-tree", "-r", "--name-only", commit, "--", path).splitlines()
    return sum(1 for n in names if n.endswith(suffix))


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    out = sys.argv[1]
    dates = sorted(set(git("log", "--format=%ad", "--date=short").splitlines()))
    rows = []
    for d in dates:
        c = git("log", "-1", f"--before={d} 23:59:59", "--format=%h").strip()
        rows.append((d, c, count(c, "ir-pass/test", ".ll"), count(c, "tests/e2e", ".expected.log")))
    with open(out, "w") as f:
        f.write("date commit fixtures goldens\n")
        for d, c, n, g in rows:
            f.write(f"{d} {c} {n} {g}\n")
    print(f"{len(rows)} rows -> {out}; last: {rows[-1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
