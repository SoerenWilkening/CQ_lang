; lowering_ctlz_idiom_generic_seed.ll — ACCEPT (bd ww4c Inc 1). PRD §1.1's
; honesty obligation, the ACCEPT direction, second instance: a shape that IS the
; idiom and is NOT `ilogb`, differing on every axis a per-function recognizer in
; a structural costume would have keyed on.
;
;   * a seed C0 the libm sources never use (0, so the emitted constant is -1);
;   * a function name with no libm relationship;
;   * no guard, no pre-shift, no exponent arithmetic, no bit-extraction preamble;
;   * the escaping counter consumed by ordinary tainted arithmetic (an `add`)
;     rather than fed straight to a measure.
;
; PRD §1.1 is explicit that a landing which accepts only the three target loops
; has FAILED the obligation even with every test green. This fixture and
; lowering_ctlz_idiom_i64.ll are the two that would go red if the fence were ever
; tuned toward `ilogb`.
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the `q + c` here lowers
; IN PLACE to the frozen `cqrt_addc_<W>` — its parent handle has no data use
; after it — so no fresh ancestor rail is minted. Nothing else about what this
; file pins has moved.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CLEAN %s < %t.cqd0.ll
;
; Operands CAPTURED, not wildcarded (bd ww4c.4): wildcards pin only the symbols
; and literals, under which three genuine miscompiles of the closed form pass.
; CHECK: %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i32(i32 %[[S1]])
; CHECK: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Z]], i32 31)
; CHECK: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_lh(i32 -1, i32 %[[M]])
; CHECK: call void @cqrt_addc_i32(i32 %[[C]], i32 7)
;
; CLEAN-NOT: = phi
; CLEAN-NOT: br i1
; The intrinsic CALL is gone (the now-unused `declare` is left behind, as it is
; for every other lowered intrinsic — cf. lowering_intrinsic_ctlz_i32.ll).
; CLEAN-NOT: call {{.*}}@llvm.ctlz

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leading_run(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 1.250000e-01)
  br label %scan

scan:                                             ; preds = %entry, %scan
  %k = phi i32 [ 0, %entry ], [ %dec, %scan ]
  %w = phi i32 [ %q, %entry ], [ %sh, %scan ]
  %dec = add nsw i32 %k, -1
  %sh = shl nuw i32 %w, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %scan, label %out, !llvm.loop !0

out:                                              ; preds = %scan
  %adj = add nsw i32 %dec, 7
  %m = call i32 @cq_measure_si32(i32 %adj)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}
