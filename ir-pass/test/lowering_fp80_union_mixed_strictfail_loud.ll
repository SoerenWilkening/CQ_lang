; lowering_fp80_union_mixed_strictfail_loud.ll — DECLINE PIN (bd vqlq, the
; Rule-13 F2 fixture family): a STRICT (tainted-seed) candidate whose §4.1
; walk FAILS, sharing the function with a walk-clean OPPORTUNISTIC
; (argument-seeded) candidate. The opportunistic fallback must NOT mask the
; strict violation: dropping the opportunistic set and re-running still ends
; at the loud kMsgFp80Padding decline (the tainted union's `and 0x1FFFF`
; keeps padding bit 16 and the diverged word reaches cq_measure). The
; widening never shrinks the strict loud-decline surface.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @mixed(i32 %a) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %uA = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %uA, align 16
  %pA8 = getelementptr inbounds i8, ptr %uA, i64 8
  %hiA = load i64, ptr %pA8, align 8
  %badA = and i64 %hiA, 131071          ; 0x1FFFF keeps padding bit 16 — walk FAIL
  %uB = alloca { x86_fp80 }, align 16
  %sB = sitofp i32 %a to x86_fp80
  store x86_fp80 %sB, ptr %uB, align 16
  %pB8 = getelementptr inbounds i8, ptr %uB, i64 8
  %hiB = load i64, ptr %pB8, align 8
  %mB = and i64 %hiB, 32767             ; meaningful-only — walk clean
  %m = call i64 @cq_measure_sll(i64 %badA)
  %sum = add i64 %m, %mB
  ret i64 %sum
}

; CHECK: error{{.*}}cq fp80 union: padding byte observed without a mask
