; lowering_reject_fp80_union_i80_merge.ll — bd 3c6m.51 Inc 3 DECLINE (the Inc-3
; safety fence): an i80 value crossing a control merge (an `phi i80`). i80 is an
; INTERMEDIATE-only width — there is no i80 controlled copy (the >64 fence), so an
; i80 phi can never be muxed. The canonicalize + PromoteMemToReg promotion keeps
; every i80 intra-block by construction (the fresh alloca is x86_fp80-typed, so
; mem2reg only ever builds f80 phis); this fence is the defensive invariant scan
; behind that construction — any `phi i80` present after a promotion LOUD-declines
; instead of flowing on toward a half-lowerable merge.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @i80phi() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8
  %exp = and i64 %hi, 32767              ; a promotable union (would ACCEPT alone)
  %bc = bitcast x86_fp80 %q to i80       ; hand-written i80 SSA
  %c = fcmp ogt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %a, label %m

a:
  %sh = lshr i80 %bc, 1
  br label %m

m:
  %p = phi i80 [ %sh, %a ], [ %bc, %entry ]   ; i80 crosses a tainted merge
  %t = trunc i80 %p to i64
  %r = add i64 %t, %exp
  %mm = call i64 @cq_measure_sll(i64 %r)
  ret i64 %mm
}

; CHECK: error{{.*}}cq fp80 union: i80 value crosses a control merge
; CHECK-NOT: cq_template_bitcast_i80_to_f80
