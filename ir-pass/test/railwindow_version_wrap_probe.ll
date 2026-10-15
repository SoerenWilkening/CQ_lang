; railwindow_version_wrap_probe.ll — ADVERSARIAL distinctness probe (bd `test_C_libtooling-01po.19` S7).
;
; Two hand-built twins. In @wrap an i8 counter k runs 0..255 (256 trips; the
; latch's k+1 wraps to 0 and exits) and the cell index is zext(k + 1) with a
; PLAIN i8 add: on the last trip k + 1 wraps to 0 and names q[0], the other
; cell of the window. The proof MUST fail and the window MUST be versioned
; (the aliased copy keeps the constant q[0]). In @nowrap the counter stops at
; 255 trips (k = 0..254): k + 1 is 1..255, never 0, and SCEV may prove the
; pair distinct from the trip count: no versioning.
; A proof that ignored the i8 wrap (or took a vacuous trip bound for a real
; one, bd memory `scev-vacuous-trip-bounds`) would leave @wrap unversioned and
; promote q[0] across the store to q[zext(k+1)] on its last trip: a
; verify-clean silent miscompile.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; WIN: CQ_RAILWINDOW_DBG: @wrap claims
; WIN-NEXT: CQ_RAILWINDOW_DBG: version region %H on ((zext i8 {1,+,1}<nw><%H> to i64) + %q.rails) != %q.rails
; WIN-NOT: CQ_RAILWINDOW_DBG: version region
; WIN: CQ_RAILWINDOW_DBG: @nowrap claims
; WIN-NOT: CQ_RAILWINDOW_DBG: version region

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1 zeroext, double) nomerge
define i32 @wrap() {
entry:
  %q = alloca [256 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %q, i8 0, i64 256, i1 false)
  br label %H
H:
  %k = phi i8 [ 0, %entry ], [ %k1, %H ]
  %a = add i8 %k, 1
  %ai = zext i8 %a to i64
  %ga = getelementptr inbounds [256 x i8], ptr %q, i64 0, i64 %ai
  %la = load i8, ptr %ga
  %ta = trunc i8 %la to i1
  %ra = call zeroext i1 @cq_theta_i1(i1 %ta, double 3.000000e-01)
  %za = zext i1 %ra to i8
  store i8 %za, ptr %ga
  %lb = load i8, ptr %q
  %tb = trunc i8 %lb to i1
  %rb = call zeroext i1 @cq_theta_i1(i1 %tb, double 5.000000e-01)
  %zb = zext i1 %rb to i8
  store i8 %zb, ptr %q
  %k1 = add i8 %k, 1
  %done = icmp eq i8 %k1, 0
  br i1 %done, label %X, label %H
X:
  %m = load i8, ptr %q
  %tm = trunc i8 %m to i1
  %r = call zeroext i1 @cq_measure_i1(i1 %tm)
  %ri = zext i1 %r to i32
  ret i32 %ri
}
define i32 @nowrap() {
entry:
  %q = alloca [256 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %q, i8 0, i64 256, i1 false)
  br label %H
H:
  %k = phi i8 [ 0, %entry ], [ %k1, %H ]
  %a = add i8 %k, 1
  %ai = zext i8 %a to i64
  %ga = getelementptr inbounds [256 x i8], ptr %q, i64 0, i64 %ai
  %la = load i8, ptr %ga
  %ta = trunc i8 %la to i1
  %ra = call zeroext i1 @cq_theta_i1(i1 %ta, double 3.000000e-01)
  %za = zext i1 %ra to i8
  store i8 %za, ptr %ga
  %lb = load i8, ptr %q
  %tb = trunc i8 %lb to i1
  %rb = call zeroext i1 @cq_theta_i1(i1 %tb, double 5.000000e-01)
  %zb = zext i1 %rb to i8
  store i8 %zb, ptr %q
  %k1 = add i8 %k, 1
  %done = icmp eq i8 %k1, 255
  br i1 %done, label %X, label %H
X:
  %m = load i8, ptr %q
  %tm = trunc i8 %m to i1
  %r = call zeroext i1 @cq_measure_i1(i1 %tm)
  %ri = zext i1 %r to i32
  ret i32 %ri
}
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
