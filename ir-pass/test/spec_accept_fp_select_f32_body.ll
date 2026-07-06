; spec_accept_fp_select_f32_body.ll — Phase 6 / issue kmdc: the fabs FP two-arm
; select at f32 (float), confirming the width-parametric path — both {f32,f64}
; resolve real cqrt_copy_f<W>_controlled / cqrt_alloc_f<W> symbols. `int
; mhelper(int n){ float x=(float)n; float a=(x<0)?-x:x; return ilogbf(a); }`.
; The ordered forward/reverse palindrome is pinned in spec_accept_fp_select_body.ll
; (f64); this fixture pins the f32 width plumbing + the four-copy / four-bracket
; palindrome counts (each on its own FileCheck pass — the copies and brackets are
; interspersed, so a single sequential CHECK-COUNT cannot span both).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CPY
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=XB
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ilogbf(float)

define i32 @mhelper(i32 %n) {
entry:
  %x  = sitofp i32 %n to float
  %c  = icmp slt i32 %n, 0
  %nx = fneg float %x
  %a  = select i1 %c, float %nx, float %x
  %r  = call i32 @ilogbf(float %a)
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; f32 rail + copy symbols resolve; clone accepted; no leftover select.
; CHECK:     define internal i32 @__cq_q_mhelper_1(i32 %n)
; CHECK:     call i32 @cqrt_alloc_f32(float 0.000000e+00)
; CHECK:     call void @cqrt_copy_f32_controlled(
; CHECK:     ret i32
; CHECK-NOT: = select

; Palindrome (independent passes — the two symbols interleave):
; four controlled copies (2 fwd + 2 rev); four cqrt_x brackets (2 fwd + 2 rev).
; A dropped-bracket regression would show two cqrt_x.
; CPY-COUNT-4: call void @cqrt_copy_f32_controlled(
; CPY-NOT:     call void @cqrt_copy_f32_controlled(
; XB-COUNT-4:  call void @cqrt_x(
; XB-NOT:      call void @cqrt_x(
