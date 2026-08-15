; lowering_io_accept_literal_coarg.ll — ACCEPT (bd c4ow).
; THE THRESHOLD CONTROL: a DEFINED constant classical co-argument is still
; DROPPED, exactly as before.
;
; The bd c4ow fence narrows `isa<Constant>` by one case (`undef`/`poison`), and
; the failure mode of a careless narrowing is to refuse EVERY constant co-arg —
; which would decline the shipped 7.6 design itself, since the format-string
; pointer is a constant co-arg on every `printf` in the tree. This file is the
; measurement that says the narrowing is exactly one case wide: `i32 7` is
; dropped, `@.str` is dropped, and the ONE tainted arg becomes the ONE tape write.
;
; It is also the counter-exhibit to the ticket's "lost output field" framing.
; `printf("%d %d\n", q, 7)` and `printf("%d %d\n", q, undef)` were measured to
; lower BYTE-IDENTICALLY on the pre-change plugin — this file is the surviving
; half of that pair, and its single tape write is what "identical" meant.
;
; GREEN ON BOTH PLUGINS, deliberately: a reviewer will find it absent from the
; BASE-vs-SHIP differential and should — a control's job is to fail if the
; narrowing ever goes too far, not to witness that it happened. Its discriminating
; power is arm-kill: widen the fence to refuse EVERY constant co-arg and THIS file
; goes red.
;
; *** STOP THERE — an earlier draft added "while both decline fixtures stay green",
; and the Rule-13 round measured that FALSE. *** Under that mutation the fail set is
; 26 rows and includes BOTH c4ow decline fixtures, because the format-string pointer
; `@.str` is ARGUMENT 0 and fires `kMsgIOArg` before the undef co-arg is ever
; reached — so they redden with the WRONG message, not the c4ow one. The arm is
; still discriminating (this row is in the fail set either way); the second clause
; was simply wrong and must not come back.
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
@.str = private constant [7 x i8] c"%d %d\0A\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q, i32 7)
  ret void
}

; One lazy tape, ONE tape write (the tainted arg only — the `7` and the format
; string are dropped classical co-args), no surviving printf, no measurement:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[H]])
; CHECK-NOT: call{{.*}}@cqrt_tape_write
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_measure
