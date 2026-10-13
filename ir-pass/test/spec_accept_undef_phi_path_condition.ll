; spec_accept_undef_phi_path_condition.ll — ACCEPT (bd p3kd.8, the exp2 shape).
;
; openlibm exp2 (src/s_exp2.c) builds its scale factor in one of two arms, so clang
; -O1 leaves TWO merge phis each with an `undef` incoming from the other arm
; (`%61 = phi [ undef, %50 ], [ %59, %55 ]`, `%62 = phi [ %54, %50 ], [ undef, %55 ]`)
; and later branches on the SAME condition `%49` to pick which one it reads. No sibling
; phi carries the arm's identity here: the fact lives in the path condition into the
; edge. UndefReach.h seeds it: on the edge %down -> %mid every execution took
; `br i1 %c` false (%down's only predecessor is %entry), so the later `br i1 %c` folds
; to %small, which reads only `%sd`; symmetrically for %up. Both undefs are
; unobservable and the callee lifts. A data-only or phi-only evaluation declines
; (`callee return value denotes no value`), as `main` fc6ee653 does (measured).
;
; Hand-written IR, reduced from the clang -O1 output of s_exp2.c above (clang merges
; a small C spelling of this into selects, so the C below does not reach the pass in
; this shape):
;   int helper(int a) {
;     int up, down, big = a > 5;
;     if (big) up = a * 7 + 3; else down = a * 3 + 1;
;     int m = a * 9;
;     return big ? m + up : m - down;
;   }
;   int example(int u0) { int q = u0; cq_theta(&q, 0.5); return cq_measure(helper(q)); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 noundef %a) {
entry:
  %c = icmp sgt i32 %a, 5
  br i1 %c, label %up, label %down

up:
  %u1 = mul nsw i32 %a, 7
  %u = add nsw i32 %u1, 3
  br label %mid

down:
  %d1 = mul nsw i32 %a, 3
  %d = add nsw i32 %d1, 1
  br label %mid

mid:
  %su = phi i32 [ %u, %up ], [ undef, %down ]
  %sd = phi i32 [ undef, %up ], [ %d, %down ]
  %m = mul nsw i32 %a, 9
  br i1 %c, label %big, label %small

big:
  %rb = add nsw i32 %m, %su
  br label %out

small:
  %rs = sub nsw i32 %m, %sd
  br label %out

out:
  %r = phi i32 [ %rb, %big ], [ %rs, %small ]
  ret i32 %r
}

define i32 @example(i32 noundef %u0) {
  %q = tail call i32 @cq_theta_si32(i32 noundef %u0, double noundef 5.000000e-01)
  %r = tail call i32 @helper(i32 noundef %q)
  %m = tail call i32 @cq_measure_si32(i32 noundef %r)
  ret i32 %m
}

; CHECK-LABEL: define i32 @example(
; CHECK:     call i32 @__cq_q_helper_1(
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(
; CHECK-NOT: {{ (undef|poison)[],) ]}}
; CHECK:     call void @cqrt_copy_i32(
; CHECK-NOT: {{ (undef|poison)[],) ]}}
; CHECK:     ret i32
