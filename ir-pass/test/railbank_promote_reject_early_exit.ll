; railbank_promote_reject_early_exit.ll — bd `xdu2` / L-1a clause C5, clause B3:
; a loop with an EARLY EXIT.
;
; ⚠ THE CLAUSE THAT PROTECTS THE STORE MOVE.  The promotion places the
; activation's write at the LATCH.  If a path can leave the loop without reaching
; the latch, that path's write is DROPPED — and with a read of the bank after the
; loop (the measure loop the whole design exists to feed) the dropped write is
; OBSERVABLE.  So the loop must have exactly one exiting block and it must be the
; latch.
;
; Here `head` is a second exiting block (the `break`), so the stage refuses.;
; ⚠ WHY THIS REFUSAL IS PINNED AGAINST A MODULE DUMP AND NOT AGAINST THE DECLINE
; STRING.  The promoter is ACCEPT-ONLY: when it refuses, the module is
; BYTE-IDENTICAL to not having the stage at all, so a fixture whose only check is
; the unchanged `kMsgStore` pins NOTHING — that is Rule 12 hygiene defect (c),
; "a decline fixture that goes green because its subject no longer exists".  So
; the `CQ_RAILBANK_DBG` MODULE DUMP is the anchor: the `DBG` prefix proves the
; stage RAN and saw this module, the `NOTS` prefix proves it did not promote and
; that none of the promoted shape's landmarks (`%cq.bank`, `%cq.bank.addr`,
; `!cq.railbank`) exists, and the decline is pinned by the `not` on the RUN line.
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

define i32 @main(i32 %n) {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %latch ]
  %brk = icmp eq i32 %n, 7
  br i1 %brk, label %out, label %body

body:
  %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
  br label %latch

latch:
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head

out:
  %r = load i8, ptr %b, align 1
  %c = trunc nuw i8 %r to i1
  %m = call zeroext i1 @cq_measure_i1(i1 %c)
  %e = zext i1 %m to i32
  ret i32 %e
}

; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; The write stays where the source put it — in the body, not at the latch.
; DBG:      body:
; DBG:        store i8 %z0, ptr %g0, align 1
; DBG:      latch:
; DBG-NEXT:   %i.next = add nuw nsw i64 %i, 1

; NOTS-NOT: CQ_RAILBANK_DBG: promote bank
; NOTS-NOT: %cq.bank
; ⚠ `!cq.railbank` is NOT checked here and that is deliberate: this stage
; refuses this module, so a re-added metadata mint could never fire on it and
; the negative would be VACUOUS (Rule 12 hygiene defect (b), the shape the
; 2026-09-14 session measured as `checked 0`).  It is checked on the ACCEPT
; fixtures instead, where the promoter actually runs.

; ⚠ THE `DECLINE` STRING BELOW WAS CHANGED AT THE 2026-09-14c MERGE GATE, AND THE
; CHANGE IS A COMPOSITION FACT RATHER THAN A CORRECTION.  This fixture was
; written on a branch where Track A's rail-bank CARVE CLASSIFIER did not exist,
; so every module here declined with the generic `cq taint escape: tainted value
; stored to memory`.  With Track A merged, `declineTaintEscapes` consults
; `railBankCarveVerdict` FIRST and this shape now takes Track A's PER-CLAUSE
; rail-bank string.  Measured at the gate, ORACLE vs merged: exit 1 on both, a
; DECLINE->DECLINE string move, never DECLINE->ACCEPT.  ⚠ The clause this file is
; ABOUT is the PROMOTER's, and it is pinned by the `DBG` + `NOTS` prefixes (the
; stage ran, and did not promote) — NOT by this line, which only pins that the
; module is still loudly refused.  RETIREMENT TRIGGER: when the deferred half of
; W1 (the taint rule + type rewrite + the D5 allow-list) lands and a `Bank`
; verdict stops falling through to a decline, this line changes again — and at
; that point re-derive it, do not delete the check.
; DECLINE: cq rail bank: cell index is not an injective per-iteration index
