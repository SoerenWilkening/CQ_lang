; loop_pairing_accept_nest_singleexit_hoisted.ll — ACCEPT (bd
; `test_C_libtooling-4jok`, Rule-13 round 5 finding F-1, 2026-09-21).
;
; THE ATTRIBUTION CONTROL FOR `loop_pairing_reject_nest_multiexit_hoisted.ll`,
; and it is a control rather than a second accept: it is the IDENTICAL nest with
; the OUTER loop's second exit destination removed, so exactly ONE conjunct
; differs — the outer loop's exit uniqueness, **which clause (ii-d) never asks
; about**.  Keep the two together; either alone proves nothing about the other.
;
; WHAT IT PINS.  With the outer exit unique, `anchorForConsumer` walks to the
; OUTERMOST loop and places the hoisted rail's discharge at its exit, BEFORE the
; trailing non-diagonal gate on `%q`:
;
;     %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 2)   <- ONE mint, outside the nest
;     …
;   out:
;     call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 2)   <- ONE adjoint
;     call void @cqrt_free(i32 %h_op)
;     call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)              <- the interference, AFTER
;
; ⚠ THAT ORDERING IS THE WHOLE MULTIPLICITY CLAIM, in the shape that most
; threatens it.  `railLocalQualifies`' final clause carries a written trigger —
; *"a recovered gate in the PREHEADER (does not repeat) with `At` in a body marked
; here (repeats K times) would emit K adjoints against ONE forward gate … no
; shipped test would go red.  Re-derive the multiplicity there first."*  A NEST is
; where that is most likely to go wrong, because the inner body runs K_inner ×
; K_outer times.  Measured here: ONE mint, ONE adjoint.
;
; ⚠ ON THE PRE-LANDING COMPILER THIS MODULE ALSO ACCEPTS, at exit 0 and with NO
; warning — so this file is NOT a non-vacuous witness for the landing on its own,
; and it is not claimed as one.  Its job is to hold the OTHER conjunct fixed while
; its sibling moves; the sibling is the one that changes verdict.  Said here
; explicitly because a control that quietly reads as a capability pin is how a
; green suite starts meaning less than it appears to (Rule 12 defect (c)).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.n0.ll
; RUN: %filecheck %s < %t.n0.ll
; RUN: %filecheck %s --check-prefix=EXITD < %t.n0.ll

; CHECK: %[[P:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q:.*]], i32 2)

; EXITD: call void @cq_template_mul_i32_hl_unc(
; EXITD-NEXT: call void @cqrt_free(
; EXITD-NEXT: call void @cqrt_ry_i32({{.*}}, double 9.000000e-01)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y = call i32 @cq_theta_si32(i32 7, double 3.000000e-01)
  %m2 = mul i32 %q, 2
  br label %outer

outer:
  %o = phi i32 [ 0, %entry ], [ %o2, %outerlatch ]
  %acc = phi i32 [ 0, %entry ], [ %acc3, %outerlatch ]
  %bail = icmp eq i32 %o, -12345
  br label %inner

inner:
  %k = phi i32 [ 1, %outer ], [ %k2, %inner ]
  %acc2 = phi i32 [ %acc, %outer ], [ %s2, %inner ]
  %sh = lshr i32 %y, %k
  %an = and i32 %sh, %m2
  %ms = call i32 @cq_measure_si32(i32 %an)
  %s2 = add i32 %ms, %acc2
  %k2 = add i32 %k, 1
  %e = icmp eq i32 %k2, 3
  br i1 %e, label %outerlatch, label %inner

outerlatch:
  %acc3 = phi i32 [ %s2, %inner ]
  %o2 = add i32 %o, 1
  %done = icmp eq i32 %o2, 3
  br i1 %done, label %out, label %outer


out:
  %accf = phi i32 [ %acc3, %outerlatch ]
  %q2 = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %q2)
  %t = add i32 %accf, %mm
  ret i32 %t
}
