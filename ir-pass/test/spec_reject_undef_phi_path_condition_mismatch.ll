; spec_reject_undef_phi_path_condition_mismatch.ll — DECLINE (bd p3kd.8, the decline
; cell of the path-condition seed in UndefReach.h).
;
; spec_accept_undef_phi_path_condition.ll with the second test on a DIFFERENT
; condition (`a > 3` instead of `a > 5`). For 3 < a <= 5 the program takes %down (so
; `%su` is undef) and then %big, which returns `m + su`: the result denotes no value
; on that path. On the edge %down -> %mid the seed knows only `%c` = false; `%c2` does
; not fold, both %big and %small stay executable, and the undef reaches the `ret`, so
; the bd 3p2a decline stands.
;
; Hand-written IR (the C spelling below folds to selects under clang -O1):
;   int helper(int a) {
;     int up, down;
;     if (a > 5) up = a * 7 + 3; else down = a * 3 + 1;
;     int m = a * 9;
;     return a > 3 ? m + up : m - down;
;   }
;   int example(int u0) { int q = u0; cq_theta(&q, 0.5); return cq_measure(helper(q)); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee return value denotes no value (undef/poison)

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
  %c2 = icmp sgt i32 %a, 3
  br i1 %c2, label %big, label %small

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
