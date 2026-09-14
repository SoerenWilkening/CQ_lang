; lowering_reject_undef_theta_seed_with_undef_angle.ll — DECLINE.
; ARM: `normalizeUndefRotationSeed`'s ARG-1 CONJUNCT (bd z9t1, review round 1
; finding F-U1-1) — THE REWRITE MUST NOT DISARM `declineUnpairedUndefLiterals`.
;
; *** THIS FIXTURE EXISTS BECAUSE AN ADVERSARIAL REVIEW FOUND AN OVER-ACCEPT
; THAT A FULLY GREEN SUITE DID NOT. *** The z9t1 rule was recorded as leaving
; arg-1 (the ANGLE) "unchanged, pinned", which is true of arg-1 IN ISOLATION and
; was FALSE for this composition:
;
;     double d; d = cq_theta(d, d);          /* review probe r14 */
;
; At CQ type `double` the SEED and the ANGLE share the LLVM type, and `undef` is
; UNIQUED PER TYPE, so ONE `double undef` object filled BOTH emitted gate slots —
; `cqrt_alloc_f64(double undef)` and `cqrt_ry_f64(i32 %h, double undef)` — and
; GUARD 1's per-function threshold of TWO fired. Normalizing the seed drops the
; count 2 -> 1 and the guard goes SILENT. Measured on both binaries 2026-09-14:
; ORACLE (f7b65d8c) exit 1, 246 B; SUBJECT-BEFORE-FIX (a5773be1) exit 0, stderr
; ZERO bytes, emitting `call void @cqrt_ry_f64(i32 %h, double undef)` — which,
; linked and run, printed the garbage angle `0x1.100000002p-1038`. A rewrite that
; deletes one of the two slots a guard is counting is a rewrite that DISARMS the
; guard; that is the one direction this rule may not move in (Prime Directive).
;
; RED-GREEN: measured ACCEPT (`opt` exit 0, 0 bytes of stderr) on the
; pre-fix plugin `a5773be142835fb8`, which is the whole finding.
;
; ⚠ WHAT THIS FIXTURE DOES **NOT** SAY, so it is not quoted wider than it is:
; it does NOT say "an undef ANGLE declines". A DEFINED seed with an undef angle
; still ACCEPTS, identically on both binaries — that is the deliberately BLESSED
; one-slot case (`lowering_accept_undef_literal_single_slot.ll`, the threshold of
; TWO, and the committed `slice_libm_ld80_nexttoward` golden that rests on it),
; and this change leaves it exactly as it found it. Whether a lone undef angle
; should decline at all is an OWNER question about that blessed ruling, filed
; separately. The conjunct fires only where BOTH slots are undef-bearing, i.e.
; only on modules the ORACLE already declined.
;
; RETIREMENT TRIGGER: if the owner ever rules that a lone `undef` rotation angle
; declines in its own right, this file's subject becomes unreachable through this
; conjunct — the module would then decline one fence earlier, on the angle alone.
; Re-derive the string and the firing site at that point; do NOT delete the file
; before checking which fence answers, because a decline fixture that goes green
; because its subject no longer exists pins NOTHING (Rule 12 hygiene (c)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison literal reaches two emitted gate operands

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

; `clang -Iinclude -include CQ.h -O1` on the C above emits exactly this call:
;   %1 = tail call double @cq_theta_f64(double noundef undef, double noundef undef)
define double @example() {
entry:
  %q = call double @cq_theta_f64(double undef, double undef)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}
