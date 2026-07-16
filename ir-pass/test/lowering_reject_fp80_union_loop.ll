; lowering_reject_fp80_union_loop.ll — bd 3c6m.51 Inc 3 DECLINE (the acyclic
; access gate — the FIRST Rule-13 clearance round's confirmed finding): a union
; access inside a CFG cycle puts the promoted value on a loop-carried path.
; Lexical-order reasoning is unsound there (a loop-body load positioned before
; the store-back reads the PREVIOUS iteration's store via the back-edge — the
; original comesBefore-based dead-insert test erased exactly such a live RMW,
; a verify-clean silent miscompile). Loop unions are Phase 7.3 territory; the
; candidate is left byte-untouched and the tainted seed falls to the existing
; loud kMsgStore taint-escape decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @loop_rmw() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  br label %loop

loop:                                           ; the union RMW rides the cycle
  %i = phi i64 [ 0, %entry ], [ %i2, %loop ]
  %w = load i64, ptr %p8, align 8               ; reads the PREVIOUS iteration's store
  %w2 = add i64 %w, 1
  store i64 %w2, ptr %p8, align 8               ; loop-carried field-insert
  %i2 = add i64 %i, 1
  %c = icmp ult i64 %i2, 3
  br i1 %c, label %loop, label %exit

exit:
  %e = load x86_fp80, ptr %u, align 16
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
; CHECK-NOT: cq_template_bitcast_f80_to_i80
