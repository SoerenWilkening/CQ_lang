; railbank_promote_uncond_prep.ll — bd `xdu2` / L-1a clause C5: the
; UNCONDITIONAL prep, where the store DOMINATES the intra-activation load.
;
; The discriminator for contract step 2.  With the store unconditional there is
; nothing to merge: the second read forwards DIRECTLY to the stored value and NO
; phi is built at all.  A stage that always minted a phi would still be
; "correct" here and would tell the reviewer nothing; this file is what
; distinguishes "forward the dominating definition" from "always build a mux".;
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
; landed 2026-09-15 and this file was RE-DERIVED, not deleted.  The promoted
; shape is UNCHANGED (W1's cast sink fires only when the store's value is a
; `phi`, i.e. only on the conditional-arm shape, and this program's prep is
; unconditional), and the bank store no longer declines.  What declines now is
; the loop-carried tainted accumulator `a` — `cq loop lowering: loop-carried
; tainted value crosses iterations`, X1 / bd `ej5w` / W3 — which is wall 4 of
; the owner's cascade and is not W1's.
; RUN: env CQ_RAILBANK_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG       --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOTS      --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=DECLINE   --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOMD      --input-file=%t.dbg %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main() {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %head ]
  %a = phi i32 [ 5, %entry ], [ %a.next, %head ]
  %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
  %g1 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s1 = load i8, ptr %g1, align 1
  %t1 = trunc nuw i8 %s1 to i1
  %sub = add nsw i32 %a, -3
  %a.next = select i1 %t1, i32 %sub, i32 %a
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head

out:
  %m = call i32 @cq_measure_si32(i32 %a.next)
  ret i32 %m
}

; DBG: CQ_RAILBANK_DBG: promote bank %b in @main header %head cells=3 cell=i8 seed=zero loads=2 stores=1
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; The seed load forwards to the manufactured zero; the second load forwards to
; the STORED VALUE (`%z0`) directly — the dominating definition, not a mux.
; DBG:      head:
; DBG:        %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
; DBG-NEXT:   %z0 = zext i1 %q to i8
; DBG-NEXT:   %t1 = trunc nuw i8 %z0 to i1
; DBG:        %cq.bank.addr = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
; DBG-NEXT:   store i8 %z0, ptr %cq.bank.addr, align 1

; NO phi is minted: there is nothing to merge.
; NOTS-NOT: %cq.bank = phi
; NOTS-COUNT-1: CQ_RAILBANK_DBG: promote bank

; ⚠⚠ THE WALL MOVED AGAIN — bd `test_C_libtooling-zujr` (2026-09-19), and this
; file was RE-DERIVED, not deleted.  It is the ONE module of the eleven the
; increment moved that did NOT become an accept, and WHY is the whole reason it
; is still here.
;
; X1 IS GONE: `a` here IS a loop-carried HANDLE variable — constant seed `5`,
; latch incoming a tainted-condition `select` — so `loopCarriedHandlePhi` admits
; it, both X1 sites defer and the promotion materialises
; `%cq.carried = cqrt_alloc_i32(5)` in the preheader exactly as it does for the
; ten siblings.  What refuses this module is the SELECT's own condition:
;
;     %t1 = trunc nuw i8 %z0 to i1        ; %z0 = zext i1 %q to i8
;     %a.next = select i1 %t1, i32 %sub, i32 %a
;
; a bare `trunc`-of-`zext` `i1` — the `_Bool` STORAGE WIRE — which is off
; `collectCondTree`'s leaf grammar (no `CmpInst`, no rail leaf).  That is bd
; `r903`, the `i8` `_Bool` wire, and it is NOT this increment's: the C spelling of
; the same program compiles, because `clang -O1` folds `trunc(zext(%q))` to `%q`
; before the pass ever sees it (MEASURED: the C twin
; `$SES/probes/p2_valuearm.c` is exit 0 on the subject).  THIS FILE IS
; HAND-TRANSCRIBED and keeps the unfolded pair, which is what makes it a
; discriminator for the wire and not for the loop.
;
; ⚠ SO THE DECLINE STRING BELOW IS A `r903` STRING, NOT A LOOP STRING, and the
; difference is the point (CLAUDE.md L6: a structural guard wearing the wrong
; label is a defect).  L8 RETIREMENT TRIGGER: the day bd `r903` gives the 4.4
; data select a `trunc`/`zext` `_Bool`-wire leaf, this module ACCEPTS with the
; same stream its ten siblings emit and this file is re-derived a third time.
; Do NOT delete it.
; DECLINE: cq controlled lowering: control flow under quantum control

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
