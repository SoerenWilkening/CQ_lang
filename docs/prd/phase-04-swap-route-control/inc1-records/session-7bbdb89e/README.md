# session `7bbdb89e` — bd `test_C_libtooling-eqpx` (P1): the fix, its round-1 lens, and the doc pass

2026-09-06. Branch `eqpx-fix`, base `main` **0b402d6** (docs-only over the code commit
**16b15b3**). The defect, the investigation and the 43 original reproducers are in the
PREVIOUS session's record, `../session-82e6b530/` (`investigate_eqpx.md` is the spec).
The design-of-record write-up is `RETIRE_SWAP_ROUTE_INC1_NOTES.md` **§3.16** and PRD §0 **E13**.

| file | what it is |
|---|---|
| `fix_eqpx.md` | the IMPLEMENTER's hand-back — the tripwire (2a) + the operand-index plumbing (2b), the 8×2 red-green, the 0-golden-churn gate, the `0 RCDIFF · 0 DIAGDIFF · 0 OUTDIFF` corpus diff, the M1 / M2+M3 mutants, and its two OWNER QUESTIONS |
| `review_eqpx_r1.md` | the ROUND-1 ADVERSARIAL LENS — verdict **`CLEAR-WITH-ITEMS`**; findings F-E1-1..F-E1-5; the whole-corpus sweep and `strictimm.py`; mutants M-A / M-B / M-E / M-F; adjudications (A) and (B) |
| `eqpx_reproducers_r1/` | the lens's own corpus — 15 NEW measured members (incl. the i8/i16 BROKEN-MODULE face and the plain-C commuted `add`), 20 over-decline boundary controls, and the `n02` parity sweep behind adjudication (B). Per-file README with every status |

**The three DOC/FIXTURE items are CLOSED** by a round-2 doc pass on the same branch
(`wip(eqpx-b):` commits): F-E1-1 the stale writer `grep` and its four line numbers, F-E1-2 the
vacuous decline `CHECK-NOT`s (the property is pinned by the `not` inversion, and each header now
says so), F-E1-3 the accept controls' injection matrix, **28 MISSED → 0 MISSED over 48
injections**. Adjudication (A)'s three-fact argument is now IN SOURCE at `ArithLowering.cpp`'s
`InPlaceRailIdx` consume; adjudication (B) is written into §3.16.

That pass changed **COMMENTS, FIXTURES AND DOCS ONLY** — verified two ways:
`git diff <base> -- ir-pass/src ir-pass/include` has ZERO non-comment lines, and the rebuilt
`cq-opt` **and** `libCQPass.so` are `cmp`-BYTE-IDENTICAL to the pre-pass binaries. So every
measurement in `fix_eqpx.md` and `review_eqpx_r1.md` still stands for the shipped tree.

⚠ **ONE LENS IS NOT A CLEARANCE (Rule 13).** This function's history is nine findings over
seven adversarial rounds, two of them introduced by a fix and one found by a round reviewing a
different increment. A green 1707/357 clears nothing.
