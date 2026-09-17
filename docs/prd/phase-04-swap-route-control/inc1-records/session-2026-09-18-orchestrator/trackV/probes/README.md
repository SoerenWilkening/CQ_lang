# probes — provenance, so no file here is read as somebody else's measurement

Every `*_9bd01598.*` artifact was produced on this track's worktree binary, whose `cq-opt` sha256 is
`9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` — **bit-identical to the session
ORACLE**, so each is a fact about `main`'s own compiler and not about a subject build. There is no
subject build: this track changed `tools/` only.

## Carried from another track, with its change named

* **`source_identity.py`** — from `$PREV/trackI/probes/source_identity.py` (bd `rpkr`, the BANK
  axis). ONE change: the module under test is given by `--tools <DIR>`, so the BASELINE can be read
  from `main`'s `tools/` directly instead of being dumped from a copy before editing. That removes
  the one way the discipline can go wrong — a baseline taken from an already-edited file.
  `source_identity_baseline_main.tsv` is that baseline, 718 cell/surface pairs, from
  `/Users/sorenwilkening/Desktop/Projects/CQ_lang/tools`.

## Written by this track

* **`nest_cells_only.py`** — the implementer's inner loop: stubs `cells_of_matrix()` to
  `nest_cells()` and calls `main()`, so the 23 new cells' verdicts come out of the SAME code path
  the gate uses rather than a second spelling of it. ⚠ Its `if __name__` guard is load-bearing and
  its absence was a measured failure (`BrokenProcessPool` in 1.5 s, zero cells) — macOS Python 3.11
  SPAWNs pool children, which re-import the parent's `__main__`. `nest_expected_stub.txt` is the
  marker-carrying empty table it points `--expected` at, so it can never touch the committed one.
  Output: `nest_verdicts_9bd01598.tsv`.
* **`nest_diverge_detail.py`** — the eight diverging cells in full: digest, first differing line
  pair, per-side `(_unc, cqrt_free, mint)` counts and the whole unified diff. A quarantine block may
  never be written from a REMEMBERED signature (`IMPL_T2` §9), so this is the evidence each block's
  `reason` was written from. Output: `nest_divergences_9bd01598.txt`.
* **`attribution.py`** — IS THE DIVERGENCE ABOUT THE NESTING? Five programs built through `_wrap`
  exactly as a cell is, each removing one half. It is what turns "class D needs both loops" from a
  reading into a measurement, and it is what measured class E as NOT needing them. ⚠ Its
  `single_iic_loop` row was `HARNESS-ERROR` in its first spelling — a bare `int u = …` at body level
  is a REDECLARATION on the dedented twin — and the comment recording that is kept rather than the
  defect quietly fixed. Output: `attribution_9bd01598.txt`.
* **`seed_fidelity.py`** — the normalised diff between each generated cell and the committed
  `$PREV/loopfix/probes/` probe it was seeded from. Not a gate: the evidence for `IMPL_V.md` §2's
  statement that byte identity was NOT reached and that the committed probe is the tie-breaker.
* **`mutants.py`** — the L10 obligation: thirteen literal source edits to a COPY of
  `tools/loop_twin_matrix.py` (M13 edits the committed quarantine instead), each run through the
  UNMODIFIED selftest by the same command the ctest entry runs. **13 applied, 13 CAUGHT, 0 MISSED,
  0 NOT-APPLIED** (`mutants_9bd01598.txt`). ⚠ It reports a non-applying edit as `NOT-APPLIED` and
  counts it as a HOLE, and it REFUSES to run with zero mutants — `0 mutations, MISSED 0` is the
  shape of a harness with no subject, not a pass.

## What these files are NOT

None of them is a ctest gate and none is a compiler measurement. The compiler here is `main`'s,
unchanged; what is being measured is an INSTRUMENT. The gates are
`e2e-loop-twin-matrix` and `e2e-loop-twin-quarantine-selftest`, and their lines are in `../GATES.md`.
