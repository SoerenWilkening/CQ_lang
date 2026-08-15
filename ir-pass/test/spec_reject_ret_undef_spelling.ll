; spec_reject_ret_undef_spelling.ll — DECLINE (bd 3p2a).
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee return value denotes no value (undef/poison)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 noundef %0) local_unnamed_addr {
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
