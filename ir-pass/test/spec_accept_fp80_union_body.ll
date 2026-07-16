; spec_accept_fp80_union_body.ll — ACCEPT (bd vqlq): an fp80-union RMW inside
; a Phase-6 specialized callee. The callee is int(int) — the fp80 exists ONLY
; as an internal bit-pattern intermediate (`u.e = (long double)a;
; u.bits.exp = a & 0x7fff; return (int)(u.e * 4.0L)` at -O1, lifetime markers
; and all). Two vqlq enablers compose here:
;   1. promoteFp80Union admits the ARGUMENT-derived seed (`sitofp i32 %arg ->
;      x86_fp80`) as an OPPORTUNISTIC candidate — the promotion is fence-sound
;      classically (the §4.1 walk is value-flow, taint-independent), and the
;      to-be-specialized clone re-taints the cone. The original body reaches
;      detectSpecializations in register form (no alloca/load/store left).
;   2. scanBody routes a NON-POINTER value bitcast to the width + castInScope
;      gates instead of the categorical "pointer cast" reject (Rule 14:
;      detection must MIRROR the lowerOps accept — castInScope admits exactly
;      the eight same-width fp<->int relabels incl. f80<->i80).
; The driver then clones @__cq_q_qpack_<mask>, seeds the param taint, the i80
; write surface lowers inside the clone, and the Bennett wrap reverse-plays
; the `_unc` adjoints (the szpr route (a), now buildable).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define i32 @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %y = call i32 @qpack(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

define i32 @qpack(i32 noundef %0) {
  %2 = alloca %union.IEEEl2bits, align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2)
  %3 = sitofp i32 %0 to x86_fp80
  store x86_fp80 %3, ptr %2, align 16
  %4 = getelementptr inbounds i8, ptr %2, i64 8
  %5 = load i64, ptr %4, align 8
  %6 = and i32 %0, 32767
  %7 = zext nneg i32 %6 to i64
  %8 = and i64 %5, -32768
  %9 = or disjoint i64 %8, %7
  %10 = getelementptr inbounds i8, ptr %2, i64 8
  store i64 %9, ptr %10, align 8
  %11 = load x86_fp80, ptr %2, align 16
  %12 = fmul x86_fp80 %11, 0xK40018000000000000000
  %13 = fptosi x86_fp80 %12 to i32
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2)
  ret i32 %13
}

; the caller measures the clone's copy-out; the original qpack (between the
; caller and the appended clone in the output) was promoted — no union memory
; survives; the clone carries the i80 write surface, Bennett-wrapped
; (compute -> copy-out -> reverse-play `_unc` -> frees):
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: alloca %union.IEEEl2bits
; CHECK:     define {{.*}}@__cq_q_qpack_{{[01]+}}(
; CHECK-DAG: call i32 @cq_template_sitofp_i32_to_f80(
; CHECK-DAG: call i32 @cq_template_bitcast_f80_to_i80(
; CHECK-DAG: call i32 @cq_template_or_i80(
; CHECK-DAG: call void @cqrt_copy_i32(
; CHECK-DAG: call void @cq_template_or_i80_unc(
; CHECK-DAG: call void @cq_template_bitcast_f80_to_i80_unc(
; CHECK-DAG: call void @cq_template_sitofp_i32_to_f80_unc(
