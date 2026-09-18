; control_predmux_leave_fp_diamond_inloop.ll — ⚠ THE FILENAME IS NOW WRONG AND IS
; KEPT ON PURPOSE. This module is an ACCEPT since bd test_C_libtooling-fn1q
; increment 3 (E2's in-loop admission, 2026-09-18). It is NOT renamed, because a
; `git mv` of a fixture can be resurrected by a merge and leave one module under
; two names with contradictory verdicts, invisible to every review that ran
; before the merge (CLAUDE.md L8; bd `gahu` holds three fixtures in exactly this
; state for exactly this reason). Rename it in a change that does nothing else.
;
; WHAT IT USED TO PIN, AND WHY THAT PIN IS GONE RATHER THAN BROKEN. The header
; this replaces (bd vyqi's W5 matrix, re-dispositioned by bd 8h7d.5) said: "no
; flat in-loop FP value diamond is ever CLAIMED, and no `cqrt_copy` is emitted
; for one". PredMux's W5 witness fired on it and E2 then LEFT the region for
; being on a CFG cycle, and `classifyArms` declined it afterwards because no
; swap-route emitter lowers a floating-point value arm.
;
; E2 no longer refuses a region that lies STRICTLY INSIDE one loop body, so the
; region is now claimed and flattened, and the fp merge goes where the fp merge
; has always gone: the 4.4 / kjd1 controlled-copy select substrate. The old
; disposition was never a statement about FP — the loop-free spelling of this
; SAME program has been a committed ACCEPT the whole time
; (control_predmux_accept_fp_diamond_solephi.ll). What changed is that the
; rolled spelling now reaches it too.
;
; ⚠ THE WITNESS IS MECHANICAL, AND IT IS THE POINT OF THIS FILE: the per-trip
; gate stream here is BYTE-IDENTICAL to that loop-free accept's whole stream —
; 13 calls, same order, same operands' shapes. The rolled form is the general
; trip of the flat form. `test -s` guards the comparison so a pair of empty
; files cannot pass for agreement.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %S/control_predmux_accept_fp_diamond_solephi.ll > %t.flat.ll
; RUN: grep -oE "call (void|double|i32) @(cqrt|cq_template)_[a-z0-9_]*\([^)]*\)" %t.cqd0.ll > %t.a.gates
; RUN: grep -oE "call (void|double|i32) @(cqrt|cq_template)_[a-z0-9_]*\([^)]*\)" %t.flat.ll > %t.b.gates
; RUN: diff %t.a.gates %t.b.gates
; RUN: test -s %t.a.gates
; RUN: grep "call void @cqrt_copy_f64_controlled" %t.cqd0.ll | count 2
; RUN: grep "call void @cqrt_free(" %t.cqd0.ll | count 1
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; The loop is STILL ROLLED — the region is flattened, the loop is not. THE BACK
; EDGE is what says so, and that is what is checked. (⚠ An earlier version of this
; line added "the `llvm.loop` metadata does not survive the flatten". That has no
; subject here — this module never had any — and it is false at C level, where the
; e2e slice carries 3 `llvm.loop` before AND after lowering. Rule-13 round 2.)
; CHECK: br i1 %{{.*}}, label %exit, label %head
;
; NEG-NOT: cqrt_rz
; NEG-NOT: cqrt_cswap
; The two arm blocks are erased by the flatten.
; NEG-NOT: label %lo
; NEG-NOT: label %hi
;
; ⚠ TWO NEGATIVES WERE REMOVED HERE, FOR `cq controlled lowering` and `cq loop
; lowering`. They read the emitted MODULE while a diagnostic goes to STDERR, so
; they could never fail (Rule-13 round 1 F-6). What pins "it accepted" is the
; first RUN line: it has no `not`, so a decline fails it.

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp olt double %q, 5.000000e-01
  br i1 %c, label %lo, label %hi
lo:
  %a = fadd double %q, -5.000000e-01
  br label %latch
hi:
  %b = fmul double %q, 2.000000e+00
  br label %latch
latch:
  %zv = phi double [ %a, %lo ], [ %b, %hi ]
  %m = call double @cq_measure_f64(double %zv)
  %inext = add i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head
exit:
  ret double %m
}
