# Track C probes — bd `test_C_libtooling-21mg` (2026-09-13)

Binaries: **ORACLE** `/Users/sorenwilkening/Desktop/CQ_lang/build` (`cq-opt`
`fbbe0820…`, e96f89c, read-only, never rebuilt) · **SUBJECT**
`/Users/sorenwilkening/Desktop/CQ_21mg/build` (`cq-opt` `c662bd0c…`, branch
`classical-measure`). Pipeline per `../../PROTOCOL.md`; the `.c` probes were run
with `-g` so a site that attaches `!dbg` renders a source location.

## `.c` — the customer and the (a)–(e) verdicts (§0 of `IMPL_C.md`)

| file | ORACLE | SUBJECT |
|---|---|---|
| `owner_2026-09-11_2218.c` | exit 1, `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` | exit 0, empty stderr, 15 trace lines, STRICT 2b `5 rail mint(s) of which 4 left allocated, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` |
| `owner_twin_no_b1.c` | exit 0, 15 lines | exit 0, trace byte-identical to the ORACLE's AND to the subject's `owner_2026-09-11_2218` |
| `c1_const_bool.c` … `c5_classical_phi.c`, `c8_theta_and_classical.c` | exit 1, the same string | exit 0 |
| `c6_undef_bool.c` | exit 1, the same string | exit 1, `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value` at `c6_undef_bool.c:3:33` |
| `c7_measure_in_arm.c` | exit 1, `cq controlled lowering: value-arm swap-route under quantum control` (`CQ_CTRL_DBG` names the `cq_measure_si32` call) | **identical** |

## `.ll` — the hand-IR family behind §2 (i), added AFTER the 3021-row sweep

These were added to `probes/` after `corpus_c662bd0ca0e7d8a4.txt` was produced, so
they appear in the NEXT sweep, not that one. Both-binary verdicts, measured
2026-09-13:

| file | shape | ORACLE | SUBJECT |
|---|---|---|---|
| `i0_poison_operand.ll` | `cq_measure_si32(i32 poison)` | `operand not recognized` | the undef/poison string |
| `i1_tainted_frem_f64.ll` | tainted `frem double`, measured f64 | exit 0 | exit 0 |
| `i2_tainted_fdiv_f64.ll` | tainted `fdiv double` | exit 0 | exit 0 |
| `i3_tainted_sqrt_f64.ll` | tainted `@llvm.sqrt.f64` | exit 0 | exit 0 |
| `i4_tainted_fptrunc_roundtrip.ll` | tainted `fneg`/`fptrunc`/`fpext` | exit 0 | exit 0 |
| `i5_tainted_vector_escape.ll` | tainted `insertelement`/`extractelement` | `cq taint escape: tainted value reaches an unsupported instruction` | identical |
| `i6_tainted_onereg_phi_i64.ll` | one-register `phi i64` lift, measured `sll` | exit 0 | exit 0 |
| `i7_tainted_classical_select_i64.ll` | `select i1 %c, i64 %q, i64 %q` | `cq taint escape: tainted value muxed by a classical-condition select` | identical |
| `i8_tainted_freeze_i64.ll` | `freeze i64` of a tainted theta | exit 0 | exit 0 |
| `i9_classical_measure_in_arm.ll` | the (c) verdict as hand IR (= `control_reject_measure_classical_in_arm.ll`) | `value-arm swap-route under quantum control` | identical |
| `i10_owner_O1_main.ll` | the owner file's `-O1` `main`, dbg stripped (= `control_measure_classical_bool_owner.ll`) | `operand not recognized` | exit 0 |

**What the `i1`–`i8` rows establish** (IMPL §2 (i)): every tainted-value lowering
that SUCCEEDS yields an `i32` handle, and every one that FAILS raises a
`DS_Error` — which `LLVMContext::diagnose` turns into `exit(1)` (`i5` produces no
output file at all, though its guard has no early return and `lowerMeasures` runs
much later). So the retained `operand not recognized` branch is a POSTCONDITION
check with no reachable input at HEAD, not a primary fence, and it ships without
an `.ll` fixture deliberately.

## scripts

* `corpusC.sh` — the ORACLE-vs-SUBJECT sweep (PROTOCOL's `corpus.sh` with three
  noted deltas; see the header). Output: `corpus_c662bd0ca0e7d8a4.txt`, 3021 rows,
  1 mover.
* `inject_C.py` — the injection matrix over the four new accept fixtures, adapted
  from `session-l4x4/probes/impl/inject.py` (Rule 14). Final:
  `fixtures=4 mutations=29 MISSED=0 DIRTY=0 n/a=7`.
