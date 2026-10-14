; railbank_promote_reject_second_exiting_block.ll — bd `xdu2` / L-1a clause C5,
; clause B3, ISOLATED.
;
; ⚠ THIS FILE EXISTS BECAUSE THE INJECTION MATRIX SAID THE OTHER ONE DOES NOT
; PIN B3.  `railbank_promote_reject_early_exit.ll` is the HAZARD (a real `break`
; whose path would drop the activation's write), and round-2 mutation measured
; its refusal as coming from SCEV — a genuinely multi-exit loop has no constant
; EXACT backedge-taken count, so the carve's C2' refuses it two clauses before B3
; is asked.  A fixture that passes for a reason other than the one its header
; claims pins the wrong thing, so B3 needs a module where it is the SOLE refuser.
;
; This is that module: the second exiting branch is `i > 100`, which SCEV proves
; is never taken over a 3-trip `{0,+,1}`, so the exact trip count IS constant and
; the carve says `Bank`.  `Loop::getExitingBlock()` is still null — LLVM asks a
; STRUCTURAL question, not a reachability one — so B3 refuses.
;
; ⚠ AND THAT MAKES THIS FIXTURE AN OVER-DECLINE PIN, WHICH IS WHY IT IS LABELLED
; AS ONE RATHER THAN QUIETLY COUNTED AS A HAZARD.  The program is harmless: the
; second exit cannot be taken, so no write is dropped and the promotion would be
; sound.  B3 refuses it anyway because "the latch is the only exiting block" is
; the cheapest sound spelling of "every activation reaches the latch", and the
; owner's 2026-09-11 ruling makes an over-decline a DEFECT TO FILE, not a safety
; margin.  Filed with the increment's follow-ons; the widening is "every block
; holding a cell store reaches the latch within `L`", which is a reachability
; question and needs its own red-green pair.
;
; ⚠ WHY IT IS PINNED AGAINST A MODULE DUMP: the promoter is ACCEPT-ONLY, so a
; refusal leaves the module byte-identical to not having the stage at all and a
; fixture whose only check is the unchanged `kMsgStore` pins NOTHING (Rule 12
; hygiene defect (c)).
;
;
; ⚠ bd `test_C_libtooling-01po.19` S1-S3 (2026-10-15, owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15` and
; `owner-ruling-01po19-rolled-design-2026-10-15`): the rolled WINDOW model
; (RailWindow.h) now claims this array, because it is a well-formed quantum array
; the one-store rail bank does not own. The rail-bank clause this file used to
; decline on protects the one-store model only; the window model replaces it, and
; until S4-S7 land the array declines with the list of steps it still needs
; (DECLINE -> DECLINE; the message below is mirrored character-for-character).
; RETIREMENT TRIGGER: each of S4-S7 that lands drops its name from the list; when
; the list empties this file becomes an ACCEPT with an analytic trace check.
; RUN: env CQ_RAILBANK_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG       --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOTS      --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=DECLINE   --input-file=%t.dbg %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main() {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %latch ]
  %never = icmp ugt i64 %i, 100
  br i1 %never, label %out, label %body

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
; DBG:        %never = icmp ugt i64 %i, 100
; DBG:        store i8 %z0, ptr %g0, align 1

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
; DECLINE: cq rail window: quantum array not lowered yet (bd 01po.19), needs S4 borrowed-root cells
