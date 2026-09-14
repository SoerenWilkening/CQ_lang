; railbank_promote_reject_noninjective_index.ll — bd `xdu2` / L-1a clause C5 /
; carve clause C2': a NON-INJECTIVE cell index.
;
; `b[i >> 1]` over four trips writes two cells twice.  The second activation on a
; cell reads, as its SEED, the live rail the first one left there — so the
; promotion's "the cell starts at the initializer" premise is FALSE and
; forwarding the zero would be a hidden `|0>` assertion on an entangled rail.
;
; C2' answers it with SCEV: the index must be an affine `{0,+,1}` add-recurrence
; of the store's own loop.  `{0,+,1} >> 1` is not an add-recurrence at all.
;
; ⚠ `getSmallConstantMaxTripCount` is NOT how the bound is read (`CLAUDE.md`
; Rule 18: it returns `4294967295` on some vacuous bounds and `0` on others, so
; neither return value distinguishes vacuity).  The EXACT backedge-taken count is
; asked, so `CouldNotCompute` is refused by the same test that reads the bound.;
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
  %b = alloca [2 x i8], align 2
  store i16 0, ptr %b, align 2
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %head ]
  %h = lshr i64 %i, 1
  %g0 = getelementptr inbounds [2 x i8], ptr %b, i64 0, i64 %h
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 4
  br i1 %done, label %out, label %head

out:
  %r = load i8, ptr %b, align 1
  %c = trunc nuw i8 %r to i1
  %m = call zeroext i1 @cq_measure_i1(i1 %c)
  %e = zext i1 %m to i32
  ret i32 %e
}

; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; DBG:        %h = lshr i64 %i, 1
; DBG:        store i8 %z0, ptr %g0, align 1

; NOTS-NOT: CQ_RAILBANK_DBG: promote bank
; NOTS-NOT: %cq.bank
; ⚠ `!cq.railbank` is NOT checked here and that is deliberate: this stage
; refuses this module, so a re-added metadata mint could never fire on it and
; the negative would be VACUOUS (Rule 12 hygiene defect (b), the shape the
; 2026-09-14 session measured as `checked 0`).  It is checked on the ACCEPT
; fixtures instead, where the promoter actually runs.

; DECLINE: cq taint escape: tainted value stored to memory
