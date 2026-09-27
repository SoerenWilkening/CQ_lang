#!/usr/bin/env python3
"""Write the bd vsfp lit fixtures into ir-pass/test: header + RUN/CHECK + the module
body (a generated fx/<k>.s1.ll, or a hand-written ll/<k>.ll)."""
import pathlib

V = pathlib.Path(__file__).parent
T = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/test")

REGEN = """; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h){extra}
;   llvm-link -S caller.ll lib.ll{extra2} -o <this file's body>"""


def src_block(k, libs=1):
    c = (V / "fx" / f"{k}.c").read_text().strip().split("\n")
    out = [";", "; Caller TU (clang -O1 -include CQ.h):"] + [";   " + l for l in c]
    for i in range(libs):
        sfx = "" if i == 0 else str(i + 1)
        lib = (V / "fx" / f"{k}.lib{sfx}.c").read_text().strip().split("\n")
        out += [f"; Library TU{'' if libs == 1 else ' ' + str(i + 1)} (plain C, no CQ.h):"] + [";   " + l for l in lib]
    extra = "" if libs == 1 else "\n;   clang -O1 -emit-llvm -S lib2.c -o lib2.ll     (plain C, no CQ.h)"
    extra2 = "" if libs == 1 else " lib2.ll"
    out += [";", REGEN.format(extra=extra, extra2=extra2), ";"]
    return "\n".join(out)


def body(path):
    return path.read_text()


FIX = {}

FIX["spec_accept_dropped_arg_boolsel.ll"] = ("fx/boolsel.s1.ll", 1, """; spec_accept_dropped_arg_boolsel.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-vsfp, P1 SILENT DEPHASING; bd 9bhg Rule-13 r2A F-9C-1, probe `b15`).
;
; THE DEFECT, on the oracle (`main` aee8f4f8). `h(a, k) = k + 1` ignores `a`, yet the
; call `h(p, m)` kept READING `p`: a Phase-6 site whose clone `__cq_q_h_01` never
; looks at its parameter 0 (bd hgwx's root cause, a phantom read). `p = b ? 9 : 4` is
; a 4.4 data select on a bare `_Bool`, so round-1 control emission minted its `%out`
; rail — two `cqrt_copy_i32_controlled` under a CNOT copy of `b`, i.e. a WHICH-PATH
; copy of `b` — and the phantom read was that rail's only reader. It was left
; allocated and entangled with `b` across `b = cq_theta(b, .7)`, so the Ry acted on a
; register whose branches were tagged: a DEPHASED circuit (analytic, r2A §F-9C-1:
; P(b=1) for odd m is cos^2(.6) = 0.6812 in the twin and 0.8356 here). `opt` exit 0,
; ZERO bytes of warnings (the lyyf-(B) warning does not model value-merge rails),
; stage 2b STRICT clean.
;
; THE FIX. `dropDeadCallArguments` (SpecializeDetect.h) runs before any stage reads an
; argument: `h`'s parameter 0 has no uses, so the operand becomes `0` and `p`'s cone
; (the select) is deleted — what `clang -O1` does to the twin (`int t = m + 1;`).
; Nothing is minted for `p`, no clone is built, and the stream is the twin's:
; Ry(.5), Ry(.7), one measurement, all on ONE handle. RED on the oracle: CHECK and
; NORAIL both fail there (it mints `%out` and calls `__cq_q_h_01`).
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NORAIL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[B:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(i1 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @h(i32 noundef 0, i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 0x3FE6666666666666)
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 [[B]])
; No which-path rail and no clone anywhere in the module (own prefix: whole file).
; NORAIL-NOT: cqrt_copy_i32_controlled
; NORAIL-NOT: __cq_q_h
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
; DROP-NOT: warning
""")

