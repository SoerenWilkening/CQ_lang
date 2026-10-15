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
; RUN: env CQ_RAILBANK_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG       --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOTS      --input-file=%t.dbg %s

; ⚠ bd `test_C_libtooling-01po.19` S4 (2026-10-15): DECLINE -> ACCEPT. The window
; model now LOWERS this array (RailWindow.h: handle array materialized at the
; quantization point, cell reads are borrowed roots, a cell rail is never freed
; or reverse-played). Reviewed by trace, not by green:
; trace: two walks — Ry(0.25) then Ry(0.5) on each of h0..h2 — measure h0.
; The S4 prefix pins the whole emitted runtime stream and that no rail is freed.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not=cqrt_free --implicit-check-not='error:'
; S4-LABEL: define {{.*}} @main(
; S4: %b.rails = alloca i32, i64 3, align 4, !cq.railwindow !0
; S4: %h = call i32 @cqrt_alloc_i1(i1 %1)
; S4: %ps.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %ps.rail, double 2.500000e-01)
; S4: store i32 %ps.rail, ptr %cq.rail.addr, align 4
; S4: %s0.rail = load i32, ptr %cq.rail.addr1, align 4
; S4: call void @cqrt_ry_i1(i32 %s0.rail, double 5.000000e-01)
; S4: store i32 %s0.rail, ptr %cq.rail.addr1, align 4
; S4: %r.rail = load i32, ptr %b.rails, align 4
; S4: %m2 = call i1 @cqrt_measure_i1(i32 %r.rail)

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
; The clause it is ABOUT is the promoter's B5 (ONE WRITER).  The negative
; `promote bank` check below (in the NOTS prefix) is satisfied VACUOUSLY: the
; promoter never runs, because `planBank`'s B6 calls Track A's carve FIRST and
; the carve refuses the module before any B-clause is asked.
;
; ⚠ WHY A RE-SPELLING WAS ATTEMPTED AND ABANDONED, with the measurement:
;   A bank with a second store ANYWHERE is `RejectAlias` at the carve's C4
;   second half (`Stores.size() != 1`, `cq rail bank: array is written from more
;   than one store site`) — MEASURED on this module — and a bank whose ONLY
;   store is outside any loop is `NotBank` at the carve's
;   `LI.getLoopFor(SI->getParent())` entry conjunct.  Every module that could
;   exercise B5 is refused earlier.  ⚠ Track B's scoping predicted this
;   structurally before measuring it (`SCOPE_B.md` §8) and it is the same
;   finding, one clause over, as merge filing F-2's unreachable multi-store
;   `SSAUpdater` path.
;
; ⚠ SO THE FIXTURE WAS NOT PAPERED OVER WITH A HAND-IR MODULE THAT ONLY *LOOKS*
; LIKE A SUBJECT (`SCOPE_B.md` §8 forbids exactly that), AND THE B CLAUSE WAS NOT
; DELETED.  What ships is this disclosure: the file keeps pinning that the module
; is LOUDLY REFUSED and that the promoter does NOT fire on it — both true, both
; worth keeping — and it states which widening restores isolation.
;
; ⚠ L8 RETIREMENT TRIGGER — the day
;   C4's `Stores.size() != 1` is relaxed to admit a two-writer bank.  ⚠ That is
;   exactly the widening B9's OWN retirement trigger already governs (the
;   several-stores `SSAUpdater` merge must come back WITH a red-green pair), so
;   the two must move together.  B5 then becomes reachable; re-derive this file
;   THEN.  ⚠ AND DO NOT DELETE B5 IN THE MEANTIME: `MERGE_FILINGS` F-1's lesson
;   is that the promoter's soundness must not rest on a conjunct that lives in
;   ANOTHER FILE and was cleared for another purpose.
;
