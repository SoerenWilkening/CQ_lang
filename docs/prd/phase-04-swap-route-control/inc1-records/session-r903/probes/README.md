# r903 scoping probes — measured verdicts on `main` @ `0c7380c`

**READ-ONLY session.** Nothing under `ir-pass/`, `include/`, `runtime/`, `tests/` or
`tools/` was touched; no build was run. Every verdict below is the **landed `main`
binary** `build/ir-pass/cq-opt` (built before this session; `git status --porcelain`
was clean at the start).

## How each probe was run

```
/usr/local/opt/llvm@19/bin/clang -I<repo>/include -include CQ.h -O1 -emit-llvm -S P.c -o P.s1.ll
build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S P.s1.ll -o P.s2.ll
```

`run.sh` (committed here) is that pair plus a `br i1` / `select i1` count of the
stage-1 module and the first diagnostic line. `.ll` probes skip stage 1 and go
straight to `cq-opt` (they are HAND IR — the shape `-O1` does not produce; each
says so in its own header).

## Verdicts — all measured, none inferred

| probe | source shape | `-O1` arrival | `main` 0c7380c verdict |
|---|---|---|---|
| `n0_nest_plain.c` | `if (a) { φ; if (b) φ; }`, two bare `_Bool` | 2 `br i1`, no select | **EXIT 0** — `toffoli(h_a,h_b,g)`, `rz(g,·)`, `toffoli`, `free(g)` |
| `n1_nest_neg_outer.c` | `if (!a) { φ; if (b) φ; }` | 2 `br i1` | DECLINE `branch phase on a bare i1 condition` |
| `n2_nest_neg_inner.c` | `if (a) { φ; if (!b) φ; }` | 2 `br i1` | DECLINE `branch phase on a bare i1 condition` |
| `n3_nest_neg_outer_cmp_twin.c` | the same nest with `int`/compare levels | 2 `br i1` | **EXIT 0** — `x(h_cmp); toffoli(...); x(h_cmp)` |
| `n4_nest_neg_outer_tree_root.c` | negated OUTER level whose root is `a && a2` (a NODE) | 2 `br i1`, 1 select | **EXIT 0** — the root is an ancilla, bracketable |
| `n5_nest_neg_inner_cmp_outer_rail.c` | compare outer, `!b` rail inner | 2 `br i1` | DECLINE `branch phase on a bare i1 condition` |
| `g0_b_and_cmp.c` | `if (b && q == 5) φ` | `select i1 %b, i1 %cmp, i1 false` | **EXIT 0** |
| `g1_notb_and_cmp.c` | `if (!b && q == 5) φ` | `icmp NE` + `select %b, true, %cmp`, arm on FALSE | **EXIT 0** — De Morgan; the NOT is absorbed by the compare predicate + branch polarity |
| `g2_notb_or_cmp.c` | `if (!b \|\| q == 5) φ` | `icmp NE` + `select %b, %cmp, false`, arm on FALSE | **EXIT 0** — same |
| `g7_notb_and_cmp_ne.c` | `if (!b && q != 5) φ` | as `g1` | **EXIT 0** |
| `g8_flat_notb.c` | `if (!b) φ` | `br i1 %b`, arm on FALSE | **EXIT 0** — 4 calls, the `rz(h,−θ)` diagonal form |
| `g3_notb_and_c.c` | `if (!b && c) φ`, TWO rails | `xor i1 %c, true` + `select %b, true, %notc` | DECLINE **`control flow`** |
| `g4_b_and_notc.c` | `if (b && !c) φ` | `xor i1 %b, true` + `select %nb, true, %c` | DECLINE **`control flow`** |
| `g5_notb_or_c.c` | `if (!b \|\| c) φ` | same as `g4`, arm on TRUE | DECLINE **`control flow`** |
| `g6_notb_and_notc_and_d.c` | `if (!b && c && d) φ` | TWO `xor …, true` children under a right-leaning or-chain | DECLINE **`control flow`** |
| `e1_b_eq_c.c` | `if (b == c) φ`, two rails | `xor i1 %b, %c`, arm on FALSE | **EXIT 0** — the xor NODE root is an ancilla |
| `e2_b_ne_c.c` | `if (b != c) φ` | `xor i1 %b, %c`, arm on TRUE | **EXIT 0** |
| `x1_select_complement_false_arm.ll` | HAND IR `select %b, false, %c` | — | DECLINE `control flow` |
| `x2_select_complement_true_arm.ll` | HAND IR `select %b, %c, true` | — | DECLINE `control flow` |
| `x3_xor_rail_true_child.ll` | HAND IR `and i1 (xor %b, true), %c` | — | DECLINE `control flow` |
| `t1_int_and1.c` | `int t = q & 1; if (t) φ` | `and` + `icmp eq …, 0` | **EXIT 0** (a COMPARE leaf, not a derived i1) |
| `t2_bool_from_int.c` | `bool t = q; if (t) φ` | `icmp eq i32 %q, 0` | **EXIT 0** |
| `t3_boolcast.c` | `if ((bool)q) φ` | `icmp eq i32 %q, 0` | **EXIT 0** |
| `t4_bool_and1.c` | `bool t = q & 1; if (t) φ` | `and` + `icmp eq …, 0` | **EXIT 0** |
| `t5_zext_bool_to_int_cond.c` | `int t = b; if (t) φ` | folded back to `br i1 %b` | **EXIT 0** (a rail root) |
| `t6_bool_xor1.c` | `bool t = b ^ 1; if (t) φ` | `br i1 %b`, arm on FALSE | **EXIT 0** |
| `t7_bool_array.c` | `bool a[2]; a[0] = θ(..); if (a[0]) φ` | `br i1` on the rail | **EXIT 0** |
| `t8_uchar_lsb.c` | `unsigned char` LSB test | `and` + `icmp` | **EXIT 0** |
| `t9_trunc_i1_data.ll` | HAND IR: a tainted `trunc i32 → i1` used as DATA | — | **EXIT 0** — `cq_template_trunc_i32_to_i1(%h)` mints a FRESH i1 rail |
| `m1_cmp_measured_before.c` | `int m = cq_measure(q); if (q > 3) φ` | `br i1 %cmp` | **EXIT 0** — the flag is minted AFTER `cqrt_measure_i32(%h)` (residual **(b)**) |
| `m3_rail_measured_before.c` | the `_Bool` twin of `m1` | `br i1 %b` | DECLINE `condition measured before the control route` |
| `m4_cmp_measured_before_crossblock.c` | `m1` with the measure in a dominating position and a classical block after | `br i1 %cmp` | **EXIT 0** — same hole |
| `m2_select_measured_before.c` | `int m = cq_measure(q); int a = (q>3)?2:5;` | `select` | **EXIT 0** — the 4.4 COMPARE select, bd `r10v`'s territory (measured here, NOT scoped) |
| `w0_loop_plain_control.c` | the shipped rolled in-loop kickback | 2 `br i1` | **EXIT 0** (8 calls) |
| `w1_loop_sibling_template.c` | in-loop sibling thetas over an `xor` parent | 2 `br i1` | DECLINE `condition predates a non-diagonal gate` |
| `w2_loop_sibling_chained_control.c` | `w1` with the sibling spelled CHAINED | 2 `br i1` | DECLINE `cq loop lowering: rail record read past an in-place gate on the same rail` |
| `w3_loop_sibling_and_parent.c` | sibling thetas over an `and` parent | 2 `br i1` | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` |
| `w4_loop_sibling_mul_parent.c` | over a `mul` parent | 2 `br i1` | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` |
| `w5_loop_sibling_and_chained_control.c` | `w3` with the sibling CHAINED | 2 `br i1` | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` |
| **`w6_loop_sibling_sub_parent.ll`** | HAND IR: sibling thetas over an **in-place `sub`** parent, in a loop | — | DECLINE **`cq loop lowering: loop-carried tainted value crosses iterations`** — i.e. the CONDITION-WIRE fence **granted** it (residual **(a)**) |
| **`w7_loop_sibling_add_parent_control.ll`** | the DISCRIMINATOR: `add %q, -9` instead of `sub %q, 9`, nothing else | — | DECLINE **`condition predates a non-diagonal gate`** — the condition-wire fence REFUSES |
| `w8_sub_sibling_nomeasure.ll` / `w9_add_sibling_nomeasure.ll` | `w6`/`w7` with the sibling's measure replaced by a pure `add` | — | both DECLINE `cq opcode lowering: operand predates a non-diagonal gate` (the pass-wide stale-record guard fires first — not useful as a discriminator) |

## The two probe pairs that matter

**`m1` vs `m3`** — one token apart (`int`/`_Bool`), opposite dispositions. `m1`'s
lowered module is

```
%h     = cqrt_alloc_i32(0) ; cqrt_ry_i32(%h, 0.5)
%m     = cqrt_measure_i32(%h)                        <-- the user's measurement
%h_cmp = cq_template_icmp_sgt_i32_hl(%h, 3)          <-- flag minted from a COLLAPSED register
         cqrt_rz_i1(%h_cmp, 0.3)  !cq.branchphase
         cq_template_icmp_sgt_i32_hl_unc(%h_cmp, %h, 3) ; cqrt_free(%h_cmp)
```

**`w6` vs `w7`** — the two modules differ in ONE instruction (`sub i32 %q, 9` vs
`add i32 %q, -9`), which M-C lowers to the SAME in-place `cqrt_addc_i32(%h, -9)`.
`w7` declines at the condition-wire fence; `w6` passes it and is caught one stage
later by `lowerLoops`' `kMsgCrossIter`. The difference is `WireWalk::
collectWireValues`' forward walk, which crosses `Instruction::Add` and
`Instruction::Xor` (`WireWalk.cpp:116-120`) and **not** `Sub` — so
`thetaOnPathTo` misses the sibling, `phiTracksWire` grants the header phi barrier
status it has not earned, and `gateIsHarmless` calls the sibling harmless. Closing
the **documented** null-`TaintSet` backward gap alone also closes `w6` (the
backward crossing would reach the `sub` result and its sibling user).
