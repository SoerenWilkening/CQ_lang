#!/usr/bin/env python3
"""mkloc_r3.py [--check] — Rule-13 round-2 F-r2-1: the two decline LOCATION fixtures, built from the
reviewer's probes VERBATIM (review_r2_nlfd/probes/{loc1_fence_dbg,pa_dbg}.ll) with a header and a
RUN/CHECK block pinning `file:line:col` character for character (the location strings were measured
on the merged binary before this file was written)."""
import pathlib
import sys

V = pathlib.Path(__file__).resolve().parent.parent
P = V.parent / "review_r2_nlfd" / "probes"
T = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/"
                 "agent-a333a1777db2f2295/ir-pass/test")

MSG_FENCE = "cq specialization: quantum argument to a parameter the lifted callee never reads"
MSG_PA = ("cq specialization: callee contains a non-reversibilizable construct under quantum lift "
          "(musttail forward of a preallocated argument)")

ENTRIES = [
    ("spec_reject_phantom_arg_read_unread_scalar_inner_inst_loc", "loc1_fence_dbg.ll",
     "fence.c:6:22", "__cq_q_h_01", MSG_FENCE,
     """DECLINE, and its SOURCE LOCATION pinned (bd
; test_C_libtooling-nlfd's `buildClone` fence; Rule-13 r2 F-r2-1, probe `loc1_fence_dbg.ll`, verbatim;
; IR-only).
;
; `spec_reject_phantom_arg_read_unread_scalar_inner_inst.ll`'s program with `!dbg` on `h`: the
; `t = a * 5` at `fence.c:5:11` and the call `h2(t, k)` at `fence.c:6:22`. The fence reports the
; FIRST CALL with an argument operand live under `SlotReads::Existence` and dead under
; `SlotReads::Value` — the frontier of the same two liveness answers that decide the verdict (r1A
; F-r1A-4). The other decline fixtures carry no `!dbg`, so their `in function …` CHECK accepts
; `<unknown>:0:0`: a mutant that never sets the location, or picks the instruction (5:11) instead of
; the call, left lit green. This file pins `6:22`. ⚠ Since bd rhk5 the fence is an IR-only
; over-decline (bd test_C_libtooling-ur72, OPEN); retiring it retires this file with it."""),
    ("spec_reject_musttail_forward_preallocated_loc", "pa_dbg.ll",
     "pa.c:4:17", "h", MSG_PA,
     """DECLINE, and its SOURCE LOCATION pinned (bd
; test_C_libtooling-m5pn round 2's `scanBody` decline; Rule-13 r2 F-r2-1, probe `pa_dbg.ll`, verbatim;
; IR-only).
;
; `spec_reject_musttail_forward_preallocated.ll`'s program with `!dbg` on `h`'s `musttail` call
; (`pa.c:4:17`). The decline is located at the forwarding call (`WhereOut = &I` in `scanBody`); a
; mutant passing an empty location would print `<unknown>:0:0`, which the unlocated fixture
; accepts. This file pins `4:17`."""),
]


def build(name, probe, loc, fn, msg, head):
    body = (P / probe).read_text()
    L = [f"; {name}.ll — {head}", ";",
         "; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \\",
         "; RUN:   | %filecheck %s",
         "; CHECK-NOT: CQ_DEADARG_DBG",
         f"; CHECK: error: {loc}: in function {fn} {{{{.*}}}}: {msg}", ""]
    return "\n".join(L) + "\n" + body


bad = 0
for e in ENTRIES:
    txt = build(*e)
    f = T / (e[0] + ".ll")
    if "--check" in sys.argv:
        if not f.exists() or f.read_text() != txt:
            print("DIFFERS", f.name)
            bad = 1
    else:
        f.write_text(txt)
        print("wrote", f.name)
sys.exit(bad)
