# probes — F2 / i1 state-prep scoping (session-f2-i1)

Every verdict here was produced by the **shipped** binary at `main` 0c7380c, unmodified:

```bash
LLVM=/usr/local/opt/llvm@19/bin
R=/Users/sorenwilkening/Desktop/CQ_lang

# a .c probe
"$LLVM/clang" -I$R/include -include CQ.h -O1 -emit-llvm -S <p>.c -o /tmp/s1.ll
$R/build/ir-pass/cq-opt -passes=cq-lowering -S /tmp/s1.ll -o /tmp/s2.ll ; echo "rc=$?"

# a .ll probe (alt/, mut/)
$R/build/ir-pass/cq-opt -passes=cq-lowering -S <p>.ll -o /dev/null ; echo "rc=$?"
```

`rc=0` = ACCEPT (lowered). `rc=1` = loud decline; the string is on stderr as
`cq controlled lowering: <reason> under quantum control`.

**Nothing here is a ctest entry and nothing here was added to the suite.** These are
scoping artefacts.

---

## 1. Owner-shape probes (`*.c`)

| file | rc | diagnostic |
|---|---|---|
| `V0.c` — `example/grover/grover_oracle_uncompute.c` verbatim | 1 | `control flow` (TWO merge phis — bd `b6ap`) |
| `C2.c` — V0 minus `cq_measure(a)`, one phi | 1 | `bare i1 register condition` (bd `l4x4`) |
| `M1.c` — the minimal bare-rail + `_Bool` prep | 1 | `bare i1 register condition` |
| `M2.c` — the same prep under an **`int` compare** | 1 | **`state prep seed is proven equal to the condition register`** (F2) |
| `M3.c` — `int` seed, `int` compare | **0** | the drbq Inc-4 shipped accept (control) |
| `mp.c` — two preps in one arm → two merge phis | 1 | `control flow` (isolates `b6ap` from the bool question) |

**Reading:** for the owner's file F2 is the **third** wall. `b6ap` → `l4x4` → F2.

## 2. Unfolded self-controlled spellings (`u*.c`, `v*.c`, `w*.c`)

The question: *is any spelling of "rotate the condition's own register under its own
control" accepted today?* **No — 13/13.**

| file | shape | rc | fence |
|---|---|---|---|
| `u1.c` | `int r=q; if(q==5) r=cq_theta(q,.9)` | 1 | F1 `state prep merged with a quantum register` (arm folded) |
| `u2.c` | `int r=5; if(q==5) r=cq_theta(q,.9)` | 1 | **F2** — the ambiguity itself |
| `u3.c` | arm-local `r`, no merge | 1 | `value-arm swap-route` |
| `u4.c` | `_Bool c=b; if(b) c=cq_theta(b,.9)` | 1 | `bare i1 register condition` |
| `u5.c` | `_Bool c=(q==5); if(c) r=cq_theta(c,.9)` | 1 | `condition data use neither escaped nor measured` |
| `u6.c` | `volatile` threshold ⇒ **unfolded** `if(q==k) r=cq_theta(q,.9)` | 1 | **2c** `condition predates a non-diagonal gate` |
| `v1.c` | `if(q>5) r=cq_theta(q,.9)` — unfolded | 1 | **2c** |
| `v2.c` | derived condition `q+1>5`, arm rotates `q` | 1 | **2c** |
| `v3.c` | `int t=q+1; if(q>5) r=cq_theta(t,.9)` — an **alias** | 1 | **R4** `rotation arm on a condition wire` |
| `v4.c` | arm rotates a **disjoint** register | **0** | control — the fences are not vacuous |
| `w1.c` | rotate `t=q&3` under `if(t>2)` | 1 | F1 (folded) |
| `w2.c` | `int r=q; if(q>5) r=cq_theta(5,.9)` — the **mux** rival | 1 | F1 `state prep merged with a quantum register` |
| `w3.c` | rotate `a=q&6` under `if(a>1)` — unfolded | 1 | **2c** |
| `w4.c` | rotate the FLAG under its own control, flag measured | 1 | `condition data use neither escaped nor measured` |
| `w5.c` | rotate `b=(q>7)` under `if(b>0)` | 1 | same |

## 3. The fold is real (`a_*.c`, `b_*.c`, `bc*.c`)

```bash
diff <(grep -v '^;\|source_filename\|ModuleID' a_prep.s1.ll) \
     <(grep -v '^;\|source_filename\|ModuleID' a_self.s1.ll)
```

| pair | result |
|---|---|
| `a_prep.c` (`if(q==0) r=cq_theta(0,.9)`) vs `a_self.c` (`…cq_theta(q,.9)`) | **BYTE-IDENTICAL after `-O1`** |
| `b_prep.c` (`if(b0) b1=cq_theta(b1,.5)`) vs `b_self.c` (`if(!b0) b1=cq_theta(b0,.5)`) | identical up to branch polarity + phi order |
| `b_prep.c` vs `b_copy.c` (`bool b1=b0; if(b0) b1=cq_theta(0,.5)`) | **DIFFER** — `-O1` keeps `%2` as the Pred incoming ⇒ F1 sees it. *The owner's shape has no reachable β rival.* |
| `a_prep.c` vs `a_copy.c` (`int r=q; if(q==0) r=cq_theta(0,.9)`) | DIFFER; `a_copy` declines F1 |
| `bc1.c` — `int r=q; if(q!=5) r=cq_theta(5,.9)` | `-O1` **DOES** fold the Pred incoming: `%7 = phi i32 [%5,%4],[5,%1]`; declines F2 today. **The β rival IS plain-C reachable at `i32`.** |
| `bc2.c` — its `_Bool` twin | declines `bare i1 register condition` — the β question at `i1` sits behind `l4x4` |

