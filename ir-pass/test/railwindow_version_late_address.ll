; railwindow_version_late_address.ll — ACCEPT (bd `test_C_libtooling-01po.19` S7).
;
; `q[i]` is rotated, then `j = *pj` is LOADED, then `q[j]` is rotated. The
; nearest common dominator of the pair (the first q[i] access) precedes j, and
; a load is never speculated, so S7 versions LOWER: at q[j]'s access, which
; dominates every later access of the pair; the earlier q[i] access stays in
; front of the guard, where no q[j] access exists. The guard compares the two
; cell offsets after j is known.
;
; ANALYTIC TRACE: h = the rail of q[i], Ry(.3).
;   distinct (i != j): Ry(.5) on cell j's own rail.
;   aliased  (i == j): Ry(.5) on h (cell i holds h: q[i] = Ry(.8)|0>).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --input-file=%t.ll
; CHECK-LABEL: define i32 @f(
; CHECK: [[H:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[H]], double 3.000000e-01)
; Cell i is written (h) in front of the guard; each copy is a window of its own
; and reloads it through memory.
; CHECK: store i32 [[H]], ptr [[CI:%[a-z0-9.]+]],
; CHECK-NEXT: %j = load i64, ptr %pj
; CHECK: %cq.win.ne = icmp ne ptr
; CHECK-NEXT: br i1 %cq.win.ne, label %[[D:[^,]+]], label %[[AL:[^,]+]], !cq.railwindow.version
; CHECK: {{^}}[[D]]:
; CHECK-NEXT: [[RJ:%[a-z0-9.]+]] = load i32, ptr
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[RJ]], double 5.000000e-01)
; CHECK: {{^}}[[AL]]:
; CHECK-NEXT: [[RA:%[a-z0-9.]+]] = load i32, ptr [[CI]],
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[RA]], double 5.000000e-01)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1 zeroext, double) nomerge
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @f(i64 %i, ptr %pj) {
entry:
  %q = alloca [4 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %q, i8 0, i64 4, i1 false)
  %im = and i64 %i, 3
  %ga = getelementptr inbounds [4 x i8], ptr %q, i64 0, i64 %im
  %la = load i8, ptr %ga
  %ta = trunc i8 %la to i1
  %ra = call zeroext i1 @cq_theta_i1(i1 %ta, double 3.000000e-01)
  %za = zext i1 %ra to i8
  store i8 %za, ptr %ga
  %j = load i64, ptr %pj
  %jm = and i64 %j, 3
  %gb = getelementptr inbounds [4 x i8], ptr %q, i64 0, i64 %jm
  %lb = load i8, ptr %gb
  %tb = trunc i8 %lb to i1
  %rb = call zeroext i1 @cq_theta_i1(i1 %tb, double 5.000000e-01)
  %zb = zext i1 %rb to i8
  store i8 %zb, ptr %gb
  %m = load i8, ptr %q
  %tm = trunc i8 %m to i1
  %r = call zeroext i1 @cq_measure_i1(i1 %tm)
  %ri = zext i1 %r to i32
  ret i32 %ri
}
