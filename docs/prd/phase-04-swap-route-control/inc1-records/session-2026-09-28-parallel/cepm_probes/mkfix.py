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
    if not os.path.exists(os.path.join(SRC, probe + ".c")):
        # a HAND-IR probe (cepm_probes/ir/<probe>.s1.ll): no C source; the prose describes it.
        lines = [f"; {name}.ll — {kind} ({bead})."]
        lines += prose.splitlines()
        lines.append(";")
        lines += ["; " + l for l in oracle.splitlines()]
        lines += ["; " + l for l in twin.splitlines()]
        lines.append(f"; Regenerate: copy {REC}/ir/{probe}.s1.ll to the probe dir (r3gen.sh), then mkfix.py.")
        lines.append(";")
        return "\n".join(l if l.startswith(";") else "; " + l for l in lines) + "\n"
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


# ⚠ The twin's inlined line is a PARAMETER (Rule-13 r2 F-r2-2): round 1 hard-coded
# `g(q); int t = m + 1;`, which is wrong for r6b (`y + 1`), lpp (`i + m + 1`), a04 and cph.
TWIN_SAME = ("Hand-inlined twin ({t}.c: `{line}`) is TRACE-IDENTICAL under argv\n"
             "`5 7` and `2 9`, stage 2b STRICT clean on both ({rec}/twincmp.sh).")
TWIN_LINE = {"a04T": "g(q); if (i + m + 1 > 5) break;", "cphT": "g(q); t = m + 1;",
             "r6bT": "g(q); int t = y + 1;", "lppT": "g(q); int t = i + m + 1;"}


def twin_same(t):
    return TWIN_SAME.format(t=t, rec=REC, line=TWIN_LINE.get(t, "g(q); int t = m + 1;"))

