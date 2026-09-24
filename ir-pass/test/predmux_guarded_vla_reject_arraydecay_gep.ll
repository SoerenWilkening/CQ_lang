; predmux_guarded_vla_reject_arraydecay_gep.ll — DECLINE (bd xdu2.8, Rule-13 round 1 P3-1).
; A two-index `getelementptr [4 x i32], ptr %p, i64 0, i64 %kz` over a SCALAR runtime
; alloca. The shared shape half (`matchAddressGep`) accepts it and proof (I) passes; ONLY
; the single-index conjunct of `classicalRuntimeAllocaReadIsInBoundsUnderGuard` refuses
; it, and without that conjunct the emission would be handed a gep it cannot rebuild
; (an abort). The leave line and the diagnostic are BOTH checked, because a bare `not`
; cannot tell a decline from an abort. Hand IR from the round-1 reviewer (probe
; h13_arraydecay.ll). Kills injection mutant M4.
;
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s 2>&1 | %filecheck %s
; CHECK: gate=E4-gep at: {{.*}}getelementptr inbounds [4 x i32]
; CHECK-NOT: LLVM ERROR
; CHECK: cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main(i32 noundef %argc, ptr nocapture noundef readonly %argv) {
  %m = add nsw i32 %argc, 2
  %ai = sext i32 %argc to i64
  %ap = getelementptr ptr, ptr %argv, i64 %ai
  %ap1 = getelementptr i8, ptr %ap, i64 -8
  %s = load ptr, ptr %ap1, align 8
  %kk = tail call i32 @atoi(ptr nocapture noundef %s)
  %k = add i32 %kk, %argc
  %r = tail call i32 @slice(i32 noundef %m, i32 noundef %k)
  ret i32 %r
}

define internal i32 @slice(i32 noundef %m, i32 noundef %k) noinline {
pre:
  %ext = zext nneg i32 %m to i64
  %ss = tail call ptr @llvm.stacksave.p0()
  %p = alloca i32, i64 %ext, align 16
  br label %fill
fill:
  %fi = phi i64 [ 0, %pre ], [ %fin, %fill ]
  %fg = getelementptr inbounds i32, ptr %p, i64 %fi
  %ft = trunc i64 %fi to i32
  %fv = add i32 %ft, 3
  store i32 %fv, ptr %fg, align 4
  %fin = add nuw nsw i64 %fi, 1
  %fc = icmp eq i64 %fin, %ext
  br i1 %fc, label %start, label %fill
start:
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01)
  %r = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %qb = icmp ne i32 %q, 0
  %kz = zext i32 %k to i64
  %inb = icmp ult i32 %k, %m
  %c = and i1 %inb, %qb
  br i1 %c, label %arm, label %mg
arm:
  %g = getelementptr inbounds [4 x i32], ptr %p, i64 0, i64 %kz
  %v = load i32, ptr %g, align 4
  %t = icmp sgt i32 %v, 4
  %t2 = icmp slt i32 %v, 9
  br label %mg
mg:
  %b = phi i1 [ %t, %arm ], [ false, %start ]
  %b2 = phi i1 [ %t2, %arm ], [ false, %start ]
  %mq = tail call i32 @cq_measure_si32(i32 noundef %q)
  %mr = tail call i32 @cq_measure_si32(i32 noundef %r)
  %mb = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %b)
  %mbz = zext i1 %mb to i32
  %mb2 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %b2)
  %mbz2 = zext i1 %mb2 to i32
  %s1 = add i32 %mq, %mr
  %s0 = add i32 %s1, %mbz
  %s2 = add i32 %s0, %mbz2
  tail call void @llvm.stackrestore.p0(ptr %ss)
  ret i32 %s2
}

declare i32 @atoi(ptr nocapture noundef)
declare ptr @llvm.stacksave.p0()
declare void @llvm.stackrestore.p0(ptr)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
