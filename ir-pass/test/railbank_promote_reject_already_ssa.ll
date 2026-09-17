; railbank_promote_reject_already_ssa.ll — bd `xdu2` / L-1a clause C5, clause B8:
; the module that is ALREADY in the post-promotion shape.
;
; ⚠ THIS IS THE `-O1` TARGET SHAPE AS A PIN, AND THAT IS ITS MAIN JOB.  The body
; below is what `clang -O1` emits for `trackL/probes/L1_promoted_store.c` — the
; scalar source whose loop body is exactly what the promotion must produce:
; exactly ONE store per trip, of the merge value, at the trip's end, with no
; intra-activation load at all.  Pinning it here means a `clang` bump that moves
; the target shape shows up as a RED here rather than as a silently diverging
; promoter.
;
; The stage refuses it (B8: no load inside the write loop) and leaves it
; BYTE-UNTOUCHED.  There is nothing to forward, the existing store already IS the
; activation's write, and firing would only churn the IR.;
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
  %i = phi i64 [ 0, %entry ], [ %i.next, %latch ]
  %a = phi i32 [ 5, %entry ], [ %a.next, %latch ]
  %c = icmp sgt i32 %a, 2
  br i1 %c, label %arm, label %latch

arm:
  %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %latch

latch:
  %m = phi i1 [ %q, %arm ], [ false, %head ]
  %sub = add nsw i32 %a, -3
  %a.next = select i1 %m, i32 %sub, i32 %a
  %addr = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %zz = zext i1 %m to i8
  store i8 %zz, ptr %addr, align 1
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head

out:
  %mm = call i32 @cq_measure_si32(i32 %a.next)
  ret i32 %mm
}

; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; The target shape, verbatim and unmoved: the merge phi, the select on it, one
; address and one store at the trip's end.
; DBG:      latch:
; DBG-NEXT:   %m = phi i1 [ %q, %arm ], [ false, %head ]
; DBG-NEXT:   %sub = add nsw i32 %a, -3
; DBG-NEXT:   %a.next = select i1 %m, i32 %sub, i32 %a
; DBG-NEXT:   %addr = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
; DBG-NEXT:   %zz = zext i1 %m to i8
; DBG-NEXT:   store i8 %zz, ptr %addr, align 1

; NOTS-NOT: CQ_RAILBANK_DBG: promote bank
; NOTS-NOT: %cq.bank
; ⚠ `!cq.railbank` is NOT checked here and that is deliberate: this stage
; refuses this module, so a re-added metadata mint could never fire on it and
; the negative would be VACUOUS (Rule 12 hygiene defect (b), the shape the
; 2026-09-14 session measured as `checked 0`).  It is checked on the ACCEPT
; fixtures instead, where the promoter actually runs.

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
