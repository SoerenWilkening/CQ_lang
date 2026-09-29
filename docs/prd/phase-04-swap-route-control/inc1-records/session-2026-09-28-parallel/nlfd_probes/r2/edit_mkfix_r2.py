#!/usr/bin/env python3
"""edit_mkfix_r2.py — round 2's edit of tools/mkfix.py (kept as a record of what changed):
reviewer-probe paths, a per-entry decline message, the r1A F-r1A-2/-3 header corrections, the
rhk5-landed re-pins (x_inst_live, x_classical_inst, the demotion fixture — r1B F-r1B-5) and the
round-2 entries (bd vaep twin-signature pins, the preallocated decline, the inalloca accept).
Every replacement is anchored and must match exactly once."""
import pathlib

p = pathlib.Path(__file__).resolve().parent.parent / "tools" / "mkfix.py"
s = p.read_text()


def rep(a, b, n=1):
    global s
    assert s.count(a) == n, (a[:70], s.count(a))
    s = s.replace(a, b)


rep('SRC = V / "src"\n',
    'SRC = V / "src"\n'
    '# Round 2: the Rule-13 round-1 reviewers\' own probes (read-only; committed under their dirs).\n'
    'RA = V.parent / "review_r1A_nlfd" / "probes"\n'
    'RB = V.parent / "review_r1B_nlfd" / "probes" / "q2"\n')

rep('''              f"; CHECK: error: {{{{.*}}}}in function {e['fn']}{{{{.*}}}}{MSG}"]''',
    '''              f"; CHECK: error: {{{{.*}}}}in function {e['fn']}{{{{.*}}}}{e.get('msg', MSG)}"]''')
rep('''            raise SystemExit(f"{e['name']}: expected a decline, got exit 0")''',
    '''            raise SystemExit(f"{e['name']}: expected a decline, got exit 0")
        if rc != 1:
            raise SystemExit(f"{e['name']}: expected a LOUD decline (exit 1), got exit {rc}: {err[:300]}")''')

rep('''; parameter dead). Both accepts are wrong: keeping `main`'s slot is bd tzfa's phantom read
; (what the ORACLE does: exit 0, a warning, `p`'s rail dirty across the Ry — TRACE-DIFF vs
; the twin), and neutralising it would lower `t = a * 5` on runtime handle 0 (bd sqjq). The
; hand-inlined twin (`r = m + 1`) ACCEPTS: this is a knowing over-decline of an IR-only shape
; (clang-19 -O1 emits only allowlisted attributes on an int parameter). Retirement trigger:
; the day `nullSafeSlot` admits string/unknown attributes, this module accepts.""")''',
    '''; parameter dead). For THIS caller operand (a DERIVED `p = q * 3`) both accepts are wrong:
; keeping `main`'s slot is bd tzfa's phantom read (what the ORACLE `main` 9a230646 does: exit 0,
; a warning, `p`'s rail dirty across the Ry — TRACE-DIFF vs the twin), and neutralising it
; would lower `t = a * 5` on runtime handle 0 (bd sqjq). ⚠ Not for every caller operand
; (Rule-13 r1A F-r1A-2): with a `cq_theta` SOURCE there the ORACLE's accept WAS the twin's
; unitary and the fence still declines — a known IR-only over-decline, bd
; test_C_libtooling-w109. The hand-inlined twin (`r = m + 1`) ACCEPTS: a knowing over-decline
; of an IR-only shape (clang-19 -O1 emits only allowlisted attributes on an int/fp parameter
; that CAN BE RECORDED DEAD — it infers `returned` on a returned, hence live, one; r1A
; F-r1A-3). Retirement trigger: the day `nullSafeSlot` admits string/unknown attributes (owner
; question bd test_C_libtooling-uyhx), this module accepts.""")''')
rep('''; string attributes (owner question, TRACK_NLFD_EV3M.md §15 Q1).""")''',
    '''; string attributes (owner question bd test_C_libtooling-uyhx).""")''')

rep('''  module=SRC / "cells/x_inst_live.ll", kind="accept",
  streams=[("CLONE", "__cq_q_h_01")], drop=False,
  extra=["; CHECK-LABEL: define {{.*}}@main(",
         "; CHECK: call i32 @__cq_q_h_01(i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}})"],
  twin="`r = m + 1 + 5p` (cells/x_inst_liveT.ll) — TRACE-DIFF on the ORACLE too (bd rhk5's shape: the clone call sits between `p` and its phase consumer)",''',
    '''  module=SRC / "cells/x_inst_live.ll", kind="accept",
  streams=[("CHECK", "main"), ("CLONE", "__cq_q_h_01")], drop=False,
  twin="`r = m + 1 + 5p` (cells/x_inst_liveT.ll) — since bd rhk5 landed (9ad22639): 0 warnings, 0 dirty template rails; tools/trace_twin_equiv.py reports DIFF only because the clone computes `r` OUT OF PLACE (`add_hl(t,6)->r`, then `t` uncomputed and freed) where the twin adds IN PLACE (`cqrt_addc_i32(t, 6)`), a representation that instrument does not contract (measured with its --show)",''')
rep('''; and the fence must NOT fire. The CLONE stream is pinned (the ORACLE's, byte-for-byte,
; measured); `main`'s is DELIBERATELY NOT: it is not the hand-inlined twin's — the clone call
; sits between `p = q * 3` and its phase consumer, which is bd rhk5 (P1, warned, PRE-EXISTING:
; one lyyf-(B) warning, `p`'s rail left dirty across the Ry, on the ORACLE and here alike) — and
; a golden of a known-wrong stream would bless it (bd jlf8's lesson). `main` is pinned only to
; keep the clone call's operand (the slot is live). Fence without its value-liveness test →
; this file declines (mutant N4).""")''',
    '''; and the fence must NOT fire. Both streams are pinned. ⚠ Until bd rhk5 landed (9ad22639,
; 2026-09-28) `main`'s was deliberately NOT: the clone call sits between `p = q * 3` and its
; phase consumer, which was rhk5's warned wrong unitary (`p`'s rail dirty across the Ry) on the
; oracle and on this track's round 1 alike, and a golden of a known-wrong stream would have
; blessed it (bd jlf8). On the merged binary it is clean (0 warnings, 0 dirty, 2b STRICT) — the
; retirement trigger round 1 recorded. Fence without its value-liveness test → this file
; declines (mutant N4).""")''')

