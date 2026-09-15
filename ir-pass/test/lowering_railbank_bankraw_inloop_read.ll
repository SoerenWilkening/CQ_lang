; lowering_railbank_bankraw_inloop_read.ll — the `BankRaw` VERDICT ANCHOR, clause
; C7(a) IN ISOLATION (bd `test_C_libtooling-de8n`, P1, closed 2026-09-15).
;
; ⚠ WHAT THIS FIXTURE IS FOR. `Bank` is the ACCEPT PREDICATE OF RECORD (the L8
; trigger at `TaintPropagation.cpp` turns the `Bank` arm into a `continue` when the
; L-1a taint rule + type rewrite land), and before clause C7 it did NOT imply the
; shape the type rewrite can serve. On the module below the per-trip cell is still
; READ inside the walk loop (`%s`, the seed) and the read is PARTIALLY AVAILABLE in
; the general case — `SCOPE_L1a.md` §0 H3 — so a `[3 x i8]` → `[3 x i32]` element
; rewrite would make that load read the initializer `0` AS A HANDLE, and `h0` is a
; LIVE RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`). It is a live-qubit alias,
; not a null.
;
; The per-activation promoter exists to REMOVE exactly these reads. Here it cannot:
; the loop has NO DEDICATED PREHEADER (`%entry` has two successors), so
; `RailBankPromote`'s B1 refuses and the read survives to the carve. A `Bank` that
; was never promoted is the defect, and C7(a) is the separation.
;
; ⚠ WHY HAND-IR AND NOT A `clang -O1` MODULE. The no-preheader shape IS reachable
; from plain C — `trackA/probes/g3_two_banks_onefn.c` / `f9_two_banks.c` /
; `g7_three_banks.c`, where an earlier bank loop's latch is the next loop's only
; outside predecessor — but in every one of those the FIRST bank's store reaches
; `diagnoseEscape` first and `LLVMContext::diagnose` EXITS on the first `DS_Error`
; (bd `br4a`), so the second bank's verdict is never printed and cannot be checked.
; One bank per module is what makes the anchor observable. The C-floor family with
; a SINGLE bank is the in-loop-initializer one (`trackA/probes/d1_rezero_inloop.c`,
; `d2_lifetime_inloop.c`, `d3_rezero_arm.c` — all `[Bank]`→`[BankRaw]`, measured),
; but those fail BOTH C7 conjuncts and so isolate neither.
;
; ⚠ THE ISOLATION IS MEASURED, NOT ASSERTED. `trackA/probes/p4_noread_uncond_
; nopreheader.ll` is this module with ONE line changed — the theta reads a literal
; `false` instead of the cell — and it measures `[Bank]` on BOTH binaries. So the
; verdict here moves with the READ and not with the missing preheader. The store is
; unconditional and in the latch, so C7(b) holds.
;
; MEASURED, ORACLE vs SUBJECT, on the SAME file:
;   ORACLE   cq-opt 0e280fc6…  ->  carve=[Bank]     promo=0     <-- THE DEFECT
;   SUBJECT  cq-opt b6554935…  ->  carve=[BankRaw]  promo=0
;
; ⚠ THIS IS STILL A DECLINE AND THE DECLINE DID NOT MOVE. `BankRaw` is NOT a
; reject: C1–C6 all held, `outMsg` stays null, and the module takes the same
; generic `cq taint escape: tainted value stored to memory` it took on the ORACLE.
; The ONLY observable is the env-gated `CQ_CTRL_DBG` anchor (Rule 12 hygiene defect
; (c) is the live hazard for every verdict on this path), and the
; `--implicit-check-not` closes the other direction — `railbank [Bank]` must not
; appear, and `[BankRaw]` does not contain that string.
;
; ⚠ L8 RETIREMENT TRIGGER, character-for-character as the thing that will fire:
;   "When the L-1a taint rule + type rewrite + D5 allow-list land, the `Bank`
;   verdict stops falling through to `kMsgStore`. THIS FILE DOES NOT BECOME AN
;   ACCEPT — `BankRaw` must keep declining in every future half. If a later
;   increment wants this program to compile it must teach the PROMOTER to
;   normalise a loop with no dedicated preheader (insert one), after which the
;   carve calls the result `Bank` on its own. Never by adding an accepting arm for
;   `BankRaw` at the consumer."
;
; SOURCE: `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackA/probes/p3_inloop_read_uncond_nopreheader.ll`, verbatim.
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]' --implicit-check-not='cq rail bank:'
; CHECK: CQ_CTRL_DBG: railbank [BankRaw] cells=3 abi=i8 trips=3 at:
; CHECK: cq taint escape: tainted value stored to memory

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main(i32 %n) {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  %c = icmp sgt i32 %n, 0
  br i1 %c, label %head, label %bail
bail:
  ret i32 0
head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %head ]
  %a = phi i32 [ 5, %entry ], [ %a.next, %head ]
  %g = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s = load i8, ptr %g, align 1
  %t = trunc nuw i8 %s to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %z = zext i1 %q to i8
  store i8 %z, ptr %g, align 1
  %am3 = add nsw i32 %a, -3
  %a.next = select i1 %q, i32 %am3, i32 %a
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head
out:
  %m = call i32 @cq_measure_si32(i32 %a.next)
  ret i32 %m
}
