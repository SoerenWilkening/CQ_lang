; lowering_reject_qram_frozen_adjoint_reads_borrowed_array.ll — DECLINE (bd
; test_C_libtooling-eqti; the PRE-EXISTING instance in bd 01po.4's QRAM-array
; frontier retry, which rests on the same premise). The `clang -O1` IR of
;     int arr[8] = {0}; bool b = u0; cq_theta(&b, .5); arr[b] = k;
;     bool p = u1; cq_theta(&p, .5);
;     int w = arr[p] + 1; cq_theta(&w, .5); printf("%d\n", w);
;     cq_theta(&b, -.5); return cq_measure(b);
;
; MEASURED on the pre-ptue binary (cq-opt sha256 50a6f549, main 8e9f3382): `opt`
; exit 0 (one M-A warning), stage 2b clean, stream
;     v = qram_load(arr, zext(p)); addc(v, 1); ry(v, .5); tape_write(T, v);
;     ry(v, -.5); addc(v, -1); qram_load_unc(v, arr, zext(p))   [v never freed]
;     ry(p, -.5); ry(b, -.5); measure(b)
; The measured `b` sits behind the array's store, so the dead-terminal DAG is
; measured upstream and the 01po.4 retry borrows the ARRAY. `v` is recorded (the
; tape) and carries an Ry, so step 3b freezes it — and its adjoint
; `qram_load_unc(v, arr, ·)` is controlled by the borrowed array's cells, which
; are entangled with `b` (cell b holds k). After the record `v` holds a definite
; |w> per branch; the frozen adjoints act on it as XOR c(b,p), so the b=0 / b=1
; branches' overlap is no longer 1, and the `ry(b, -.5)` AFTER the reversal reads
; the changed coherence: a wrong distribution for `b`. The source leaves `v` alone.
;
; The kept-rail adjoint fence (`keptRailAdjointReadsBorrowed`) applies to the
; WHOLE retry, array borrows included, so this module now keeps the decline
; verbatim. lowering_qram_store_measured_index_nonmain.ll is the discrimination:
; its frozen rail (`p`) is reverse-played by a LOCAL `ry(p, -.5)` that reads no
; borrowed register, and it still lowers.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @printf(ptr, ...)

define i32 @slice(i1 zeroext %0, i1 zeroext %1, i32 %2) {
  %4 = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %4, i8 0, i64 32, i1 false)
  %5 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %0, double 5.000000e-01)
  %6 = zext i1 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %6
  store i32 %2, ptr %7, align 4
  %8 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %1, double 5.000000e-01)
  %9 = zext i1 %8 to i64
  %10 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %9
  %11 = load i32, ptr %10, align 4
  %12 = add nsw i32 %11, 1
  %13 = tail call i32 @cq_theta_si32(i32 %12, double 5.000000e-01)
  %14 = tail call i32 (ptr, ...) @printf(ptr @.str, i32 %13)
  %15 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %5, double -5.000000e-01)
  %16 = tail call zeroext i1 @cq_measure_i1(i1 zeroext %15)
  %17 = zext i1 %16 to i32
  ret i32 %17
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
