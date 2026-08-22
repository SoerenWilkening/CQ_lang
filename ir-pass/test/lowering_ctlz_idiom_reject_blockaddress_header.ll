; lowering_ctlz_idiom_reject_blockaddress_header.ll — DECLINE (bd ww4c.4, the
; `hasAddressTaken` probe). The accepted shape with ONE addition: a module-level
; `blockaddress` naming the loop HEADER.
;
; WHY IT NEEDED A FIXTURE. `CtlzIdiomPrepass.cpp`'s comment argues that Z2
; "already covers the real hazard" — an `indirectbr` into the header is an extra
; predecessor, so the phis would carry a third incoming and decline. That
; argument is CORRECT about the indirectbr edge, and it is exactly why this
; predicate is easy to mistake for testable-by-proxy. It is not: THIS module has
; no `indirectbr` at all, so the header keeps exactly two predecessors, Z2 passes
; cleanly, and `H->hasAddressTaken()` is the SOLE gate. Measured by delta pair —
; delete the `@ba` global and nothing else, and the pass claims the loop.
;
; Before this fixture, no `lowering_ctlz_idiom_*.ll` contained the string
; `blockaddress` anywhere, so a change that dropped the predicate would have kept
; the whole matrix green.
;
; The hazard the predicate guards is real and this project has already paid for
; it once: `LiteralIntegrity.cpp` exists partly because `~BasicBlock()` RAUWs a
; live `BlockAddress` to `inttoptr (i32 1 to ptr)` MODULE-WIDE on a well-defined
; source. This pass erases no block (§4.6), so it does not reach that site today
; — the predicate is the belt to that braces, and declining costs nothing.
;
; RUN: not env CQ_CTLZ_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: CQ_CTLZ_DBG: claiming shift-count loop
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; The one line that matters. No `indirectbr` uses it, so the header's predecessor
; set is untouched and Z2 passes — leaving `hasAddressTaken` alone on the gate.
@ba = global ptr blockaddress(@blockaddress_header, %loop)

define i32 @blockaddress_header(i32 %u) {
entry:
  %hx = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %hx, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
