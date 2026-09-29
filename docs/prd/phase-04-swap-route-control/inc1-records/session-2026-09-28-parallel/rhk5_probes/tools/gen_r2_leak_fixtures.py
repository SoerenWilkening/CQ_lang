#!/usr/bin/env python3
"""gen_r2_leak_fixtures.py — bd rhk5 round 2: turn three of Rule-13 reviewer r1A's
hand-IR probes into LEAK fixtures. The IR body is copied VERBATIM (non-comment
lines) from round2/r1A/ (itself a verbatim copy of the reviewer's probes/, which is
never written); only the header and the CHECK lines are this file's."""
import os

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
SRC = W + ('/docs/prd/phase-04-swap-route-control/inc1-records/'
           'session-2026-09-28-parallel/rhk5_probes/round2/r1A/')
T = W + '/ir-pass/test/'

RUN = ('; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err\n'
       '; RUN: %filecheck %s --check-prefix=WARN < %t.err\n'
       '; RUN: %filecheck %s --check-prefix=LEAK < %t.cqd0.ll\n\n')
LEAKCHK = ('\n; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record\n'
           ';\n'
           '; The caller\'s chain `3q`, `3q ^ q` is NOT discharged: the strip, then straight to the Ry.\n'
           '; LEAK-LABEL: define i32 @slice(\n'
           '; LEAK: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)\n'
           '; LEAK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)\n'
           '; LEAK-NOT: call void @cq_template_xor_i32_unc(\n'
           '; LEAK-NOT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)\n'
           '; LEAK: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)\n')

FIX = {
    'spec_leak_clone_read_defined_template_name.ll': ('a1f_evil_after_uncompute.ll', '''\
; spec_leak_clone_read_defined_template_name.ll — LEAK + WARNING, deliberately (bd
; test_C_libtooling-fb5y, a P1 against bd rhk5 round 1; Rule-13 r1A F-r1A-1, probe
; `a1f_evil_after_uncompute.ll`, body copied VERBATIM). The module PRE-SUPPLIES the
; inner twin `@__cq_q_g_1_unc`, which uncomputes `out` correctly and THEN calls a
; module-DEFINED `@cq_template_evil_i32(%k)` whose body is `cqrt_x(%k)`. Round 1's
; body walk admitted that call by its NAME (a `cq_template_*` forward producer "reads
; every operand"), proved `q` read-only across the outer clone call, and discharged
; the caller's chain AFTER the write: two `cqrt_free`s of non-|0⟩ rails, one
; entangled with `q` — a hidden measurement — at `opt` exit 0 with no warning and
; STRICT 2b clean (the reviewer's measurement). The ORACLE leaks and warns.
;
; Round 2 trusts a name ONLY for a callee this module merely DECLARES (the runtime
; ABI); a DEFINED callee must be recorded and walked (B4) or it refuses. So the walk
; refuses here, and the disposition is the oracle's. RED on round 1 (fa71e37a…),
; GREEN on the oracle and on round 2. The 2-TU C spelling of the same program is
; r1A's `a1c_c.c` (in the round-2 battery).
;
'''),
    'spec_leak_clone_read_weak_twin.ll': ('a5_weak_twin.ll', '''\
; spec_leak_clone_read_weak_twin.ll — LEAK + WARNING, deliberately (bd
; test_C_libtooling-fb5y; Rule-13 r1A F-r1A-2, probe `a5_weak_twin.ll`, body copied
; VERBATIM). The pre-supplied inner twin `@__cq_q_g_1_unc` is READ-ONLY here — but
; `weak`, and r1A's `a5_strong_twin.c`, linked at stage 3, interposes a strong
; definition that ends in `cqrt_x(k)`. The walked body is not the body that runs.
; Round 1 proved the weak body read-only and discharged the caller's chain after
; the (link-time) write — the same two dirty frees as the defined-name route.
;
; Round 2 requires an EXACT definition (`hasExactDefinition()`: not `weak`,
; `linkonce`, `available_externally` or `extern_weak`), so the walk refuses and the
; disposition is the oracle's. RED on round 1 (fa71e37a…), GREEN on the oracle and on
; round 2 — this file needs no link: the refusal is visible in the lowered IR.
;
'''),
    'spec_leak_clone_read_twin_cycle.ll': ('cyc_self_twin.ll', '''\
; spec_leak_clone_read_twin_cycle.ll — LEAK + WARNING (bd rhk5 round 2; Rule-13 r1A
; F-r1A-5, probe `cyc_self_twin.ll`, body copied VERBATIM). The pre-supplied inner
; twin `@__cq_q_g_1_unc` CALLS ITSELF with `%k`. Walking it re-enters the
; (function, formal slot) being proved: a CYCLE, which refuses. The refusal is
; PROVISIONAL (it depends on the path) and is never memoised, so it cannot license
; the cycle through the cache (bd `tcpq`).
;
; WHAT THIS FILE PINS AND WHAT IT CANNOT. It goes red if the walk ever ADMITS a
; cycle (or does not terminate). It does NOT pin the cycle test alone: with the
; cycle test deleted, the walk recurses until the nesting cap and refuses anyway, so
; the two are mutually redundant for the VERDICT (r1A measured this). The cap is
; pinned on its own by spec_leak_clone_read_depth_cap.ll.
;
'''),
}

for dst, (src, hdr) in FIX.items():
    body = ''.join(l for l in open(SRC + src) if not l.startswith(';')).lstrip('\n')
    with open(T + dst, 'w') as f:
        f.write(hdr + RUN + body.rstrip('\n') + '\n' + LEAKCHK)
    print('wrote', dst)
