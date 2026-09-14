; railbank_promote_uninit_bank.ll — bd `xdu2` / L-1a clause C5 composed with bd
; `z9t1`: the UNINITIALIZED bank (owner ruling D1).
;
; The owner's `example/grover/grover_oracle_uncompute.c` writes `bool b0[3];`
; with NO `= {0}`, so a C1 that demanded a proven constant-zero initializer would
; refuse the owner's literal file — an over-decline of the very program the
; increment exists to compile.  RULED (`$SES/DECISIONS.md` D1): an uninitialized
; bank cell's seed normalizes to the type's CONCRETE ZERO AT THE ALLOCATION, the
; same rule `normalizeUndefRotationSeed` (`RotationLowering.cpp`) already ships
; for a scalar `undef` seed at a SOURCE `cq_theta`.
;
; ⚠ THE DISCLOSURE, in the two halves `CLAUDE.md` §4c requires (the full text is
; at the mechanism, `RailBankCarveShim.cpp`'s header):
;   THE RIVAL READING AS A PROGRAM — the author of `bool b[3];` may have meant
;   "whatever was on the stack", and the compiler now reads it as `0`.
;   WHY IT HAS NO LOWERING TO BE ROBBED OF — on the ORACLE this module is a LOUD
;   DECLINE (`trackL/probes/L7_array_uninit.c` takes the same `kMsgStore`), so no
;   circuit for the rival is displaced; and `0` is a value LangRef already
;   licensed for a read of uninitialized memory, so the accept it moves toward is
;   a REFINEMENT and the emitted module is identical to the written-`{0}` twin's.
; NO WARNING IS ADDED, deliberately (owner, 2026-09-14: "both codes are supposed
; to compie!! also no warnings.").
;
; ⚠ bd `z9t1`'s three RETIREMENT TRIGGERS (`CLAUDE.md` §4c) now have a SECOND
; CUSTOMER.  This file is the tripwire for trigger (ii).;
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
  br i1 %done, label %out, label %head

out:
  %m = call i32 @cq_measure_si32(i32 %a.next)
  ret i32 %m
}

; DBG: CQ_RAILBANK_DBG: promote bank %b in @main header %head cells=3 cell=i8 seed=zero loads=2 stores=1
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; The MANUFACTURED zero — the whole of ruling D1, in one line.  With no
; initializer in the module, the seed is still the type's concrete zero.
; DBG:      arm:
; DBG-NEXT:   %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
; DBG:      latch:
; DBG-NEXT:   %cq.bank = phi i8 [ %z0, %arm ], [ 0, %head ]

; No initializer is INVENTED in the IR either — the manufacture is at the SEED,
; not a written store (which is what makes it a refinement and not a rewrite).
; ⚠ `call void @llvm.memset` and not a bare `llvm.memset`: this file DECLARES the
; intrinsic, and a bare `-NOT` would match its own declaration line (bd `qta2`).
; NOTS-NOT: call void @llvm.memset
; NOTS-COUNT-1: store i8 %cq.bank

; DECLINE: cq taint escape: tainted value stored to memory

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
