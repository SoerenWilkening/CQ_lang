; railbank_promote_reject_inloop_other_read.ll — bd `xdu2` / L-1a clause C5: a
; SECOND OBSERVER OF THE OBJECT INSIDE THE WRITE LOOP.
;
; ⚠ THIS IS THE STORE-MOVE HAZARD AS A DECLINE, AND IT IS A CLASSICAL
; MISCOMPILE, WHICH IS WHY IT IS EASY TO MISS.  The promotion moves the
; activation's write to the activation's END.  The body here also reads cell 0
; through a constant offset:
;     for (i…) { if (c) b[i] = theta(b[i]); x = b[0]; }
; On trip 0 the source reads `b[0]` AFTER the store; after the move it reads it
; BEFORE.  `opt -verify` cannot see that, the value is not even quantum, and no
; rail fence in the tree looks at memory at all (`SCOPE_L1a.md` §4.1).
;
; So the clause is structural and blunt: NOTHING non-rewritable may live inside
; the write loop.  A constant-offset read, an initializer or a lifetime marker
; inside `L` refuses the bank outright rather than being reasoned about.  The
; same read OUTSIDE the loop is admitted — `railbank_promote_unrolled_reads.ll`.;
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
; ⚠ bd `test_C_libtooling-01po.19` S1-S3 (2026-10-15, owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15` and
; `owner-ruling-01po19-rolled-design-2026-10-15`): the rolled WINDOW model
; (RailWindow.h) now claims this array, because it is a well-formed quantum array
; the one-store rail bank does not own. The rail-bank clause this file used to
; decline on protects the one-store model only; the window model replaces it, and
; until S4-S7 land the array declines with the list of steps it still needs
; (DECLINE -> DECLINE; the message below is mirrored character-for-character).
; S7 (index alias versioning) LANDED 2026-10-15: the unproven pair (q[i] vs the
; constant cell) is versioned and the window lowers; the module now stops at the
; NEXT owner, the in-loop tainted accumulator `acc += cell` (F5's X1, loop
; lowering: `loop-carried tainted value crosses iterations`, the same decline as
; loop_carried_handle_reject_accumulator.ll). DECLINE -> DECLINE; the clause
; this file is about (the rail-bank promoter refusing) is still pinned by DBG/NOTS.
; RETIREMENT TRIGGER: each of S4-S7 that lands drops its name from the list; when
; the list empties this file becomes an ACCEPT with an analytic trace check.
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
  %i = phi i64 [ 0, %entry ], [ %i.next, %head ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %head ]
  %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
  %r0 = load i8, ptr %b, align 1
  %w0 = zext i8 %r0 to i32
  %acc.next = add nsw i32 %acc, %w0
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head

out:
  %m = call i32 @cq_measure_si32(i32 %acc.next)
  ret i32 %m
}

; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; The in-loop observer and the store keep their SOURCE order: store, then read.
; DBG:        store i8 %z0, ptr %g0, align 1
; DBG-NEXT:   %r0 = load i8, ptr %b, align 1

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
;
; ⚠⚠ MERGE FILING F-3, MEASURED AND RESOLVED IN THE HONEST DIRECTION (Track B,
; session 2026-09-15).  **THIS FILE NO LONGER ISOLATES ITS CLAUSE, AND THE
; CLAUSE'S SUBJECT IS STRUCTURALLY UNREACHABLE — NOT MERELY MIS-SPELLED.**
;
; The clause it is ABOUT is the promoter's B4' (NOTHING NON-REWRITABLE OBSERVES THE OBJECT INSIDE `L`).  The negative
; `promote bank` check below (in the NOTS prefix) is satisfied VACUOUSLY: the
; promoter never runs, because `planBank`'s B6 calls Track A's carve FIRST and
; the carve refuses the module before any B-clause is asked.
;
; ⚠ WHY A RE-SPELLING WAS ATTEMPTED AND ABANDONED, with the measurement:
;   The in-loop read of a DIFFERENT cell is `RejectTotality` at the carve's C6
;   in-loop-read test — MEASURED on this module — so B4' is never asked.  Track
;   A recorded the same shadowing from the other side: `SIGNATURE.md` trigger T5
;   says in writing that B4' becomes the SOLE defence, and
;   `railbank_promote_reject_inloop_hoisted_read.ll` an ISOLATING negative, only
;   once C6's in-loop-read test is widened.
;
; ⚠ SO THE FIXTURE WAS NOT PAPERED OVER WITH A HAND-IR MODULE THAT ONLY *LOOKS*
; LIKE A SUBJECT (`SCOPE_B.md` §8 forbids exactly that), AND THE B CLAUSE WAS NOT
; DELETED.  What ships is this disclosure: the file keeps pinning that the module
; is LOUDLY REFUSED and that the promoter does NOT fire on it — both true, both
; worth keeping — and it states which widening restores isolation.
;
; ⚠ L8 RETIREMENT TRIGGER — the day
;   C6's in-loop-read test is widened (SIGNATURE trigger T5's own example is
;   `if (b[i-1]) ...`).  B4' then becomes the sole defence against the store
;   move and this file becomes isolating; re-derive its DECLINE line THEN.
;
; DECLINE: cq loop lowering: loop-carried tainted value crosses iterations
