; lowering_reject_taint_escape_return_straightline.ll — DECLINE: a tainted value
; of NON-i32 width returned straight-line (test_C_libtooling-udw, member 1/3).
;
; Every lowering path RAUWs an iN-typed tainted SSA value to an ALWAYS-i32 runtime
; handle (`cqrt_alloc_*` returns i32; RotationLowering.cpp §1) and relies on
; LAUNDERING-BY-ERASURE: the type mismatch is transient because every tainted user
; is itself lowered and erased. A `ret` user is NEVER erased. So `ret i64 %q`
; leaves `ret i64 <i32 handle>` in the final IR and the verifier aborts with
; report_fatal_error("Broken module found") + bug-report banner — loud and
; unconsumable, but NOT the Rule-1 source-located DiagnosticInfoUnsupported decline.
;
; The fix declines this escape pre-RAUW (declineTaintEscapes): a `ret` of a tainted
; value at a width other than i32 cannot be laundered — the same move as
; ArmClassify::taintedAngleGate ("declining here turns the later broken-module abort
; into a clean, source-located decline"). i32-width tainted rets stay accepted
; (FreePoint Escaped; pinned lowering_uncompute_escape_return.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)

define i64 @slice(i64 %x) {
entry:
  %q = call i64 @cq_theta_sll(i64 %x, double 2.500000e-01)
  ret i64 %q                                       ; non-i32 escape — cannot launder
}

; CHECK: error{{.*}}cq taint escape: tainted value returned at non-i32 width
