; control_multiexit_musttail_classical_exit_alloca.ll — ACCEPT (bd test_C_libtooling-dm7f.5,
; review round 2 F-A, probe p6). `@example` is `clang -O1`'s output (cleaned of target
; attributes and TBAA) for
;     int f(int u, int a) {
;       int buf[2] = {a, u}; int s = sum2(buf);
;       if (s == 1000) __attribute__((musttail)) return g(u, a);   // CLASSICAL exit
;       int q = u; cq_theta(&q, 0.5);
;       if (q > 3) __attribute__((musttail)) return h(u, s);
;       return 5;
;     }
; Only the tainted `br %c` needs the merge, and it reaches `%arm`'s and `%other`'s `ret`s;
; the classical `%cexit` exit is reached by no needing branch, so it keeps its `musttail`
; call to `g` and its own `ret` (review round 1 F2). `%arm`'s `musttail` is demoted, the two
; quantum `ret`s merge, `buf`'s `lifetime.end` sinks into the merge, `%other` folds, and the
; region lowers as the 6.5 classical-call arm.
;
; ⚠ THIS IS NOT ITS TWIN'S CFG — the case the contract in ReturnMerge.h names. The
; plain-return spelling (control_multiexit_reject_twin_outside_pred_value_arm.ll) sends the
; classical `g` exit through clang's ONE return block, where it is a predecessor from OUTSIDE
; the quantum region, and that module declines `control flow under quantum control`. The
; multi-exit spelling compiles at least whenever its twin does, and here where the twin does
; not; this accept is correct (trace below) and the twin's decline is a pre-existing
; over-decline (bd to be filed: value/6.5-arm merge with an outside classical predecessor).
;
; HAND TRACE. `s = sum2(buf)` runs classically. If s == 1000 the function returns g(u, a)
; classically: no gate, no qubit. Otherwise q = Ry(0.5)|u0>; r = h(poison, s) runs once,
; classically (hoisted, operand frozen); f = [x > 3]; out = |0>, XOR-copied from alloc(r)
; under f and from alloc(5) under NOT f; f stripped to 0 and freed; `buf` dies; out escapes.
; (Review probe p6 linked it: trace for m = 5 is that stream with r = 110; for m = 500,
; s = 1000 and the trace is empty.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

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
  %gr = musttail call i32 @g(i32 poison, i32 noundef %a)
  ret i32 %gr
quant:
  %q = call i32 @cq_theta_si32(i32 noundef %u0, double noundef 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %other
arm:
  %r = musttail call i32 @h(i32 poison, i32 noundef %s)
  ret i32 %r
other:
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %buf)
  ret i32 5
}

attributes #0 = { noinline nounwind willreturn memory(none) }
attributes #1 = { noinline nounwind willreturn memory(argmem: read) }

; CHECK: define i32 @example(i32 noundef %u0, i32 noundef %a) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %buf = alloca [2 x i32], align 4
; CHECK-NEXT: call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %buf)
; CHECK-NEXT: store i32 %a, ptr %buf, align 4
; CHECK-NEXT: %hi = getelementptr inbounds i8, ptr %buf, i64 4
; CHECK-NEXT: store i32 %u0, ptr %hi, align 4
; CHECK-NEXT: %s = call i32 @sum2(ptr noundef nonnull %buf)
; CHECK-NEXT: %big = icmp eq i32 %s, 1000
; CHECK-NEXT: br i1 %big, label %cexit, label %quant
; CHECK-EMPTY:
; CHECK-NEXT: cexit:
; CHECK-NEXT: %gr = musttail call i32 @g(i32 poison, i32 noundef %a)
; CHECK-NEXT: ret i32 %gr
; CHECK-EMPTY:
; CHECK-NEXT: quant:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[FR:[a-zA-Z0-9_.]+]] = freeze i32 %s
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call i32 @h(i32 poison, i32 noundef %[[FR]])
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[S1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[S2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %buf)
; CHECK-NEXT: ret i32 %[[OUT]]
; CHECK-NEXT: }

; NEG-NOT: musttail call i32 @h
; NEG-NOT: cq.retmerge
