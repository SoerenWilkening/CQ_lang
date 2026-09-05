# BRIEF_impl_inc2 — bd test_C_libtooling-3qlq.3: Inc 2 — value arms by controlled-copy merge; retire the value-arm cswap route
Read `$SP/briefs/BRIEF_common.md` first, then PRD §3 ("Value arm by controlled copy"), §5,
§7 (all of it), §10.3 item 8, §11. Agent name: `impl_inc2`. Model: opus.

## Where you work
Worktree `$SP/wt/inc2`, branch `3qlq-inc2`, created from `main` (dfb8e83) — ALREADY CREATED. You will REBASE onto Inc 1's branch later, so keep your commits small and file-local. Configure + build
in the background (~5–7 min). Inc 2 is INDEPENDENT of Inc 1 in mechanism (its witness is the
`?:` select twin through the Rule-13-cleared `SelectMergeEmit`), but overlaps it in
`SwapRouteEmit.cpp` / `ArmClassify.cpp` — keep your edits to the VALUE path
(`emitValueRegion`, SwapRouteEmit.cpp:246; `walkValueChain` ArmClassify.cpp:1394;
`valueArmIsPureChain` :1446; `SwitchValueEmit.cpp`) and do not touch the phase/rotation
paths.

## Step 0 — compile the twin FIRST (bd memory drbq-inc3-compile-the-twin-first)
`tests/e2e/slice_control_value_diamond.c` is the shipped customer:
`if (q > 5) { p = p+3; p = p*5; p = p^9; p = p+1; p = p*7; p = p^2; }`. Write its `?:` twin
with `R` as a `static inline` function so the chain is straight-line:
`p = (q > 5) ? R(p) : p;` — compile at `-O1` on the ORACLE and READ what arrives: a `select`
on `p` (→ `SelectMergeEmit`, the 4.4 controlled-XOR copy merge) or a diamond (SimplifyCFG's
speculation cost threshold)? Do the same for a one-op arm and for if/else arms (`R1`/`R2`).
Record the -O1 shapes and the ORACLE traces for each in the progress file BEFORE touching
the pass. If the six-op `?:` twin does NOT arrive as a select at -O1, the byte-identity
witness must be built differently (e.g. hand IR with the select) — say so, do not hide it.

## The replacement (PRD §7.1–7.2), per arm
Today (oracle, `slice_control_value_diamond.expected.log`): `alloc w; cswap(f,p,w); 6 ops on
w; cswap(f,p,h9); alloc out; copy(p,out); cswap; 6 _unc; cswap; free w; strip; free f`.
After: hoist the arm's pure out-of-place chain to the pred on the ORIGINAL `p`
(unconditionally: `6 ops on p → h9`); `alloc out (|0>)`; `cqrt_copy_<W>_controlled(f, h9,
out)`; `cqrt_x(f)`; `cqrt_copy_<W>_controlled(f, p, out)`; `cqrt_x(f)`; the chain's `_unc`
(a function of the unchanged `p`) in LIFO; strip f; free f. `out` is the merge value; `p`
stays allocated and entangled with `out` (keep-source-live — exactly as the route left it;
freeing p is follow-on 3qlq.5). The `cqrt_copy_<W>_controlled` symbols EXIST (minted by
`ControlledSymbols::copyControlledFn` for 4.4/6.5) — no new symbol.
V1 flat diamond incl. DERIVED bases; V2 if/else (both chains hoisted; `out ^= f?R1(p):0;
out ^= ¬f?R2(p):0`); V3 switch homogeneous value (`SwitchValueEmit`): preload `copy(p,out)`,
per case `d_i = R_i(p) ^ p` (QQ xor), `copy_controlled(f_i, d_i, out)`, uncompute d_i and
R_i — the 4.5 data-mux "preload + XOR-delta" precedent, no conjunction flag; ASSERT (never
silently accept) that case values are pairwise distinct (switch semantics guarantee it).
`cqrt_cswap` is then minted ONLY by `AbortParkEmit` — grep the tree and prove it.

## Preconditions that stay (PRD §7.3) — and the lens-8 hazards you must fence up front
- §3c clobber: the arm rewrites a register the condition reads → decline (existing string).
  UNDER THE HOIST the hazard is sharper: the hoisted chain runs UNCONDITIONALLY on `p`, so
  if the CONDITION reads `p` (e.g. `if (p > 5) p = p*3`), the out-of-place chain on p is
  fine (p unchanged) — but an IN-PLACE dtzb op (`cqrt_addc/xorc` on p's rail, M-C) would
  relabel the condition's operand before the strip. Decide: the hoisted chain must be
  OUT-OF-PLACE only (fresh rails), never in place — pin it.
- Speculation TOTALITY: every arm op is a pure TOTAL template. `sdiv`/`srem`/`udiv`/`urem`
  by a TAINTED divisor that is zero on the inactive branch: the template must be total (what
  does `cq_template_sdiv_*` do at zero? read `runtime/cq_templates.c` — it is generated;
  read the YAML). If any arm opcode is not total (division by a possibly-zero tainted
  operand, a shift by ≥ W, a `fdiv` producing inf/NaN — NaN is a label, so a permutation
  template is still total; say so per opcode), DECLINE it under the hoist with its own string
  and fixture. Arm ops restricted to the pure template set (no calls, no memory, no `cq_*`).
- In-loop value arms keep the loop decline (follow-on .6); mixed arms decline.
- The FreePoint/whole-DAG spine must treat `out` as the merge register and the hoisted
  chain's intermediates as dischargeable at the region — check `railCarriesControlledRotation`
  / freeze logic is NOT triggered (no controlled rotation here) and that
  `free_pairing_check.py` STRICT is clean on every slice.

## Fixtures + slices + witness
Red-green per Rule 12 for V1/V2/V3 (accept fixtures with whole-file negatives: NO
`cqrt_cswap`, NO work-rail `cqrt_alloc_<W>(0)` other than `out`; counts in their own prefix)
and each decline. The existing value fixtures (`control_swap_value_*.ll`, `control_switch_*value*.ll`,
227 files mention `cqrt_cswap`, most in prose/declines) — re-derive CHECKs from the pass
output, never hand-edit; handle names from the output. Goldens: regenerate
`slice_control_value_diamond`, `slice_control_switch_value` (the 2 non-abort non-phase
cswap goldens at HEAD) and audit the diff by hand in the progress file (old stream vs new
stream, line by line). New slices + `cmp` twin gates: `slice_control_value_diamond_twin.c`
(`?:`), `slice_control_value_oneop{,_twin}.c`, `slice_control_value_ifelse{,_twin}.c` —
BYTE IDENTITY between diamond and select twin is the witness (≥3 pairs).

## Hand-back
Per BRIEF_common: files, commits, measured counts, the three twin byte-identity results
(with `cmp` output), the cswap census (`grep -rn cqrt_cswap ir-pass/src` → AbortParkEmit
only), the totality decision per opcode, red partition of ir-pass-lit, OWNER QUESTIONS.
