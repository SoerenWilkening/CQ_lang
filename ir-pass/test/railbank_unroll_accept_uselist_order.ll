; ACCEPT (bd `test_C_libtooling-01po.19`, review round 1 item 1): the stage is
; DETERMINISTIC and never spins.
;
; Reviewer probe rv/p4.ll, verbatim. `uselistorder` reverses %q's use list, and loop
; B's trip (`%n1`, a sum of a constant table) becomes a constant only after loop A is
; unrolled. On c7a734af the trial on the clone succeeded, the re-run on the original
; (which reads users() in a different order) failed without changing anything, the
; stage still returned `true`, and `promoteRailBankCells` never terminated. Now loops are
; picked in INSTRUCTION order, a variable index no loop resolves YET does not fail the
; round while another access offers a loop, and the clone's body is ADOPTED (the trial
; is the adoption: nothing can diverge, and `true` means the array is gone).
;
; Stream: A rotates q0..q2 by 0.5; n1 = 1+1+0 = 2, so B measures q0 and q1.
;
; RUN: env CQ_RAILBANK_UNROLL_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=DBG
; DBG: CQ_RAILBANK_UNROLL_DBG: unroll trip-3 loop at %A in @main
; DBG-NEXT: CQ_RAILBANK_UNROLL_DBG: unroll trip-2 loop at %B in @main
; DBG-NEXT: CQ_RAILBANK_UNROLL_DBG: @main array q scalarized
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK-LABEL: define {{.*}} @main(
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK: %h1 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01)
; CHECK: %h2 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h2, double 5.000000e-01)
; CHECK: %m3 = call i1 @cqrt_measure_i1(i32 %h)
; CHECK: %m4 = call i1 @cqrt_measure_i1(i32 %h1)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@T = private unnamed_addr constant [3 x i64] [i64 1, i64 1, i64 0]

define i32 @main() {
entry:
  %q = alloca [4 x i8], align 1
  call void @llvm.memset.p0.i64(ptr align 1 %q, i8 0, i64 4, i1 false)
  br label %A

B:
  %j = phi i64 [ 0, %Bpre ], [ %j1, %B ]
  %s = phi i32 [ 0, %Bpre ], [ %s1, %B ]
  %g2 = getelementptr inbounds [4 x i8], ptr %q, i64 0, i64 %j
  %l = load i8, ptr %g2, align 1
  %tr = trunc i8 %l to i1
  %m = call zeroext i1 @cq_measure_i1(i1 zeroext %tr)
  %mz = zext i1 %m to i32
  %s1 = add i32 %s, %mz
  %j1 = add nuw nsw i64 %j, 1
  %cB = icmp ult i64 %j1, %n1
  br i1 %cB, label %B, label %exit

A:
  %i = phi i64 [ 0, %entry ], [ %i1, %A ]
  %n = phi i64 [ 0, %entry ], [ %n1, %A ]
  %g = getelementptr inbounds [4 x i8], ptr %q, i64 0, i64 %i
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01) #1
  %z = zext i1 %t to i8
  store i8 %z, ptr %g, align 1
  %tp = getelementptr inbounds [3 x i64], ptr @T, i64 0, i64 %i
  %tl = load i64, ptr %tp, align 8
  %n1 = add i64 %n, %tl
  %i1 = add nuw nsw i64 %i, 1
  %c = icmp eq i64 %i1, 3
  br i1 %c, label %Bpre, label %A

Bpre:
  br label %B

exit:
  ret i32 %s1
  uselistorder ptr %q, { 1, 0, 2 }
}

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
attributes #1 = { nomerge nounwind }
