; lowering_io_controlled_printf_ne.ll — ACCEPT (Phase 7.6 Increment 2), the
; NEGATED polarity. `clang -O1` canonicalizes `if (q != 5) printf("%d", q)` to
; `icmp eq` + SWAPPED successors — the gate arm is the FALSE successor (Rule 9).
; The controlled write must therefore fire on ¬flag, achieved by a self-inverse
; `cqrt_x` bracket enclosing ONLY the write (the 4.1/4.4 convention). A mis-bracket
; (X before the strip, or around the wrong span) is VERIFY-CLEAN-INVISIBLE — it
; yields the identical symbol multiset yet commits the entry on the wrong basis
; branch — so the bracket span is pinned by the ORDERED CHECK sequence below.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %merge, label %arm

arm:                                              ; preds = %entry
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

merge:                                            ; preds = %entry, %arm
  %m = call i32 @cq_measure_si32(i32 %q)
  ret void
}

; The mint, then the ¬flag bracket enclosing ONLY the controlled write, then the
; strip + free — in this EXACT order (the bracket-span hazard, §16.3):
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call i32 @cqrt_tape_write_i32_controlled(i32 %[[FLAG]], i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FLAG]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: br i1
