#!/usr/bin/env python3
"""mkfix.py — write the bd cepm / bd 3zr4 lit fixtures into ir-pass/test/ from the
battery's stage-1 modules ($S/cepm/p/<probe>.s1.ll, built by gen.sh). Each fixture is
a header (the C of every TU, the oracle's verdict, the twin, what is pinned) + RUN/CHECK
lines + the linked module verbatim. Re-run after regenerating a probe."""
import os

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d"
S = ("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
     "e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad")
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
P = os.path.join(S, "cepm", "p")
REC = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes"

ACC_RUN = ("; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \\\n"
           "; RUN:   | %filecheck %s\n")
DEC_RUN = ("; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\\n"
           "; RUN:   | %filecheck %s\n")

READING = """\
; THE READING CALLEE. `h` READS its quantum argument — through a call to `g`, whose own
; callee `f2` is an external in `g`'s TU, so `-O1` infers no `memory(none)`/`willreturn`
; for `g` and the pass's liveness (DeadValueLiveness.h) keeps the call as a ROOT, so bd
; vsfp's dead-argument drop does NOT fire — and returns the CLASSICAL `k + 1`.
; `predictReturnTainted(h, 01)` is FALSE (the masked parameter reaches neither the
; `ret` nor a conditional terminator), so since bd cepm propagation leaves the call's
; RESULT classical (`specCallResultPredictedClassical`, SpecializeClone.h): no stage
; before `specialize()` reads it as a register, and the clone `@__cq_q_h_01` (built
; unchanged) returns the classical value. Before bd cepm the result was tainted
; CONSERVATIVELY and scrubbed only after both control rounds."""


def libs_of(probe):
    out = []
    with open(os.path.join(SRC, probe + ".libs")) as f:
        for s in f:
            s = s.strip()
            if s:
                out.append(open(os.path.join(SRC, s + ".lib1.c")).read().strip())
    return out


def header(name, kind, bead, probe, prose, oracle, twin):
    c = open(os.path.join(SRC, probe + ".c")).read().strip().splitlines()
    libs = libs_of(probe)
    lines = [f"; {name}.ll — {kind} ({bead})."]
    lines += prose.splitlines()
    lines.append(";")
    lines.append(f"; {1 + len(libs)} TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.")
    lines.append("; Caller TU (-include CQ.h):")
    lines += [";   " + l for l in c if not l.startswith("#include")]
    for i, lb in enumerate(libs, 1):
        lines.append(f"; Library TU {i} (plain C):")
        lines += [";   " + l for l in lb.splitlines()]
    lines.append(";")
    lines += ["; " + l for l in oracle.splitlines()]
    lines += ["; " + l for l in twin.splitlines()]
    lines.append(f"; Regenerate: {REC}/mkprobes.py + gen.sh {probe}, then mkfix.py.")
    lines.append(";")
    return "\n".join(l if l.startswith(";") else "; " + l for l in lines) + "\n"


FIX = []


def fix(name, kind, bead, probe, prose, oracle, twin, checks):
    FIX.append((name, kind, bead, probe, prose, oracle, twin, checks))


TWIN_SAME = ("Hand-inlined twin ({t}.c: `g(q); int t = m + 1;`) is TRACE-IDENTICAL under argv\n"
             "`5 7` and `2 9`, stage 2b STRICT clean on both ({rec}/twincmp.sh).")

