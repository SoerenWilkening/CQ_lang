; lowering_io_accept_global_pad_coarg.ll — ACCEPT (bd c4ow).
; ARM: the GLOBAL-ADDRESS SKIP inside the co-argument fence's predicate. This is
; the ONLY file pinning `slotCarriesUndef` rather than `valueCarriesUndef` at this
; site, and it is the single most dangerous edit available in this area.
;
; A `GlobalValue`'s OPERANDS are its INITIALIZER, while the value sitting in the
; argument slot is the global's ADDRESS — defined no matter what the global is
; initialised to. `valueCarriesUndef` (the un-skipped predicate) recurses into
; that initializer; `slotCarriesUndef` does not, and the fence calls the latter.
;
; WHY THE DISTINCTION IS NOT ACADEMIC HERE. A `printf` argument list is DOMINATED
; by global addresses — the format string is one on literally every call — and
; `clang -O1` really emits
;
;     @v = global { i32, [12 x i8] } { i32 3, [12 x i8] undef }
;
; for a partially-initialised `union { long double f; int i; }`, the fp80-union
; idiom this project is built on. `@u` below is exactly that shape. Under
; `valueCarriesUndef` this WELL-DEFINED program declines; under `slotCarriesUndef`
; it lowers, and only the tainted arg is taped.
;
; *** THE TWO PREDICATES MUST STAY DISTINCT. *** After bd c4ow + 3p2a there are
; three `slotCarriesUndef` call sites and exactly ONE `valueCarriesUndef` caller —
; `classifyConeNode`'s cone leaf in PredMuxFlatten.cpp, where the over-decline is
; PRE-EXISTING and removing it is an accept WIDENING that was written and then
; deliberately reverted (bd ajw7, still OPEN). Do not "unify" them.
;
; ARM-KILL: point the fence at `valueCarriesUndef` and this file goes red with the
; c4ow diagnostic while `lowering_reject_io_undef_coarg.ll` stays green — the two
; together are what fix the predicate, not either alone.
;

; NOTE ON THE NEGATIVES BELOW. A `CHECK-NOT` for a cq DIAGNOSTIC would be VACUOUS
; here and is deliberately absent: this RUN line pipes only the OUTPUT FILE into
; FileCheck, and every `DiagnosticInfoUnsupported` goes to STDERR, so such a
; pattern could never match and would pin nothing. (Measured; and it is a tree-wide
; pattern — 51 of the 73 fixtures carrying such a line do not pipe stderr.) The
; accept assertion is carried by cq-opt's EXIT CODE, which an un-inverted run line
; already requires, plus the positive CHECKs. (Do not spell either directive token
; in this prose: lit and FileCheck parse them out of comments — that is what turned
; this block into a shell syntax error the first time it was written.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [7 x i8] c"%d %s\0A\00"
; The fp80-union idiom: a partially-initialised aggregate whose PADDING is undef.
@u = global { i32, [12 x i8] } { i32 3, [12 x i8] undef }

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  ; `ptr @u` is a GlobalValue ADDRESS in a classical co-arg slot — defined.
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q, ptr @u)
  ret void
}

; The address co-arg is DROPPED like any other defined constant; the tainted arg
; is taped once; nothing declines:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[H]])
; CHECK-NOT: call{{.*}}@cqrt_tape_write
; CHECK-NOT: call{{.*}}@printf
