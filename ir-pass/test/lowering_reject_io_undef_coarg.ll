; lowering_reject_io_undef_coarg.ll — DECLINE (bd c4ow).
; ARM: `collectTapeTargets`' classical-co-argument definedness fence, on the
; UNCONTROLLED emitter (`lowerIOSinks`).
;
; *** DO NOT DESCRIBE THIS AS A LOST OUTPUT FIELD. *** The ticket framed it that
; way ("the golden trace has one fewer field than the program specifies") and the
; framing is FALSE — measured on the pre-change plugin, this module and the same
; module with `i32 7` in place of `i32 undef` lower BYTE-IDENTICALLY: one
; `cqrt_tape_write_i32`, `@printf` erased, `opt` exit 0. Dropping a CLASSICAL
; co-arg is the shipped 7.6 design (only TAINTED args are taped), so a defined `7`
; is dropped too and no observable moves.
;
; WHAT IS ACTUALLY WRONG IS THE ACCEPT PREDICATE. The fence means "this co-arg is
; COMPILE-TIME KNOWN, so dropping it costs the program nothing", and it is spelled
; `isa<Constant>`. `undef`/`poison` ARE `Constant`s and they DENOTE NO VALUE —
; the one kind of `Constant` for which the fence's own justification does not
; hold. The predicate admitted exactly the input its rationale excludes; the Prime
; Directive says an unproven accept surface should not exist, and the input is UB,
; so the decline costs no capability.
;
; REACH IS PROVEN AND TRIVIAL, not hand-written-IR-only: `int y;
; printf("%d %d\n", x, y);` makes stock `clang -O1` emit
; `i32 noundef undef` in the arg list, with no warning. This fixture is that
; module's shape.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module (`opt` exit 0) and emits
; the single tape write below, so the decline is genuinely new.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq I/O output sink: classical argument is undef/poison, not a compile-time known value

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [7 x i8] c"%d %d\0A\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q, i32 undef)
  ret void
}
