# Track E2 probes — probe → question → verdict on BOTH binaries

Binaries, hash-keyed (`../GATES.md` is authoritative):

```
ORACLE  / BASELINE  0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  cq-opt
SUBJECT             57e7420c50ddf8027d9c686672a1db282ed03d8bd94e5d9c366a8d2bfdc15439  cq-opt
```

⚠ The BASELINE (this worktree at `main` `74eabd2c`, before the edit) came out **bit-identical to the
ORACLE**. That is recorded as a result, not as housekeeping: every RED measurement below was taken
on a binary provably equal to the frozen one, so no RED is a build artefact.

Pipeline: `e2.sh` — the `PROTOCOL.md` per-probe pipeline (clang `-O1 -g` → `cq-opt` →
`free_pairing_check.py` → link → run), parameterised by `BUILD` so **one script measures both
binaries**. `A` = `opt` exit 0, `D` = exit 1 with the diagnostic quoted.

⚠ Probe hygiene, carried from `PROTOCOL.md` S3 and re-checked here: a hand-IR probe with no `@main`
scores on the exit code and `e2.sh` reports `LINKFAIL`, which is expected; a **0-byte `.ll` ACCEPTS**
through the passthrough early-out, and every probe here is non-empty.

---

## E2 — bd `fve8`: `cq_measure` of an `undef`/`poison`

`src/e2a…e2l` are Track M's scoping probes, **re-run by this track rather than cited** (Rule 11);
all twelve ORACLE verdicts reproduced Track M's table exactly. `src/e2m…e2p` are new.

| probe | question | ORACLE | SUBJECT |
|---|---|---|---|
| `e2a_direct_undef_bool.c` | `_Bool b; return cq_measure(b);` — the spelling the ruling retires | **D** undef string | **A**, 0 lines |
| `e2b_direct_zero_bool.c` | its written-zero twin | **A**, 0 | **A**, 0 |
| `e2c_direct_undef_int.c` | the same at `i32` | **D** | **A**, 0 |
| `e2d_direct_zero_int.c` | twin | **A**, 0 | **A**, 0 |
| `e2e_undef_used_twice.c` | `int u; int m=cq_measure(u); return m+u;` | **D** | **A**, 0 |
| `e2f_zero_used_twice.c` | twin | **A**, 0 | **A**, 0 |
| `e2g_undef_measure_with_quantum.c` | ⚠ the RAUW-target discriminator, and: does the decline PREEMPT a module with real quantum content? | **D** — yes, it preempts | **A**, **3 lines** |
| `e2h_zero_measure_with_quantum.c` | twin — the byte target | **A**, 3 | **A**, 3 |
| `e2i_constexpr_undef_operand.ll` | `ptrtoint (ptr undef to i32)` — a residual? | **D** | **A** — ⚠ **NOT a residual**, see below |
| `e2j_poison_operand.ll` | does one predicate cover `poison`? | **D** | **A** — yes |
| `e2k_global_initializer_undef.ll` | ⚠ the clause that decides the narrowing: a FULLY DEFINED address whose global merely CONTAINS an `undef` field | **D** | **D**, unchanged string |
| `e2l_global_initializer_defined.ll` | the control: `{ i32 1, i32 2 }` | **A** | **A** |
| `e2m_residual_gep_field.ll` | a residual whose ConstantExpr points AT the undef field | **D** | **D** |
| `e2n_residual_bitcast_undef.ll` | `bitcast (i32 undef to float)` — residual or whole-value? | **D** | **A** — ⚠ parser-FOLDED to `float undef` |
| `e2o_residual_global_defined_addr.ll` | `undef` nested TWO levels down in a global's initializer | **D** | **D** |
| `e2p_global_undef_initializer_whole.ll` | the global's initializer is ITSELF a whole `undef` | **D** | **D** |

## E2 — the ADVERSARIAL probes (new; Rule 13 posture before the reviewer, not instead of it)

Each asks *"where else can the rewritten value go, and does the refinement survive the trip?"*
Every one is a **twin pair**, so the answer is a comparison and not an impression.