FIX["spec_accept_dropped_arg_boolsel_provisional.ll"] = ("fx/boolsel_provisional.s1.ll", 1, """; spec_accept_dropped_arg_boolsel_provisional.ll — ACCEPT with the hand-inlined twin's
; stream (bd test_C_libtooling-vsfp; r2A_9bhg F-9C-1 probe `b10f`, the repro in the bead).
;
; The same phantom read as `spec_accept_dropped_arg_boolsel.ll`, inside a `noinline` `f`
; whose return then depends on the spec site `t = h(p, m)` (a template rail here:
; `p = b + 1`). On the oracle (`main` aee8f4f8) this DECLINES at bd 3jru's refusal
; (`quantum value returned across a function boundary` — `t` is conservatively tainted
; and crosses `f`'s return); on bd 9bhg's branch (f2148d0a) it ACCEPTS SILENTLY with
; `%out` left entangled across Ry(.7) — P(b=1) 0.8356 vs the twin's 0.6812 (r2A). With
; the drop the call is `h(0, m)`, `t` is classical, `f`'s return is classical, and the
; stream is the twin's (`int t = m + 1;`): Ry(.5), Ry(.7), measure, one handle.
; RED on the oracle (it declines, so CHECK finds nothing).
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NORAIL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @f(
; CHECK:      [[B:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(i1 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @h(i32 noundef 0, i32 noundef %0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 0x3FE6666666666666)
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 [[B]])
; NORAIL-NOT: cqrt_copy_i32_controlled
; NORAIL-NOT: cq_template_
; NORAIL-NOT: __cq_q_h
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h in @f (inst)
; DROP-NOT: warning
""")

FIX["spec_reject_dropped_arg_classical_call_arm.ll"] = ("fx/classical_call_arm.s1.ll", 1, """; spec_reject_dropped_arg_classical_call_arm.ll — DECLINE with the hand-inlined twin's
; verdict and string (bd test_C_libtooling-vsfp; r2A_9bhg F-9C-1 probe `s3d`).
;
; THE DEFECT, on the oracle (`main` aee8f4f8): `if (q > 3) r = K(m);` is a 6.5
; classical-call arm — `K` hoisted, its result route-merged into a fresh `%out` rail
; under the flag of `q > 3` — and `r`'s ONLY reader was the phantom read `h(r, m)` of a
; clone that ignores it (`h(a, k) = k + 1`). ROUND 2 found that site (bd 9paa: `r` is
; classical until the `%out` reseed), so a taint-keyed fix could not have seen it.
; `%out` was left entangled with `q` across `q = cq_theta(q, .7)`: a dephased circuit,
; `opt` exit 0, NO warning, stage 2b STRICT clean.
;
; THE FIX. `dropDeadCallArguments` is STRUCTURAL and runs FIRST, before round 1 — `r`'s
; phi dies with the operand, exactly as `-O1` deletes it in the twin (`int u = m + 1;`,
; `K(m)` kept: its body is in another TU, so its call stays in the arm). What is left is
; the twin's IR, a tainted diamond whose arm holds a classical call and whose merge has
; NO phi, and it declines as the twin does — measured, the twin's `opt` prints this very
; string. RED on the oracle (exit 0 there, so `not` fails).
{src}
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\
; RUN:   | %filecheck %s
; CHECK: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
""")

FIX["spec_accept_dropped_arg_inplace_mc.ll"] = ("fx/inplace_mc.s1.ll", 1, """; spec_accept_dropped_arg_inplace_mc.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-hgwx, the WARNED sibling of bd vsfp; d88e probe `j02C`).
;
; THE DEFECT, on the oracle (`main` aee8f4f8). `t = h(q, m)` with `h(a, k) = k + 1`: the
; clone `__cq_q_h_01(q, m)` ignores `q`, but it still counted as a PRIOR USE of `q`, so
; M-C's G7 (`priorUseIsSettled`, ArithLowering.cpp arm (d)) refused to lower `u = t + q`
; IN PLACE: `cq_template_add_i32_hl(h, t)` minted a fresh rail, the Ry(.2) acted on it
; while `q` still carried the which-value record — a DEPHASED circuit (analytic, r1B
; §2: P(bit0 = 0) ~0.070 vs the twin's ~0.118), reported only by the lyyf-(B) warning
; `non-diagonal gate over a live derived record`. r1B's name-based mutant of arm (d)
; made it twin-identical; that mutant is UNSOUND for a quantum-verdict clone.
;
; THE FIX needs no change to M-C: the dead-argument drop removes the phantom read
; before any stage sees it (`h(0, m)`), so `q` has no prior user and `u = t + q` lowers
; IN PLACE as in the twin (`int t = m + 1;`): `cqrt_addc_i32(h, t)`, then Ry(.2) on the
; SAME handle, one measurement, no warning. RED on the oracle (out-of-place + warning).
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOOOP < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @h(i32 noundef 0, i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_addc_i32(i32 [[Q]], i32 [[T]])
; CHECK:      call void @cqrt_ry_i32(i32 [[Q]], double 2.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 [[Q]])
; NOOOP-NOT: cq_template_add_i32
; NOOOP-NOT: __cq_q_h
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
; DROP-NOT: warning
""")

