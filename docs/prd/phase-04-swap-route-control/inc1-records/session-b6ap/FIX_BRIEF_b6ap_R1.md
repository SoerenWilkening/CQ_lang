# Fix brief — bd `b6ap` (multi-phi merge peel), after round-1 Rule-13 review `review_b6ap_r1.md` (verdict BLOCK)

Worktree `/Users/sorenwilkening/Desktop/CQ_b6ap`, branch `merge-phi-peel`. Read `review_b6ap_r1.md` in
full, then `IMPL_b6ap.md`, `SCOPE_b6ap.md` §2/§8/§9, `BRIEF_b6ap.md`, the reviewer's probes
(`review_b6ap_r1_probes/`, `ab.sh`, README). You are the FIX agent (opus). Do NOT commit/push; never write
under `/Users/sorenwilkening/Desktop/CQ_lang/` or the other worktrees; ORACLE
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` + `libCQPass.so`. Report only what you ran.
Read CLAUDE.md's two standing lessons first: "a stage that runs ONCE has a round-2-FALSE premise" is
EXACTLY this finding, one stage over — the peel is a taint-growth event and the stages that adjudicate
consumers of tainted values had already run.

## F-B6-1 — CONFIRMED SILENT MISCOMPILE (the BLOCKER; fix first)

The peel grows `taint.Tainted` at `CQLoweringPass.cpp:416` (and `:887`), but `detectSpecializations`
(`:321`), `declineTaintEscapes` (`:330`) and `declineStaleRecordOps` (`:337`) ran BEFORE it and are not
re-asked, so a consumer of the newly-tainted select escapes: `r20_clone_measured.c` calls the untouched
classical `@helper` with the quantum rail HANDLE and measures `handle+1`; `r04`/`r11` store the handle
tag to a global/array and print `4`; `r07` prints `g=5`; `r02` hands `%out` to an unknown callee — all
plain C `-O1`, exit 0, verify-clean, STRICT 2b clean, and every hand-peeled twin lowers correctly or
declines loudly on both binaries (the increment's own contract, falsified). The ROUND-2 site is covered
because `repropagateControlMerges` re-runs `replanReseedSpecialization` + `declineTaintEscapes` after
ITS taint growth; the two ROUND-1 sites are the hole.

Two candidate fixes — MEASURE both against the stage table before choosing, and write the argument in
`FIX_b6ap_R1.md`:
(a) MOVE the round-1 peel EARLIER: immediately after the PredMux fixpoint (`:250`) and BEFORE
    `detectSpecializations` (`:321`), so every consumer guard sees the peeled selects as ordinary tainted
    instructions. Check what runs between `:250` and `:416` and whether the peel needs any of it
    (LoopInfo/DT freshness, the `CtlzIdiomPrepass`, `LoopUnrollPrepass`, the by-ref math stage, anything
    that erases/creates merges); check that a peeled select inside a function that `detectSpecializations`
    then CLONES is handled (the clone copies the select; `cloneTaint` must include it) — the reviewer's
    clone probes are the test.
(b) KEEP the position and RE-RUN the consumer guards after the peel, in the ORDER the round-2 path uses
    (`replanReseedSpecialization`, `declineTaintEscapes`, `declineStaleRecordOps` — read
    `repropagateControlMerges` and call the SAME functions, never a second spelling).
Prefer (a) if the stage table allows it — it removes a once-only premise instead of patching it — and say
in the record which stages between the old and new position you re-asked in writing (the NOTES §2
table method). Whichever you choose: the five reproducers become DECLINE fixtures with the escape strings
the oracle gives their hand-peeled twins (`r20`→ the specialisation/escape string of `r23`'s oracle run;
`r04`/`r11`/`r07`/`r02` → `declineTaintEscapes`'s strings), plus their hand-peeled twins as ACCEPT
controls where the oracle lowers them; a `probes/` entry for each with both TUs where two.

## F-B6-2 — LEAK / new accept unprobed: `classifyGuardedStoreArm` + an all-peelable merge

`g01`: the guarded-store arm's merge becomes all-peelable, the region flips `guarded store with a merge
value` → accept, and the ENTIRE 7.5 Shadow reversal stops running (no `qram_load_unc`, no
`qram_store_controlled_unc`, no strip/free of the path-predicate flag, no `ry` inverses; 10 mints / 10 left
allocated); control `g02` (same, no merge φ) runs the full reversal on the oracle. Rule-6-safe direction
but a 10-rail leak on a shipped shape. FENCE IT (decline-keeping): do not peel a merge whose region arm
contains a guarded store (ask `classifyGuardedStoreArm`'s own recogniser, or refuse when any arm
instruction is a `StoreInst`/QRAM marker — one spelling, reuse), so `g01` keeps its `guarded store with a
merge value` decline; pin `g01` (decline) and `g02` (accept, unchanged). If you believe the reversal
SHOULD run instead, do not build that here — write it as an open question.

## DOC — D1's reason and P3b `freeze`

Measured `d01` (one-φ angle tail) vs `d02` (angle tail + data mux, both peeled): identical relative
phases — peeling an angle-tail φ is NOT a wire-crossing. D1's real reason is that on a ONE-φ merge the
stage cannot tell the angle tail from the region's own value φ. Rewrite the comment in
`MergePhiPeel.cpp` and IMPL §2 / §7 Q1 accordingly. `freeze i32 poison` IS peeled (`x03`) and is sound
(single-valued — what `LiteralIntegrity` guard 1 counts); `poison` itself is refused (`x02`): one line in
the predicate's comment and a fixture for each.

## Matrix rows — ruling: KEEP `UNROLLED-ONLY` (the reviewer re-derived `m_rz_eq_rz` from the generator's
own sources: relative phase `c=1 → 2π`, `c=0 → 0`, the source's unitary; the rolled side is a
pre-existing rolled-side over-decline, the established class of 63 sibling cells). Add the reviewer's
caveat to the matrix header block: the peel is a second, non-obvious customer-generator for the
angle-select path, whose accept class is narrower than the data path's.

## Gates, in order

`lit --filter` → `ctest -R ir-pass-lit` → `ctest -j6 -R '^e2e-'` + `git status --porcelain tests/` → the
corpus diff over the 1776 (accept-monotone: only the listed DECLINE→ACCEPT movers; F-B6-1's fix must not
add ACCEPTs — the five reproducers now DECLINE) → re-run `review_b6ap_r1_probes/ab.sh` and the
implementer's `probes/` with every verdict listed (the five reproducers DECLINE; `g01` DECLINE; `g02`
ACCEPT; the 9 accept fixtures unchanged) → full `ctest -j6` ONCE (never relink under a running
measurement; never `pkill` by pattern) → `cq-opt-equivalence-full` if any string moved. Append
`FIX_b6ap_R1.md`: per finding → change (file:line) → fixtures → measurements; the stage-table argument
for the chosen position; round-2 open questions.

Final message ≤30 lines: per finding one line (what, where, measured), the position chosen and why, the
gate lines verbatim, movers, open questions.
