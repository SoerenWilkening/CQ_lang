; railbank_promote_reject_store_outside_loop.ll — bd `xdu2` / L-1a clause C5,
; clauses B1/B5: a SECOND WRITING LOOP.
;
; The per-activation seed is the INITIALIZER, and that claim rests on the object
; being untouched between the initializer and the activation.  A second loop that
; writes the same bank breaks it: the seed of the SECOND loop's activations is
; the FIRST loop's stored value — a live, possibly entangled rail — and the
; promotion would forward a classical zero over it.
;
; ⚠ THE SPELLING IS A SECOND LOOP AND NOT A STRAIGHT-LINE STORE, AND THAT IS
; MEASURED.  With a straight-line `b[1] = 1;` before the loop, Track A's carve
; refuses that store at C2' (a store outside any loop has no add-rec) and this
; fixture would go green for a reason that has nothing to do with B1/B5 — the
; injection matrix measured exactly that as a MISSED mutation, twice, before the
; fixture was rewritten.  Here BOTH stores are in an outermost `{0,+,1}` walk
; loop of the right trip count, so each is `Bank` on its own and the ONLY clause
; refusing is the promoter's "every `Bank` store resolves to the same loop".;
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
  br label %pre.head

pre.head:
  %j = phi i64 [ 0, %entry ], [ %j.next, %pre.head ]
  %pg = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %j
  %ps = load i8, ptr %pg, align 1
  %pt = trunc nuw i8 %ps to i1
  %pq = call zeroext i1 @cq_theta_i1(i1 %pt, double 2.500000e-01)
  %pz = zext i1 %pq to i8
  store i8 %pz, ptr %pg, align 1
  %j.next = add nuw nsw i64 %j, 1
  %pdone = icmp eq i64 %j.next, 3
  br i1 %pdone, label %mid, label %pre.head

mid:
  br label %head

head:
  %i = phi i64 [ 0, %mid ], [ %i.next, %head ]
  %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
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
; Both writing loops survive, untouched.
; DBG:        store i8 %pz, ptr %pg, align 1
; DBG:        store i8 %z0, ptr %g0, align 1

; NOTS-NOT: CQ_RAILBANK_DBG: promote bank
; NOTS-NOT: %cq.bank
; ⚠ `!cq.railbank` is NOT checked here and that is deliberate: this stage
; refuses this module, so a re-added metadata mint could never fire on it and
; the negative would be VACUOUS (Rule 12 hygiene defect (b), the shape the
; 2026-09-14 session measured as `checked 0`).  It is checked on the ACCEPT
; fixtures instead, where the promoter actually runs.

; DECLINE: cq taint escape: tainted value stored to memory