FIX["spec_accept_dropped_arg_nested.ll"] = ("fx/nested.s1.ll", 2, """; spec_accept_dropped_arg_nested.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-vsfp — the TRANSITIVE case; a THREE-TU module).
;
; `out3(a, b) = in1(a, b) * 2 + b` FORWARDS `a` to `in1(a, k) = k + 1`, which ignores it.
; Within one TU `clang -O1`'s own dead-argument elimination would already have replaced
; `in1`'s argument by `poison` — so the forwarding call survives only when `in1` lives in
; ANOTHER TU, which is what this module is: `a` IS used in `out3` (by the call), and the
; one-pass rule "callee parameter has no uses" is false for `out3`. The drop is therefore
; a FIXPOINT: turn 1 replaces `in1`'s argument inside `out3`, which leaves `out3`'s `a`
; with no uses; turn 2 replaces `out3`'s argument in `main` and deletes the bool-select
; `p`. On the oracle (`main` aee8f4f8) `p`'s `%out` is minted and kept alive by the call
; across Ry(.7) — the vsfp dephasing, silently. Twin: `int t = (m + 1) * 2 + m;`.
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NORAIL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[B:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(i1 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @out3(i32 noundef 0, i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 0x3FE6666666666666)
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 [[B]])
; CHECK-LABEL: define {{.*}}@out3(
; CHECK:      call i32 @in1(i32 noundef 0,
; NORAIL-NOT: cqrt_copy_i32_controlled
; NORAIL-NOT: __cq_q_
; The two turns, in order: the inner drop FIRST is what licenses the outer one.
; DROP: CQ_DEADARG_DBG: drop arg 0 of @in1 in @out3 (arg)
; DROP-NEXT: CQ_DEADARG_DBG: drop arg 0 of @out3 in @main (inst)
; DROP-NOT: warning
""")

FIX["spec_accept_dropped_arg_quantum_clone_dead_slot.ll"] = ("fx/quantum_clone_dead_slot.s1.ll", 1, """; spec_accept_dropped_arg_quantum_clone_dead_slot.ll — ACCEPT with the hand-inlined twin's
; stream (bd test_C_libtooling-vsfp — a member NO earlier record named: the phantom read
; of a SPEC-QUANTUM clone).
;
; `h3(a, b, k) = b + k` reads `b` (a genuine quantum argument: the clone's verdict is
; QUANTUM) and ignores `a`. On the oracle (`main` aee8f4f8) the site's mask was `011`:
; `__cq_q_h3_011(%out, q, m)`, whose clone never looks at slot 0 — and `%out` is the 4.4
; bool-select rail of `p = b ? 9 : 4`, a which-path copy of `b`, left entangled across
; `b = cq_theta(b, .7)`. Silent, stage 2b clean. So the class is "a clone that does not
; read a slot it is passed", not "a classical-verdict clone" — the verdict is irrelevant.
; With the drop the mask is `010`: the clone reads exactly what it is given, `p` is
; never computed, and the stream is the twin's (`int t = q + m;`): the clone's
; Bennett copy-out of `q + m` is unchanged, the bool register sees Ry(.5), Ry(.7).
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NORAIL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[B:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(i1 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 5.000000e-01)
; CHECK-NEXT: [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 3.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h3_010(i32 noundef 0, i32 noundef [[Q]], i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 0x3FE6666666666666)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 [[B]])
; NORAIL-NOT: cqrt_copy_i32_controlled
; NORAIL-NOT: __cq_q_h3_011
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h3 in @main (inst)
; DROP-NOT: warning
""")

