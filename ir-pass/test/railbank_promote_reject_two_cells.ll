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

; DECLINE: cq taint escape: tainted value stored to memory