## 4. `alt/` — the alternative reading of each flip candidate

Each file is the shipped fixture with **one** substitution, so the module is the
alternative source's `-O1` image:
* **α** — the arm theta's constant seed replaced by the in-cone register
  (`cq_theta_si32(i32 5, …)` → `(i32 %q, …)`);
* **β** (`b_*.ll`) — the merge phi's Pred incoming constant replaced by the register.

| file | rc | fence |
|---|---|---|
| `eqfold_coincidence`, `eqfold_cast`, `eqfold_ne_else`, `eqfold_extremum`, `eqfold_derived_cond`, `eqfold_ult`, `range_mask1`, `range_ordered`, `range_knownbits`, `range_knownbits_enum`, `range_constleft_eq`, `range_constleft_ugt`, `fcmp_oeq_folded`, `fcmp_une_folded` | 1 (×14) | **`condition predates a non-diagonal gate`** |
| `i1_arm_flag`, `i1_arm_flag_owned` | 1 | `condition data use neither escaped nor measured` — a `cq_theta` user of the condition is structurally `Unowned`; adding `cq_measure(%c)` does not change it |
| `b_coincidence_ne`, `b_a2_alias`, `b_i1_both_edges` | 1 | **F1 `state prep merged with a quantum register`** |
| `b_i1_flag_pinned` | 1 | `condition data use neither escaped nor measured` |
| `rail_cond_i1.ll` | 1 | `bare i1 register condition` — `range_i1_both_edges` rewritten with `br i1 %q` (no `icmp`): proves `l4x4` pre-empts F2 for the owner's spelling |

**19/19 alternative readings decline.**

## 5. `mut/` — pin identification

Each file moves **one** value and nothing else, then is re-run. The rule:

* a **class-B** (out-of-cone) pin ⇒ perturbing the out-of-cone expression alone, with the
  condition's whole backward cone untouched, turns the decline into an **accept**;
* a **class-A** (in-cone) pin ⇒ perturbing the in-cone value alone does the same;
* a `Truncated` decline ⇒ **neither** perturbation changes it.

| mutant | edit | rc | conclusion |
|---|---|---|---|
| `eqfold_coincidence` | `icmp eq %q,5` → `,6` | 0 | pin = `%q` → **A** |
| `eqfold_cast` | `,0` → `,1` | 0 | A |
| `eqfold_ne_else` | `,5` → `,6` | 0 | A |
| `eqfold_coincidence_ne` | `,5` → `,6` | 0 | A (β) |
| `eqfold_extremum` | `INT_MIN` → `INT_MIN+1` | 0 | A |
| `eqfold_derived_cond` | `icmp eq %a,2` → `,4` | 0 | A |
| `range_mask1`/`range_a2_alias`/`range_constleft_ugt` | `and %q,1` → `,2` | 0 | A |
| `range_ordered` | `and %q,3` → `,7` | 0 | A |
| `range_knownbits_enum` | `and %q,4` → `,8` | 0 | A |
| `range_constleft_eq` | `icmp eq 5,%q` → `6,%q` | 0 | A |
| `fcmp_oeq_folded`, `fcmp_une_folded` | `5.0` → `6.0` | 0 | A |
| `range_forward_add` | `add %t,5` → `,55` (cone untouched) | 0 | pin = `%fwd` → **B** |
| `range_forward_xor` | `xor %t,7` → `,70` | 0 | B |
| `range_forward_or` | `or %t,8` → `,80` | 0 | B |
| `range_forward_lshr` | `lshr %q,31` → `,30` | 0 | B |
| `sideways_sdiv`, `merge_edge_sideways` | `sdiv %q,4` → `,7` | 0 | B (sibling) |
| `sideways_offset` | `udiv %q,3` → `,7` | 0 | B (sibling) |
| `intrinsic_bswap`, `intrinsic_bitreverse`, `intrinsic_fshl` | compare constant +1 | 0 | B (the in-cone pin never equalled the seed) |
| `fcmp_oeq_derived` | `fmul %t,3.0` → `,4.0` | 0 | B (forward hop) |
| `cast_sext_live`, `fp_seed_sitofp` | compare constant +1 | 0 | B — and structurally: no cone member has the seed's type |
| `step_cap_over` | compare constant +1 | **1**, same string | `Truncated` — never reaches the test → **B** |
| `unevaluable_pinned_operand` | compare constant +1 | **1**, same string | `Truncated` → **B** |
| `unfoldable_curated_call` | compare constant +1 | **1**, same string | `Truncated` → **B** |

**Result: 19 class-A (would flip) / 21 class-B (stay) / 0 unclear**, over all 40 fixtures
that pin `state prep seed is proven equal to the condition register`
(`grep -l … ir-pass/test/*.ll | wc -l` → 40; no `tests/e2e` golden carries the string).

The three `Truncated` rows are the **H-6 tripwire**: they are the proof that the
conservative half of F2 does not run through the equality test, and therefore that an
exclusion applied at the *anchor* rather than at the *test* would behave differently.
