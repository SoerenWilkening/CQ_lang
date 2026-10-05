; control_multiexit_reject_twin_outside_pred_value_arm.ll — DECLINE, a GAP pin (bd
; test_C_libtooling-dm7f.5 review round 2 F-A, probe p6t). The PLAIN-RETURN TWIN of
; control_multiexit_musttail_classical_exit_alloca.ll: the same C source without
; `__attribute__((musttail))`, `clang -O1`'s output (cleaned of target attributes and TBAA).
; Clang sends all three exits — the CLASSICAL `s == 1000` exit through `g`, the 6.5 arm through
; `h`, and the `return 5` — into ONE return block whose φ has a predecessor from OUTSIDE the
; quantum region (`%cexit`), and the region declines `control flow under quantum control`
; (measured on main 7b4e6359 and on this branch). The multi-exit spelling ACCEPTS, because the
; dm7f.5 merge belongs to the region alone and the classical exit keeps its own `ret`: the
; contract in ReturnMerge.h ("compiles at least whenever its twin does, and may compile where
; the twin's outside-predecessor return block declines"). The program is valid, so this is a
; pre-existing OVER-decline of the twin. Retirement trigger: bd to be filed: value/6.5-arm
; merge with an outside classical predecessor. When it lands this file ACCEPTS with the
; accept fixture's stream (the classical exit then reaches the shared return block) —
; re-derive it then, do not delete it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define i32 @g(i32 %u, i32 %a) #0 {
  %s = add nsw i32 %a, 7
  ret i32 %s
}

define i32 @h(i32 %u, i32 %a) #0 {
  %s = add nsw i32 %a, 100
  ret i32 %s
}

define i32 @sum2(ptr nocapture noundef readonly %p) #1 {
  %x = load i32, ptr %p, align 4
  %gp = getelementptr inbounds i8, ptr %p, i64 4
  %y = load i32, ptr %gp, align 4
  %s = add nsw i32 %y, %x
  ret i32 %s
}

define i32 @example(i32 noundef %u0, i32 noundef %a) {
entry:
  %buf = alloca [2 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %buf)
  store i32 %a, ptr %buf, align 4
  %hi = getelementptr inbounds i8, ptr %buf, i64 4
  store i32 %u0, ptr %hi, align 4
  %s = call i32 @sum2(ptr noundef nonnull %buf)
  %big = icmp eq i32 %s, 1000
  br i1 %big, label %cexit, label %quant
cexit:
  %gr = tail call i32 @g(i32 poison, i32 noundef %a)
  br label %m
quant:
  %q = call i32 @cq_theta_si32(i32 noundef %u0, double noundef 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %m
arm:
  %r = tail call i32 @h(i32 poison, i32 noundef %s)
  br label %m
m:
  %y = phi i32 [ %gr, %cexit ], [ %r, %arm ], [ 5, %quant ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %buf)
  ret i32 %y
}

attributes #0 = { noinline nounwind willreturn memory(none) }
attributes #1 = { noinline nounwind willreturn memory(argmem: read) }
