#!/usr/bin/env python3
"""Measure the test-corpus size at every commit of a git range, straight from
`git ls-tree` / `git show` -- never from a doc, never hand-typed.

Written for a session that lands several increments in one day, where
`corpus_growth.py` (one row per commit DATE) collapses them all into one point.
This is its per-commit sibling.

Writes a pgfplots-readable table:

    idx  commit  fixtures  goldens  addtests

  fixtures = ir-pass/test/*.ll                  (the lit corpus)
  goldens  = tests/e2e/*.expected.log           (the e2e byte-diff baselines)
  addtests = add_test( lines in tests/e2e/CMakeLists.txt

Row 0 is the range's BASE (the commit before the first landing), so a plot of
this table shows the session's own deltas. The commit subject of each row is
printed to stdout for the author to read; it is deliberately NOT in the table,
so no prose can drift into the data file.

Usage:

    tools/labreport/figures/session_landings.py docs/labreport/figures/NNN/session_landings.dat 0c7380c..HEAD

Lab-report figures are sealed with their session (docs/labreport/README.md), so
each session regenerates into its OWN figures/NNN/ dir.
"""
import subprocess
import sys


def git(*args: str) -> str:
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def count_suffix(commit: str, path: str, suffix: str) -> int:
    names = git("ls-tree", "-r", "--name-only", commit, "--", path).splitlines()
    return sum(1 for n in names if n.endswith(suffix))


def count_add_tests(commit: str) -> int:
    try:
        body = git("show", f"{commit}:tests/e2e/CMakeLists.txt")
    except subprocess.CalledProcessError:
        return 0
    return sum(1 for line in body.splitlines() if line.lstrip().startswith("add_test("))


def main() -> int:
    if len(sys.argv) != 3 or ".." not in sys.argv[2]:
        print(__doc__, file=sys.stderr)
        return 2
    out, rng = sys.argv[1], sys.argv[2]
    base, _, head = rng.partition("..")
    base = git("rev-parse", "--short", base).strip()
    commits = [base] + [
        c for c in git("rev-list", "--reverse", rng, "--abbrev-commit").splitlines() if c
    ]
    rows = []
    for i, c in enumerate(commits):
        rows.append(
            (
                i,
                c,
                count_suffix(c, "ir-pass/test", ".ll"),
                count_suffix(c, "tests/e2e", ".expected.log"),
                count_add_tests(c),
            )
        )
    with open(out, "w") as f:
        f.write("idx commit fixtures goldens addtests\n")
        for r in rows:
            f.write("%d %s %d %d %d\n" % r)
    for i, c, n, g, a in rows:
        subject = git("log", "-1", "--format=%s", c).strip()
        print(f"{i} {c} fixtures={n} goldens={g} add_test={a}  {subject[:90]}")
    print(f"{len(rows)} rows -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
