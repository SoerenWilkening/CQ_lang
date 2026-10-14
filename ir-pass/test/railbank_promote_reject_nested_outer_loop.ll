; railbank_promote_reject_nested_outer_loop.ll — bd `xdu2` / L-1a: the cell walk
; RE-EXECUTED BY AN ENCLOSING LOOP.
;
; ⚠ THIS IS THE ONE FIXTURE IN TRACK B'S BATCH WHOSE REFUSAL COMES ENTIRELY FROM
; TRACK A'S CARVE, AND THE PROMOTER HAS NO CLAUSE OF ITS OWN FOR IT.  Say it
; plainly, because the next person to widen either side needs to know:
;
;   * the hazard is the PROMOTER'S.  `for (k…) for (i…) b[i] = theta(b[i], .5);`
;     writes every cell once per OUTER trip, so on the second outer trip the SEED
;     load reads a HANDLE the first outer trip stored.  The promoter would
;     forward the initializer there — replacing a live, possibly entangled rail
;     with a classical zero, a hidden `|0>` assertion that `opt -verify` cannot
;     see and that no rail fence can see either (`SCOPE_L1a.md` §4.1: the
;     rail/wire/uncompute machinery is MEMORY-BLIND by construction).
;   * the FENCE is Track A's: `Loop::getParentLoop() == nullptr` on the walk
;     loop, added by Track A's adversarial self-attack AFTER 18 green fixtures, a
;     clean 2096-row corpus sweep and a 29/29 injection matrix had all missed it
;     (`trackA/SIGNATURE.md` ADDENDUM; the self-attack probe is
;     `H1_nested_outer_rewrite.c`, MEASURED `Bank` before the conjunct).
;   * the promoter's own B-clauses do NOT cover it.  B1 refuses an access in a
;     SUB-loop; it says nothing about an ENCLOSING one.  Measured on this module:
;     with the carve's conjunct deleted, the promoter FIRES (injection matrix
;     round 2, mutant M12).
;
; It is deliberately NOT duplicated in the promoter: a second spelling of a
; predicate the tree owns is the drbq Inc-3 (b') defect, filed by name (Rule 14).
; The dependency is recorded instead, in `RailBankCarve.h` and at the promoter's
; one call site.
;
; ⚠ L8 RETIREMENT TRIGGER: the day the carve admits a non-outermost walk loop,
; the promoter needs a clause of its own or it is an OVER-ACCEPT — and the
; over-accept is a wrong unitary, not a wrong decline.  Re-derive it then; do NOT
; delete this file.
;
; ⚠ WHY IT IS PINNED AGAINST A MODULE DUMP: the promoter is ACCEPT-ONLY, so when
; it refuses the module is byte-identical to not having the stage at all and a
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
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main() {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  br label %okhead

okhead:
  %k = phi i64 [ 0, %entry ], [ %k.next, %oklatch ]
  br label %head

head:
  %i = phi i64 [ 0, %okhead ], [ %i.next, %head ]
  %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %oklatch, label %head

oklatch:
  %k.next = add nuw nsw i64 %k, 1
  %okdone = icmp eq i64 %k.next, 2
  br i1 %okdone, label %out, label %okhead

out:
  %r = load i8, ptr %b, align 1
  %c = trunc nuw i8 %r to i1
  %m = call zeroext i1 @cq_measure_i1(i1 %c)
  %e = zext i1 %m to i32
  ret i32 %e
}

; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; The seed load and the write stay exactly where the source put them.
; DBG:        %s0 = load i8, ptr %g0, align 1
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
