# Track L probes — the LOOP form of the owner's controlled-operation cascade (2026-09-13)

Measured on the frozen **ORACLE** (PROTOCOL.md): `build/ir-pass/cq-opt` sha256
`fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661`, `libCQPass.so`
`40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93` (built 2026-09-11 22:23 from
`e96f89c`; `main` `01c89b5` is docs-only over it). Hash verified with `shasum -a 256` before the
first run and unchanged after the last. **No build, no `lit`, no `ctest`** (scoping row).

Command per probe (from the repo root, `LLVM=/usr/local/opt/llvm@19/bin`) — `run.sh` is this loop:

```
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S <probe>.c -o s1.ll
build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S s1.ll -o s2.ll; echo $?
python3 tools/free_pairing_check.py s2.ll                                          # accepts only, STRICT
"$LLVM/clang" s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o a && ./a
CQ_CTRL_DBG=1 build/ir-pass/cq-opt … 2>&1 | grep CQ_CTRL_DBG                       # the firing ANCHOR
```

`-g` is used for the source-located diagnostic and **omitted** for every IR line count (debug
metadata inflates it — the reason this file's `ir=` column, taken with `-g`, differs from the
K-independence numbers below).

## Verdict table (every row run on the ORACLE, 2026-09-13)

| probe | shape | exit | first diagnostic / result |
|---|---|---|---|
| `a_loop_n2` | **Q2(i)** `bool b[2]` in a `for`, rolled | 1 | `a_loop_n2.c:6:26: … cq taint escape: tainted value stored to memory` |
| `a_loop_n3` | Q2(i) N=3 (= `../../probes/ve.c`) | 1 | same, `:6:26` |
| `a_loop_n8` | Q2(i) N=8 | 1 | same — **the wall is N-independent** |
| `a_loop_n3_noarm` | Q2(i), value arm deleted | 1 | same — the subject is the STORE |
| `a_loop_n3_uncond` | Q2(i), prep unconditional (no region) | 1 | same, `:6:14` — upstream of all control work |
| `a_flat_n2` | Q2(i) hand-unrolled, constant indices | 1 | `:8:9: … control flow under quantum control` — **the array is GONE** |
| `a_flat_n3` | Q2(i) hand-unrolled N=3 | 1 | `:5:24: … state prep seed is proven equal to the condition register` |
| `s_loop_n2` | **Q2(ii)** scalar `bool b = 0`, rolled N=2 | 1 | `:6:23: … arm rewrites a condition operand` |
| `s_loop_n3` / `s_loop_n8` | Q2(ii) N=3 / N=8 | 1 | same string, same site — N-independent |
| `s_flat_n2` / `s_flat_n3` | Q2(ii) hand-unrolled | 1 | `:5:21: … condition predates a non-diagonal gate` |
| `s_loop_phase` | Q2(ii), phase arm, `bool b = 0` | 1 | `… cq taint escape: tainted value muxed by a classical-condition phi` |
| `s_loop_uncond_phase` | `for(i<3){ b = cq_theta(b,.2); if (b) cq_phi(.7); }` with `bool b = 0` | 1 | same — **p2's accept shape loses ONLY the theta seed** |
| `s_loop_uncond_value` | same, value arm | 1 | same |
| `t_loop_n2/n3/n8` | Q2(ii) with a **theta seed** | 1 | `:6:23: … arm rewrites a condition operand`, anchor `%17 = zext i1 %16 to i8` |
| `t_flat_n2` | the theta-seeded flat twin | 1 | `condition predates a non-diagonal gate` |
| `t_loop_phase` | theta-seeded phase spelling | 1 | `cq_measure_<sfx> operand not recognized…` — **probe artefact** (`cq_measure` of a classical `a`); use `w2` |
| `t_loop_uncond_value` | theta seed, uncond prep, value arm | 1 | `cq loop lowering: loop-carried tainted value crosses iterations` |
| `t_loop_uncond_value_inv` | invariant bool, value arm only | 1 | same |
| `w1_phase_quantum_a` | clobber peeled → phase arm, quantum `a` | 1 | `condition predates a non-diagonal gate`, anchor `%4 = icmp sgt i32 %1, 2` (**LICM-hoisted invariant compare**, row W) |
| **`w2_uncond_prep_phase_qa`** | uncond prep + phase arm + a second quantum register | **0** | **ACCEPT**, 12 trace lines, STRICT 2b `2 rail mint(s) of which 2 left allocated, 0 cqrt_free site(s): … 0 violation(s), 0 unproven` |
| `w3_value_diamond` | the value arm as a two-op DIAMOND, no prep | 1 | `loop-carried tainted value crosses iterations` — **the LOOP LAYER, before detection** |
| `w5_invariant_bool_value` | value arm as a select, invariant bool | 1 | same |
| `w8_cond_not_clobbered` | prep condition on a different register `q` | 1 | `condition predates a non-diagonal gate`, same `icmp` anchor |
| `w9_cond_not_clobbered_phase` | `w8` + phase arm | 1 | same |
| `p1` | boi6 p1 — the carried **header phi** as the condition | 1 | `:6:13: … branch phase on a bare i1 condition` (bd `boi6.a`) |
| **`p2`** | boi6 p2 — theta BEFORE the region | **0** | **ACCEPT rolled**, 9 trace lines, 50 lowered lines (no `-g`), STRICT 2b `1 rail mint … 0 violation(s)` |
| **`p9`** | p2 with `if (!b)` | **0** | **ACCEPT**, `cqrt_rz_i1(h0, −θ)`, **no `cqrt_x`**, 9 lines |
| `p2u` / `p9u` | the hand-unrolled K=3 twins | 0 | ACCEPT; traces **byte-identical** to `p2` / `p9` (`diff` clean) |
| `p2k1000` | p2 at K=1000 | 0 | ACCEPT; 2003 trace lines, **50 lowered lines — identical to K=3** |
| `p6` | boi6 p6 — 4.4 data select on a carried bool in a loop | 1 | `loop-carried tainted value crosses iterations` |
| `p23` | boi6 p23 — the loop-INVARIANT bool (shipped 1b accept) | 0 | ACCEPT, 6 trace lines (the control) |

