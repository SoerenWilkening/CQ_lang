; lowering_fp80_union_reload_chain_drop.ll — SILENT-DROP PIN (bd vqlq, the
; Rule-13 F2 fixture family, the adversarial chain case): candidate A is
; classified STRICT only because its seed rides candidate B's fp80 RELOAD
; (the candidate-reload rule); B is OPPORTUNISTIC (argument-seeded) and
; walk-FAILING (its raw straddle word reaches the return). The fallback drops
; B; the strict-only re-run must then drop A too — its seed cone lost B's
; reloads (the monotonicity argument: drop-then-rerun equals
; strict-from-scratch, where B was never a candidate and A's seed was always
; inadmissible). NOTHING promotes, nothing diagnoses, the module compiles
; with both unions in memory (all classical — no taint escape).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

define i64 @punion(i32 %a) {
entry:
  %uB = alloca { x86_fp80 }, align 16
  %sB = sitofp i32 %a to x86_fp80
  store x86_fp80 %sB, ptr %uB, align 16
  %rB = load x86_fp80, ptr %uB, align 16   ; candidate reload of B
  %uA = alloca { x86_fp80 }, align 16
  %sA = fadd x86_fp80 %rB, 0xK3FFF8000000000000000
  store x86_fp80 %sA, ptr %uA, align 16    ; A's seed rides B's reload
  %pA8 = getelementptr inbounds i8, ptr %uA, i64 8
  %hiA = load i64, ptr %pA8, align 8
  %mA = and i64 %hiA, 32767                ; clean use of A
  %pB8 = getelementptr inbounds i8, ptr %uB, i64 8
  %hiB = load i64, ptr %pB8, align 8       ; RAW straddle word of B
  %sum = add i64 %mA, %hiB                 ; B's diverged bits reach ret — walk FAIL
  ret i64 %sum
}

; the anchor lowers; both unions stay byte-untouched in memory (the CHECK-NOT
; covers the promotion's bitcast relabel from @punion onward):
; CHECK:     call double @cqrt_measure_f64(
; CHECK:     define i64 @punion(
; CHECK:     alloca { x86_fp80 }
; CHECK:     alloca { x86_fp80 }
; CHECK-NOT: bitcast x86_fp80
