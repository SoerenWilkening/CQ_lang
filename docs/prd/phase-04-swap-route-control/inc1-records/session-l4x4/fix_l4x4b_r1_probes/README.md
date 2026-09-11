# Probes — l4x4.b ROUND-1 RULE-13 **FIX** (finding F-1)

Written by the FIX agent, 2026-09-11. Four of the ten `.c` files are the
reviewer's own reproducers, copied here so this directory stands alone; the rest
are the boundary members the fix needed and the review did not name.

## The binaries

Everything here is measured against **FROZEN COPIES**, never a live build tree
(the `IMPL_f2` §5b lesson: a relink makes `build/ir-pass/cq-opt` vanish for a
second and kills anything holding a path to it). Two pairs were frozen in
scratch:

* **`chk`** = the PRE-REVIEW checkpoint **267937d**, obtained by
  `git stash push -- ir-pass/src/ArmClassify.cpp`, rebuilding, copying
  `cq-opt` + `libCQPass.so` to scratch, then `git stash pop` and rebuilding.
  The restored source was `diff`-verified identical and the rebuilt binary
  `cmp`-verified identical to the pre-stash copy — **the build is deterministic
  here**, which is also what makes the later comment-only edits provably free.
* **`fix`** = this round's tree.

⚠ **Neither `main` 0c7380c nor the F2 base 578dbc4 can witness F-1** — they
decline every program below at `classifyArms`' first gate with `bare i1 register
condition`, a different string from a different layer. The checkpoint binary is
the only oracle for this finding, which is why it had to be reconstructed.

## The files

| probe | shape | chk (267937d) | fix |
|---|---|---|---|
| `x01_neg_inf_angle.c` | NEGATED rail arm, `+inf` | **rc 0** — `ry(h1,+inf); cry(h,h1,-inf)` | `rotation angle` |
| `x02_neg_nan_angle.c` | NEGATED rail arm, NaN | **rc 0** | `rotation angle` |
| `x03_neg_neginf_angle.c` | NEGATED rail arm, `-inf` | **rc 0** | `rotation angle` |
| `x06_prep_neg_inf.c` | NEGATED **STATE PREP**, `+inf` | **rc 0** — `ry(%h1,+inf); cry(%h,%h1,-inf)` | `rotation angle` |
| `n11_neg_runtime_angle.c` | NEGATED, RUN-TIME angle | rc 0, `fneg` | rc 0 — **decision (b)**, unmoved |
| `n12_neg_zero_angle.c` | NEGATED, `0.0` | rc 0 | rc 0, unmoved |
| `x04_negzero_angle.c` | NEGATED, `-0.0` | rc 0 | rc 0, unmoved |
| `x05_unneg_inf_angle.c` | **UN-**negated, `+inf` | rc 0 — ONE gate | rc 0, unmoved |
| `x07_prep_neg_finite.c` | NEGATED prep, `0.9` | rc 0 | rc 0, unmoved |
| `x01c_neg_inf_cmp.c` | `x01`'s COMPARE twin | rc 0 — `x(f); cry(f,h1,+inf); x(f)` | rc 0, unmoved |

**`x01c` is the reason F-1 is l4x4.b's own hole and not a pre-existing
disposition about non-finite angles**: the compare form brackets ONE gate, so its
non-firing branch is untouched. **`x05` is the reason the fence carries the
`Region.ArmNegated` conjunct**: un-negated, the rail form also emits one gate and
is equally faithful.

## The runners

* `probes_rerun.sh <dir>` — every single-TU `.c` in `<dir>` through `chk` and
  `fix`; prints only the rows that MOVED. An ACCEPTING row is compared by the
  **md5 of its lowered IR**, not by exit code alone, so an unchanged verdict over
  a changed circuit would still show.
* `probes_rerun_multi.sh <dir>` — the same for `*_caller.c` two-TU probes
  (`llvm-link`ed against `probes/impl/multi/w2_lib.c`).
* `sweep3p.py <a> <b>` — the whole-corpus three-way sweep (exit code, diagnostic
  string, lowered stdout) over every `*.ll` in `ir-pass/test`, parallel at 6
  workers. Keys: `oracle`, `f2`, `chk`, `fix`.
* `sweep_common.py <a> <b>` — the same restricted to the fixtures COMMON to both
  trees by NAME (`git ls-tree 578dbc4 ir-pass/test` ∩ disk). ⚠ A `git mv`'d
  fixture is simply ABSENT from that intersection — which is exactly why the
  implementer's sweep read **2 movers over 1784** and the reviewer's whole-tree
  sweep read **26 over 1810**. Both are right at their own denominator; the two
  renamed files must be compared BY CONTENT (`git show 578dbc4:<old path>`), which
  `FIX_l4x4b_R1.md` gate 4(c) does.

The scratch paths inside the two `.py` files are absolute (the frozen binaries
live outside the repo) — edit them, or re-freeze into the same scratch layout,
before re-running from a different session.

## Results (all recorded in `../FIX_l4x4b_R1.md` gates 4 and 5)

```
[chk -> fix] files=1818 RCDIFF=4 DIAGDIFF=0 OUTDIFF=0     <- the 4 new decline fixtures
[f2  -> fix] common=1782 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0    <- + the 2 renamed, by content
probes: 35 + 8 + 4 + 42 + 3 + 10  ->  MOVED only inside F-1's own class
```
