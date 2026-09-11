# Rule-13 INTEGRATION review brief — the four landed tracks as ONE binary (session 2026-09-11)

Tree under review: `main` at the hash the orchestrator gives you (A.1 7203d1c → b6ap 3a3a2b9 → F2 a9cc062
→ l4x4.b, the last squash), built in `/Users/sorenwilkening/Desktop/CQ_l4x4/build/` (the l4x4.b worktree
after its second merge is BYTE-IDENTICAL in source to the landed main — verify with `git diff main
l4x4b-bool-ry-arm --stat -- ir-pass include runtime tests tools` = empty, else stop and report). Do NOT
rebuild; do NOT edit `ir-pass/`, `include/`, `tests/`, `tools/` anywhere. ORACLE (pre-session):
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` + `libCQPass.so` at 0c7380c (read-only; it
is rebuilt only after you report).

Each track was reviewed on its own (A.1: BLOCK→fixed→CLEAR-WITH-ITEMS→applied; b6ap: BLOCK→fixed→
CLEAR-WITH-ITEMS→applied; F2: CLEAR-WITH-ITEMS→applied; l4x4.b: CLEAR-WITH-ITEMS→applied) and each merge
re-ran every corpus with 0 unexplained movers. What NOBODY has reviewed is the COMBINATION as a
capability: the owner's `example/grover/grover_oracle_uncompute.c` compiles ONLY because the peel (b6ap)
hands a rail-conditioned NEGATED state prep (l4x4.b) to a classifier whose F2 (Track C) no longer collides
on the rail, under fences A.1 added. Read, in order: `inc1-records/session-2026-09-11-orchestrator/
LANDING_PLAN.md`; `session-l4x4/MERGE_l4x4_1.md` (the first end-to-end trace, 19 lines, with its
line-by-line reading) and `MERGE_l4x4_2.md`; `session-b6ap/IMPL_b6ap.md` §2c (stage table) + §2d;
`session-9pum/FIX_A1_R2.md` (the WireRuled bit table); `session-f2-i1/IMPL_f2.md` §1; CLAUDE.md's
CORRECTNESS-RISK section (the two standing lessons + the taint-growth species in bd memory
`taint-growth-after-consumer-guards-b6ap`).

## Attack the COMBINATION (over-accept is the only unforgivable bug)

1. **The owner's file and its neighbourhood.** Re-derive the 19-line stream from the state vector
   yourself (the negated prep by Ry additivity commuting past the peeled a-mux's CNOT-copy merge — both
   block-diagonal in `h0`'s basis, disjoint targets). Then the neighbourhood, plain C at `-O1`, each on
   the ORACLE and the subject: a THIRD region reading `b1` (`if (b1) cq_phi(.3)`, `if (b1) a += 1`, `if
   (b1) b0 = cq_theta(b0, .2)`); the S† on `b0` after everything (`b0 = cq_theta(b0, -.5)` — 1b-B.1's
   admitted shape at the select; now the prep's CONTROL is `b0` — the l4x4 review's ITEM 1 said the spine
   never claims it; does the S† pass the `_controlled` gate's freeze/record fences?); `b1` measured
   BEFORE its prep on some path; `b0` measured before the fused region (A.1's rung (ii) at the peeled
   select — the peel clones a compare for an `int b0` but uses the rail for a `bool b0`: is the rail
   ladder's measured-before asked of the PEELED select? PRD §14.3 rung 2 with the select as read point —
   measure); the loop form `for (i<2) { ... }` around the owner's two regions (must decline loudly — say
   which fence, and whether the string is the l4x4.c carve-out or something earlier); the owner's
   commented-out block (uncomment it: the retired two-argument `cq_phi(a, M_PI)` must be a HARD COMPILE
   ERROR at clang, not a pass decline — confirm); `int a = 5` replaced by a run-time `a` (the compare
   survives: then the second region is a compare-conditioned bool prep — the FILED F2 follow-on decline,
   confirm the string).
2. **Peel × A.1.** A peeled select's compare CLONE is minted inside `lowerCompareToFlag` → a `CmpCondRead`
   entry with `WireRuled` per `SelectClassify` gate 2c — confirm the bit is set for a PEELED select (it
   goes through `classifySelectRegion`), and that the round-2 re-verification (`reverifyCmpCondReads`)
   sees the clone, not the original compare (the original may be erased/RAUW'd): construct the 9pum
   two-TU window THROUGH a peeled mux (the `%out` of a 6.5 arm feeding the fused region's condition).
3. **Peel × F2 × l4x4.** A peeled diamond whose REMAINING phi is a state prep with an `i1` seed under an
   `int` compare — the filed follow-on (declines at F2, byte-identical on main before l4x4) — and the same
   with a `bool` condition (accepts) — and with the prep's seed equal to the compare constant (`int r =
   5; if (q == 5) r = cq_theta(5, θ)` beside a peeled mux — F2's narrowing admits it; the peeled select's
   clone is a SECOND compare on the same operands: does F2's CondWire (built from `Region.Condition`) still
   cover the region's compare, or does the clone confuse `condProvenance`?).
4. **A.1 × l4x4.** The rail ladder at the in-place-Ry/prep arm calls A.1's widened
   `railWireNamesBackward` (now crossing `InPlaceRailOps`): a bool prep whose condition rail was
   relabelled in place (`b0 ^= 1` — M-C in place on an `i1`? measure what `-O1` and M-C do) before the
   branch; and the A.1 per-activation barrier with an iteration-local `bool` driving a prep in a loop
   (declines at the l4x4.c fence — confirm the ORDER of fences, i.e. which fires first, and that no
   accept sneaks between them).
5. **b6ap × l4x4 emission order.** MERGE_l4x4_1 F-3: the prep is emitted BEFORE the peeled mux (swapped
   vs source). Find a program where that swap is NOT a commutation: the peeled mux's ARM incoming reads
   the prepped register (`int a = b1 ? 2 : 5` peeled beside `b1`'s own prep in the same fused diamond —
   can `-O1` produce that shape? if so, the mux reads `b1` BEFORE its prep — a wrong unitary); the prep's
   angle depending on the mux (impossible from C — say why); two preps in one fused diamond.
6. **The whole-DAG spine on the combined stream.** `b0` has THREE readers now (the `_controlled`
   control, the CNOT copy, the CNOT un-copy): dead `b0` (no measure) → left allocated, never freed?
   dead `b1`? dead `a` (`h3` out rail)? `cq_invert` around the owner's two regions? Grade any free of an
   entangled rail CONFIRMED.
7. **Corpus-level**: run every session corpus on the subject (the READMEs record the expected columns
   after each merge) — 0 unexplained movers; then 10 plain-C programs of your own combining ≥3 of the
   four capabilities.

## Method

Scratch `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/integration_review/`;
recipe: `/usr/local/opt/llvm@19/bin/clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, then
`build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S`, link
`libcq_templates.a` then `libcq_runtime.a`, run, `tools/free_pairing_check.py`. State-vector arguments;
grade CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED / OVER-DECLINE / LEAK / DOC; verdict BLOCK /
CLEAR-WITH-ITEMS / CLEAR. Report `session-2026-09-11-orchestrator/review_integration.md`, probes
`review_integration_probes/` with a runner. Final message ≤30 lines: verdict, findings one line each
with grade, the owner's-file neighbourhood table (program → oracle → subject → reading).
