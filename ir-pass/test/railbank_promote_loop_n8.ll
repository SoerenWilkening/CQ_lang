; railbank_promote_loop_n8.ll — bd `xdu2` / L-1a clause C5: the customer at N=8.
;
; The increment's third size, and the one that shows the stage is N-INDEPENDENT:
; the rewrite is per-ACTIVATION, so the emitted module has exactly one phi, one
; gep and one store whatever N is.  `-O1` stamps `llvm.loop.unroll.disable` on
; this loop, so no constant N scalarises the array (`SCOPE_L1a.md` §1).
;
; N=8's initializer is again the whole-object `store i64 0` — see
; `railbank_promote_loop_n2_wholeobj_init.ll` for why that clause exists.;
; ⚠ STAGED LANDING.  W1 is three pieces and only TWO land this session (Track A's
; carve verdict and this promotion).  The taint rule (a `load` from a
; `!cq.railbank` alloca is tainted), the `[N x i1]` -> `[N x i32]` type rewrite
; and the D5 allow-list are deliberately DEFERRED, so an ACCEPT here would be a
; SILENT MISCOMPILE: `SCOPE_L1a.md` §4.4(D) — `cq_measure` of an UNTAINTED load
; takes `MeasureLowering.cpp`'s classical split and emits no gate, no symbol and
; NO TRACE LINE, which the golden byte-diff cannot see.  So the module still
; DECLINES `cq taint escape: tainted value stored to memory`.
;
; ⚠ A `DS_Error` decline writes 0 BYTES TO STDOUT, so the promotion is not
; observable on the lowered IR at this stage and an IR-text `CHECK` on stdout
; would be VACUOUS (Rule 12 hygiene defect (b)).  It is pinned on the
; `CQ_RAILBANK_DBG` MODULE DUMP instead — the `CQ_FP80_DBG` / `CQ_SPEC_DBG`
; precedent — so the `DBG` prefix below checks the REAL post-promotion module.
;
; ⚠ L8 RETIREMENT TRIGGER: when the L-1a taint rule + type rewrite + D5
; allow-list land (bd `xdu2`, the second half), this file's RUN lines become an
; ACCEPT and the shape below becomes checkable on stdout.  Re-derive it then; do
; NOT delete it.
;
;
; ⚠⚠ THE L8 RETIREMENT TRIGGER BELOW HAS FIRED — bd `xdu2` W1's SECOND HALF
; landed 2026-09-15 and this file was RE-DERIVED, not deleted, in the same
; change.  TWO things moved and both are recorded here rather than absorbed:
;
;   (1) THE PROMOTED SHAPE.  W1 piece 2 SINKS the `_Bool` cell's storage cast
;       out of the region arm: the merge phi is now built at the RAIL type
;       (`%cq.bank1 = phi i1`) and the `zext i1 -> i8` sits immediately in front
;       of the activation-end store (`%cq.bank.stg`).  With the cast IN the arm
;       the arm classified as a VALUE arm and the module declined `value-arm
;       swap-route under quantum control` anchored at the `zext` itself; with
;       the phi rail-typed it gets past that.  The PUN FENCE
;       (`StoreVal->getType() != CellTy`) is untouched — the store still stores
;       `i8` — which is why the cast is SUNK and not deleted.
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

; ⚠⚠ THE L8 RETIREMENT TRIGGER ABOVE HAS FIRED — bd `test_C_libtooling-zujr`
; landed the LOOP-CARRIED HANDLE VARIABLE, and this file was RE-DERIVED, not
; deleted, in the same change.  ⚠ READ THE TRIGGER'S OWN WORDS AGAINST THE
; RESULT: it predicted the decline would MOVE to `cq loop lowering: loop-carried
; tainted value crosses iterations` (X1 / bd `ej5w` / W3).  It did not move — it
; is GONE.  The trigger was written when (c3) and X1 were expected to land
; separately; they landed in ONE increment, because X1 was never the last wall
; either: behind it stood `declineUnmarkedRolledIterLocal`'s conjunct 2 and then
; `declineClassicalMuxes`.  **A trigger that names the NEXT wall is only ever a
; LOWER BOUND on how many are left.**
;
; WHAT THE ACCEPT IS: `a` is a LOOP-CARRIED HANDLE VARIABLE — a register that
; crosses the back edge AND is re-minted every trip, because the merge emitter
; mints a FRESH `%out = cqrt_alloc_<W>` per activation.  The four sites that
; refused it now CALL `loopCarriedHandlePhi`, and `promoteLoopCarriedHandleSeeds`
; materialises the TRIP-1 register `%cq.carried = cqrt_alloc_i32(5)` in the
; preheader — the owner's ruling (1) of 2026-09-17.  The FLAT twin already did
; exactly that, as the `cqrt_alloc_i32(5)` copy source inside its trip-1 mux.
;
; ⚠ THE `DBG` AND `NOTS` PREFIXES BELOW ARE UNTOUCHED, AND THAT IS THE POINT:
; the PROMOTED SHAPE this file exists to pin did not move one character.  What
; moved is what happens to it afterwards.  The `DECLINE` prefix is replaced by
; `ACCEPT`, which reads the LOWERED IR on stdout — a thing a `DS_Error` module
; never had (Rule 12 hygiene defect (b): a decline fixture's IR-text checks are
; vacuous because stdout is 0 bytes).
;
; ⚠ NEXT L8 RETIREMENT TRIGGER: the day the promotion learns to hoist its
; `cqrt_alloc` ABOVE a rotated loop's zero-trip GUARD — clause (Z8) refuses that
; shape today, so a RUNTIME trip bound still declines `kMsgCrossIter` — a guarded
; spelling of this module becomes an accept too.  This one is unguarded and does
; not move.  Re-derive it then; do NOT delete it.
; RUN: env CQ_RAILBANK_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s > %t.ll 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG       --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOTS      --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=ACCEPT    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOREG     --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOMD      --input-file=%t.dbg %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main() {
entry:
  %b = alloca [8 x i8], align 8
  store i64 0, ptr %b, align 8
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %latch ]
  %a = phi i32 [ 5, %entry ], [ %a.next, %latch ]
  %c = icmp sgt i32 %a, 2
  br i1 %c, label %arm, label %latch

