; spec_reject_ret_undef_spelling.ll — DECLINE (bd 3p2a).
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@leaf` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces
; an integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; never reaches the specializer: the call became an ordinary classical call,
; `scanBody`'s return fence was never asked, and the module ACCEPTED (the caller reads
; the call's RESULT as one runtime value, so no undef literal is duplicated).
; The ONE added line in `@leaf`, `%vsfp.read`, is a DEAD READ that keeps the
; parameter used, so this file still reaches the fence it was written for. That
; residual population — a callee that READS the argument yet returns classical — is
; IR-ONLY from C at -O1 (the library TU deletes a dead read). The `env
; CQ_DEADARG_DBG=1` + `CHECK-NOT: CQ_DEADARG_DBG` pair pins that the drop does NOT
; fire here: a widening of the drop (e.g. to dataflow liveness) retires this subject
; and must re-derive it (CLAUDE.md L8).
;
; ARM: the `undef` SPELLING, which is the one stock `clang -O1` actually emits —
; `poison` (spec_reject_ret_poison.ll) is the hand-IR canonical form.
;
; `PoisonValue` derives from `UndefValue`, so the single `isa<UndefValue>` inside
; `slotCarriesUndef` covers both and this file cannot diverge from its sibling by
; construction. It is here because the REACH argument runs through this spelling
; and a reader should be able to see the real shape: this body is verbatim what
;
;     int leaf(int a) { int x; return x; }
;
; compiles to under `clang -I<inc> -O1 -emit-llvm` (measured — `ret i32 undef`,
; no warning), and the `@example` below is the linked caller from a
; `run_slice_multi.sh` two-TU program. Single-TU the shape is unreachable (IPSCCP
; replaces the call with `undef` and deletes it); across `llvm-link` it reaches the
; clone gate, which is why this is a real accept-surface hole rather than a
; hand-written-IR curiosity.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error{{.*}}cq specialization: callee return value denotes no value (undef/poison)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 noundef %0) local_unnamed_addr {
  %vsfp.read = mul i32 %0, 3   ; bd vsfp: a DEAD READ keeps this parameter used
  ret i32 undef
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @leaf(i32 noundef %q)
  %d = add nsw i32 %s, %q
  %m = call i32 @cq_measure_si32(i32 %d)
  ret void
}
