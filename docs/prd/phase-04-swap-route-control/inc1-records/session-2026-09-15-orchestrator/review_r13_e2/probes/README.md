# review_r13_e2 — reproducers

Every probe below was run against the two binaries named in `../REVIEW.md` §0 and **nothing was
built**. `run.sh <oracle|subject> <file>` does stage 1→2; `stream.sh` prints the emitted
`cqrt_*`/`cq_template_*` stream; `full.sh` does stage 1→2→2b→3→run.

⚠ `run.sh` prints `stage1bytes` and `cqcalls` on every row **on purpose**: a 0-byte module ACCEPTS
through the passthrough early-out, so no ACCEPT in `../REVIEW.md` is reported without them.

| probe | question | ORACLE | SUBJECT |
|---|---|---|---|
| `y1_quantum_measure_folded_to_undef.c` | **`F-E2-1`.** `cq_measure(q + u)` — `-O1` folds the operand to `undef`. Does the user's QUANTUM measurement survive? | **D** | **A**, 0 B stderr, trace `684d2394674bd01b`, **no `cqrt_measure`** |
| `y1_min.ll` / `y1_min_control.ll` | the same, as hand IR: the minimal red-green pair | D / A | A (`cqrt_measure` count **0**) / A (count 2) |
| `y1b_written_zero.c` | the C-level written-zero twin of `y1` | **A**, trace `ea3c225a0aadc87e`, **with** `cqrt_measure_i32` | — |
| `y2_quantum_measure_mul_undef.c` | `q * u` — `-O1` folds to a concrete `0`. Proves `F-E2-1`'s class **pre-exists at HEAD** | **A**, trace `684d2394674bd01b` (identical to y1's SUBJECT trace) | A |
| `y3_quantum_measure_and_undef.c` | `q & u`, same | **A** | A |
| `g1_guard1_two_slots.c` / `g1b_no_undef_measure.c` | does E2's preemption removal DISARM `declineUnpairedUndefLiterals`? | D on the measure string / D on the literal-integrity string | **D on the literal-integrity string** — GUARD 1 fires. Not disarmed |
| `w1_void_return_measure.ll` | can `(1a)`, now ABOVE the type guard, reach `Constant::getNullValue(VoidTy)` (Release UB)? | D `unsupported declared prototype` | **identical** — `declMatchesPrototype` fences it |
| `w2_type_mismatch_measure.ll` | mismatched param/return with an `undef` operand | D, same | identical |
| `z1`/`z1b` | `switch` scrutinee guarding quantum arms | D / A | A, trace **equal** to the twin (`6ce3829ef2c7c3ed`) |
| `z5` | loop-carried classical phi beside a rolled in-loop `cq_theta` | D | A, trace equal to twin (`e53ecc1a125bc066`) |
| `z6` | `cq_measure(cq_measure(u))` — nested sink | D | A, empty trace, equal to twin |
| `z8` / `z8c` | undef ROTATION ANGLE beside the undef measure (E1 × E2). `z8c` is the control with the measure deleted | z8 **D**; **z8c A**, trace `243328cdcef5e209` | z8 **A**, trace `243328cdcef5e209` — **identical to the ORACLE's z8c**, so the garbage angle is E1's ruled behaviour, not a new E2 capability |
| `z9` | the user's measurement result is UNUSED | D | A, trace equal to twin |
| `x1`/`x1b` | **cross-function** (bd `1yeu`): undef measure in fn A, quantum content in fn B | D (first `DS_Error` kills the module) / A | A, trace equal to twin (`ea3c225a0aadc87e`) |

Also run, not stored here because they are the track's own files: `refinement_check.py` over the
**11 historical `D→A` movers** `IMPL_E2.md` §4 names but did not refinement-check
(`11 BYTE-IDENTICAL, 0 DIVERGENCE(S)`), and over 9 of the probes above
(`9 BYTE-IDENTICAL, 0 DIVERGENCE(S)`).
