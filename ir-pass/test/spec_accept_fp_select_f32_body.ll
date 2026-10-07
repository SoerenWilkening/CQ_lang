; spec_accept_fp_select_f32_body.ll — Phase 6 / issue kmdc: the fabs FP two-arm
; select at f32 (float), confirming the width-parametric path — both {f32,f64}
; resolve real cqrt_copy_f<W>_controlled / cqrt_alloc_f<W> symbols. `int
; mhelper(int n){ float x=(float)n; float a=(x<0)?-x:x; return a>1.0f; }`. (p119:
; the terminal is a stock `fcmp ogt`+`zext` — the original `ilogbf` cross-width
; libm producer was removed as a library function; the lifting is identical.)
; The ordered forward/reverse palindrome is pinned in spec_accept_fp_select_body.ll
; (f64); this fixture pins the f32 width plumbing + the four-copy / two-bracket
; mirror counts (each on its own FileCheck pass — the copies and brackets are
; interspersed, so a single sequential CHECK-COUNT cannot span both).
;
; bd p3kd.7.8: main's stage list now lowers the clone (SelectMergeEmit) and the
; Bennett wrap elides the forward's closing `cqrt_x` strip (it writes only the flag
; after the flag's last forward read), so there is one bracket each way, not two:
; the forward leaves the flag at ¬c and the mirror's `cqrt_x` restores it between
; the two reverse copies. Hand trace as in the f64 sibling: out = c ? −x : x = |x|,
; and the mirror (copy_c(¬c,x), `cqrt_x`, copy_c(c,−x)) returns out to 0 before its
; free. The CHECK prefix now also pins the bracket BETWEEN the copies in each
; direction. The old trailing `CHECK-NOT: = select` scanned only the text after the
; clone's `ret`, so it pinned nothing; it now spans the clone body.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPY < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XB < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mhelper(i32 %n) {
entry:
  %x  = sitofp i32 %n to float
  %c  = icmp slt i32 %n, 0
  %nx = fneg float %x
  %a  = select i1 %c, float %nx, float %x
  %cmp = fcmp ogt float %a, 1.000000e+00
  %r  = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; f32 rail + copy symbols resolve; clone accepted; no leftover select in the clone;
; the ¬flag bracket sits between the two copies forward AND reverse.
; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(i32 %n)
; CHECK-NOT:   = select
; CHECK:       call i32 @cqrt_alloc_f32(float 0.000000e+00)
; CHECK-NOT:   = select
; CHECK:       call void @cqrt_copy_f32_controlled(i32 %[[FL:[a-zA-Z0-9_.]+]], i32 %[[T:[a-zA-Z0-9_.]+]], i32 %[[SEL:[a-zA-Z0-9_.]+]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[FL]])
; CHECK-NEXT:  call void @cqrt_copy_f32_controlled(i32 %[[FL]], i32 %[[F:[a-zA-Z0-9_.]+]], i32 %[[SEL]])
; CHECK-NOT:   = select
; CHECK:       call void @cqrt_copy_f32_controlled(i32 %[[FL]], i32 %[[F]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[FL]])
; CHECK-NEXT:  call void @cqrt_copy_f32_controlled(i32 %[[FL]], i32 %[[T]], i32 %[[SEL]])
; CHECK-NOT:   = select
; CHECK:       call void @cqrt_free(i32 %[[SEL]])
; CHECK-NOT:   = select
; CHECK:       ret i32
; CHECK-NEXT:  }

; Mirror (independent passes — the two symbols interleave):
; four controlled copies (2 fwd + 2 rev); two cqrt_x brackets (1 fwd + 1 rev).
; A dropped-bracket regression would show one cqrt_x.
; CPY-COUNT-4: call void @cqrt_copy_f32_controlled(
; CPY-NOT:     call void @cqrt_copy_f32_controlled(
; XB-COUNT-2:  call void @cqrt_x(
; XB-NOT:      call void @cqrt_x(