| probe | the question it attacks | ORACLE | SUBJECT | twin verdict |
|---|---|---|---|---|
| `e2q_undef_measure_feeds_seed.c` | the outcome crosses into the QUANTUM side as a `cqrt_alloc_<W>` **seed** | **D** | **A**, 3 | trace **byte-identical** to `e2r`'s, sha `ea3c225a0aadc87e` |
| `e2r_zero_measure_feeds_seed.c` | its written-zero twin | **A**, 3 | **A**, 3 | — |
| `e2s_undef_measure_feeds_angle.c` | the outcome becomes a rotation **ANGLE** (Rule 3's classical arg-1). ⚠ It must NOT become a quantum-derived-angle decline, and it must not carry an `undef` into `cqrt_ry` | **D** | **A**, 3 — `cqrt_ry_i32(h0, 0x0p+0)` | trace **byte-identical** to `e2t`'s, sha `ad3599abb0a97556` |
| `e2t_zero_measure_feeds_angle.c` | twin | **A**, 3 | **A**, 3 | — |
| `e2u_undef_measure_guards_quantum.c` | the outcome is a CLASSICAL **branch condition** guarding quantum code — can the rewrite manufacture or destroy a region? (No: `lowerMeasures` runs long after detection, and the condition was never tainted) | **D** | **A**, 3 | trace **byte-identical** to `e2v`'s, sha `ea3c225a0aadc87e` |
| `e2v_zero_measure_guards_quantum.c` | twin | **A**, 3 | **A**, 3 | — |
| `e2w_undef_measure_inside_tainted_arm.c` | a classical `undef` measure INSIDE a tainted-condition arm | **D** `value-arm swap-route under quantum control` | **D**, same string | ⚠ **D→D on BOTH** — the shape is refused upstream for an unrelated reason, so E2 neither helps nor harms it |
| `e2x_zero_measure_inside_tainted_arm.c` | twin | **D**, same | **D**, same | — |

⚠ **`e2w` caught an instrument lie, and that is why it is in the set.** `refinement_check.py`'s first
spelling reported it as `A->D !!` — a finding *against* this change — purely because the SUBJECT
exited non-zero, without ever asking whether the written-zero TWIN also declines. It does, with the
identical string. The classifier now decides the label **by asking the twin**, and reports `D-BOTH`.
An instrument that turns a pre-existing, unrelated decline into a regression report is the same
failure class as one that reports a pass.

### ⚠ THE CORRECTION THIS TRACK OWES TRACK M

Track M's `SCOPE_M.md` §1.3(b) and bd `fve8`'s note call `e2i_constexpr_undef_operand.ll`
(`ptrtoint (ptr undef to i32)`) *"the same species"* as `e2k` and name the residual the
**"`ConstantExpr` / global-initializer"** residual. **The `ConstantExpr` half of that name is wrong
on LLVM 19, and it was measured here rather than argued:**

```
$ /usr/local/opt/llvm@19/bin/opt -passes=verify -S src/e2i_constexpr_undef_operand.ll | grep cq_measure
  %m = call i32 @cq_measure_si32(i32 undef)            # FOLDED BY THE PARSER
$ /usr/local/opt/llvm@19/bin/opt -passes=verify -S src/e2k_global_initializer_undef.ll | grep cq_measure
  %m = call i32 @cq_measure_si32(i32 ptrtoint (ptr @g to i32))   # SURVIVES
```

`e2i` and `e2n` are **whole-value members under a different source spelling** and they ACCEPT. Had
the fixture set followed the scoping verbatim, `lowering_reject_measure_undef_constexpr.ll` would
have been written as a DECLINE and gone **green on a subject that no longer exists** — CLAUDE.md's
fixture-hygiene defect (c), exactly. The residual's real membership rule is measured and stated in
`../IMPL_E2.md` §2: **a `GlobalValue` in the operand's constant chain**, because that is the one
thing the constant folder cannot evaluate. Four probes (`e2k`, `e2m`, `e2o`, `e2p`) are members;
two candidate spellings (`e2i`, `e2n`) are not.

---

## Instruments

| file | what it is | self-check |
|---|---|---|
| `e2.sh` | the per-probe pipeline, `BUILD`-parameterised | — |
| `injection_matrix.py` | Rule 12's mutation validation over the ACCEPT fixtures: lower once, mutate the LOWERED IR, re-run **every** `--check-prefix` the fixture's own RUN lines name, with the same FileCheck command line lit runs | exits **2** with no argument; a fixture yielding 0 mutants is a **HOLE**; ⚠ **a mutant equal to its base is an assertion failure** — the first `rename_body` spelling was a no-op on a fixture not named `@f_*` and scored a phantom MISSED |
| `refinement_check.py` | obligation (c): `SUBJECT(undef module)` vs `ORACLE(written-zero twin)`, byte-for-byte | exits 2 with no argument; a no-op twin rewrite is an assertion failure; **normalises through the LLVM-19 parser first**, because the population is defined on the module the PASS sees |
| `corpus_E2.sh` | the ORACLE-vs-SUBJECT sweep, derived from `trackS/probes/corpus_S2.sh` | carries S3's exit-code + FULL-stderr-sha compare (the shared tag regex renders the whole `cq_measure_<sfx>` family as an empty `D:`, which would make E2's own string move **invisible**) plus a per-row first-stderr-line so the string's population can be **censused** rather than grepped |