# ---------------------------------------------------------------- ACCEPTS (bd cepm)
fix("spec_accept_predicted_classical_branch", "ACCEPT", "bd test_C_libtooling-cepm", "brC",
    READING + "\n; Here the result is a BRANCH condition over an in-place Ry of `q`: a CLASSICAL branch.",
    "Oracle 9a230646: DECLINE `condition predates a non-diagonal gate under quantum control` (the\n"
    "conservative taint made `t > 3` a quantum condition on the handle `t`).",
    TWIN_SAME.format(t="brT", rec=REC),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[H:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %[[H]], i32 noundef %{{[0-9]+}})
; CHECK-NEXT:  %[[C:[0-9]+]] = icmp sgt i32 %[[T]], 3
; CHECK-NEXT:  br i1 %[[C]],
; CHECK:       call void @cqrt_ry_i32(i32 %[[H]], double 2.000000e-01)
; CHECK:       cqrt_measure_i32(i32 %[[H]])
; CHECK-LABEL: define internal i32 @__cq_q_h_01(
; CHECK-NOT:   cqrt_copy_i32(
; CHECK:       ret i32
""")
fix("spec_accept_predicted_classical_select", "ACCEPT", "bd test_C_libtooling-cepm", "selC",
    READING + "\n; Here the result drives an if-converted DATA select: a CLASSICAL `select`, no 4.4 merge.\n"
    "; (bd l3oi's `taint_reject_scrubbed_handle_branch.ll` shape, with a callee that READS.)",
    "Oracle 9a230646: DECLINE `classical call result used as a quantum register` (bd l3oi: the 4.4\n"
    "emitter minted `icmp_sgt_i32_hl` on the integer `t` as a handle).",
    TWIN_SAME.format(t="selT", rec=REC),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[H:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %[[H]], i32 noundef %{{[0-9]+}})
; CHECK-NEXT:  %[[C:[0-9]+]] = icmp sgt i32 %[[T]], 3
; CHECK:       select i1 %[[C]],
; CHECK-NOT:   cqrt_copy_i32_controlled
; CHECK-NOT:   cq_template_icmp
; CHECK:       ret i32
""")
fix("spec_accept_predicted_classical_phase", "ACCEPT", "bd test_C_libtooling-cepm", "ph1C",
    READING + "\n; Here the result is a `cq_phi` condition: a CLASSICAL condition, so the phase is global and\n"
    "; deleted (Rule 3) — no kickback, no flag.",
    "Oracle 9a230646: DECLINE `classical call result used as a quantum register` (the kickback flag\n"
    "was minted on the handle `t`).",
    TWIN_SAME.format(t="ph1T", rec=REC),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK-NEXT:  icmp sgt i32 %[[T]],
; CHECK-NOT:   cqrt_rz_i1
; CHECK-NOT:   cq_template_icmp
; CHECK:       ret i32
""")
fix("spec_accept_predicted_classical_return", "ACCEPT", "bd test_C_libtooling-cepm (bd 9bhg's population)", "rt9C",
    READING + "\n; Here `f` RETURNS `t + cq_measure(q)`, a classical value: `f`'s `ret` is never tainted, so bd\n"
    "; 3jru's return crossing never taints `f(m)` in `main` and `if (x > 5)` is classical. This is\n"
    "; bd 9bhg's reported class, reached with a callee that READS its argument (bd vsfp's drop\n"
    "; covers only a callee that ignores it).",
    "Oracle 9a230646: DECLINE `quantum value returned across a function boundary` (bd 3jru).",
    TWIN_SAME.format(t="rt9T", rec=REC),
    """; CHECK-LABEL: define i32 @f(
; CHECK:       %[[H:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %[[H]],
; CHECK:       %[[M:[A-Za-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  add nsw i32 %[[M]], %[[T]]
; CHECK-LABEL: define i32 @main(
; CHECK:       %[[X:[0-9]+]] = tail call i32 @f(
; CHECK:       icmp sgt i32 %[[X]], 5
; CHECK-NOT:   cq_template_icmp
; CHECK:       ret i32
""")
fix("spec_accept_predicted_classical_clone_arg", "ACCEPT", "bd test_C_libtooling-cepm", "ybC",
    READING + "\n; Here the result is the FIRST argument of another lifted call `g4(t, q)`: its detection mask is\n"
    "; `10` (only `q` quantum) and `t` rides the clone's LITERAL slot. Before bd cepm the mask was\n"
    "; `11` from the conservative taint and bd l3oi's clone-reader clause declined.",
    "Oracle 9a230646: DECLINE `classical call result used as a quantum register` (clone-reader clause).",
    TWIN_SAME.format(t="ybT", rec=REC),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[H:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %[[H]],
; CHECK-NEXT:  tail call i32 @__cq_q_g4_10(i32 noundef %[[T]], i32 noundef %[[H]])
; CHECK-NOT:   __cq_q_g4_11
; CHECK:       ret i32
""")
fix("spec_accept_predicted_classical_lift", "ACCEPT", "bd test_C_libtooling-cepm (bd d88e's `l19`)", "l19C",
    READING + "\n; Here `cq_theta(t, .1)` is a SOURCE (a classical seed, `cqrt_alloc_i32(t)`), so the one-register\n"
    "; lift's conjunct (6) sees the twin's shape. Before bd cepm it was a conservatively CHAINED theta\n"
    "; outside the arm and the lift refused.",
    "Oracle 9a230646: DECLINE `tainted value muxed by a classical-condition phi`.",
    TWIN_SAME.format(t="l19T", rec=REC),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK-NEXT:  %[[R:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[T]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)
; CHECK:       call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK:       cqrt_measure_i32(i32 %[[R]])
""")
fix("spec_accept_predicted_classical_loop_break", "ACCEPT", "bd test_C_libtooling-cepm (bd d88e's `a04`)", "a04C",
    READING + "\n; Here the result decides a loop `break`: a CLASSICAL exit test, an ordinary classical loop.",
    "Oracle 9a230646: DECLINE `loop under quantum control`.",
    TWIN_SAME.format(t="a04T", rec=REC),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK-NEXT:  %[[C:[0-9]+]] = icmp sgt i32 %[[T]], 5
; CHECK-NEXT:  br i1 %[[C]],
; CHECK-NOT:   cq_template_icmp
; CHECK:       ret i32
""")
fix("spec_accept_predicted_classical_bank", "ACCEPT", "bd test_C_libtooling-cepm (bd d88e's `a03`)", "a03C",
    READING + "\n; Here each result is STORED to an ordinary array (`b[i] = h(q, i)`) and later `cq_measure`d:\n"
    "; a classical store and a classical `cq_measure` (bd 21mg — the value itself, no gate). No rail\n"
    "; bank is built. ⚠ stage 2b (tools/free_pairing_check.py) CANNOT adjudicate this module: it models\n"
    "; every `@__cq_q_*` result as a rail and refuses a store of one to unmarked memory\n"
    "; (`L1-rail-stored-to-unmarked-memory`) — an instrument gap filed with this change, not a defect\n"
    "; of the stream; the traces were compared by hand.",
    "Oracle 9a230646: DECLINE `cq rail bank: a cell parks a value that is not a rail handle`.",
    "Hand-inlined twin (a03T.c) is TRACE-IDENTICAL under argv `5 7` and `2 9` (compared by hand; the\n"
    "twin passes stage 2b STRICT).",
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK:       store i32 %[[T]], ptr
; CHECK-NOT:   railbank
; CHECK:       ret i32
""")
fix("spec_accept_predicted_classical_fp_return", "ACCEPT", "bd test_C_libtooling-cepm", "fpC",
    READING.replace("returns the CLASSICAL `k + 1`", "returns the CLASSICAL `k * 2.0`")
    + "\n; An fp return: the SAME predictor already decided the clone's signature (`cloneFor` keeps the\n"
    "; `double`), and now also leaves the call's result classical: `fcmp` on it is a classical branch.",
    "Oracle 9a230646: DECLINE `condition predates a non-diagonal gate under quantum control`.",
    "Hand-inlined twin (fpT.c: `g(q); double t = (double)m * 2.0;`) is TRACE-IDENTICAL under argv\n"
    "`5 7` and `2 9`, stage 2b STRICT clean on both.",
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call double @__cq_q_hf_01(
; CHECK-NEXT:  %[[C:[0-9]+]] = fcmp ogt double %[[T]], 7.000000e+00
; CHECK-NEXT:  br i1 %[[C]],
; CHECK-LABEL: define internal noundef double @__cq_q_hf_01(
""")
fix("spec_accept_predicted_classical_switch", "ACCEPT", "bd test_C_libtooling-cepm", "swC",
    READING + "\n; Here the result is a `switch` scrutinee over in-place rotations: a CLASSICAL switch.",
    "Oracle 9a230646: DECLINE `control flow under quantum control`.",
    TWIN_SAME.format(t="swT", rec=REC),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK-NEXT:  switch i32 %[[T]],
; CHECK-NOT:   cq_template_icmp_eq
; CHECK:       ret i32
""")
fix("spec_accept_predicted_classical_classical_phi", "ACCEPT", "bd test_C_libtooling-cepm", "cphC",
    READING + "\n; Here the call sits on a CLASSICAL branch (`if (n > 3) t = h(q, m);`), so `t` is merged by a\n"
    "; classical-condition φ — of two classical values, which the classical-mux guard never asks about.",
    "Oracle 9a230646: DECLINE `control flow under quantum control`.",
    TWIN_SAME.format(t="cphT", rec=REC),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK-NEXT:  icmp sgt i32 %[[T]], 4
; CHECK-NOT:   cq_template_icmp
; CHECK:       ret i32
""")

# ---------------------------------------------------------------- ACCEPT (bd 3zr4)
fix("spec_accept_predicted_classical_round2_site", "ACCEPT", "bd test_C_libtooling-3zr4 (and bd cepm)", "z3C",
    READING.replace("`predictReturnTainted(h, 01)`", "`predictReturnTainted(h, 01)`") +
    "\n; bd 3zr4's shape: `y` is a 6.5 classical-call-arm merge `%out`, tainted only in ROUND 2, so\n"
    "; `h(y, m)` is a ROUND-2 Phase-6 site (`detectSpecializations(…, &live)` APPENDS it to `Pending`)\n"
    "; and `g2(t, q)` a ROUND-1 site reading its result. Before bd cepm, `t` was tainted in round 2,\n"
    "; `replanReseedSpecialization` grew `g2`'s mask to `11`, `specialize()` built `g2`'s clone with `t`\n"
    "; in a HANDLE slot, then scrubbed `t`, and bd l3oi's clone-reader clause declined. Now the round-2\n"
    "; drain asks the SAME predictor (every `propagateWorklist` drain does): `t` stays classical, `g2`'s\n"
    "; mask stays `10`, and there is no stale mask to resolve — in ANY drain order.\n"
    "; ⚠ bd 3zr4's own text names an ordered scrub over `Pending` in STORAGE order; that mechanism is\n"
    "; bd 9bhg's PARKED branch (tag archive/2026-09-27/9bhg-provisional-return) and is not on `main`.\n"
    "; On `main` the decline had the same verdict for this simpler reason.",
    "Oracle 9a230646: DECLINE `classical call result used as a quantum register`. (The bead's original\n"
    "repro, `h(a,k) = k + 1`, ACCEPTS on the oracle since bd vsfp: its argument is dropped.)",
    "Hand-inlined twin (z3T.c: `g(y); int t = m + 1;`) is TRACE-IDENTICAL under argv `5 7` and `2 9`,\n"
    "stage 2b STRICT clean on both.",
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[H:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:       %[[OUT:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %[[OUT]],
; CHECK-NEXT:  tail call i32 @__cq_q_g2_10(i32 noundef %[[T]], i32 noundef %[[H]])
; CHECK-NOT:   __cq_q_g2_11
; CHECK:       ret i32
""")

# ---------------------------------------------------------------- DECLINES
fix("spec_reject_predicted_classical_inner_clone", "DECLINE", "bd test_C_libtooling-cepm (residual)", "in2C",
    "; The predictor OVER-approximates through an INNER call's result: `h2(a,k) = h(a,k) * 2` with `h`\n"
    "; the reading callee (classical return). `predictReturnTainted(h2, 01)` follows `a` into `h(a, k)`\n"
    "; and on through its result to `h2`'s `ret` — TRUE — so `t = h2(q, m)` is tainted conservatively\n"
    "; as before bd cepm, the 4.4 emitter mints a flag on it, `specialize()` proves the clone classical,\n"
    "; and bd l3oi's fence refuses the integer read as a register. A SAFE over-decline that bd cepm does\n"
    "; not remove (the predictor is not recursive). RETIREMENT TRIGGER (L8): a predictor that asks the\n"
    "; inner callee's own prediction turns this into an ACCEPT — re-derive it (its twin, in2T.c,\n"
    "; accepts), do not delete it; the l3oi fence then needs another subject.",
    "Oracle 9a230646: the same DECLINE (byte-identical first error line).",
    "Hand-inlined twin (in2T.c) ACCEPTS: an over-decline, filed on bd cepm.",
    """; CHECK: cq taint escape: classical call result used as a quantum register
""")
fix("spec_reject_predicted_classical_value_arm", "DECLINE", "bd test_C_libtooling-cepm (the L3 conjunct)", "vaC",
    "; The call sits in the ARM of a QUANTUM condition (`if (q > 5) y = h(q, m);`). Its result is\n"
    "; predicted classical, so it is no longer tainted — and `classifyClassicalCallArm` (6.5) used the\n"
    "; RESULT's taint as its proof that every INPUT is classical (\"propagate taints EVERY user of a\n"
    "; tainted value\", false since bd cepm). It now asks the inputs directly (`readsTaintedValue`),\n"
    "; so the call is NOT a 6.5 classical-call arm and the region declines at `classifyArms` exactly\n"
    "; as on the oracle. THE STRING IS THE PIN: without the `readsTaintedValue` conjunct the 6.5\n"
    "; classifier claims the shape and declines `control flow under quantum control` (measured on\n"
    "; this module), and a callee whose argument survives the drop with a `memory(none)` body (an\n"
    "; IR-level shape) would be claimed and hoisted by it — see the ATTACK list in TRACK_CEPM_3ZR4.md.",
    "Oracle 9a230646: the same DECLINE (byte-identical first error line).",
    "Hand-inlined twin (vaT.c) declines with the SAME string.",
    """; CHECK: cq controlled lowering: value-arm swap-route under quantum control
""")
fix("spec_reject_predicted_classical_stale_record", "DECLINE", "bd test_C_libtooling-cepm (bd d88e's `l04`)", "l04C",
    "; `t = h(q, m); r = t; if (m > 3) r = cq_theta(t, .2); … return t + s`. Before bd cepm the\n"
    "; EARLY `declineStaleRecordOps` read the conservative taint (the arm's `cq_theta(t, .2)` a chained\n"
    "; gate on `t`'s wire) and declined `operand predates a non-diagonal gate` — an owner the twin never\n"
    "; reaches. With `t` classical the module declines at the TWIN'S owner (the classical-mux guard:\n"
    "; `r` muxes the rotated register against the classical `t` under the classical `m > 3`).",
    "Oracle 9a230646: DECLINE `operand predates a non-diagonal gate` (a different owner).",
    "Hand-inlined twin (l04T.c) declines with the SAME string as this module now does.",
    """; CHECK: cq taint escape: tainted value muxed by a classical-condition phi
; CHECK-NOT: operand predates a non-diagonal gate
""")
fix("spec_reject_predicted_quantum_some_paths", "DECLINE", "bd test_C_libtooling-cepm (negative)", "npC",
    "; `h(a,k) { g(a); return k > 3 ? a : k; }` returns the QUANTUM argument on SOME paths: the\n"
    "; masked parameter reaches the `ret` through the select, `predictReturnTainted` is TRUE, and the\n"
    "; call's result stays tainted exactly as before bd cepm. The clone then declines its own\n"
    "; classical-condition select over a quantum arm. Pins that a partially-quantum return is never\n"
    "; predicted classical.",
    "Oracle 9a230646: the same DECLINE (byte-identical first error line).",
    "Hand-inlined twin (npT.c) accepts; this is the specializer's pre-existing select fence, unchanged.",
    """; CHECK: cq specialization: mixed classical/quantum select under quantum lift
""")
fix("spec_reject_predicted_classical_memory_escape", "DECLINE", "bd test_C_libtooling-cepm (negative)", "nmC",
    "; `int G; h(a,k) { G = a; return k + 1; }` returns a classical value but lets the quantum\n"
    "; argument ESCAPE THROUGH MEMORY. The predictor says classical (the store is not a use it\n"
    "; follows), so the result is untainted — and the callee is still refused by `scanBody` (a store\n"
    "; is not reversibilizable), loudly, at detection: an untainted result never makes a callee\n"
    "; liftable.",
    "Oracle 9a230646: the same DECLINE (byte-identical first error line).",
    "Hand-inlined twin (nmT.c) declines `tainted value stored to memory` (a different owner, same verdict).",
    """; CHECK: cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access)
""")
fix("spec_reject_predicted_classical_recursive_subcall", "DECLINE", "bd test_C_libtooling-cepm (negative)", "nr2C",
    "; `h(a,k) { g(a); return k2(k); }` with `k2` doubly recursive on the CLASSICAL `k`: predicted\n"
    "; classical, so the result is untainted — and `scanBody`'s call-graph cycle rule still refuses\n"
    "; `h` (it walks into the classical subcall `k2`), loudly, at detection. (The tail-recursive\n"
    "; spelling is turned into a loop by `-O1` and is a cepm ACCEPT, battery member `tre`.)",
    "Oracle 9a230646: the same DECLINE (byte-identical first error line).",
    "Hand-inlined twin (nr2T.c: `k2(m)` a classical call) accepts: `scanBody`'s pre-existing\n"
    "over-decline of a recursive CLASSICAL subcall, unchanged by bd cepm.",
    """; CHECK: cq specialization: recursive callee has no static depth bound
""")

# ---------------------------------------------------------------- ROUND 1b: mask growth
R2 = """\
; bd cepm ROUND 1b — a ROUND-2 MASK-GROWTH site. `t = h(q, y)` with `y` a 6.5 classical-call-arm
; merge `%out` (`if (q > 5) y = ext_f(7);`), tainted only in ROUND 2. At round 1 the mask is `01`
; and `predictReturnTainted(h, 01)` is FALSE (`k + 1` reads only `y`); at round 2 it is `11`
; and the return is QUANTUM. Round 1 of bd cepm left `t` classical at round 1 and tainted it in
; ROUND 2, which ACCEPTED this module with a stream that is NOT the hand-inlined twin's (the
; clone's copy-out rail `copy(y + 1)` stays allocated where the twin's `-O1` folded `y + 1 > 3`
; to `y > 2`; TRACK_CEPM_3ZR4.md §5.2.1). Orchestrator ruling 2026-09-28: such a site must behave
; as on the oracle. The SETTLE step (`settleSpecPredictions`) asks `LaterTaintOracle`: `y` is a φ
; decided by the TAINTED `q > 5`, so a later round can taint it, the POSSIBLE mask is `11`, the
; prediction is quantum, and `t` is tainted AT ROUND 1 — the oracle's taint set, hence the
; oracle's verdict and string. RETIREMENT TRIGGER (L8): an owner ruling that a compiler-kept
; clone copy-out is acceptable (bd filed with this change) would make this an accept; re-derive,
; do not delete."""
fix("spec_reject_predicted_classical_round2_mask_growth", "DECLINE", "bd test_C_libtooling-cepm (round 1b)", "r2bC",
    R2 + "\n; Here `t` decides an in-place Ry of an unrelated register `q2`.",
    "Oracle 9a230646: the same DECLINE (byte-identical first error line). Round 1 of bd cepm: ACCEPT.",
    "Hand-inlined twin (r2bT.c: `g(q); int t = y + 1;`) ACCEPTS with a different stream — the\n"
    "compiler-kept copy-out class, left for an owner ruling.",
    """; CHECK: cq controlled lowering: control flow under quantum control
""")
fix("spec_reject_predicted_classical_round2_mask_growth_ry", "DECLINE", "bd test_C_libtooling-cepm (round 1b)", "r2dC",
    R2 + "\n; Here, besides r2b's region, a trailing Ry on `y` (round 1 of bd cepm accepted it and BOTH\n"
    "; sides warned `live derived record`).",
    "Oracle 9a230646: the same DECLINE (byte-identical first error line). Round 1 of bd cepm: ACCEPT.",
    "Hand-inlined twin (r2dT.c) ACCEPTS (warned) with a different stream.",
    """; CHECK: cq controlled lowering: control flow under quantum control
""")

for (name, kind, bead, probe, prose, oracle, twin, checks) in FIX:
    body = open(os.path.join(P, probe + ".s1.ll")).read()
    assert len(body) > 200, probe
    run = ACC_RUN if kind == "ACCEPT" else DEC_RUN
    txt = header(name, kind, bead, probe, prose, oracle, twin) + run + checks + "\n" + body
    with open(os.path.join(W, "ir-pass/test", name + ".ll"), "w") as f:
        f.write(txt)
    print(name)