# ---------------------------------------------------------------- ACCEPTS (bd cepm)
fix("spec_accept_predicted_classical_branch", "ACCEPT", "bd test_C_libtooling-cepm", "brC",
    READING + "\n; Here the result is a BRANCH condition over an in-place Ry of `q`: a CLASSICAL branch.",
    "Oracle 9a230646: DECLINE `condition predates a non-diagonal gate under quantum control` (the\n"
    "conservative taint made `t > 3` a quantum condition on the handle `t`).",
    twin_same("brT"),
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
    twin_same("selT"),
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
    twin_same("ph1T"),
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
    twin_same("rt9T"),
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
    twin_same("ybT"),
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
    twin_same("l19T"),
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
    twin_same("a04T"),
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
; CHECK:       %[[L:[0-9]+]] = load i32, ptr
; CHECK-NEXT:  add nsw i32 %[[L]],
; CHECK:       ret i32
; ROUND 2 (Rule-13 r1B F-r1B-6): the property that separates right from wrong here is that
; `cq_measure(b[i])` over a loaded CLASSICAL integer lowers to the VALUE (bd 21mg) — the load feeds
; the sum directly (CHECK-NEXT above) — and that the ONLY measurement gate in the module is the one
; on `q`'s handle. MEAS is a whole-file prefix (Rule 12 (a): counts never inside a negative prefix):
; exactly one measurement CALL, and none after it (a regression that measured each loaded integer
; as a handle — the Rule-3 wire crossing — would add three).
; MEAS-COUNT-1: call i32 @cqrt_measure_i32(
; MEAS-NOT:     call i32 @cqrt_measure_i32(
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
    twin_same("swT"),
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
    twin_same("cphT"),
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

# ---------------------------------------------------------------- ROUND 2 (Rule-13 r1A/r1B)
RUN_OVERRIDE = {
    "spec_accept_predicted_classical_bank":
        ("; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.bank.ll\n"
         "; RUN: %filecheck %s < %t.bank.ll\n"
         "; RUN: %filecheck --check-prefix=MEAS %s < %t.bank.ll\n"),
}
fix("spec_accept_predicted_classical_measured_callee", "ACCEPT", "bd test_C_libtooling-cepm (round 2; bd we38)", "r6bC",
    READING + "\n; Here the site's SECOND argument is `F(n)`, where `F` holds a `cq_theta` but returns a MEASURED\n"
    "; classical value (`F(n){ r = cq_theta(n,.3); return n + cq_measure(r); }`). Round 1b's\n"
    "; `LaterTaintOracle` counted any call to a callee holding a `cq_theta` as a value a later round can\n"
    "; taint (a SYNTACTIC answer, L5), predicted the site quantum, tainted `t` at round 1, and bd l3oi's\n"
    "; fence declined. Round 2 removed that seed (Rule-13 r1A F-r1A-1 / bd we38): the only channel by which\n"
    "; a call RESULT gains taint beyond its operands is bd 3jru's return crossing, and that growth is\n"
    "; refused by `declineQuantumReturnCalls` before `specialize()` (`spec_reject_predicted_classical_\n"
    "; round2_return_crossing.ll` pins it). RETIREMENT TRIGGER (L8): the day that refusal is relaxed,\n"
    "; a crossing onto an ARGUMENT the oracle does not foresee ends at `specialize()`'s check; a crossing\n"
    "; onto the recorded SITE ITSELF is kept loud only by `scanBody`'s refusal of a callee that holds a\n"
    "; `cq_*` primitive (Rule-13 r2 F-r2-5) — re-derive this pair then.",
    "Oracle 9a230646: DECLINE `classical call result used as a quantum register`. Round 1b: same.",
    twin_same("r6bT"),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[Y:[0-9]+]] = tail call i32 @F(
; CHECK-NEXT:  %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %{{[A-Za-z0-9_.]+}}, i32 noundef %[[Y]])
; CHECK-NOT:   cq_template_icmp
; CHECK:       %[[C:[0-9]+]] = icmp sgt i32 %[[T]], 3
; CHECK-NEXT:  br i1 %[[C]],
; CHECK:       ret i32
; (Rule-13 r2: the CHECK-NOT sat between `br` and `ret`, where no icmp could appear — decorative. It
; now sits between the site and its classical compare, where a quantum compare template would be.)
""")
fix("spec_reject_predicted_classical_round2_return_crossing", "DECLINE", "bd test_C_libtooling-cepm (round 2; bd we38)", "r6aC",
    "; The decline twin of `spec_accept_predicted_classical_measured_callee.ll`: here `F`'s RETURN is a 6.5\n"
    "; merge `%out` (`F(n){ r = cq_theta(n,.3); y = 0; if (r > 5) y = ext_f(7); return y; }`), so bd 3jru's\n"
    "; return crossing taints `F(n)` in ROUND 2 and the site `h(q, F(n))`'s mask grows. That growth is\n"
    "; refused by `declineQuantumReturnCalls` at the post-fixpoint slot, before `specialize()` — with or\n"
    "; without round 1b's callee seed (measured by Rule-13 r1A: identical decline string). THE STRING IS\n"
    "; THE PIN: it is the 3jru owner's, not `specialize()`'s check and not bd l3oi's.",
    "Oracle 9a230646: the same DECLINE (byte-identical first error line).",
    "Hand-inlined twin (r6aT.c) declines with the SAME string.",
    """; CHECK: cq taint escape: quantum value returned across a function boundary
""")
fix("spec_accept_predicted_classical_loop_body_branch", "ACCEPT", "bd test_C_libtooling-cepm (round 2)", "lppC",
    READING + "\n; Here the site sits in a ROLLED loop, reads the loop counter (`h(q, i + m)`), and its result is\n"
    "; compared against `q` by a tainted phase branch in the same body (`if (q > t) cq_phi(.2)`). Round 1b's\n"
    "; settle step counted EVERY conditional terminator between the header's idom and the header as a\n"
    "; decider of the header φ `i` — the whole loop body — so the tainted `br (q > t)` made `i` \"may gain\n"
    "; taint\", the site was tainted at round 1, and the compare became Q+Q (Rule-13 r1B F-r1B-2; round 1\n"
    "; ACCEPTED it twin-identically). Round 2 counts a branch only if it SELECTS which incoming edge of the\n"
    "; φ arrives (`selectsIncoming`): this branch's arms reconverge before the latch, so both reach the\n"
    "; header through the latch and it selects nothing.",
    "Oracle 9a230646: DECLINE `quantum-quantum compare condition under quantum control`. Round 1b: same.",
    twin_same("lppT"),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[H:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:       %[[I:[0-9]+]] = phi i32
; CHECK-NEXT:  %[[A:[0-9]+]] = add nsw i32 %[[I]],
; CHECK-NEXT:  %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %[[H]], i32 noundef %[[A]])
; CHECK-NEXT:  %[[F:[A-Za-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 %[[T]])
; CHECK-NEXT:  call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01)
; CHECK-NOT:   cq_template_icmp_sgt_i32(
""")

# ---------------------------------------------------------------- ROUND 3 (Rule-13 r2)
fix("spec_accept_predicted_classical_peel_diamond_climb", "ACCEPT", "bd test_C_libtooling-cepm (round 3; Rule-13 r2 F-r2-1)", "pkdC",
    "; HAND IR (Rule-13 r2 review probe `review_r2_cepm/probes/ir/pkdC.s1.ll`, copied verbatim to\n"
    "; `cepm_probes/ir/`): an if/else diamond on the tainted `q > 5` with two NON-EMPTY phase arms\n"
    "; (`cq_phi(.2)` | `cq_phi(.3); cq_phi(.1)`) and two pred-available merge φs `y=[m|n]`, `z=[n|m]`, feeding\n"
    "; `t = h(q, z); if (t > 3) q2 = cq_theta(q2, .2)` with the READING callee (`h(a,k){ g(a); return k+1; }`).\n"
    ";\n"
    "; THIS FILE PINS `LaterTaintOracle::walk`'s CLIMB past the φ block's direct predecessors. The merge-φ\n"
    "; peel (`MergePhiPeel`) replaces `z` by a tainted `select` in a GROWTH drain, so `h(q, z)`'s mask grows\n"
    "; `01` → `11` and its clone returns a register. The tainted `br` is the ENTRY block's; both of the\n"
    "; merge's direct predecessors are ARM blocks with unconditional terminators. The round-1 settle step\n"
    "; therefore taints the site at round 1 only because the climb reaches that `br`. Remove the climb and\n"
    "; the site stays STICKY, the peel's growth replans its mask to `11`, and `specialize()` declines\n"
    "; `lifted callee returns a quantum register where propagation predicted a classical result` — a LOUD\n"
    "; over-decline, never an accept (Rule-13 r2 mutant C1; re-measured in round 3, TRACK §15).\n"
    "; Round 2's comment at the climb called it \"UNPINNED AND, TODAY, UNREACHABLE\" (F-r2-1; L7). No C\n"
    "; spelling is known: `-O1` sinks the arms' common trailing `cq_phi` into the merge (probes `pk1`/`pk2`).",
    "Oracle 9a230646: the same ACCEPT with a BYTE-IDENTICAL stream (so this file is green on the oracle; its\n"
    "red is the climb-less mutant, not the oracle).",
    "Hand-inlined twin (pkdT.s1.ll) ACCEPTS with a different stream: the quantum-returning clone keeps its\n"
    "copy-out rail (the compiler-kept copy-out class, bd ffir, owner question), identical on the oracle.",
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_11(i32 noundef %[[H:[A-Za-z0-9_.]+]], i32 noundef %{{[A-Za-z0-9_.]+}})
; CHECK:       %[[F:[A-Za-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[T]], i32 3)
; CHECK-NEXT:  call void @cqrt_ry_i32_controlled(i32 %[[F]],
; CHECK:       ret i32
""")
fix("spec_accept_predicted_classical_indirect_call_arg", "ACCEPT", "bd test_C_libtooling-cepm (round 3; Rule-13 r2 F-r2-4)", "fp3C",
    READING + "\n; Here the site's SECOND argument is `fp(n)`, an INDIRECT call through a function pointer chosen at\n"
    "; run time (`fp = (m > 4) ? G : G2`, both classical). Round 1b's `LaterTaintOracle` counted ANY indirect\n"
    "; call as a value a later round can taint, predicted the site quantum, tainted `t` at round 1 and bd\n"
    "; l3oi's fence declined. Round 2 removed that seed with the callee seed (bd we38): an indirect call is\n"
    "; never crossed by bd 3jru (the crossing requires the call to NAME the function). THIS FILE PINS the\n"
    "; indirect half, which `spec_accept_predicted_classical_measured_callee.ll` (the callee-name half) does\n"
    "; not (Rule-13 r2 F-r2-4). Sibling probe `fp1` (fp → a `cq_theta`-holding, measured-return callee)\n"
    "; accepts twin-identically too.",
    "Oracle 9a230646: DECLINE `classical call result used as a quantum register`. Round 1b: same.",
    TWIN_SAME.format(t="fp3T", rec=REC, line="g(q); int t = y + 1;"),
    """; CHECK-LABEL: define i32 @main(
; CHECK:       %[[Y:[0-9]+]] = tail call i32 %{{[0-9]+}}(
; CHECK-NEXT:  %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %{{[A-Za-z0-9_.]+}}, i32 noundef %[[Y]])
; CHECK-NOT:   cq_template_icmp
; CHECK:       %[[C:[0-9]+]] = icmp sgt i32 %[[T]], 3
; CHECK-NEXT:  br i1 %[[C]],
; CHECK:       ret i32
""")

for (name, kind, bead, probe, prose, oracle, twin, checks) in FIX:
    body = open(os.path.join(P, probe + ".s1.ll")).read()
    assert len(body) > 200, probe
    run = RUN_OVERRIDE.get(name) or (ACC_RUN if kind == "ACCEPT" else DEC_RUN)
    txt = header(name, kind, bead, probe, prose, oracle, twin) + run + checks + "\n" + body
    with open(os.path.join(W, "ir-pass/test", name + ".ll"), "w") as f:
        f.write(txt)
    print(name)
