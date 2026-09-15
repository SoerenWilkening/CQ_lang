# Track M probes — probe → question → ORACLE verdict

Every row was measured by the Track M scoping agent on the frozen session ORACLE

```
0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  build/ir-pass/cq-opt
94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b  build/ir-pass/libCQPass.so
```

with `./m.sh <probe>` (the `PROTOCOL.md` per-probe pipeline: clang `-O1 -g` → `cq-opt` →
`free_pairing_check.py` → link → run). Verdict `A` = `opt` exit 0, `D` = exit 1 with the
diagnostic quoted. Outputs are under `out/` (`.s1.ll`, `.s2.ll`, `.err`, `.fp`, `.trace`).

⚠ **Probe hygiene.** A hand-IR probe with no `@main` scores on the `opt` exit code, not on a
trace — `m.sh` reports `LINKFAIL` for those and it is expected (`e2l`). A **0-byte `.ll`
ACCEPTS** through the passthrough early-out (bd memory `empty-module-accepts-vacuity-trap`);
every probe here is non-empty and was checked.

---

## E2 — bd `fve8`, `cq_measure` of an `undef`/`poison`

| probe | question | ORACLE |
|---|---|---|
| `src/e2a_direct_undef_bool.c` | the direct spelling the ruling retires (`_Bool b;`) | **D** `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value` |
| `src/e2b_direct_zero_bool.c` | its written-zero twin — the refinement target | **A**, 0 trace lines |
| `src/e2c_direct_undef_int.c` | the same at `i32` | **D**, same string |
| `src/e2d_direct_zero_int.c` | twin | **A**, 0 lines |
| `src/e2e_undef_used_twice.c` | is the RAUW target observable when the operand is read elsewhere? | **D**; `-O1` folds the second read to `ret i32 undef`, so this one shape cannot answer it — `e2g` does |
| `src/e2f_zero_used_twice.c` | twin | **A** |
| `src/e2g_undef_measure_with_quantum.c` | **the RAUW-target discriminator**, and: does the decline preempt a module with real quantum content? | **D** — yes, it preempts. Stage-1 keeps `%4 = add nsw i32 %3, %2`, so RAUW-to-zero gives `add %3, 0` and RAUW-to-operand gives `add %3, undef` |
| `src/e2h_zero_measure_with_quantum.c` | twin — the byte target | **A**, 3 lines; lowered `%1 = add nsw i32 %m, 0` |
| `src/e2i_constexpr_undef_operand.ll` | is the **non-whole-value** residual reachable at the sink? | **D**, same string — **YES**, so the retirement needs `z9t1`'s `isa<UndefValue>` conjunct |
| `src/e2j_poison_operand.ll` | does one predicate cover `poison`? | **D**, same string — yes (`PoisonValue` derives from `UndefValue`) |
| `src/e2k_global_initializer_undef.ll` | ⚠ **the clause that decides the narrowing**: the operand is a FULLY DEFINED address; only the referenced global's *initializer* holds an `undef`, and `valueCarriesUndef` walks into it (`SkipGlobals=false`) | **D** — rewriting this to zero would be a **VALUE CHANGE** |
| `src/e2l_global_initializer_defined.ll` | the control: identical but `{i32 1, i32 2}` | **A** (exit 0; `LINKFAIL` is expected — no `@main`) |

## E3 — bd `yiid`, `cq_measure` as a wire event, reading (b)

### The §14 family, re-taken on THIS oracle (all eight reproduce `IMPL_D.md` §14.7 exactly)

| probe | ORACLE |
|---|---|
| `src/m14a_measure_then_theta.c` | **A**, 5 — and it **CHAINS**: `cqrt_ry_i32(h0,.5)` after `cqrt_measure_i32(h0)` |
| `src/m14b_measure_theta_measure_parent.c` | **D** `cq opcode lowering: rotation/measure operand predates a non-diagonal gate` |
| `src/m14c_measure_then_inloop_reuse.c` | **D**, same |
| `src/m14d_measure_then_two_siblings.c` | **D**, same |
| `src/m14e_unmeasured_two_siblings.c` | **D**, same — **the control**, one line from `m14d` |
| `src/m14f_measure_then_pureop.c` | **D** `cq opcode lowering: operand predates a non-diagonal gate` |
| `src/m14g_entangled_then_measure_reuse.c` | **A**, 12 |
| `src/m14h_runtime_seed_alloc.c` | **A**, 3 — `cqrt_alloc_i32(1)` from `argc`: the allocator ABI takes a **runtime value**, §14.4 confirmed |

### The explicit-re-seed TWINS — E3's target stream, read off the shipped compiler

| probe | question | ORACLE |
|---|---|---|
| `src/e3a_twin_reseed_from_m.c` | is `cq_theta(**m**,θ)` already a capability? | **A**, 6, STRICT 2b clean — `cqrt_alloc_i32(i32 %m)` |
| `src/e3b_twin_reseed_measure_parent.c` | the re-measure case, via bd `21mg`'s classical measure | **A**, 6 |
| `src/e3c_twin_reseed_two_siblings.c` | two independent rails from one outcome | **A**, 9 |
| `src/e3d_twin_reseed_pureop.c` | classical arithmetic on `m` | **A**, 6 |
| `src/e3e_twin_reseed_inloop.c` | in-loop | **A**, 14 |
| `src/e3f_twin_bool_reseed.c` | width: `_Bool` | **A**, 7 — `cqrt_alloc_i1` / `cqrt_measure_i1` |
| `src/e3g_twin_f64_reseed.c` | width: `double` | **A**, 6 — `cqrt_alloc_f64` / `cqrt_measure_f64`, types match by `T(T)` |