FIX["spec_accept_dropped_arg_quantum_clone_control.ll"] = ("fx/quantum_clone_control.s1.ll", 1, """; spec_accept_dropped_arg_quantum_clone_control.ll — ACCEPT, the CONTROL (bd
; test_C_libtooling-vsfp): a clone that READS its argument is untouched.
;
; `h(a, k) = a + k` reads `a`, so the drop must not fire, the site keeps its mask `01`,
; and `__cq_q_h_01` receives the bool-select's `%out` rail exactly as on the oracle —
; the lowered module is BYTE-IDENTICAL to `main` aee8f4f8's (measured with `cmp`). Here
; the rail is a REAL read: the clone's result `t = p + m` is measured, so `b`'s later
; Ry is dephased by the USER'S OWN measurement of a copy of `b`, as in the twin
; (`int t = p + m;`). What this pins: spec-QUANTUM clones are lowered as before.
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[OUT:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[a-z0-9.]+}}, i32 %{{[a-z0-9.]+}}, i32 [[OUT]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[a-z0-9.]+}}, i32 %{{[a-z0-9.]+}}, i32 [[OUT]])
; CHECK:      tail call i32 @__cq_q_h_01(i32 noundef [[OUT]], i32 noundef %{{[0-9]+}})
; NODROP-NOT: CQ_DEADARG_DBG
""")

FIX["spec_accept_dropped_arg_scrubbed_handle_branch.ll"] = ("fx/scrubbed_handle_branch.s1.ll", 1, """; spec_accept_dropped_arg_scrubbed_handle_branch.ll — ACCEPT with the hand-inlined twin's
; stream (bd test_C_libtooling-vsfp; the ORIGINAL spelling of bd l3oi's
; `taint_reject_scrubbed_handle_branch.ll`, which bd vsfp re-spelled with a dead read).
;
; On the oracle (`main` aee8f4f8) `t = h(q, m)` was a Phase-6 site, round-1 control built
; `cq_template_icmp_sgt_i32_hl(t, 3)` on it as a HANDLE, `specialize()` then proved the
; clone classical and bd l3oi's fence declined (`classical call result used as a quantum
; register`). That decline was an OVER-decline — the twin (`int t = m + 1;`) is a
; classical branch and accepts (bd cepm's class). With the drop, `h(0, m)` is an ordinary
; classical call, `t` is classical from the start, and the module is the twin: one Ry on
; `q`, a classical select, and the `cq_measure` of the classical `r` lowers to the value
; itself (bd 21mg — no symbol, no trace line). RED on the oracle (it declines).
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLASSICAL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @h(i32 noundef 0, i32 noundef %{{[0-9]+}})
; CHECK-NEXT: icmp sgt i32 [[T]], 3
; CHECK:      select i1
; No compare template on `t`, no clone, no measurement symbol.
; CLASSICAL-NOT: cq_template_
; CLASSICAL-NOT: __cq_q_
; CLASSICAL-NOT: cqrt_measure
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
""")

FIX["spec_reject_dropped_arg_statepred_runtime_seed.ll"] = ("fx/statepred_runtime_seed.s1.ll", 1, """; spec_reject_dropped_arg_statepred_runtime_seed.ll — DECLINE with the hand-inlined twin's
; verdict and string (bd test_C_libtooling-vsfp; the OWNER QUESTION bd z0re's member
; `l12C`, d88e probes).
;
; On the oracle (`main` aee8f4f8) `t = h(q, m)` was a Phase-6 site: round 1 read the
; conservatively-tainted `t` as a register and classified `if (q2 > 3) r = cq_theta(t, .2)`
; as an IN-PLACE controlled-Ry arm; after `specialize()` scrubbed `t` it lowered as a
; controlled state prep seeded by a RUNTIME value — a correct unitary by bd z0re's
; reading, but one the direct path's F1 fence refuses (the seed must be a literal, PRD
; §14.11 Q2, open in bd drbq.14). The twin (`int t = m + 1;`) declines at F1.
;
; With the drop the call is `h(0, m)`, `t` is classical from the start, and the module IS
; the twin: F1 declines with this very string. ⚠ THIS IS NOT A RULING ON bd z0re: it is
; what twin parity (the definition of "fixed" for bd vsfp) does to the DEAD-parameter
; spelling of z0re's side door — the program no longer goes through the side door at
; all. The side door itself (a clone that READS its argument yet returns classical) is
; unchanged and still awaits the owner's (a)/(b). RED on the oracle (exit 0 there).
{src}
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\
; RUN:   | %filecheck %s
; CHECK: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
; CHECK: error{{.*}}cq controlled lowering: state prep seed does not match the merge incoming under quantum control
""")

