# `session-9pum/probes` — Track A.1 probe corpus, verdicts on BOTH binaries

ORACLE = `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` at `main` 0c7380c.
SUBJECT = this branch (`compare-select-parity`).

Recipe, single TU:

```
clang -Iinclude -include CQ.h -O1 -emit-llvm -S <p>.c -o s1.ll
<bin>/cq-opt -load-pass-plugin <bin>/libCQPass.so -passes=cq-lowering -S s1.ll -o s2.ll
```

Two TUs (`*_caller.c` + `*_lib.c`), the shipped 6.5 recipe — the lib TU is compiled
WITHOUT `-include CQ.h`, then `llvm-link`, then ONE `cq-lowering`:

```
clang -Iinclude -include CQ.h -O1 -emit-llvm -S <p>_caller.c -o a.ll
clang -Iinclude              -O1 -emit-llvm -S <p>_lib.c    -o b.ll
llvm-link -S a.ll b.ll -o c.ll && <bin>/cq-opt ... -S c.ll -o s2.ll
```

| probe | oracle | subject | subject diagnostic |
|---|---|---|---|
| `r10v.c` (= `session-r9e5/probes/m2_...compare_twin.c`) | ACCEPT | **DECLINE** | `condition measured before the control route` |
| `r903b.c` | ACCEPT | **DECLINE** | `condition measured before the control route` |
| `9pum_{caller,lib}.c` (= `review_b1_r2_probes/multi/e13_*`) | ACCEPT | **DECLINE** | `condition predates a non-diagonal gate` |
| `d1_sel_cmp_measured_before.c` | ACCEPT | **DECLINE** | `condition measured before the control route` |
| `d2_sel_cmp_measured_sidepath.c` | ACCEPT | **DECLINE** | `condition measured before the control route` |
| `d3_sel_cmp_measured_parent_name.c` | ACCEPT | **DECLINE** | `condition measured before the control route` |
| `d4_kick_cmp_measured_sidepath.c` | ACCEPT | **DECLINE** | `condition measured before the control route` |
| `d5_kick_cmp_round2_sibling_{caller,lib}.c` | DECLINE (`control flow`) | DECLINE (`control flow`) | pre-empted earlier — see IMPL §7 O-4 |
| `a1_sel_cmp_measure_after.c` | ACCEPT | ACCEPT | — |
| `a2_sel_cmp_other_register_measured.c` | ACCEPT | ACCEPT | — |
| `a3_kick_cmp_measure_after.c` | ACCEPT | ACCEPT | — |
| `a4_sel_cmp_round2_window_{caller,lib}.c` | ACCEPT | ACCEPT | — |
| `a5_sel_cmp_round2_opaque_seed.c` | ACCEPT | ACCEPT | — |
| `a6_sel_cmp_inloop_measure_after_constarm.c` | ACCEPT | ACCEPT | `-O1` LICM-hoists the whole select out of the loop |
| `a7_sel_cmp_inloop_iterlocal_measure_after.c` | ACCEPT | ACCEPT | iteration-local register — the per-activation barrier |

Every DECLINE above is RED on the oracle by construction (the oracle ACCEPTS it), which is
the Rule-12 red-green evidence for the lit fixture that pins it.

---

## Round-1 fix additions (`FIX_A1_R1.md`, 2026-09-11)

| probe | finding | oracle | pre-fix subject | fixed subject |
|---|---|---|---|---|
| `k7_caller.c` + `lib3.c` | **F-A1-1**, the BLOCKER — bd `9pum` verbatim, plain C ×2 TUs | ACCEPT | **ACCEPT** (wrong unitary) | **DECLINE** `predates a non-diagonal gate` |
| `k8_caller.c` + `lib3.c` | the same program WITHOUT the S-dagger | ACCEPT | DECLINE | DECLINE |
| `k9_caller.c` + `lib3.c` | the discriminator — the S-dagger on ANOTHER register | ACCEPT | DECLINE | DECLINE |
| `k10_caller.c` + `lib3.c` | **the accept control** — the S-dagger ALONE, no round-2 sibling | ACCEPT | ACCEPT | **ACCEPT** |
| `c1.c`, `c10.c` | **F-A1-3** — the flag reads a separate out-of-place rail | ACCEPT | DECLINE (over-decline) | **ACCEPT** |
| `c2.c`, `c9.c` | the SAME source shape, but `-O1` folds the compare back onto the measured register | ACCEPT | DECLINE | **DECLINE** (correct — r903(b)) |
| `c7.c`, `c8.c` | the MIRROR — the derived rail measured, the parent controlled | ACCEPT | ACCEPT | ACCEPT |
| `b1.c`, `b2.c` | **F-A1-2** — the per-activation barrier on the RAIL ladder | DECLINE | **ACCEPT** | **ACCEPT** (both correct) |
| `sw1.ll` / `sw2.ll` | **F-A1-4**, PRE-EXISTING — bd `test_C_libtooling-lo7u`: the 4.5 `switch` mints its eq-flags from a MEASURED scrutinee (`emitEqFlag` has no `CmpInst`, so neither the new rung nor `CmpCondReads` reaches it), while the `icmp`+`br` spelling of the same program declines | ACCEPT / ACCEPT | ACCEPT / DECLINE | ACCEPT / DECLINE |
| `ip1_inplace_preloop_measure.c`, `ip3_inplace_inbody_measure.c` | the IN-PLACE face of F-A1-3's wire closure: both are pre-empted one stage earlier by `cq loop lowering: rail record read past an in-place gate on the same rail`, on BOTH binaries — the measured evidence that `taint.InPlaceRailOps` crossing in `railWireNamesBackward` has no reachable DECLINE face at HEAD | DECLINE | DECLINE | DECLINE |

`k{7,8,9}_caller.c`, `lib3.c`, `b*.c`, `c*.c`, `o7*.c`, `g*.c`, `sp*.c` and `o3_kick.ll` live in
`review_a1_r1_probes/` with the reviewer's own `run.sh`, which re-derives every row above on both
binaries; `k10_caller.c`, `sw{1,2}.ll` and `ip{1,3}_*.c` are here.
