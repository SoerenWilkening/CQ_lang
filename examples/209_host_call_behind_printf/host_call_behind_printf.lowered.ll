; HAND-WRITTEN. Rules: 16, 19, 7, 4, 2; BACKEND_ABI §1.11 (the event sequence).
; Checked: host_call_behind_printf: x (%5, measured -> %7).
; Clean: mark: the |1> predicate seed of its effect entry (%3: never written, freed directly, rule 7).
; Kept: host_call_behind_printf: x (%5: rotated, measured), its tape (%4) and the write-only tape rail of the printf
; field (%6: a copy of x, entangled with it, never freed). mark: its tape (%2). The putchar entry has no result rail
; (the program does not read the result: the bare form).
; Rotations: (Ry, x, th, 1).
; Expected: host_call_behind_printf(3, .5, 10): Ry(.5) acts on every qubit of the i32 rail x = 3, so each of its 32
; bits flips with probability s = sin^2(.25) = 0.061209 and the measured value v is 3 with probability
; (1 - s)^32 = 0.132498, 3 ^ (1 << b) with probability (1 - s)^31 s = 0.008639 for each bit b, and in general
; 3 ^ e with probability s^|e| (1 - s)^(32 - |e|). The tape rail is a copy of x, so the output of the shot is the
; decimal of that same v followed by the byte 10: "<v>\n", in this order on every shot.
; THE ORDINARY-HOST-CALL CONDITION (rule 16). printf("%d", x) has a rail field: a format entry (47), an OUTPUT call
; with a quantum field, which the backend defers to the end of the shot (BACKEND_ABI §1.11). mark(c) is called by
; name after that tape event in its only caller, so mark is a function CALLED AFTER AN EVENT, and its putchar(c),
; although every argument is classical and no quantum predicate is in scope, is NOT an ordinary host call: made as it
; stands it would write its byte before the deferred printf. It is an EFFECT ENTRY: tape_alloc, the argument as a
; _lit field, then cqrt_tape_effect_controlled under a cqrt_alloc_i1(true) seed with the host name "putchar" (the
; bare form: the result is unused). The entry is behind an unresolved event, so the backend defers it too and
; performs both at the end of the shot in sequence order: the printf, then the putchar. The lowered program asks
; nothing; it emits the same one call whatever the backend will do. The property is static (the least fixpoint over
; calls by name), so mark's body is the effect entry for every call of it; mark is internal and has one caller.
; A second clause of rule 16 gives the same answer here: host_call_behind_printf is externally visible in a module
; that contains an event, so it is itself called after an event and mark, its callee, is too (the least fixpoint),
; whatever the position of mark(c) relative to the printf. Both clauses yield this text.
; THE SEED IS FREED WHILE THE ENTRY IS DEFERRED. The backend captures an entry's predicate when the entry is opened
; (as 47 relies on for its uncomputed x > k flag), so the |1> seed is a rule-7 seed: freed directly after the effect
; call, although the putchar is performed only at the end of the shot.
; mark itself is reached with a classical argument: the call is to its OWN symbol (§1.4, the all-zero mask), fastcc
; and internal as -O1 left it; nothing is inlined (rule 19). Neither function touches the bus (no __cq_mem).
source_filename = "host_call_behind_printf.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1    ; IR: @.str
@.cq.effect.putchar = private unnamed_addr constant [8 x i8] c"putchar\00", align 1    ; IR: effect entry name for putchar (a host string): @.cq.effect.<name>, one per host callee, after the module's own globals

define i32 @host_call_behind_printf(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_tape_fmt(i32 %4, ptr @.str)    ; IR: %5 = printf(@.str, %4): the format entry (no predicate in scope; the count %5 is unused)
  %6 = call i32 @cqrt_tape_write_i32(i32 %4, i32 %5)    ; IR: %5 = printf(..., %4): field 0, the rail x copied onto a fresh tape rail (kept): the entry is deferred by the backend
  call fastcc void @mark(i32 %2)    ; IR: call fastcc void @mark(i32 %2): classical argument, the own symbol; called after the tape event above
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%4)
  ret i32 %7    ; IR: ret i32 %6
}

define internal fastcc void @mark(i32 noundef %0) {
  %2 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape, allocated once at entry as in 47 (mark records an entry: it is called after an event, so its putchar is not an ordinary host call)
  %3 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: %2 = putchar(%0): no predicate in scope, the |1> seed
  call void @cqrt_tape_write_i32_lit(i32 %2, i32 %0)    ; IR: %2 = putchar(%0): argument 0, classical: a _lit field, <W> the width token of the argument's IR type at the call (i32)
  call void @cqrt_tape_effect_controlled(i32 %3, i32 %2, ptr @.cq.effect.putchar)    ; IR: %2 = putchar(%0): the effect entry, complete after its fields; bare form, the result is unused
  call void @cqrt_free(i32 %3)    ; IR: release the seed (|1>, never written: freed directly, rule 7); the backend captured the predicate at the effect call (BACKEND_ABI §1.11), so the deferred entry does not read this rail again
  ret void    ; IR: ret void
}

declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_fmt(i32, ptr)
declare i32 @cqrt_tape_write_i32(i32, i32)
declare void @cqrt_tape_write_i32_lit(i32, i32)
declare void @cqrt_tape_effect_controlled(i32, i32, ptr)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
