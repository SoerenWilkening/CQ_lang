; control_predmux_accept_qrom_mask_clone_i32.ll — ACCEPT (bd 01po.2): the
; narrow-source PredMux mask inside a Phase-6 Bennett CLONE (the `ClaimAll`
; flatten of a specialized callee with internal tainted control). A clone read is
; re-proved in bounds at the emitter (`lowerQramReads(inBennettClone=true)` asks
; `qromIndexKnownInBounds` of the gep's trailing operand, and declines loudly
; with "speculated const-global table read in a specialized clone: index not
; provably in-bounds" when it cannot). So the re-widened index the flatten
; leaves on the gep must stay provable: `zext i32 (and i32 sel, 3) to i64` is
; (the bound walk reads `zext` as value-preserving and `and` as <= the mask); a
; `sext` re-widening would NOT be (the walk takes `sext` at full range), and
; every masked clone read would then decline.
;   * @lookup32: a NeedsMask read, the atan `id` shape at i32 (phi {2,-1}
;     sign-extended);
;   * @lookup32p: a PROVABLE read whose index becomes opaque after the flatten
;     (phi {0,1} zero-extended, bd 20xt.7), which gets the identity mask so the
;     emitter's re-proof can see the bound.
; Both: one `and_i32_hl` on the i32 select rail feeds the read and the Bennett
; reverse's `cqrt_qram_load_f64_unc` directly; no i64 widening, no `and_i64`, no
; `trunc_i64_to_i32` bracket around either call.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NARROW %s < %t.cqd0.ll
@tbl = internal unnamed_addr constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0], align 16
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define internal double @lookup32(double %x) {
entry:
  %c1 = fcmp ogt double %x, 1.000000e+00
  br i1 %c1, label %inner, label %base
inner:
  %c2 = fcmp olt double %x, 4.000000e+00
  br i1 %c2, label %ia, label %ib
ia:
  br label %join
ib:
  br label %join
join:
  %id = phi i32 [ 2, %ia ], [ -1, %ib ]
  %idx = sext i32 %id to i64
  %g = getelementptr inbounds [4 x double], ptr @tbl, i64 0, i64 %idx
  %v = load double, ptr %g, align 8
  %s = fadd double %x, %v
  br label %exit
base:
  br label %exit
exit:
  %r = phi double [ %s, %join ], [ %x, %base ]
  ret double %r
}

define internal double @lookup32p(double %x) {
entry:
  %c1 = fcmp ogt double %x, 1.000000e+00
  br i1 %c1, label %inner, label %base
inner:
  %c2 = fcmp olt double %x, 2.000000e+00
  br i1 %c2, label %ia, label %ib
ia:
  br label %join
ib:
  br label %join
join:
  %id = phi i32 [ 0, %ia ], [ 1, %ib ]
  %idx = zext i32 %id to i64
  %g = getelementptr inbounds [4 x double], ptr @tbl, i64 0, i64 %idx
  %v = load double, ptr %g, align 8
  %s = fadd double %x, %v
  br label %exit
base:
  br label %exit
exit:
  %r = phi double [ %s, %join ], [ %x, %base ]
  ret double %r
}

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @lookup32(double %q)
  %r2 = call double @lookup32p(double %r)
  %m = call double @cq_measure_f64(double %r2)
  ret double %m
}

; CHECK-LABEL: define internal i32 @__cq_q_lookup32_1(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 4)
; CHECK:      %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[SEL]], i32 3)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR]], i32 %[[M]])
; CHECK:      call void @cqrt_qram_load_f64_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[M]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[M]], i32 %[[SEL]], i32 3)
; NARROW-LABEL: define internal i32 @__cq_q_lookup32_1(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i64
; NARROW-NOT: trunc_i64_to_i32

; CHECK-LABEL: define internal i32 @__cq_q_lookup32p_1(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 4)
; CHECK:      %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[SEL]], i32 3)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR]], i32 %[[M]])
; CHECK:      call void @cqrt_qram_load_f64_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[M]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[M]], i32 %[[SEL]], i32 3)
; NARROW-LABEL: define internal i32 @__cq_q_lookup32p_1(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i64
; NARROW-NOT: trunc_i64_to_i32
; NARROW-LABEL: declare
