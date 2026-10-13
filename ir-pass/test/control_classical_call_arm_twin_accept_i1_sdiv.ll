; control_classical_call_arm_twin_accept_i1_sdiv.ll — ACCEPT (batch 053, R11 round-1
; finding A-F1, bd dm7f.30). Hand IR: an i1 signed division,
;   h(a, b) { x = trunc a to i1; d = trunc b to i1; r = sdiv i1 x, d; ret zext r }
; and its `srem` sibling. The generic signed guard `select((F==0)|(F==-1), 1, F)`
; is WRONG at i1: the constant 1 IS -1 there, so `bad` is always true and the twin
; would divide by -1, and -1 / -1 overflows (immediate UB on an excluded state).
; Fixed: an i1 divisor is 0 (UB) or -1, and `x / -1` overflows for x = -1 (INT_MIN),
; so the only UB-free result of i1 sdiv AND srem is 0 (x = 0). The twin computes
; exactly 0 and divides by nothing; `guardedDivisor` refuses the signed shape at i1.
; ANALYTIC (R2): on a basis state where the source runs `h` without UB, d = -1 and
; x = 0, so the source's result is 0 and the twin's is 0; elsewhere 0 is defined and
; never merged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:       %r = call i32 @__cq_specsafe_h(i32 %a, i32 %b)
; CHECK:       %r2 = call i32 @__cq_specsafe_hr(i32 %a, i32 %b)
; CHECK:       define internal i32 @__cq_specsafe_h(i32 noundef %a, i32 noundef %b) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin !{{[0-9]+}} {
; CHECK-NOT:     sdiv
; CHECK:         %z = zext i1 false to i32
; CHECK-NEXT:    %z.fr = freeze i32 %z
; CHECK-NEXT:    ret i32 %z.fr
; CHECK:       define internal i32 @__cq_specsafe_hr(i32 noundef %a, i32 noundef %b) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin !{{[0-9]+}} {
; CHECK-NOT:     srem
; CHECK:         %z = zext i1 false to i32
; CHECK-NEXT:    %z.fr = freeze i32 %z
; CHECK-NEXT:    ret i32 %z.fr

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @h(i32 noundef %a, i32 noundef %b) #0 {
entry:
  %x = trunc i32 %a to i1
  %d = trunc i32 %b to i1
  %q = sdiv i1 %x, %d
  %z = zext i1 %q to i32
  ret i32 %z
}

define internal i32 @hr(i32 noundef %a, i32 noundef %b) #0 {
entry:
  %x = trunc i32 %a to i1
  %d = trunc i32 %b to i1
  %q = srem i1 %x, %d
  %z = zext i1 %q to i32
  ret i32 %z
}

define i32 @example(i32 noundef %u0, i32 noundef %a, i32 noundef %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @h(i32 %a, i32 %b)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %c2 = icmp sgt i32 %q, 2
  br label %mid
mid:
  br i1 %c2, label %arm2, label %merge2
arm2:
  %r2 = call i32 @hr(i32 %a, i32 %b)
  br label %merge2
merge2:
  %y2 = phi i32 [ %r2, %arm2 ], [ %y, %mid ]
  %m = call i32 @cq_measure_si32(i32 %y2)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
