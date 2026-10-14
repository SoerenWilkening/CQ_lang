; railwindow_quantization_point_irreducible.ll — DECLINE (bd `test_C_libtooling-01po.19` S2).
;
; ADVERSARIAL for S2's quantization point Q: every access of the array lies in an
; IRREDUCIBLE cycle (two entries, LoopInfo models no loop). The first candidate
; for Q is inside the cycle and would re-materialize the cells on every trip; Q
; must be hoisted to a dominator that runs once (here the entry block's branch),
; so the claim's `Q=` names that branch. Hand IR: `-O1` C does not produce an
; irreducible cycle around a cell walk on demand.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank'
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; CHECK: cq rail window: quantum array not lowered yet (bd 01po.19), needs S4 borrowed-root cells
; WIN: CQ_RAILWINDOW_DBG: @main claims %q cells=i8 loads=1 stores=1 Q=  br i1 %c, label %A, label %B

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; An IRREDUCIBLE cycle (two entries, A and B) around the tainted write: LoopInfo
; models no loop, so the write is its own quantization candidate, and it is
; re-executed, and every access of the array lies in that cycle, so the point
; cannot be hoisted out of it.
define i32 @main(i32 %n) {
entry:
  %q = alloca [4 x i8], align 1
  call void @llvm.memset.p0.i64(ptr align 1 %q, i8 0, i64 4, i1 false)
  %c = icmp sgt i32 %n, 2
  br i1 %c, label %A, label %B

A:
  %i = phi i64 [ 0, %entry ], [ %j1, %B ]
  %g = getelementptr inbounds [4 x i8], ptr %q, i64 0, i64 %i
  %l = load i8, ptr %g, align 1
  %t = trunc i8 %l to i1
  %r = call zeroext i1 @cq_theta_i1(i1 zeroext %t, double 5.000000e-01)
  %z = zext i1 %r to i8
  store i8 %z, ptr %g, align 1
  %m = call zeroext i1 @cq_measure_i1(i1 zeroext %r)
  %i1 = add nuw nsw i64 %i, 1
  br label %B

B:
  %j = phi i64 [ 1, %entry ], [ %i1, %A ]
  %j1 = and i64 %j, 3
  %d = icmp ult i64 %j, 3
  br i1 %d, label %A, label %out

out:
  ret i32 0
}

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
