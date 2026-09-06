# inc2-records — reproducers filed by the Inc-2 Rule-13 reviews

bd epic `test_C_libtooling-3qlq` (retire the swap route), increment 2 (value arms
by controlled-copy merge). These files are **records**, not tests: they are the
reproducers a review finding rests on, kept where the finding's issue can point
at them. Nothing in `ir-pass/test` or `tests/e2e` runs them.

Two sections, one per review round:
* **round 1** — the tainted `icmp i128` branch condition (F-V1-9 → bd `3qlq.8`),
  `{e1,f1,f2}_i128cond.*`.
* **round 2** — the preheader in-place op on a control-owned merge out-rail
  (F-I2-1 → bd `test_C_libtooling-7yd0`), the eighteen `q*.c` programs. Run them
  with the ordinary pipeline (they are plain C and need the Inc-1 header, so the
  pre-3qlq oracle cannot compile them):

```
$LLVM/clang -I<repo>/include -include CQ.h -O1 -emit-llvm -S q5sel_preadd_rolled.c -o s1.ll
<cq-opt> -load-pass-plugin <libCQPass.so> -passes=cq-lowering -S s1.ll -o s2.ll
python3 <repo>/tools/free_pairing_check.py s2.ll        # STRICT; reports 0 violations EITHER WAY
$LLVM/clang s2.ll <build>/runtime/libcq_templates.a <build>/runtime/libcq_runtime.a -o a && ./a
```
The witness is `diff` of the rolled trace against its `_unrolled`/`_u` twin's.

## The tainted `icmp i128` branch condition (finding F-V1-9 → bd `test_C_libtooling-3qlq.8`)

`CLAUDE.md` Rule 1: *"a tainted `br` / `select` / `switch` is **never** silently
passed to the backend … `ControlDetect` either hands the region to the swap-route
emitter or declines it loudly; there is no third path."* A tainted `icmp i128`
used as a branch condition took a third path.

