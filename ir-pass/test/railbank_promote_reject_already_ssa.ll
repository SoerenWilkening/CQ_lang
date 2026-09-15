; railbank_promote_reject_already_ssa.ll — bd `xdu2` / L-1a clause C5, clause B8:
; the module that is ALREADY in the post-promotion shape.
;
; ⚠ THIS IS THE `-O1` TARGET SHAPE AS A PIN, AND THAT IS ITS MAIN JOB.  The body
; below is what `clang -O1` emits for `trackL/probes/L1_promoted_store.c` — the
; scalar source whose loop body is exactly what the promotion must produce:
; exactly ONE store per trip, of the merge value, at the trip's end, with no
; intra-activation load at all.  Pinning it here means a `clang` bump that moves
; the target shape shows up as a RED here rather than as a silently diverging
; promoter.
;
; The stage refuses it (B8: no load inside the write loop) and leaves it
; BYTE-UNTOUCHED.  There is nothing to forward, the existing store already IS the
; activation's write, and firing would only churn the IR.;
; ⚠ WHY THIS REFUSAL IS PINNED AGAINST A MODULE DUMP AND NOT AGAINST THE DECLINE
; STRING.  The promoter is ACCEPT-ONLY: when it refuses, the module is
; BYTE-IDENTICAL to not having the stage at all, so a fixture whose only check is
; the unchanged `kMsgStore` pins NOTHING — that is Rule 12 hygiene defect (c),
; "a decline fixture that goes green because its subject no longer exists".  So
; the `CQ_RAILBANK_DBG` MODULE DUMP is the anchor: the `DBG` prefix proves the
; stage RAN and saw this module, the `NOTS` prefix proves it did not promote and
; that none of the promoted shape's landmarks (`%cq.bank`, `%cq.bank.addr`,
; `!cq.railbank`) exists, and the decline is pinned by the `not` on the RUN line.
;
; ⚠⚠ THE L8 RETIREMENT TRIGGER BELOW HAS FIRED — bd `xdu2` W1's SECOND HALF
; landed 2026-09-15 and this file was RE-DERIVED, not deleted, in the same
; change.  TWO things moved and both are recorded here rather than absorbed:
;
;   (1) THE PROMOTED SHAPE.  W1 piece 2 SINKS the `_Bool` cell's storage cast
;       out of the region arm: the merge phi is now built at the RAIL type
;       (`%cq.bank1 = phi i1`) and the `zext i1 -> i8` sits immediately in front
;       of the activation-end store (`%cq.bank.stg`).  With the cast IN the arm
;       the arm classified as a VALUE arm and the module declined `value-arm
;       swap-route under quantum control` anchored at the `zext` itself; with
;       the phi rail-typed it gets past that.  The PUN FENCE
;       (`StoreVal->getType() != CellTy`) is untouched — the store still stores
;       `i8` — which is why the cast is SUNK and not deleted.
;
;   (2) THE DECLINE.  The bank store no longer declines; the REGION does —
;       `cq controlled lowering: control flow inside a loop body under quantum
;       control`, `iterationLocalRollable`'s conjunct (c3), bd `8h7d.11`.  That
;       conjunct is BANK-INDEPENDENT (the same loop with a scalar `bool` and no
;       array declines identically), so W1 neither caused it nor can move it.
;       Owner ruling E5 in one line: *the bank compiles; the owner's cascade
;       needs (c3) + W3.*
;
; ⚠ NEXT L8 RETIREMENT TRIGGER: the day bd `8h7d.11` lands, this decline moves
; again, to `cq loop lowering: loop-carried tainted value crosses iterations`
; (X1 / bd `ej5w` / W3).  Re-derive it then; do NOT delete it.
; RUN: env CQ_RAILBANK_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG       --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOTS      --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=DECLINE   --input-file=%t.dbg %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @sink(ptr)

define i32 @main() {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %latch ]
  %a = phi i32 [ 5, %entry ], [ %a.next, %latch ]
  %c = icmp sgt i32 %a, 2
  br i1 %c, label %arm, label %latch

arm:
  %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %latch

latch:
  %m = phi i1 [ %q, %arm ], [ false, %head ]
  %sub = add nsw i32 %a, -3
  %a.next = select i1 %m, i32 %sub, i32 %a
  %addr = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %zz = zext i1 %m to i8
  store i8 %zz, ptr %addr, align 1
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head

out:
  %mm = call i32 @cq_measure_si32(i32 %a.next)
  ret i32 %mm
}

; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; The target shape, verbatim and unmoved: the merge phi, the select on it, one
; address and one store at the trip's end.
; DBG:      latch:
; DBG-NEXT:   %m = phi i1 [ %q, %arm ], [ false, %head ]
; DBG-NEXT:   %sub = add nsw i32 %a, -3
; DBG-NEXT:   %a.next = select i1 %m, i32 %sub, i32 %a
; DBG-NEXT:   %addr = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
; DBG-NEXT:   %zz = zext i1 %m to i8
; DBG-NEXT:   store i8 %zz, ptr %addr, align 1

; NOTS-NOT: CQ_RAILBANK_DBG: promote bank
; NOTS-NOT: %cq.bank
; ⚠ `!cq.railbank` is NOT checked here and that is deliberate: this stage
; refuses this module, so a re-added metadata mint could never fire on it and
; the negative would be VACUOUS (Rule 12 hygiene defect (b), the shape the
; 2026-09-14 session measured as `checked 0`).  It is checked on the ACCEPT
; fixtures instead, where the promoter actually runs.

; DECLINE: cq controlled lowering: control flow inside a loop body under quantum control