FIX["spec_accept_dropped_arg_fp.ll"] = ("fx/fp.s1.ll", 1, """; spec_accept_dropped_arg_fp.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-vsfp — the FLOATING-POINT slot).
;
; `hf(double a, int k) = k + 1` ignores its `double` parameter; the operand `e = d * 2.0`
; is an fp template rail on the `double` register `d`. On the oracle (`main` aee8f4f8) the
; phantom read kept `e`'s `cq_template_fmul_f64_hl` rail live across `d = cq_theta(d,
; .7)` — dephased, WARNED (`non-diagonal gate over a live derived record`). The drop's
; replacement constant is `Constant::getNullValue(double)`, i.e. `0.000000e+00` (+0.0,
; which no `nofpclass` clang emits at -O1 excludes; the attribute whitelist refuses any
; other parameter attribute anyway), and the stream is the twin's: Ry(.5), Ry(.7),
; measure, one handle, no warning.
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NORAIL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[D:%[a-z0-9.]+]] = call i32 @cqrt_alloc_f64(double %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_f64(i32 [[D]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @hf(double noundef 0.000000e+00, i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_f64(i32 [[D]], double 0x3FE6666666666666)
; CHECK-NEXT: call double @cqrt_measure_f64(i32 [[D]])
; NORAIL-NOT: cq_template_fmul
; NORAIL-NOT: __cq_q_hf
; DROP: CQ_DEADARG_DBG: drop arg 0 of @hf in @main (inst)
; DROP-NOT: warning
""")

FIX["spec_reject_phantom_arg_read_volatile_callee.ll"] = ("fx/derived_exempt_negative.s1.ll", 1, """; spec_reject_phantom_arg_read_volatile_callee.ll — DECLINE (bd test_C_libtooling-vsfp, the
; TOTAL half: `declinePhantomCloneArgReads`, reached FROM C).
;
; `h(a, k) { volatile int z = a; return k + 1; }` USES `a` — a volatile store to a
; non-escaping local — so the dead-argument drop (a predictor keyed on `use_empty()`)
; correctly leaves the call alone. But the CLONE's pipeline erases that store (the fenv
; ruling: a volatile access to a non-escaping local is not observable), and the built
; clone `__cq_q_h_01` then never reads its parameter 0: the phantom read the drop could
; not predict. The operand is the 4.4 bool-select `%out` rail, a which-path copy of `b`,
; kept alive only by that call across `b = cq_theta(b, .7)` — on the oracle (`main`
; aee8f4f8) a SILENTLY dephased circuit (exit 0, no warning, stage 2b clean). The
; backstop OBSERVES the built clone after `specialize()` and declines, as the last owner
; before `lowerRotations`. The operand is not a `cq_theta` result, so the fence's one
; exemption does not apply (its control: spec_accept_phantom_arg_read_theta_source.ll).
;
; ⚠ The hand-inlined twin (`volatile int z = p;` in the caller) is NOT a correctness
; oracle here: it compiles on every binary and is dephased the same way — the erased
; store leaves `p` dead, and a dead 4.4 select still gets its `%out` minted and never
; discharged. That is a separate, pre-existing defect with no clone in it, filed as bd
; qjoc (P1); declining this module is the safe direction and costs no correct accept.
{src}
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error{{.*}}in function main{{.*}}cq specialization: quantum argument to a parameter the lifted callee never reads
""")

FIX["spec_accept_phantom_arg_read_theta_source.ll"] = ("fx/theta_source_exempt.s1.ll", 1, """; spec_accept_phantom_arg_read_theta_source.ll — ACCEPT, byte-identical to the oracle (bd
; test_C_libtooling-vsfp — the backstop's ONE exemption; r2A_9bhg probe `cv9S`).
;
; The same volatile callee as `spec_reject_phantom_arg_read_volatile_callee.ll`, so the
; built clone again never reads its parameter 0 — but the operand is `q`, a `cq_theta`
; RESULT: the user's own register. The phantom read neither mints nor keeps alive a rail
; the hand-inlined twin lacks (`clang -O1` never deletes a `cq_theta` call, and nothing
; discharges a user register) — r2A's harmless quadrant, and the twin (`volatile int z =
; q; int t = m + 1;`) is TRACE-IDENTICAL on this binary. `declinePhantomCloneArgReads`
; exempts a `taint.ThetaCalls` member by MEMBERSHIP; delete the exemption and this file
; declines (an over-decline the oracle does not have).
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %{{[0-9]+}})
; CHECK:      call i32 @cqrt_measure_i32(i32 [[Q]])
; CHECK-LABEL: define internal i32 @__cq_q_h_01(
; CHECK-NOT:  store volatile
; CHECK:      ret i32
; NODROP-NOT: CQ_DEADARG_DBG
; NODROP-NOT: error
""")