### The RELABELLED originals — E3's rewrite applied textually to stage-1, fed to the ORACLE

`relabelled/*.relabel.ll`, generated from `out/m14*.s1.ll`. Each differs from its original in
**exactly the operand(s) E3 rewrites**.

| relabelled | before | after | note |
|---|---|---|---|
| `m14a` | A 5 (chained) | **A 6** | lowered body and trace **BYTE-IDENTICAL** to the `e3a` C twin |
| `m14b` | D | **A 6** | the second measure becomes bd `21mg`'s classical one |
| `m14c` | D | **A 12** | 3 independent rails, 3 i.i.d. measures |
| `m14d` | D | **A 9** | two independent rails |
| `m14f` | D | **A 6** | classical arithmetic |

### Position / control / escape hazards

| probe | question | ORACLE |
|---|---|---|
| `src/e3h_inloop_measure_then_read.c` | measure INSIDE the loop, read after it — the probe that separates plain `DT.dominates` from `WireWalk::provablyBefore` | **D** `…predates a non-diagonal gate`; E3 **relabels** it |
| `src/e3i_inloop_read_then_measure.c` | read BEFORE the measure — **the MUST-NOT-RELABEL control** | **D**; dominance fails, E3 leaves it |
| `src/e3j_inloop_measure_only.c` | **the brief's back-edge question**: `for(…) s += cq_measure(q);` | **A**, 5 — **UNCHANGED by E3 by construction** (the only use is the measure's own operand slot) |
| `src/e3k_postmeasure_branch_cond.c` | post-measure read as a tainted BRANCH CONDITION | **D** `cq controlled lowering: condition measured before the control route under quantum control` |
| `src/e3l_postmeasure_branch_cond_twin.c` | its `m` twin | **A**, 3 — the `cq_phi` is uncontrolled and is deleted (Rule 3) |
| `src/e3m_golden_shape_pureop.c` | the shape `IMPL_D.md` §14.6 named as the 2 moving goldens | **A**, 8 — quantum `icmp` + `_unc` + `cqrt_free` |
| `src/e3n_golden_shape_pureop_twin.c` | its `m` twin | **A**, 3 — the block disappears, §14.6's "both get SHORTER" confirmed |
| `src/e3o_postmeasure_store.c` | post-measure read stored to memory | **D** `cq taint escape: tainted value stored to memory` |
| `src/e3p_postmeasure_store_twin.c` | twin | **A**, 3 |
| `src/e3q_postmeasure_angle.c` | ⚠ post-measure read used as a ROTATION **ANGLE** | **D** `cq rotation lowering: unsupported quantum-derived rotation angle` — E3 turns this into an accept; see `SCOPE_M.md` §2.7 |
| `src/e3r_postmeasure_angle_twin.c` | twin | **A**, 6 |
| `src/e3s_postmeasure_return.c` | post-measure read returned | **A**, 3 |
| `src/e3t_postmeasure_return_twin.c` | twin | **A**, 3 |

---

## Instruments

| file | what it measures | self-test |
|---|---|---|
| `m.sh` | the `PROTOCOL.md` per-probe pipeline against the ORACLE | — |
| `post_measure_trace_scan.py` | **UPPER BOUND** on committed goldens whose stream E3 moves (trace level: rail handles, not SSA names; re-measure and `cqrt_free` excluded) | `--selftest`: **6 cases, 2 known positives, 4 known negatives — PASSED**. Result: **0 of 383**, correcting `IMPL_D.md` §14.6's "2 of 367" (those two goldens were DELETED at `66428ddc`) |
| `post_measure_ir_scan.py` | the E3 population over `.ll` modules: **DEFINITE** (same block ⇒ dominance certain) and **POSSIBLE** (cross-block upper bound) | `--selftest`: **7 modules, 5 known positives, 2 known negatives — PASSED**. ⚠ Its FIRST spelling counted LLVM-19 `#dbg_` debug records as uses and failed **7 of 7**; caught by the self-test, not by re-reading it (Rule 12(c) on an instrument). Result: **DEFINITE 23 uses in 22 modules; POSSIBLE ≤873 uses in 608 modules** of 2039 |
| `relabel.py` | applies E3's **same-block** relabel to a `.ll` — a strict SUBSET of the real predicate, so it can only UNDER-state the blast radius | validated by `post_measure_ir_scan.py --selftest` sharing its parse, and by the byte-identity of `m14a.relabel` against the `e3a` C twin |
| `definite_fixtures.txt` | the 22 fixtures and their per-measure counts | — |
| `fixture_relabel/` | the 22 fixtures relabelled; ORIG-vs-RELABELLED verdicts are `SCOPE_M.md` §2.8 | — |
| `fixture_relabel2/` | the classical-measure family relabelled — **0 lines rewritten, IDENTICAL after lowering** in all 5 | — |
