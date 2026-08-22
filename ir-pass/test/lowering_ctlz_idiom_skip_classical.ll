; lowering_ctlz_idiom_skip_classical.ll — SKIP, NO DIAGNOSTIC (bd ww4c Inc 1, the
; Z8 probe). A textbook instance of the idiom that is entirely CLASSICAL, in a
; module that DOES lower (a separate tainted lineage keeps the pass off its
; byte-identical passthrough path, so this fixture proves a skip and not a no-op).
;
; Z8 requires the shift recurrence's preheader incoming to be TAINTED, mirroring
; LoopUnrollPrepass's U7: a purely classical loop is not ours to churn. It is the
; cheapest clause to get wrong — the recognizer is a pure structural matcher, and
; structure alone does not distinguish openlibm's exponent scan from any other
; program's bit twiddling.
;
; *** BUT DO NOT CALL Z8 "the clause that keeps every existing ctest entry
; byte-stable", which is what this header used to say. bd ww4c.4 measured that a
; misattribution: across every module the pass can see — 1093 ir-pass fixtures,
; 245 CQ.h e2e sources, 19 classical lib TUs — the recognizer emits ZERO claims,
; and Z8 declines EXACTLY ONE loop in the entire tree: THIS ONE, which this
; branch itself added. Byte-stability is delivered 100% by the structural fence
; Z1-Z7/Z9 (nothing pre-existing has this shape at all) and 0% by Z8.
; That is not an argument for deleting Z8 — it is the opposite. This fixture is
; the ONLY thing standing between Z8 and being silently unexercised, and whoever
; widens Z3/Z6/Z9 per PRD §5.2 is the first person for whom Z8 actually carries
; load. It has to still be here, and still green, when they arrive. ***
;
; Note what makes this fixture different from every other negative here: it
; asserts NO DIAGNOSTIC AT ALL. The recognizer is accept-only and never speaks;
; a classical loop has no tainted exit either, so Q1 does not speak, and `opt`
; must exit ZERO with the loop intact. The RUN line therefore has no `not`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The tainted lineage lowered, so the pass really ran...
; CHECK: call i32 @cqrt_alloc_i32(i32 %u)
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; ...and the classical loop is untouched: both phis, the shl, the add, the icmp
; and the back edge all survive verbatim.
; CHECK-LABEL: @classical_scan(
; CHECK: phi i32 [ -1022, %entry ], [ %dec, %loop ]
; CHECK: phi i32 [ %v, %entry ], [ %sh, %loop ]
; CHECK: %dec = add nsw i32 %ix, -1
; CHECK: %sh = shl nuw i32 %x, 1
; CHECK: %pos = icmp sgt i32 %sh, 0
; CHECK: br i1 %pos, label %loop, label %exit
; CHECK-NOT: @cq_template_ctlz

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; The tainted lineage — nothing to do with the loop; it exists so the module is
; not a passthrough and the skip below is a real skip.
define i32 @tainted_neighbour(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; The classical idiom — byte-identical on the way out.
define i32 @classical_scan(i32 %v) {
entry:
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %v, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  ret i32 %dec
}