FIX["spec_reject_phantom_arg_read_range_attr.ll"] = ("ll/bk_range_sel.ll", 0, """; spec_reject_phantom_arg_read_range_attr.ll — DECLINE (bd test_C_libtooling-vsfp, the TOTAL
; half: `declinePhantomCloneArgReads`). HAND-WRITTEN IR.
;
; `@h` ignores `%a`, the bead's shape, but `%a` carries `range(i32 1, 100)`: a null
; constant would violate it, so the dead-argument drop's attribute whitelist
; (noundef/signext/zeroext/inreg only) leaves the call alone — the predictor is
; deliberately conservative, and this is its miss. The operand is the 4.4 bool-select
; `%out` rail (`select i1 %b, i32 9, i32 4`), a which-path copy of `%b`, read only by the
; clone that ignores it, across Ry(.7) on `%b`: on the oracle (`main` aee8f4f8) a SILENTLY
; dephased circuit (exit 0, no warning, stage 2b clean). After `specialize()` the backstop
; sees the built clone's parameter 0 with no uses and a non-`cq_theta` tainted operand in
; that slot, and declines. The CHECK-NOT pins that the DROP did not fire — so the fence
; that speaks is the observer, not the predictor.
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error{{.*}}in function main{{.*}}cq specialization: quantum argument to a parameter the lifted callee never reads
""")

FIX["spec_reject_phantom_arg_read_clone_sweep.ll"] = ("ll/bk_sweep_sel.ll", 0, """; spec_reject_phantom_arg_read_clone_sweep.ll — DECLINE (bd test_C_libtooling-vsfp, the TOTAL
; half: `declinePhantomCloneArgReads` OBSERVES the built clone). HAND-WRITTEN IR.
;
; `@h` USES `%a` — `icmp sgt i32 %a, 3` steers a branch whose arms are EMPTY and whose
; merge carries no phi (`clang -O1` would have deleted it; hence IR) — so the drop, keyed
; on `use_empty()` of the callee's parameter, correctly does nothing. Inside the clone the
; branch is tainted: the scoped PredMux flatten (claimAll) removes it and its sweep takes
; the dead compare, so the BUILT `__cq_q_h_01` never reads parameter 0. That is the
; property only an observer after `specialize()` can see (the "observe, don't predict"
; lesson of bd woa0). The operand is the 4.4 bool-select `%out` rail, left entangled
; across Ry(.7) on the oracle (`main` aee8f4f8): silent, exit 0, stage 2b clean.
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error{{.*}}in function main{{.*}}cq specialization: quantum argument to a parameter the lifted callee never reads
""")

FIX["spec_accept_phantom_arg_read_theta_source_inplace_mc.ll"] = ("fx/theta_source_inplace_mc.s1.ll", 1, """; spec_accept_phantom_arg_read_theta_source_inplace_mc.ll — ACCEPT, IN PLACE like the
; hand-inlined twin (bd test_C_libtooling-hgwx's C-reachable RESIDUAL after bd vsfp's
; drop; M-C `priorUseIsSettled` arm (d0)).
;
; bd hgwx's `j02C` (`t = h(q, m); u = t + q; ... Ry(.2) on u`) with the callee's
; parameter READ by `volatile int z = a;` — so the dead-argument drop leaves the call
; alone, the clone's own lowering erases the store, and the built `__cq_q_h_01` never
; reads `q`. `q` is a `cq_theta` result, which `declinePhantomCloneArgReads` exempts, so
; the module reaches `lowerOps`. There, on the oracle (`main` aee8f4f8) and before arm
; (d0), M-C's G7 counted that phantom call as an UNSETTLED prior reader of `q` and
; lowered `u = t + q` OUT of place (`cq_template_add_i32_hl`) — the Ry(.2) then acted on
; the copy while `q` kept the which-value record: DEPHASED (hgwx's analytic 0.070 vs
; 0.118). Arm (d0) asks the CALLEE'S PARAMETER: a call that passes `q` only in slots its
; body never reads does not read `q`, and neither can its `_unc` twin. The add lowers IN
; PLACE (`cqrt_addc_i32` on `q`'s handle) and the gate stream is TRACE-IDENTICAL to the
; twin's (`volatile int z = q; int t = m + 1; ...`), measured.
;
; ⚠ STILL WARNED, AND THE WARNING IS SPURIOUS: M-A's `isCloneCallHop` classifies every
; non-void `__cq_q_*` result as a RECORD by NAME, and a classical-verdict clone's result
; is plain data. The stream is the twin's; the warning is filed as bd jr8q and is
; deliberately NOT pinned here either way. RED on the oracle (out-of-place add).
{src}
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=INPLACE < %t.cqd0.ll
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_addc_i32(i32 [[Q]], i32 [[T]])
; CHECK:      call void @cqrt_ry_i32(i32 [[Q]], double 2.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 [[Q]])
; INPLACE-NOT: cq_template_add_i32
""")

