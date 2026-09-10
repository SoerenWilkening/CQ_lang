# session-r9e5 probes — the plain-C family behind bd `test_C_libtooling-r9e5` sub-increment 1b-B.1 (the 4.4 DATA SELECT on a bare `_Bool` condition), 2026-09-10

Single-TU programs, `clang -O1` → `cq-lowering` → stage 2b (`tools/free_pairing_check.py`, STRICT) → link → run.
Verdicts MEASURED on **`main` 87d0699** (the PRE column, the tree this branch forked from) and on branch
**`3qlq-inc1b-b-rail-select`** (the POST column). `lines` = trace lines. Every ACCEPT below is stage-2b clean
with `0 violation(s)` and `0 unproven`.

`k1`–`k4` are the orchestrator's four measured probes from `BRIEF_B1.md`; `s01`–`s20` are this session's, one
per shipped fixture shape; `p08`/`p09`/`p12`/`p16`/`q08` are Inc-1b re-runs copied verbatim from
`../session-3qlq4/probes/`.

| file | shape | on `main` 87d0699 | on the branch |
|---|---|---|---|
| `k1_loop_stale.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int acc = 0; for (int i = 0; …` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` |
| `k2_loop_stale_measure_out.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); bool t = b; for (int i = 0; i…` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` |
| `k3_flat_sdagger.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; b =…` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` | ACCEPT, 16 lines, 2b clean |
| `k4_flat_stale_after.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.9); bool t = …` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` |
| `s01_rail_const.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; ret…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 15 lines, 2b clean |
| `s02_rail_quantum_arm.c` | `int main(void){ int q = cq_theta(3, 0.3); bool b = cq_theta((bool)0, 0.5); int…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 16 lines, 2b clean |
| `s03_rail_qq_arms.c` | `int main(void){ int q = cq_theta(3, 0.3); int r = cq_theta(7, 0.2); bool b = c…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 17 lines, 2b clean |
| `s04_rail_post_ry.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; b =…` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` | ACCEPT, 16 lines, 2b clean |
| `s05_rail_measure_after.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; int…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 15 lines, 2b clean |
| `s06_rail_cross_block.c` | `volatile int g = 1; int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5)…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 15 lines, 2b clean |
| `s07_rail_two_regions.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; int…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 16 lines, 2b clean |
| `s08_rail_then_select.c` | `int main(void){ int a = 5; int c = 7; bool b = cq_theta((bool)0, 0.5); if (b) …` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 27 lines, 2b clean |
| `s09_rail_in_xor_tree.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); bool c = cq_theta(…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 20 lines, 2b clean |
| `s10_rail_fp_data.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); double d = b ? 1.5 : 2.5; ret…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 15 lines, 2b clean |
| `s11_rail_i1_data.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); bool c = cq_theta((bool)0, 0.…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 17 lines, 2b clean |
| `s12_rail_inloop_invariant.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int acc = 0; for (int i = 0; …` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 39 lines, 2b clean |
| `s13_rail_dead_register.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; ret…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 14 lines, 2b clean |
| `s14_reject_measured_before.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); int m = cq_measure…` | DECLINE `cq controlled lowering: bare i1 register condition` | DECLINE `cq controlled lowering: condition measured before the control route` |
| `s15_reject_measured_sidepath.c` | `volatile int g = 1; int main(void){ int a = 5; int m = 0; bool b = cq_theta((b…` | DECLINE `cq controlled lowering: bare i1 register condition` | DECLINE `cq controlled lowering: condition measured before the control route` |
| `s16_reject_sibling_theta.c` | `int main(void){ int q = cq_theta(0, 0.3); int a = 5; bool t = (bool)(q & 1); b…` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` |
| `s17_reject_chained_between.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); bool c = cq_theta(…` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` |
| `s18_reject_inloop_stale_theta.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int acc = 0; for (int i = 0; …` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` | DECLINE `cq controlled lowering: condition predates a non-diagonal gate` |
| `s19_reject_trunc_cond.c` | `int main(void){ int q = cq_theta(0, 0.3); int a = 5; if (q & 1) a -= 3; return…` | ACCEPT, 15 lines, 2b clean | ACCEPT, 15 lines, 2b clean |
| `s20_reject_phi_cond.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int a = 5; for (int i = 0; i …` | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` |
| `p08_select_const.c` | `int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; ret…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 15 lines, 2b clean |
| `p09_value_arm.c` | `int main(void){ int a = cq_theta(5, 0.2); bool b = cq_theta((bool)0, 0.5); if …` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 16 lines, 2b clean |
| `p12_angle_select.c` | `int main(void){ int r = cq_theta(0, 0.2); bool b = cq_theta((bool)0, 0.5); if …` | DECLINE `cq controlled lowering: bare i1 register condition` | DECLINE `cq controlled lowering: bare i1 register condition` |
| `p16_cascade_bool.c` | `int main(void){ int a = cq_theta(5, 0.0); bool b0 = 0; bool b1 = 0; if (a >= 3…` | DECLINE `cq controlled lowering: state prep seed is proven equal to the condition register` | DECLINE `cq controlled lowering: state prep seed is proven equal to the condition register` |
| `q08_measured_before.c` | `int main(void){ bool b = cq_theta((bool)0, 0.5); int m = cq_measure(b); if (b)…` | DECLINE `cq controlled lowering: condition measured before the control route` | DECLINE `cq controlled lowering: condition measured before the control route` |
| `user_file_as_of_2026-09-10_close.c` | `(the owner's file, session-3qlq4/)…` | DECLINE `cq controlled lowering: bare i1 register condition` | ACCEPT, 15 lines, 2b clean |

## What the table says, in four claims

1. **THE OWNER'S PROGRAM COMPILES.** `user_file_as_of_2026-09-10_close.c` (`example/grover/
   grover_oracle_uncompute.c` as it stood at the close of session 3qlq4) declined
   `bare i1 register condition` on `main` and now lowers to 15 trace lines, stage-2b clean. Its
   `main()` is committed verbatim as `tests/e2e/slice_control_select_bool.c`.

2. **THE DT PRONG IS THE CAPABILITY, AND IT IS LOOP-SAFE.** `k3` (the S† — a chained Ry on the
   condition register AFTER the select) moves DECLINE → ACCEPT; `k1`, `k2` and `k4` do NOT move.
   `k1`/`k2` put the theta in a LOOP BODY, where the back edge defeats the reachability half of
   `provablyBefore`, and `k4` is a KICKBACK shape this increment does not touch at all (a control).
   `s16`/`s17`/`s18` are the same three refusals in the select's own idiom and are green on BOTH
   binaries — the widening did not reach them.

3. **RUNG 2 IS THE ONE PLACE THE READ POINT MATTERS.** `s05` (measure AFTER the select, same block)
   and `s14` (measure BEFORE it, same block) are one line apart and have opposite verdicts. On `main`
   both declined with the blanket `bare i1 register condition`; the kickback's block-terminator read
   point would have declined BOTH.

4. **TWO PROBES BEHAVED DIFFERENTLY FROM THE BRIEF'S EXPECTATION, AND BOTH ARE MEASUREMENTS, NOT
   REGRESSIONS.**
   * **`p09_value_arm` ACCEPTS.** `BRIEF_B1.md` §5 predicted it would keep declining as a B.2 value-arm
     shape. It is not one at `-O1`: `int a = cq_theta(5,.2); … if (b) a = a + 3;` is HOISTED by clang
     (`%3 = add nsw i32 %1, 3`) and folded to `select i1 %2, i32 %3, i32 %1` — a 4.4 DATA select with
     two tainted operands, i.e. exactly this sub-increment's shape. Its COMPARE twin
     (`int b; if (b == 1) a = a + 3;`) has ACCEPTED on `main` through this same path since 4.4 shipped
     (measured: 15 lines), and the two traces differ only by the flag lines — `cqrt_alloc_i1(0) -> h3;
     cqrt_cnot(h1,h3) … cqrt_cnot(h1,h3)` here against `cq_template_icmp_eq_i32_hl(h1,1) -> h3 …
     _unc(h3,h1,1)` there. The GENUINE B.2 value arm is an unfolded diamond with a merge φ, which
     `-O1` does not produce for this source; it is pinned by the hand-IR fixture
     `ir-pass/test/control_swap_reject_value_rail_cond.ll`, whose `bare i1 register condition` decline
     is UNCHANGED and green.
   * **`s19_reject_trunc_cond` ACCEPTS ON BOTH BINARIES,** because plain C cannot express the shape:
     `if (q & 1) a -= 3;` gives `and`+`icmp` — a COMPARE, which has always lowered. The `trunc` and
     `phi` conditions are hand-written IR in
     `control_swap_reject_select_rail_{trunc_cond,phi_cond}.ll`, and `s19`/`s20` are kept as the
     record of what the C route actually produces (`s20`'s loop-carried `bool` declines one layer
     earlier still, in the loop lowering).

## Reproducing

```
LLVM=/usr/local/opt/llvm@19/bin
$LLVM/clang -Iinclude -include CQ.h -O1 -emit-llvm -S <probe>.c -o x.s1.ll
build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S x.s1.ll -o x.s2.ll
python3 tools/free_pairing_check.py x.s2.ll
$LLVM/clang x.s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o x.bin && ./x.bin
```

## Orchestrator addendum — the F-B1-1 family (`m1`–`m4`), measured after the fix (see `IMPL_B1.md` §8)

| file | shape | first B.1 build | after the F-B1-1 fix |
|---|---|---|---|
| `m1_inloop_select_measure_after.c` | `for (i<3) { int a = b ? i : 5; acc += cq_measure(a) + cq_measure(b); }` — a loop-VARIANT arm keeps the select in the body; `b` measured after it in the same block | ACCEPT (over-accept: trip ≥2 controlled on a collapsed register) | DECLINE `cq controlled lowering: condition measured before the control route` |
| `m2_inloop_select_measure_after_compare_twin.c` | the `int b; (b == 1) ? i : 5` twin | ACCEPT | ACCEPT — PRE-EXISTING on `main` 87d0699 (saved pre-change binary), bd `test_C_libtooling-r10v` |
| `m3_inloop_select_measure_downstream.c` | same loop, `b` measured only after the loop | ACCEPT | ACCEPT, byte-identical |
| `m4_inloop_constarm_hoisted.c` | `for (i<3) { int a = b ? 2 : 5; acc += cq_measure(a) + cq_measure(b); }` — `-O1` LICM-hoists the invariant select out of the loop | ACCEPT (correct: the select runs once, before any measure) | ACCEPT, byte-identical |

The hand-IR form of `m4` (constant arms kept INSIDE the body) accepted on the first build and declines now;
it is `control_swap_reject_select_rail_inloop_measure_after_constarm.ll`.

## Round-1 fix — the F-B1R1-1 family (`n01`–`n05`), measured on the fix-1 binary

Rung (ii) of the rail ladder (measured-before) now asks the rail's WIRE (`railWireNamesBackward`:
the chained-theta ancestry and the first non-theta parent), not the rail's SSA users, in BOTH
callers (select and kickback). Re-running the reviewer's 108-program corpus on this binary moves
exactly five programs, all ACCEPT → DECLINE `condition measured before the control route`:
`r02`, `r22`, `h14` (the select), `r21`, `r41` (the kickback); nothing else moves.

| file | shape | first B.1 build | after the F-B1R1-1 fix |
|---|---|---|---|
| `n01_measured_parent_name.c` | `b0 = θ(b0,.5); b = θ(b0,.3); m = measure(b0); a = b ? 2 : 5;` — the PARENT name measured | ACCEPT (the merge's `cnot(h0,·)` right after `measure_i1(h0)`) | DECLINE `condition measured before the control route` |
| `n02_measured_parent_before_chain.c` | `b0 = θ; m = measure(b0); b = θ(b0,.3); a = b ? 2 : 5;` | ACCEPT | DECLINE (same string) |
| `n03_kickback_measured_parent_name.c` | `n01`'s shape at the KICKBACK (`if (b) cq_phi(.9)`) — accepted on `main` b00fdc2 too (pre-existing, shared helper) | ACCEPT | DECLINE (same string) |
| `n04_measured_template_parent.c` | `t = (bool)(q & 1); b = θ(t,.5); m = measure(t); a = b ? 2 : 5;` — the NON-theta parent, in place under `b` | ACCEPT | DECLINE (same string) |
| `n05_other_register_measured.c` | as `n04` but `measure(q)` — the cast's SOURCE, a different rail (the closure STOPS at the template) | ACCEPT | ACCEPT, 2b clean — the stop pin |

## Round-2 fix — the F-B1R2-1 consumer-reachability probes (`w1`–`w6`), measured on f8d29e8 and on the fix

The round-2 BLOCK (`review_b1_r2.md` §2) established the round-2 taint window for the **4.4 data
select** and left the KICKBACK consumer open: the reviewer's `ll/e09` declines `control flow` on both
binaries "for an unrelated structural reason", so no kickback program was known to reach it. These six
probes close that for the kickback AND for the 4.3 nest, and they are `.ll` rather than `.c` (the convention this directory otherwise keeps)
for one reason: the window needs a 6.5 classical-call arm, i.e. a callee `clang -O1` cannot inline, and
a single-TU C program cannot express one. `w1`/`w2` measure the `e09` shape WITH the `%out` kept live
by a `cq_measure` — it still declines `control flow`, with AND without the sibling theta, so the refusal
is the region SHAPE (a rail branch sitting in the previous region's own merge block) and not the ladder.
`w3` inserts ONE `br label %second` and the window opens: on f8d29e8 it ACCEPTS at rc=0, verify-clean and
STRICT-2b clean, emitting `ry_i1(h,.5); ry_i1(h,.9); rz_i1(h,.7),!cq.branchphase` — the branch phase on a
register the SIBLING moved — and after the fix it declines `condition predates a non-diagonal gate`.
`w4` is `w3` minus the sibling: it ACCEPTS on both binaries with BYTE-IDENTICAL lowered modules, which is
the kickback-side discriminator that the fix re-verifies the ladder rather than refusing the window.
`w3`/`w4` are shipped as the fixtures `control_phase_kickback_{reject_,}rail_round2_{sibling_theta,window_accept}.ll`.
`w5`/`w6` do the same for the 4.3 depth-2 NEST and are the reason the recording ended up inside
`emitCondNode` rather than in `emitCondNetwork`'s node loop: the nest builds its CONJUNCTION node by hand
and calls the node emitter DIRECTLY, so when the outer arm carries no phase gates (the ordinary nested-AND
`if (b) { if (c) cq_phi(θ); }`) that toffoli is the ONLY read of the user's register — and for an INNER
rail it is the only read in every case. `w5` ACCEPTS on f8d29e8 with `ry_i1(h,.5); ry_i1(h,.9);
toffoli(h, h_cmp2, g); rz_i1(g,.7)` (2b `3 verified, 0 violation(s)`) and DECLINES after the fix; `w6`,
the same module minus the sibling, ACCEPTS on both with byte-identical modules. They are shipped as
`control_phase_nest_{reject_,}rail_round2_{sibling_theta,window_accept}.ll`.