rep('''  module=SRC / "cells/x_classical_inst.ll", kind="accept",
  streams=[("CLONE", "__cq_q_h_001")], drop=False,
  extra=["; CHECK-LABEL: define {{.*}}@main(",
         "; CHECK: call i32 @__cq_q_h_001(i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}})"],
  twin="`r = m + p` (cells/x_classical_instT.ll) — TRACE-DIFF on the ORACLE too (bd rhk5's shape)",''',
    '''  module=SRC / "cells/x_classical_inst.ll", kind="accept",
  streams=[("CHECK", "main"), ("CLONE", "__cq_q_h_001")], drop=False,
  twin="`r = m + p` (cells/x_classical_instT.ll) — TRACE-EQUIV (tools/trace_twin_equiv.py) since bd rhk5 landed; TRACE-DIFF (rhk5's warned shape) on `main` 9a230646",''')
rep('''; clone's HANDLE parameters) must not fire. The CLONE stream is pinned (the ORACLE's,
; byte-for-byte, measured); `main`'s is deliberately NOT, for `…_inst_live.ll`'s reason (bd
; rhk5's pre-existing warned divergence from the twin). Fence without the handle-mask
; conjunct → this file declines (mutant N5).""")''',
    '''; clone's HANDLE parameters) must not fire. Both streams are pinned; `main`'s was not until bd
; rhk5 landed, for `…_inst_live.ll`'s reason (rhk5's pre-existing warned divergence from the
; twin), and it is now the twin's circuit (TRACE-EQUIV). Fence without the handle-mask
; conjunct → this file declines (mutant N5).""")''')

rep('''E(name="spec_accept_musttail_in_clone_demoted", module=SRC / "mtl.s1.ll", kind="accept",
  streams=[], drop=False,
  twin="its plain-`tail` spelling `mtlN` (byte-identical traces, measured); the hand-inlined twin `mtlT` differs on BOTH (bd rhk5's shape)",''',
    '''E(name="spec_accept_musttail_in_clone_demoted", module=SRC / "mtl.s1.ll", kind="accept",
  streams=[("CHECK", "main")], drop=False,
  twin="its plain-`tail` spelling `mtlN` (byte-identical traces) and the hand-inlined twin `mtlT` (TRACE-EQUIV, tools/trace_twin_equiv.py) — both measured on the binary merged with bd rhk5 9ad22639; the e2e pair `e2e-spec-musttail-clone-live-arg-twin-equivalent` links it",''')
rep('''  extra=["; CHECK-LABEL: define {{.*}}@main(",
         "; CHECK: call i32 @__cq_q_h_01(i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}})",
         "; CHECK-LABEL: define {{.*}}@h(",
         "; CHECK-NEXT: musttail call i32 @h2(",''',
    '''  extra=["; CHECK-LABEL: define {{.*}}@h(",
         "; CHECK-NEXT: musttail call i32 @h2(",''')
rep('''; tail-call lowering, so `stripStaleClassicalAttrs` now demotes it in every clone body (the
; CLONE lines; the ORIGINAL `h`, a non-clone, keeps its `musttail` — the CHECK-NEXT line). The
; trace is then byte-identical to the plain-`tail` spelling's on the ORACLE (measured). ⚠ That
; trace is NOT the hand-inlined twin's: the clone call sits between `p = q * 3` and its phase
; consumer — bd rhk5 (P1, warned, PRE-EXISTING), whose population this demotion GROWS by the
; `musttail` spellings (previously exit 134) — so `main`'s stream is deliberately NOT pinned
; here (a golden of a known-wrong stream would bless it, bd jlf8). See TRACK_NLFD_EV3M.md.
; Remove the demotion and this file ABORTS again (mutant D1).""")''',
    '''; tail-call lowering (for every argument kind reachable from C; a `preallocated` forward is
; declined earlier, `spec_reject_musttail_forward_preallocated.ll`), so `stripStaleClassicalAttrs`
; now demotes it in every clone body (the CLONE lines; the ORIGINAL `h`, a non-clone, keeps its
; `musttail` — the CHECK-NEXT line). ⚠ The one cause is code emitted after the call; round 1's
; second reason ("the fp→i32 rewrite changes prototypes") was false on the reachable surface
; (Rule-13 r1B F-r1B-4). The trace is byte-identical to the plain-`tail` spelling's. ⚠ Until
; bd rhk5 landed (9ad22639) that trace was rhk5's warned wrong unitary (the clone call sits
; between `p = q * 3` and its phase consumer) and `main`'s stream was deliberately NOT pinned
; (bd jlf8); on the merged binary it is clean (0 warnings, 0 dirty, 2b STRICT) and the
; hand-inlined twin's circuit, so it is pinned now (r1B F-r1B-5 — whose note that round 1's
; "1 warning" comment would go stale was the retirement trigger). Remove the demotion and this
; file ABORTS again (mutant D1).""")''')

NEW = (pathlib.Path(__file__).resolve().parent / "mkfix_r2_entries.py.txt").read_text()
rep('\n\ndef src_comment(paths):', NEW + '\n\ndef src_comment(paths):')
p.write_text(s)
print("ok")