FIX["spec_accept_dropped_arg_theta_kept.ll"] = ("fx/theta_kept.s1.ll", 1, """; spec_accept_dropped_arg_theta_kept.ll — ACCEPT (bd test_C_libtooling-vsfp): the drop's
; cone deletion NEVER deletes a call, and a dead `cq_theta` stays.
;
; `q = cq_theta(m, .5)` is read only by `h(q, m)`, whose callee ignores it. The drop
; replaces the operand by `0`, which leaves `q` with no users — and `q` is a CALL, so
; the cone walk stops there: a `cq_theta` is the user's gate, "never this stage's to
; erase, WHATEVER ITS USE COUNT" (CLAUDE.md §4i), and `clang -O1` keeps it in the
; hand-inlined twin too (`cq_theta` carries no attributes in `CQ.h`, so a dead call to
; it is not trivially dead). The stream is the twin's (`int t = m + 1;`): the qubit is
; allocated and rotated, then left allocated (Rule 6; `Ry(θ)|m⟩` is not |0⟩).
; Deleting the `!isa<CallBase>` conjunct of the walk turns this red.
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @h(i32 noundef 0, i32 noundef %{{[0-9]+}})
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
""")

FIX["spec_reject_dropped_arg_weak_callee.ll"] = ("fx/weak_callee.s1.ll", 1, """; spec_reject_dropped_arg_weak_callee.ll — DECLINE, UNCHANGED from the oracle (bd
; test_C_libtooling-vsfp): the drop does NOT fire on an interposable callee.
;
; `__attribute__((weak)) int h(int a, int k) { return k + 1; }` ignores `a` in THIS
; module's body — but a `weak` definition may be replaced at link time by another
; body that reads `a`, so "the parameter has no uses" is a fact about a body that may
; never run. `dropDeadCallArguments` requires `hasExactDefinition()` (LLVM's own DAE
; precondition, and the specializer's `scanBody` precondition), so it leaves `h(p, m)`
; alone and the site declines where it always did, at the specializer's
; non-link-exact fence — character-for-character below, and the CHECK-NOT pins that
; the drop did not run first. Deleting the exactness conjunct of the drop turns this
; into an ACCEPT that drops an argument a different body may read.
{src}
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error{{.*}}cq specialization: callee has a non-link-exact definition (interposable/derefinable linkage); the linker may bind a different body
""")

FIX["spec_accept_dropped_arg_quantum_reader_unsettled.ll"] = ("fx/quantum_reader_unsettled.s1.ll", 1, """; spec_accept_dropped_arg_quantum_reader_unsettled.ll — ACCEPT, byte-identical to the
; oracle (bd test_C_libtooling-vsfp / hgwx — a CONTROL; d88e probe `j02Q`).
;
; `h(a, k) = a + k` READS `a`: the drop does not fire, the clone `__cq_q_h_01(q, m)` is
; spec-QUANTUM, and `u = t + q` is a Q+Q add (two handles), which M-C never lowers in
; place — so the stream is the oracle's, out of place. ⚠ What this file does NOT pin:
; M-C `priorUseIsSettled` arm (d0)'s per-slot READ test. A first draft of this header
; claimed it did; the mutation matrix measured that mutant (settle any call to a
; defined function) MISSED here, because a Q+Q add never reaches G7. The fixture that
; does pin it is spec_accept_dropped_arg_quantum_reader_outofplace.ll (a Q+C add).
; The warning that fires is the owner's lyyf-(B) user-circuit class, as on the oracle
; and the twin, and is not pinned here.
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call i32 @cq_template_add_i32(i32 [[T]], i32 [[Q]])
; CHECK-NOT:  cqrt_addc_i32
; CHECK:      ret i32
; NODROP-NOT: CQ_DEADARG_DBG
""")

