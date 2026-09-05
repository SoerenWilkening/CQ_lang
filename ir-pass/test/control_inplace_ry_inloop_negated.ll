; control_inplace_ry_inloop_negated.ll — ACCEPT: the in-loop control-in-place Ry
; arm on the FALSE successor (Rule 9 polarity), bd test_C_libtooling-drbq Inc 3.
;
; `clang -O1` canonicalizes `if (u != k)` to `icmp eq; br eq, Merge, Arm`, so the
; GATE ARM is routinely the false successor. The emitter controls on the negated
; flag with a self-inverse `cqrt_x(f)` bracket — the SAME bracket `emitRoute` puts
; around a negated route, so the two spellings of "fires on not-f" cannot drift.
; Nothing about the loop changes that; this fixture exists so the polarity and the
; rolled path are pinned TOGETHER (the round-4 lesson: an axis nobody crossed is
; an axis nobody tested).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; CHECK: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %h_cmp)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.0
; CHECK-NEXT: call void @cqrt_x(i32 %h_cmp)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
;
; WHOLE-FILE, via the `NOROUTE` prefix rather than a trailing `CHECK-NOT` (bd
; drbq Inc 3, round-1 lens L6, F-L6-1): a `CHECK-NOT` here would have scanned
; only from the last positive match to EOF, leaving the ENTRY BLOCK — where a
; route or an unlowered rotation would be just as wrong — unchecked.
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp eq i32 %q, 5
  br i1 %c, label %merge, label %arm            ; GATE ARM IS THE FALSE SUCCESSOR
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
