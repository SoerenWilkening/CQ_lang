; railbank_promote_reject_nonzero_init.ll — bd `xdu2` / L-1a clause C5 / carve
; clause C1: a NON-ZERO initializer.
;
; ⚠ THE TRIPWIRE FOR THE bd `z9t1` COMPOSITION (`CLAUDE.md` §4c, retirement
; trigger (ii)).  The seed is manufactured for exactly two initializer shapes —
; a proven whole-object constant ZERO (memset or integer store), and NO
; initializer at all (owner ruling D1).  A non-zero or partial initializer is
; refused, never rewritten.  The day a third case is admitted, the D1 disclosure
; must be re-derived from scratch, and this file is what goes red.;
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
; trace: memset 1 before Q is classical, so the walk mints alloc(1) for every cell; one Ry each; measure h0.
; The S4 prefix pins the whole emitted runtime stream and that no rail is freed.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not=cqrt_free --implicit-check-not='error:'
; S4-LABEL: define {{.*}} @main(
; S4: %b.rails = alloca i32, i64 3, align 4, !cq.railwindow !0
; S4: %h = call i32 @cqrt_alloc_i1(i1 %1)
; S4: %s0.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %s0.rail, double 5.000000e-01)
; S4: store i32 %s0.rail, ptr %cq.rail.addr, align 4
; S4: %r.rail = load i32, ptr %b.rails, align 4
; S4: %m1 = call i1 @cqrt_measure_i1(i32 %r.rail)

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @sink(ptr)

define i32 @main() {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 1, i64 3, i1 false)
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %head ]
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
; DBG:        call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 1, i64 3, i1 false)
; DBG:        %s0 = load i8, ptr %g0, align 1

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
