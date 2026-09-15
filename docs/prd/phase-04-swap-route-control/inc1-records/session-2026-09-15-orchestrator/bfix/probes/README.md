# BFIX probes — the fix agent's set (session 2026-09-15)

`run4.sh <probe>.c`, from any directory. Stage 1 (`clang -O1 -g`), then the SAME
stage-1 module through **FOUR** `cq-opt` binaries, and on exit 0 through stage 2b
+ link + run:

| label | worktree | `cq-opt` sha256 (16) |
|---|---|---|
| ORACLE | `/Users/sorenwilkening/Desktop/CQ_lang` (`main` `74eabd2c`) | `0e280fc62a91cec2` |
| BASE_A | `/Users/sorenwilkening/Desktop/CQ_A` (`railbank-blockers` `9e11f524`) | `b655493561683546` |
| SUBJ_B | `/Users/sorenwilkening/Desktop/CQ_B` (`railbank-accept` `3b982459`) | `784c14fa05c16c50` |
| **FIX** | `/Users/sorenwilkening/Desktop/CQ_BFIX` (`railbank-fix`) | `fd310f8037fb8f48` |

SUBJ_B is **the reviewed binary**, i.e. the BEFORE for the P1. `CQ_FIX_ROOT=/nonexistent`
runs the three pre-fix binaries only and prints `NO-BINARY (absence, not a
result)` for the fourth — used to take the BEFORE column while the fix was still
building, because **a binary that does not exist is an ABSENCE, not a pass.**

The reviewer's vacuity guard is carried verbatim (≥1 `define` and ≥1 `@cq_` call
in the stage-1 module, `unreachable` count printed): a 0-byte `.ll` ACCEPTS
through the passthrough early-out (bd memory `empty-module-accepts-vacuity-trap`)
and a UB body collapses to a bare `unreachable` that also "accepts".

## What is here

* `a0*`, `b0*`, `c0*`, `d0*`, `e0*`, `f0[1-7]`, `g0*`, `h0*`, `i0*` — the **33
  reviewer probes**, copied verbatim from `review_r13_railbank/probes/`.
* `o01`–`o05` — **THE OWNER'S CAPABILITY**, added after the constraint relayed
  2026-09-15: a DISTINCT THETA PER CELL, minted inside the walk loop. `o04` is
  the load-bearing one (a genuine non-diagonal gate between the loops, on another
  register). `o03` is the owner's inner loop VERBATIM and is the DEFERRED
  capability: it declines at DECISIONS.md E5 **wall 3**, which is bank-independent.
* `f08`–`f15` — **the fix agent's RE-ATTACK** (Rule 13: *a fix introduces new
  holes*). See `../FIX.md` §7.

## Measured results this set carries

* the P1 (`f01`, `i02`) ACCEPT on SUBJ_B and DECLINE on FIX; everything else in
  the 38-probe reviewer+owner set is **identical in verdict AND string**, and the
  17 probes accepting on both have **byte-identical traces**.
* `o03` DECLINES with the SAME STRING and the SAME ANCHOR on all four binaries.
  With `CQ_STALEBANK_DBG=1` the hop is seen firing on it — seed
  `%cq.bank1 = phi i1 [ %26, %25 ], [ false, %21 ]`, PASS G's manufactured phi —
  and finding no staling gate, so **this fence is not a second wall behind wall 3**.

## What these probes do NOT cover

Stated so absence is not read as clearance:

* **a `_Bool`-cell STALE bank is not constructible at the `-O1` floor.** `f08`/`f09`
  were written for it and measured: `clang` turns an invariant `_Bool` park into
  an `llvm.memset` and the module dies at `tainted value consumed by an unknown
  callee` on all four binaries. So the `TruncInst` arm of `railBankParkedRails`
  has **no stale subject today** and is pinned by mutant M13 rather than by a
  fixture.
* a bank cell load consumed by `freeze` or by `cq_invert_*` is still unprobed —
  inherited from the reviewer's own "what these probes do NOT cover", and not
  closed here.
* `g03_bank_plus_dead_terminal.c` still measures nothing it was written for
  (`-O1` folds `(d & 0)`), and is kept for the same reason the reviewer kept it.
* every probe is ONE FUNCTION PER MODULE except `i01`/`i02`/`f0[1,2,5-15]`'s
  `slice`+`main` pair — bd `1yeu`'s structural gap applies here as everywhere.
