; control_multiexit_untouched_reconverged.ll — BOUNDARY (bd test_C_libtooling-dm7f.5):
; "normalize only where needed". In both functions a tainted `br` reaches TWO `ret`s,
; but every path from it to a `ret` passes one block first, where a CLASSICAL branch
; on `%k` splits into the two exits. `unifyTaintedReturns` leaves both functions
; byte-untouched: no `cq.retmerge`, both `ret`s and the classical `br i1 %k` survive,
; and each stream is main 7b4e6359's (measured).
;
;   * `@example` — the kickback region RECONVERGES at `%j`: LLVM's
;     `PostDominatorTree` names `%j` as the immediate post-dominator.
;   * `@park` — the abort PARK (`AbortParkEmit`, agent-owned row; it must keep its
;     behaviour): one arm `exit`s, so the post-dominator tree's only answer is its
;     virtual root (an `unreachable` block is a root too), yet both `ret`s are
;     reached through `%cont`. The gate re-asks over the `ret` exits alone
;     (`returnsReconverge`) and refuses. MEASURED: the PostDominatorTree-only gate of
;     this change's first build merged `@park`'s `ret`s (`cq.retmerge` fed by `%cont`
;     and `%r2`) — a semantically harmless rewrite of a function that did not need
;     one, and the reason this function is here.
;
; HAND TRACE, @example. q = Ry(0.5)|u0>; f = [x > 5]; Rz(f, .25) phases x > 5; the
; `_unc` strip returns f to 0 and frees it; then the classical `%k` either returns q
; live (escape) or measures it (the user's measurement). @park: the park's stream
; (flag, Fredkin into a |0> grave, the flag onto the output tape), then the user's
; measurement and the classical split.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @exit(i32)

define i32 @example(i32 %u0, i1 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %j
a:
  call void @cq_phi(double 2.500000e-01)
  br label %j
j:
  br i1 %k, label %e1, label %e2
e1:
  ret i32 %q
e2:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

define i32 @park(i1 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %cont
a:
  call void @exit(i32 1)
  unreachable
cont:
  %m = call i32 @cq_measure_si32(i32 %q)
  br i1 %k, label %r1, label %r2
r1:
  ret i32 %m
r2:
  %m2 = add i32 %m, 1
  ret i32 %m2
}

; CHECK: define i32 @example(i32 %u0, i1 %k) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: br i1 %k, label %e1, label %e2
; CHECK-EMPTY:
; CHECK-NEXT: e1:
; CHECK-NEXT: ret i32 %[[H]]
; CHECK-EMPTY:
; CHECK-NEXT: e2:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
; CHECK-NEXT: }
; CHECK: define i32 @park(i1 %k) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK-NEXT: %[[PH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PH]], double 5.000000e-01)
; CHECK-NEXT: %[[PF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[PH]], i32 5)
; CHECK-NEXT: %[[GR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[PF]], i32 %[[PH]], i32 %[[GR]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_tape_write_i1(i32 %[[T]], i32 %[[PF]])
; CHECK-NEXT: br label %cont
; CHECK-EMPTY:
; CHECK-NEXT: cont:
; CHECK-NEXT: %[[PM:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[PH]])
; CHECK-NEXT: br i1 %k, label %r1, label %r2
; CHECK-EMPTY:
; CHECK-NEXT: r1:
; CHECK-NEXT: ret i32 %[[PM]]
; CHECK-EMPTY:
; CHECK-NEXT: r2:
; CHECK-NEXT: %[[PM2:[a-zA-Z0-9_.]+]] = add i32 %[[PM]], 1
; CHECK-NEXT: ret i32 %[[PM2]]
; CHECK-NEXT: }

; NEG-NOT: cq.retmerge
; NEG-NOT: cq.ret
; NEG-NOT: phi i32