FIX["spec_accept_dropped_arg_quantum_reader_outofplace.ll"] = ("fx/quantum_reader_outofplace.s1.ll", 1, """; spec_accept_dropped_arg_quantum_reader_outofplace.ll — ACCEPT, byte-identical to the
; oracle (bd test_C_libtooling-vsfp / hgwx — the CONTROL for M-C `priorUseIsSettled`
; arm (d0)'s per-slot READ test).
;
; `h(a, k) = a * 3 + k` READS `a`, so the clone `__cq_q_h_01(q, m)` is a real reader of
; `q` and `u = q + 5` (a Q+C add, an in-place candidate) sees it as a PRIOR USER. Arm
; (d0) settles a call only when every slot passing `q` is a parameter the callee never
; reads; here the slot is read, so (d0) does not apply, arm (d) refuses, and the add
; stays OUT of place — as on the oracle. MEASURED: the mutant "(d0) settles any call to
; a defined function passing `q`" lowers it IN place (`cqrt_addc_i32`), and this file
; is what catches it.
;
; ⚠ Whether that in-place lowering would be WRONG is a separate question and this file
; does not answer it. Arm (d)'s written hazard is a clone `_unc` twin re-reading `q`
; after the add, and the module-level spine never adjoints a clone call today
; (`Uncomputation.cpp`, `emitDagReversal`'s header: clone results are not rails). So
; settling a READING clone is plausibly sound — bd hgwx's "consult the verdict"
; suggestion goes further than (d0) — but it is an ACCEPT-direction widening of M-C that
; would owe its own argument and Rule-13 round. (d0) deliberately settles only a call
; that cannot read `q` at all; this file pins that boundary. The lyyf-(B) warning that
; fires is the oracle's too, and is not pinned.
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %{{[0-9]+}})
; CHECK-NEXT: [[U:%[a-z0-9._]+]] = call i32 @cq_template_add_i32_hl(i32 [[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[U]], double 2.000000e-01)
; CHECK-NOT:  cqrt_addc_i32
; CHECK:      ret i32
; NODROP-NOT: CQ_DEADARG_DBG
""")

FIX["spec_accept_dropped_arg_pure_call_kept.ll"] = ("fx/pure_call_kept.s1.ll", 1, """; spec_accept_dropped_arg_pure_call_kept.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-vsfp): the drop's cone deletion never deletes a CALL, even one LLVM
; calls trivially dead.
;
; `p = k2(q, 3)` feeds only `h(p, m)`, whose callee ignores it. After the drop `p` is dead,
; and — `k2` being a `memory(none) willreturn` definition after llvm-link —
; `isInstructionTriviallyDead` would let the walk delete it. The walk refuses every call:
; the hand-inlined twin (`int t = m + 1;`, `k2` still in another TU) keeps the call,
; because `clang -O1` in the caller TU sees only `int k2(int, int);`. So the stream is the
; twin's: `__cq_q_k2_01(q, 3)` still runs (its Bennett body's gates are in the trace)
; and its result is dropped. (A `cq_theta`/`cq_measure` call is not trivially dead in any
; case — `CQ.h` gives it no attributes — which is why `…theta_kept.ll` alone cannot see
; this conjunct: the mutation matrix measured it MISSED there.)
{src}
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @__cq_q_k2_01(i32 noundef [[Q]], i32 noundef 3)
; CHECK-NEXT: tail call i32 @h(i32 noundef 0, i32 noundef %{{[0-9]+}})
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
""")

for name, (bodyf, libs, text) in FIX.items():
    src = src_block(pathlib.Path(bodyf).name.replace(".s1.ll", ""), libs) if libs else ""
    hdr = text.replace("{src}", src) if libs else text
    b = body(V / bodyf)
    (T / name).write_text(hdr.rstrip("\n") + "\n\n" + b)
    print("wrote", name)