arm:
  %g0 = getelementptr inbounds [8 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
  br label %latch

latch:
  %g1 = getelementptr inbounds [8 x i8], ptr %b, i64 0, i64 %i
  %s1 = load i8, ptr %g1, align 1
  %t1 = trunc nuw i8 %s1 to i1
  %sub = add nsw i32 %a, -3
  %a.next = select i1 %t1, i32 %sub, i32 %a
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 8
  br i1 %done, label %out, label %head

out:
  %m = call i32 @cq_measure_si32(i32 %a.next)
  ret i32 %m
}

; DBG: CQ_RAILBANK_DBG: promote bank %b in @main header %head cells=8 cell=i8 seed=zero loads=2 stores=1
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; DBG:      latch:
; DBG-NEXT:   %cq.bank1 = phi i1 [ %q, %arm ], [ false, %head ]
; DBG:        %cq.bank.addr = getelementptr inbounds [8 x i8], ptr %b, i64 0, i64 %i
; DBG-NEXT:   %cq.bank.stg = zext i1 %cq.bank1 to i8
; DBG-NEXT:   store i8 %cq.bank.stg, ptr %cq.bank.addr, align 1

; N-INDEPENDENCE: one phi, one address, one store, whatever N is.
; NOTS-COUNT-1: %cq.bank1 = phi
; NOTS-COUNT-1: %cq.bank.addr = getelementptr
; NOTS-COUNT-1: store i8 %cq.bank.stg
; NOTS-NOT: load i8, ptr %g

; ── THE ACCEPT, read off stdout (bd `test_C_libtooling-zujr`). ───────────────
; The trip-1 promotion, in the PREHEADER:
; ACCEPT: %cq.carried = call i32 @cqrt_alloc_i32(i32 5)
; The header phi is a HANDLE MUX — the promoted register and the previous
; activation's merge `%out` — under the loop's own CLASSICAL exit test:
; ACCEPT: = phi i32 [ %cq.carried, %{{[0-9a-zA-Z._]+}} ], [ %out{{[0-9]*}}, %{{[0-9a-zA-Z._]+}} ]
; ONE ACTIVATION, in order: flag, controlled prep, `_unc` strip, proven-|0> free;
; then the arm's chain, the CNOT-copied ancilla, the fresh `|0>` merge rail, the
; two X-bracketed controlled copies, and the ancilla's free at |0>.
; ACCEPT: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[A:[0-9a-zA-Z._]+]], i32 2)
; ACCEPT: %h = call i32 @cqrt_alloc_i1(i1 false)
; ACCEPT: call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h, double 5.000000e-01)
; ACCEPT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %[[A]], i32 2)
; ACCEPT: call void @cqrt_free(i32 %h_cmp)
; ACCEPT: %h_op = call i32 @cq_template_add_i32_hl(i32 %[[A]], i32 -3)
; ACCEPT: %bf = call i32 @cqrt_alloc_i1(i1 false)
; ACCEPT: call void @cqrt_cnot(i32 %h, i32 %bf)
; ACCEPT: %out{{[0-9]*}} = call i32 @cqrt_alloc_i32(i32 0)
; ACCEPT: call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op, i32 %out
; ACCEPT: call void @cqrt_x(i32 %bf)
; ACCEPT: call void @cqrt_copy_i32_controlled(i32 %bf, i32 %[[A]], i32 %out
; ACCEPT: call void @cqrt_x(i32 %bf)
; ACCEPT: call void @cqrt_cnot(i32 %h, i32 %bf)
; ACCEPT: call void @cqrt_free(i32 %bf)
;
; THE REGISTER IS NEVER BRACKETED AND NEVER FREED, in its OWN whole-file prefix
; (Rule 12 hygiene defect (a): a positive above a negative WINDOWS it).
; NOREG-NOT: cqrt_x(i32 %cq.carried)
; NOREG-NOT: cqrt_free(i32 %cq.carried)
; NOREG-NOT: cqrt_free(i32 %h)

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