| file | shape | disposition |
|---|---|---|
| `f1_i128cond.ll` | VALUE arm (`p*5; p+15`) under `icmp sgt i128` | pre-3qlq oracle `52d7764` **and** Inc 2 @ `8c526d9`: rc=1 with `no template for opcode 'icmp i1' in tainted context` and **zero** `cq controlled lowering:` diagnostics. **Since the Inc-2 round-1 fix** (`emitValueRegion`'s pre-mutation flag-mintability fence): rc=1 with `cq controlled lowering: control flow under quantum control` at the compare. Pinned by `ir-pass/test/control_swap_value_reject_i128_cond.ll`. |
| `f2_i128cond_phase.ll` | PHASE arm (`cq_phi`) under the same condition | **unchanged on every binary**: only the template error, no control diagnostic. THE GAP IS STILL OPEN on this half. |
| `e1_i128cond.c` | the plain-C spelling | does not compile: `cq_theta`'s `_Generic` has no `__int128` association (`controlling expression type '__int128' not compatible with any generic association type`). So the shape is reachable only from hand IR at this frontend — which is why it is a filed record and not an e2e slice. |

`opt` exits non-zero in every row and no gate is emitted, so nothing wrong is
*compiled*; what was wrong is that the control layer neither claimed nor declined
the region. Reproduce with either binary:

```
<cq-opt> -load-pass-plugin <libCQPass.so> -passes=cq-lowering -S f1_i128cond.ll -o /dev/null
CQ_CTRL_DBG=1 <cq-opt> ... f1_i128cond.ll -o /dev/null     # names the declining instruction
```

---

# The preheader in-place op on a control-owned merge out-rail (round-2 finding F-I2-1 → bd `test_C_libtooling-7yd0`)

Filed by the Inc-2 Rule-13 **round-2** review and re-measured by `fix_inc2_r2`
before being written down. **The defect is PRE-EXISTING on the landed `main`
(a3c1513) and is NOT introduced by Increment 2** — the 13-line headline
reproducer contains no Inc-2 feature at all. What Inc 2 adds is a **fourth
producer** of the rail shape the defect needs, i.e. more customers for it.
**The fix does not live on this branch**: it touches `LoopLowering.cpp`, a
Rule-13 core file on landed `main`, and is scheduled as a separate C-1 round 4
on `main` AFTER Inc 2 lands (bd `test_C_libtooling-7yd0`).

## The shape

> a control-owned merge whose `%out` holds a NON-constant value, followed by a
> classical op that M-C converts **IN PLACE** on that out-rail, followed by a
> **rolled** in-loop kickback region reading it.

The rolled loop then mints one per-bit template rail per trip and **never
discharges any of them**, while the hand-unrolled twin discharges all K. Each
leaked rail holds one bit of the merged register — an entangled **which-path
record** — and the idiom it leaks in is exactly the one owner decision **D4**
designates as the way to write a register-wide Z
(`for (i…) if ((m>>i)&1) cq_phi(θ)`).

Nothing in the tree can see it: `opt` exits 0, the module verifies, the golden
byte-diff cannot witness "freed at |0⟩", and **STRICT stage 2b is structurally
blind** — a template-minted rail has no `cqrt_alloc` to count, so
`free_pairing_check.py` reports `0 violation(s)` on the broken circuit. The full
`ctest -j6` on the rebased tree was 361/361 green.

## Headline reproducer — `q5sel_preadd_{rolled,unrolled}.c`, 13 lines, NO Inc-2 feature

```c
int slice(void){ int q=3,p=7,r=9; q=cq_theta(q,0.5); p=cq_theta(p,0.25); r=cq_theta(r,0.3);
  int m = (q>5) ? p : r;                 /* 4.4 tainted-condition SELECT merge -> %out */
  m = m + 7;                             /* preheader dtzb op on the merge out-rail    */
  for (int i=0;i<4;i++) if ((m>>i)&1) cq_phi(0.7);   /* D4's designated per-bit idiom  */
  return cq_measure(m); }
```

MEASURED by `fix_inc2_r2` (2026-09-06), full pipeline stage 1 → 2 → **STRICT 2b**
→ 3 → 4, `opt` exit 0 and 2b rc=0 in every cell. `and_hl` counts
`cq_template_and_i32_hl(` (the per-bit rail mint); `unc` counts
`cq_template_and_i32_hl_unc(` (its discharge).

| binary | rolled | hand-unrolled |
|---|---|---|
| SUBJECT (`3qlq-inc2`, Inc 2 rebased) | **44 trace lines, 4 mints, 0 unc** | 52 lines, 4 mints, **4 unc** |
| INC-1-ONLY (`main` a3c1513) | **44 lines, 4 mints, 0 unc** | 52 lines, 4 mints, **4 unc** |

The two binaries agree **exactly**, which is the measurement that makes
"pre-existing, not Inc 2's" a fact rather than a claim. The pre-3qlq oracle
cannot run it (`void cq_phi` does not exist there).

**The leak is O(K)** — `q7_k32_{rolled,unrolled}.c`, the same program at K=32:
rolled **240 lines, 32 mints, 0 unc**; unrolled **301 lines, 31 mints, 31 unc**;
identical on both binaries.

## It is the MERGE-OUT-RAIL ROOT — the discrimination, re-measured on the SUBJECT

Every row is `<rolled>.c` vs its unrolled twin, per-bit K=4, `opt` exit 0 and
STRICT 2b rc=0 throughout. "preheader op AS EMITTED" is read off the trace.

| files | merge kind + preheader op | preheader op as EMITTED | rolled vs unrolled |
|---|---|---|---|
| `q5ctl_theta_preadd_{rolled,unrolled}.c` | THETA root, `p+7` | `cqrt_addc_i32` IN PLACE | **IDENTICAL** 40/40 — the C-1 `commitOutOfLoopInPlaceOps` customer works |
| `q5v_none{,_u}.c` | 4.4 SELECT merge, NO preheader op | — | **IDENTICAL** 51/51 — clause (ii-b) works |
| `q5sel_preadd_{rolled,unrolled}.c` | 4.4 SELECT merge + `m+7` | `cqrt_addc_i32` IN PLACE | **DIVERGE** 44 vs 52 |
| `q5v_xor{,_u}.c` | 4.4 SELECT merge + `m^7` | `cqrt_xorc_i32` IN PLACE | **DIVERGE** 44 vs 52 |
| `q5v_mul{,_u}.c` | 4.4 SELECT merge + `m*3` | `cq_template_mul_i32_hl` OUT of place | **DIVERGE** 44 vs 52 — but this row is the SEPARATE, already-open owner question **Q-R1-1** (a hoisted loop-invariant TEMPLATE rail), a different cause that happens to present the same way |
| `q5v_add2{,_u}.c` | 4.4 SELECT merge + `m+7; m+9` | `-O1` folds to `+16`; the low 4 bits are unchanged so the loop reads the merge DIRECTLY | **IDENTICAL** 52/52 |
| `q4b_preadd_{rolled,unrolled}.c` | **Inc-2 VALUE-arm merge** + `p+7` | in place, inside a 6-op chain | **DIVERGE** 52 vs 60 on the subject (57 vs 65 on INC-1-ONLY, which still routes the arm) |
| `q5w_mux_{rolled,unrolled}.c` | 4.5 switch DATA-MUX + `m+7` | folds into the case constants — no preheader op survives | **IDENTICAL** 58/58 |

So the measured population is **two** producers — the 4.4 select merge and (new)
Inc 2's value-arm merge. The **6.5 classical-call arm** is a third by the same
structural argument (its `%out` is a `cqrt_alloc_<W>` in `ControlOwnedRails`,
written by controlled copies before it is read) but was **NOT measured** — the
lens's probe declined `value-arm swap-route` instead of lowering as a 6.5 arm, so
treat that as ANALYTIC. The 4.5 data-mux is measured **out** of the population.

## Root cause (ANALYTIC from source, consistent with every row above; NOT instrumented)

`LoopLowering.cpp` `commitOutOfLoopInPlaceOps` refuses at its stability conjunct
`if (!P || !P->hasOneUse()) return;`. For this shape `P` is the merge out-rail,
which **structurally cannot have one use**: every emitter writes it with two
`cqrt_copy_<W>_controlled` calls before anything reads it. The commit therefore
returns without marking, `peelInPlaceBase` stops at the un-committed op,
`invariantRegisterRootsImpl` returns false, `markIfRailLocal` is never called and
the body's per-bit rails are not iteration-local. Meanwhile `lowerOps`' M-C
independently converts that same op IN PLACE — which is precisely the
"peel refuses / M-C converts" mismatch the commit exists to eliminate.
`hasOneUse()` cannot distinguish a PRIOR WRITER from a LATER READER.

**This is the 8h7d.5 lesson again, in the file that documents it:** C-1 round 2
widened the ROOT set (clause (ii-b): a control-owned merge out-rail may be an
invariant root) and did not re-ask the question `commitOutOfLoopInPlaceOps`
computes over the same closure.

## Why nothing covers it

`ir-pass/test` has both halves and never their product: six
`control_phase_kickback_mixed_preheader_*.ll` (all THETA roots), one
`control_phase_kickback_inloop_merge_rail.ll` (merge-out-rail root, NO preheader
op), and exactly two `tools/loop_twin_matrix.expected.txt` F3 cells
(`m_addpre_pbit_none_none_rypost`, `m_addpre_pbitd_none_none_rypost`), both theta
roots.

**These files are records, not tests.** Nothing in `ir-pass/test` or `tests/e2e`
runs them, and **no fixture in this branch pins the leak as an accept** — pinning
it would bless it. The round-4 fix on `main` is what pins the discharge.
