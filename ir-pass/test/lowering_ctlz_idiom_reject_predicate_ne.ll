; lowering_ctlz_idiom_reject_predicate_ne.ll — DECLINE (bd ww4c Inc 1, the Z5
; predicate probe). The accepted shape with ONE change: `icmp ne %sh, 0` instead
; of `icmp sgt %sh, 0`.
;
; THIS ONE MATTERS MORE THAN IT LOOKS, because it is the idiom LLVM ITSELF
; recognizes. `while (x != 0)` is LoopIdiomRecognize's documented spelling, and
; its closed form is N-cttz-shaped, NOT the `sgt 0` form this pass substitutes.
; Stock clang lowers it to `icmp eq x,0` + `ctlz(x, i1 TRUE)` + `sub 32, z` + a
; SELECT — a different value AND a different repair (bd memory
; ww4c-ctlz-idiom-closed-form-2026-08-22: "the obvious form is wrong and the
; wrong one is what LLVM prints"). Substituting THIS pass's closed form here
; would be a silent miscompile of exactly the kind a green suite cannot see.
;
; So the decline is not "we have no closed form for it" — it is "its closed form
; is a DIFFERENT one, and Z5 is what keeps the two apart". Note also that clang
; usually turns this spelling into a ctlz before the pass ever sees it, which is
; precisely bd ww4c's decisive experiment: openlibm's `sgt 0` spelling produces
; no ctlz at -O1, -O2 or -O3, while LLVM's own spelling produces one at all three.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_predicate_ne(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %live = icmp ne i32 %sh, 0
  br i1 %live, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
