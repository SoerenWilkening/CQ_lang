; control_predmux_reject_classical_table_inloop_willtaint.ll — DECLINE (bd fn1q
; increment 4, Rule-13 round 2 R4R2-1). THE IN-LOOP HALF OF THE LAUNDERING FENCE.
;
; ⚠ IT EXISTS BECAUSE THE ROUND-1 FIX WAS STRUCTURALLY VACUOUS INSIDE A LOOP, AND
; NOTHING SAID SO. `qromShapedReadTaintsIndexAfterFlatten` reaches its answer
; through `matchQramAccess`, which returns `nullopt` UNCONDITIONALLY for any memop
; in a loop. So for every IN-LOOP load — exactly the half of E4's accept surface
; that increment 3 opened — the fence answered `false` at its first `if` and fenced
; nothing. The shipped header said it "must refuse EVERY such load"; it refused
; none of them in a loop.
;
; ⚠ AND THE PROGRAM STILL DECLINED, WHICH IS WHY NO GATE SAW IT. The closure was
; two OTHER owners — `kMsgQramLoop` and `unrollConstTripLoops`' U2b — i.e. a
; CONTINGENT closure, not the stated reason (CLAUDE.md's bd `xt20` class). The
; region was CLAIMED AND FLATTENED first, so detect-before-mutate was lost too.
; Measured before the fix: no `leave` line at all, then
; `cq QRAM access: tainted-index memory access inside a loop`.
;
; THE FIX asks the will-taint question DIRECTLY on the pointer operand via
; `valueWillTaintAfterFlatten` — the same predicate, no QROM matcher, hence no loop
; gate. Measured after: `gate=E4-gep`, refused BEFORE the claim, and the diagnostic
; moves back to the ordinary control-flow decline.
;
; THE MECHANISM THAT GETS A WILL-TAINT INDEX PAST THE BOUNDS ARM, worth knowing:
; `%r = phi i64 [ %i, %a ], [ undef, %b ]`. LLVM's `simplifyPHINode` SKIPS undef and
; folds the phi to `%i`, so SCEV sees an affine AddRec and proves bounds — while
; `indexWillTaintAfterFlatten` NORMALISES undef to zero (mirroring `convertPhis`)
; and correctly answers "will taint". The two disagree by design, and only the
; fence sees it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; ⚠ THE `DBG` LINE IS THE WHOLE POINT: it asserts the refusal happens at a GATE,
; i.e. before the claim. Without it this file would pass on the defective binary
; too, since that one also declined — just later, and for someone else's reason.
; DBG: gate=E4-gep
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
; CHECK-NOT: cq QRAM access

@c = internal constant [4 x i32] [i32 11, i32 22, i32 33, i32 44], align 16
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i64 %n) {
entry:
  br label %head
head:
  %i = phi i64 [ 0, %entry ], [ %in, %latch ]
  %Z = phi i32 [ 5, %entry ], [ %Zn, %latch ]
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 2
  br i1 %c1, label %r1, label %latch
r1:
  %c2 = icmp sgt i32 %q, 7
  br i1 %c2, label %a, label %b
a:
  br label %j
b:
  br label %j
j:
  %r = phi i64 [ %i, %a ], [ undef, %b ]
  %g = getelementptr inbounds [4 x i32], ptr @c, i64 0, i64 %r
  %v = load i32, ptr %g, align 4
  %Z1 = sub i32 %Z, %v
  br label %latch
latch:
  %Zn = phi i32 [ %Z, %head ], [ %Z1, %j ]
  %in = add nuw nsw i64 %i, 1
  %d = icmp eq i64 %in, 4
  br i1 %d, label %exit, label %head
exit:
  ret i32 %Zn
}
