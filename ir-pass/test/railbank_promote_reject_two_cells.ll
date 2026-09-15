; railbank_promote_reject_two_cells.ll — bd `xdu2` / L-1a clause C5, clause B2:
; TWO CELLS IN ONE ACTIVATION.
;
; ⚠ THE CLAUSE THAT PROTECTS THE SEED, AND THE ONE WHOSE ABSENCE WOULD BE A
; SILENT MISCOMPILE.  The activation stores `b[i]` but READS `b[2-i]`, so what
; the promoter would forward the initializer to is not this activation's cell at
; all — at trip 2 `b[2-i]` is `b[0]`, which trip 0 already wrote.  Replacing that
; read with a classical zero is a hidden `|0>` assertion on an entangled rail,
; and it is invisible to every fence in the tree: `SCOPE_L1a.md` §4.1 measures
; the rail/wire/uncompute machinery as MEMORY-BLIND by construction (zero
; `StoreInst`/`LoadInst`/`AllocaInst` tokens across eleven files).
;
; B2 asks the question with SCEV EQUALITY over the access addresses, which is
; strictly stronger than comparing gep operands (it also catches `b[i]` written
; as `b[i+1-1]`).
;
; ⚠ THE SPELLING IS `b[2-i]` AND NOT THE OBVIOUS `b[i+1]`, AND THAT IS A
; MEASURED CHOICE, NOT A STYLISTIC ONE.  With `b[i+1]` the STORE's index is
; `{1,+,1}`, so Track A's carve refuses it at C2' (start != 0) and this fixture
; would go green for a reason that has nothing to do with B2 — the injection
; matrix measured exactly that as a MISSED mutation before the fixture was
; rewritten.  Here the store's index is `{0,+,1}` and the carve says `Bank`, so
; B2 is the ONLY clause refusing and deleting it turns this file red.;
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

define i32 @main() {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %head ]
  %rv = sub nuw nsw i64 2, %i
  %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %rv
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  %g1 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  store i8 %z0, ptr %g1, align 1
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
; Both addresses survive, untouched — the stage never modelled this activation.
; DBG:        %rv = sub nuw nsw i64 2, %i
; DBG:        %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %rv
; DBG:        %g1 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
; DBG:        store i8 %z0, ptr %g1, align 1

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
; The clause it is ABOUT is the promoter's B2 (ONE CELL PER ACTIVATION).  The negative
; `promote bank` check below (in the NOTS prefix) is satisfied VACUOUSLY: the
; promoter never runs, because `planBank`'s B6 calls Track A's carve FIRST and
; the carve refuses the module before any B-clause is asked.
;
; ⚠ WHY A RE-SPELLING WAS ATTEMPTED AND ABANDONED, with the measurement:
;   Two distinct in-`L` cell addresses cannot reach B2, because the CARVE gets
;   there first, three ways and all measured:
;     * a second address with a LOAD  -> C6's in-loop-read test requires
;       `SE.getSCEV(LIdx) == IdxS`, so any other cell is `RejectTotality`
;       (`cq rail bank: array has cells no iteration writes`) — MEASURED both on
;       this module (`b[2-i]`) and on a purpose-built `b[i+1]` probe;
;     * a second address with a STORE -> C4's `Stores.size() != 1` is
;       `RejectAlias`;
;     * a second address with NO user -> `planBank`'s own
;       `if (!G || G->use_empty()) return false;` refuses it ABOVE B2.
;
; ⚠ SO THE FIXTURE WAS NOT PAPERED OVER WITH A HAND-IR MODULE THAT ONLY *LOOKS*
; LIKE A SUBJECT (`SCOPE_B.md` §8 forbids exactly that), AND THE B CLAUSE WAS NOT
; DELETED.  What ships is this disclosure: the file keeps pinning that the module
; is LOUDLY REFUSED and that the promoter does NOT fire on it — both true, both
; worth keeping — and it states which widening restores isolation.
;
; ⚠ L8 RETIREMENT TRIGGER — the day
;   C6's in-loop-read test is widened to admit a read of a cell OTHER than the
;   one this trip writes (Track A's SIGNATURE trigger T5 names exactly this
;   widening for B4'). B2 then becomes reachable and this file becomes an
;   ISOLATING negative again; re-derive its DECLINE line THEN.
;
; DECLINE: cq rail bank: array has cells no iteration writes
