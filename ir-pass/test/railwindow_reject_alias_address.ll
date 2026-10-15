; railwindow_reject_alias_address.ll — DECLINE, COMPILER GAP (bd `test_C_libtooling-01po.19` S7;
; follow-up bd `test_C_libtooling-01po.19.8`).
;
; `q[j]` (j loaded from memory INSIDE a branch arm) and `q[i]` after the join
; are one unproven pair in one window. The version point must dominate both
; accesses (the branch block), where j's address is not computable (its index
; is a load in the arm, never speculated). Versioning lower, at q[j], is
; refused because q[i] after the join is reachable from it without being
; dominated. Until the arm-local versioning exists the pass fails loudly
; (R1: a gap, never a guess). The message is mirrored CHARACTER-FOR-CHARACTER
; from kMsgAddr. The straight-line form (`q[i]`, then `j = *p`, then `q[j]`)
; LOWERS: railwindow_version_late_address.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='quantum array not lowered yet'
; CHECK: error: {{.*}}in function f i32 (i64, ptr, i1): cq rail window: aliased cell address is not available at the version point

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1 zeroext, double) nomerge
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @f(i64 %i, ptr %pj, i1 %c) {
entry:
  %q = alloca [4 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %q, i8 0, i64 4, i1 false)
  %im = and i64 %i, 3
  %ga = getelementptr inbounds [4 x i8], ptr %q, i64 0, i64 %im
  br i1 %c, label %arm, label %join
arm:
  %j = load i64, ptr %pj
  %jm = and i64 %j, 3
  %gb = getelementptr inbounds [4 x i8], ptr %q, i64 0, i64 %jm
  %lb = load i8, ptr %gb
  %tb = trunc i8 %lb to i1
  %rb = call zeroext i1 @cq_theta_i1(i1 %tb, double 5.000000e-01)
  %zb = zext i1 %rb to i8
  store i8 %zb, ptr %gb
  br label %join
join:
  %la = load i8, ptr %ga
  %ta = trunc i8 %la to i1
  %ra = call zeroext i1 @cq_theta_i1(i1 %ta, double 3.000000e-01)
  %za = zext i1 %ra to i8
  store i8 %za, ptr %ga
  %m = load i8, ptr %q
  %tm = trunc i8 %m to i1
  %r = call zeroext i1 @cq_measure_i1(i1 %tm)
  %ri = zext i1 %r to i32
  ret i32 %ri
}
