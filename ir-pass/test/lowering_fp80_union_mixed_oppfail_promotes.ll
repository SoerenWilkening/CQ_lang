; lowering_fp80_union_mixed_oppfail_promotes.ll — ACCEPT (bd vqlq, the
; Rule-13 F2 fixture family): a walk-clean STRICT (tainted-seed) candidate
; sharing the function with a walk-FAILING OPPORTUNISTIC (argument-seeded)
; one — the raw straddle word of the argument-seeded union reaches the
; return. The fallback must drop ONLY the opportunistic candidate, re-run
; the strict-only fixpoint + walk, and still PROMOTE the strict union: the
; tainted extraction lowers to the i80 template stream while the opportunistic
; union is left byte-untouched in memory (an untainted store is no escape).
; Partial progress, no diagnostic — the fallback is per-class, not
; all-or-nothing.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @mixed2(i32 %a) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %uA = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %uA, align 16
  %pA8 = getelementptr inbounds i8, ptr %uA, i64 8
  %hiA = load i64, ptr %pA8, align 8
  %mA = and i64 %hiA, 32767             ; meaningful-only — walk clean (strict)
  %uB = alloca { x86_fp80 }, align 16
  %sB = sitofp i32 %a to x86_fp80
  store x86_fp80 %sB, ptr %uB, align 16
  %pB8 = getelementptr inbounds i8, ptr %uB, i64 8
  %hiB = load i64, ptr %pB8, align 8    ; RAW straddle word — walk FAIL at B
  %m = call i64 @cq_measure_sll(i64 %mA)
  %sum = add i64 %m, %hiB               ; diverged bits reach ret (classical)
  ret i64 %sum
}

; the strict union promotes + lowers; the opportunistic one stays in memory:
; CHECK:     call i32 @cq_template_bitcast_f80_to_i80(
; CHECK:     alloca { x86_fp80 }
; CHECK:     call i64 @cqrt_measure_i64(
