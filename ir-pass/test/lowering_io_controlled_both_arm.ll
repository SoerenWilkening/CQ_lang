; lowering_io_controlled_both_arm.ll — ACCEPT (Phase 7.2 Increment 2): a BOTH-ARM
; controlled I/O if/else `if (q > 5) printf("%d", q); else putchar(q);`. clang -O1
; keeps a br-DIAMOND (neither sink is speculatable, and the two arms call DISTINCT
; sinks so they do not fold to one printf): two single-pred sole-sink arms
; reconverging at one 2-predecessor NO-phi merge (orientation C). Detection
; declines such a both-arm diamond ('control flow under quantum control'); this
; step lowers it to ONE shared tape with TWO controlled writes — the TRUE arm
; (printf) under `flag`, the FALSE arm (putchar) under the `cqrt_x`-bracketed
; ¬flag. ONE flag minted from the ONE compare. Tape length is classical/
; deterministic (exactly 2 entries; only CONTENT is gated — the inactive arm
; commits |0> content, accepted Bennett-tape semantics). A mis-bracket (the TRUE
; arm wrapped, or the wrong span) is VERIFY-CLEAN-INVISIBLE — identical symbol
; multiset, wrong basis branch — so each arm's bracket span is pinned by the
; ORDERED CHECK below (§16.3), and the entry COUNT by the CNT scan.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
declare i32 @putchar(i32)
@.str = private constant [3 x i8] c"%d\00"

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else

then:                                             ; preds = %entry  (TRUE arm)
  %p = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

else:                                             ; preds = %entry  (FALSE arm)
  %u = call i32 @putchar(i32 %q)
  br label %merge

merge:                                            ; preds = %then, %else
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; ONE tape, ONE flag, then the TRUE arm's write UNBRACKETED (the CHECK-NOT forbids
; a `cqrt_x` between the mint and the first write), then the FALSE arm's write
; enclosed in the self-inverse `cqrt_x` bracket, then the strip + free — EXACTLY in
; this order (the per-arm bracket-span hazard, §16.3):
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NOT: call void @cqrt_x(
; CHECK:     call i32 @cqrt_tape_write_i32_controlled(i32 %[[FLAG]], i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call i32 @cqrt_tape_write_i32_controlled(i32 %[[FLAG]], i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FLAG]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: call{{.*}}@putchar
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: br i1

; Deterministic tape length: EXACTLY one tape alloc and EXACTLY two controlled
; writes (one per arm) — never a third, never a second tape.
; CNT-COUNT-1: call i32 @cqrt_tape_alloc
; CNT-NOT:     call i32 @cqrt_tape_alloc
; CNT-COUNT-2: call i32 @cqrt_tape_write_i32_controlled
; CNT-NOT:     call i32 @cqrt_tape_write_i32_controlled