## The numbers, each with its command

```
# ORACLE identity
shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
#   fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661  cq-opt
#   40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93  libCQPass.so

# K-INDEPENDENCE of the H-10 pin (NO -g)
clang -Iinclude -include CQ.h -O1 -emit-llvm -S p2.c      | cq-opt … | wc -l   ->  50
clang -Iinclude -include CQ.h -O1 -emit-llvm -S p2k1000.c | cq-opt … | wc -l   ->  50
# and the traces:  p2 9 lines, p2k1000 2003 lines, p2u 9 lines
diff p2.trace p2u.trace   -> identical ;  diff p9.trace p9u.trace -> identical

# Does -O1 scalarise a small constant-N bool array?  ONLY when the SOURCE is unrolled.
grep -cE 'alloca|store' <a_flat_n2 stage-1 .ll>      ->  0      (fully SROA'd)
grep -E 'llvm.loop|alloca|store i8' <a_loop_n2 stage-1 .ll>
#   %1 = alloca [2 x i8] ; store i8 %13, ptr %9 ; !57 = !{!"llvm.loop.unroll.disable"}
# -O1 stamps llvm.loop.unroll.disable on the loop, so NO N makes the rolled array scalarise.

# a_flat_n2's main vs ../../probes/vb.c's main (both -O1, no -g)
diff <(sed -n '/define.*@main/,/^}/p' vb.ll) <(sed -n '/define.*@main/,/^}/p' a_flat_n2.ll)
#   differs ONLY in the measure order (the probes' return expressions differ) — the
#   cascade itself is byte-identical, i.e. the unrolled ARRAY spelling IS the flat file.
```

## Firing sites (read in source at `01c89b5`, anchors from `CQ_CTRL_DBG=1`)

| string | site | what it is |
|---|---|---|
| `tainted value stored to memory` | `TaintPropagation.cpp:526` (`kMsgStore`), via `declineTaintEscapes`; the QRAM carve returns `NotQram` for a **classical-index / value-tainted** store (`QramLowering.h:56-60`) | the array wall |
| `tainted value muxed by a classical-condition phi` | `TaintPropagation.cpp:958`, `declineClassicalMuxes`, run AFTER detection | the classical-seed rail-root wall |
| `arm rewrites a condition operand` | `ArmClassify.cpp:4593` (`diagonalAliasHit(Routed, Prov)` with `StraightThrough && Hit == Routed`), anchor `Chain.Ops.front()` | the §3c clobber fence, reached through the BACK EDGE |
| `condition predates a non-diagonal gate` | the 2c wire fence in `classifyArms`, anchored on the LICM-hoisted `icmp` | row W / bd `drbq.12` |
| `loop-carried tainted value crosses iterations` | `LoopLowering.cpp:2108` (`kMsgCrossIter`, the X1 clause: the latch incoming peels to a FRESH value-op rail), reached from `lowerLoops` at `CQLoweringPass.cpp:373` — **before** `detectControlRegions` at `:455` | the value-arm wall |
| `branch phase on a bare i1 condition` | `ArmClassify.cpp` step-5 refusal (boi6 §1 row) | bd `boi6.a` |
