; railbank_promote_loop_n3.ll — bd `xdu2` / L-1a clause C5, the PER-ACTIVATION
; PROMOTER (Track B, session 2026-09-14c).  THE CUSTOMER at N=3.
;
; The module is the `clang -O1` stage-1 form of `trackL/probes/a_loop_n3.c`
;   int a = 5; bool b[3] = {0};
;   for (int i = 0; i < 3; ++i) { if (a >= 3) b[i] = cq_theta(b[i], .5);
;                                 if (b[i]) a -= 3; }
; hand-transcribed with named blocks (the numeric form is pinned verbatim by
; `railbank_promote_o1_shape.ll`, which is what a `clang` bump moves).
;
; ⚠ STAGED LANDING — READ THIS BEFORE READING THE RUN LINES.  W1 is three
; pieces and only TWO land this session (Track A's carve verdict and this
; promotion).  The taint rule (a `load` from a `!cq.railbank` alloca is
; tainted), the `[N x i1]` -> `[N x i32]` type rewrite and the D5 allow-list are
; deliberately DEFERRED, so an ACCEPT here would be a silent miscompile
; (`SCOPE_L1a.md` §4.4(D): `cq_measure` of an untainted load emits no gate, no
; symbol and NO TRACE LINE).  The promoted module therefore still DECLINES
; `cq taint escape: tainted value stored to memory` — at the ONE surviving
; store per activation, which this stage moves to the activation's end.
;
; ⚠ A `DS_Error` decline writes 0 BYTES TO STDOUT, so the promotion is NOT
; observable on the lowered IR at this stage and an IR-text `CHECK` on stdout
; would be VACUOUS (Rule 12 hygiene defect (b)).  The promotion is pinned on the
; `CQ_RAILBANK_DBG` stream instead — the `CQ_FP80_DBG` / `CQ_SPEC_DBG`
; precedent, a module dump on stderr — so the DBG prefix below is checking the
; REAL post-promotion module, not a summary of it.
;
; ⚠ L8 RETIREMENT TRIGGER: when the L-1a taint rule + type rewrite + D5
; allow-list land (bd `xdu2`, the second half), this file's second RUN line
; becomes an ACCEPT and the promoted shape below becomes checkable on stdout.
; Re-derive it then; do NOT delete it.
;
;
; ⚠⚠ THE L8 RETIREMENT TRIGGER BELOW HAS FIRED — bd `xdu2` W1's SECOND HALF
; landed 2026-09-15 and this file was RE-DERIVED, not deleted, in the same
; change.  TWO things moved and both are recorded here rather than absorbed:
;
;   (1) THE PROMOTED SHAPE.  W1 piece 2 SINKS the `_Bool` cell's storage cast
;       out of the region arm: the merge phi is now built at the RAIL type
;       (`%cq.bank1 = phi i1`) and the `zext i1 -> i8` sits immediately in front
;       of the activation-end store (`%cq.bank.stg`).  The `trunc` the arm's
;       consumer used to read is folded away with it.  With the cast IN the arm
;       the arm classified as a VALUE arm and the module declined `value-arm
;       swap-route under quantum control` anchored at the `zext` itself.  The
;       PUN FENCE (`StoreVal->getType() != CellTy`) is untouched — the store
;       still stores `i8` — which is why the cast is SUNK and not deleted.
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
; RUN: %filecheck --check-prefix=DECLINE   --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOMD      --input-file=%t.dbg %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

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
  %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
  br label %latch

latch:
  %g1 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s1 = load i8, ptr %g1, align 1
  %t1 = trunc nuw i8 %s1 to i1
  %sub = add nsw i32 %a, -3
  %a.next = select i1 %t1, i32 %sub, i32 %a
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %mend, label %head

mend:
  %m0 = call i32 @cq_measure_si32(i32 %a.next)
  br label %mhead

mhead:
  %j = phi i64 [ 0, %mend ], [ %j.next, %mhead ]
  %acc = phi i32 [ %m0, %mend ], [ %acc.next, %mhead ]
  %g2 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %j
  %s2 = load i8, ptr %g2, align 1
  %t2 = trunc nuw i8 %s2 to i1
  %mq = call zeroext i1 @cq_measure_i1(i1 %t2)
  %z2 = zext i1 %mq to i32
  %acc.next = add nsw i32 %acc, %z2
  %j.next = add nuw nsw i64 %j, 1
  %mdone = icmp eq i64 %j.next, 3
  br i1 %mdone, label %out, label %mhead

out:
  ret i32 %acc.next
}

; The promotion fired, once, on the one bank in the one loop.
; DBG: CQ_RAILBANK_DBG: promote bank %b in @main header %head cells=3 cell=i8 seed=zero loads=2 stores=1
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===

; (1) The SEED load is the proven initializer constant, folded through the
;     `trunc` so the theta reads a LITERAL — the `-O1` target's `@cq_theta_i1(i1
;     false, …)` verbatim.  Nothing addresses the bank in the arm any more.
; DBG:      arm:
; DBG-NEXT:   %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
; DBG-NEXT:   br label %latch

; (2) The intra-activation load is the SSA MERGE, and (3) exactly ONE store per
;     activation survives, at the activation's end, of that merge value.
; DBG:      latch:
; DBG-NEXT:   %cq.bank1 = phi i1 [ %q, %arm ], [ false, %head ]
; DBG:        %cq.bank.addr = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
; DBG-NEXT:   %cq.bank.stg = zext i1 %cq.bank1 to i8
; DBG-NEXT:   store i8 %cq.bank.stg, ptr %cq.bank.addr, align 1
; DBG-NEXT:   br i1 %done, label %mend, label %head

; The measure loop is NOT promoted — it reads cells written by a DIFFERENT
; activation of a DIFFERENT loop, which no per-activation forwarding can reach
; (`SCOPE_L1a.md` §3c).  It keeps its load, and that load is what the deferred
; taint rule will have to claim.
; DBG:      mhead:
; DBG:        %s2 = load i8, ptr %g2, align 1

; DECLINE: cq controlled lowering: control flow inside a loop body under quantum control

; ⚠ ITS OWN WHOLE-FILE PREFIX, AND THAT IS THE POINT.  A positive `CHECK-COUNT`
; inside a negative prefix WINDOWS every negative after it — FileCheck only scans
; forward from the positive match — and this file's `NOTS` prefix carries counts,
; so a `NOTS-NOT: !cq.railbank` there would never see the `alloca` line, which is
; ABOVE them in the dump.  MEASURED: with the negative in `NOTS`, a mutant that
; re-adds the metadata mint was caught by only 3 of the 7 accept fixtures; in its
; own prefix it is caught by all 7.  (`CLAUDE.md` Rule 12 hygiene defect (a): the
; same shape was caught by 0 of 20 blocks the first time it shipped.)
;
; The promoter mints NO membership record.  `!cq.railbank` is the FREEZE's, and the
; freeze is in W1's deferred half — `SCOPE_L1a.md` §4.3 and `trackA/SIGNATURE.md`
; deviation (2) put the mint on the TYPE REWRITER next session, because a record
; with no reader is Rule 12 hygiene defect (c) in its purest form.
; NOMD-NOT: !cq.railbank
