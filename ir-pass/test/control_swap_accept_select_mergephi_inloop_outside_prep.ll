; control_swap_accept_select_mergephi_inloop_outside_prep.ll — ACCEPT. bd `boi6`
; D-B / Track M, round-1 finding **F-M6**; probe `r22_inloop_select_outside_prep.c`.
; RED ON THE ORACLE (`control flow` at the select), GREEN HERE.
;
; A 4.4 DATA SELECT **INSIDE A BOUNDED LOOP** whose condition is the merge φ of a
; prep region **OUTSIDE** the loop. The select's stream is minted per iteration on
; a register the loop never touches.
;
; ⚠ WHY THIS IS ADMITTED AND `m30` IS NOT, because the two look alike and are not.
; `m30` is the LOOP-CARRIED shape: its φ is a loop header phi, the tainted value
; crosses iterations, and the LOOP LAYER declines it BEFORE detection ever runs
; (`cq loop lowering: loop-carried tainted value crosses iterations`,
; `CQLoweringPass` ~`:364`). That is a different cell and it is UNCHANGED on both
; binaries (round-1 probe `r21`). Here the φ is defined OUTSIDE the loop and is
; LOOP-INVARIANT: nothing about it crosses the back edge, so the loop layer has no
; objection and the ordinary flat ladder applies. `SCOPE_M.md` §4's "a φ in a
; loop — OUT, pinned by `m30`" covers the carried cell only; this cell moved
; DECLINE→ACCEPT with this increment and had no fixture until F-M6.
;
; ⚠ ROLLED, AND THE FIXTURE PINS IT. The loop is NOT unrolled: the lowered IR is
; K-INDEPENDENT — MEASURED at **78 lines / 19 gate calls at K=3 AND at K=1000**
; (`clang -O1` without `-g`, the same module body as below). A regression that
; unrolled instead would multiply the counts below by the trip count and redden
; every count prefix. The dynamic trace is 43 lines over 3 trips against 6 STATIC
; rail mints and ONE static `cqrt_free` site.
;
; PER ITERATION the stream is the shipped rail-root copy merge: `alloc_i1 → bf;
; cnot(h_b1, bf); alloc_i32(0) → out; alloc_i32(i); copy_controlled; x(bf);
; alloc_i32(5); copy_controlled; x(bf); cnot(h_b1, bf); free(bf)`. The prepped
; register is read ONLY as a `cqrt_cnot` control — never `cqrt_x`-bracketed, never
; freed — and each trip's ancilla returns to `x ⊕ x = 0` before its free, so the
; single static free site is a proven-|0⟩ one on every iteration (2b STRICT
; `0 violation(s), 0 unproven`).
;
; The loop twin matrix has no `_Bool` axis, so this fixture plus
; `tests/e2e/slice_control_cascade_select_in_loop_outside_prep.c` and its
; hand-unrolled twin are the ONLY instruments for this cell.

;
; ⚠ THIS FIXTURE CARRIES **NO** `= phi` NEGATIVE, deliberately, and the omission is
; the point rather than an oversight: the loop is ROLLED, so the induction and
; accumulator `phi`s are exactly what a correct lowering must leave standing. The
; sibling flat accepts all assert `NOROUTE-NOT: {{= phi }}` because their regions
; ARE flattened; asserting it here would demand an UNROLL. What replaces it is the
; K-independence measurement in the header and the counts below.
;
; ⚠ The stream pins are ORDERED, not adjacent: the loop body's own control flow
; and `#dbg_value` records sit between gates, so no `CHECK-NEXT` chain can span
; them. Order is still pinned, which is what the X-bracket scope depends on.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNOTCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r22_inloop_select_outside_prep.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r22_inloop_select_outside_prep.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !27
  br i1 %1, label %4, label %2, !dbg !30

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !31
  br label %4, !dbg !34

4:                                                ; preds = %2, %0
  %5 = phi i1 [ %3, %2 ], [ false, %0 ], !dbg !26
  br label %13, !dbg !36

6:                                                ; preds = %13
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !37
  %8 = zext i1 %7 to i32, !dbg !37
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2, !dbg !38
  %10 = zext i1 %9 to i32, !dbg !38
  %11 = add i32 %18, %8, !dbg !39
  %12 = add i32 %11, %10, !dbg !40
  ret i32 %12, !dbg !41

13:                                               ; preds = %4, %13
  %14 = phi i32 [ 0, %4 ], [ %19, %13 ]
  %15 = phi i32 [ 0, %4 ], [ %18, %13 ]
  %16 = select i1 %5, i32 %14, i32 5, !dbg !42
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !44
  %18 = add nsw i32 %17, %15, !dbg !45
  %19 = add nuw nsw i32 %14, 1, !dbg !46
  %20 = icmp eq i32 %19, 3, !dbg !47
  br i1 %20, label %6, label %13, !dbg !36, !llvm.loop !48
}

declare !dbg !52 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !57 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !60 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r22_inloop_select_outside_prep.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "f2ad0b7a069e02da8db0abbfb9d57c2b")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 7, type: !12, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r22_inloop_select_outside_prep.c", directory: "", checksumkind: CSK_MD5, checksum: "f2ad0b7a069e02da8db0abbfb9d57c2b")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !20, !21, !23}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 8, type: !14)
!17 = !DILocalVariable(name: "acc", scope: !10, file: !11, line: 8, type: !14)
!18 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 8, type: !19)
!19 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!20 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 8, type: !19)
!21 = !DILocalVariable(name: "i", scope: !22, file: !11, line: 12, type: !14)
!22 = distinct !DILexicalBlock(scope: !10, file: !11, line: 12, column: 5)
!23 = !DILocalVariable(name: "t", scope: !24, file: !11, line: 12, type: !14)
!24 = distinct !DILexicalBlock(scope: !25, file: !11, line: 12, column: 33)
!25 = distinct !DILexicalBlock(scope: !22, file: !11, line: 12, column: 5)
!26 = !DILocation(line: 0, scope: !10)
!27 = !DILocation(line: 9, column: 24, scope: !28)
!28 = distinct !DILexicalBlock(scope: !29, file: !11, line: 9, column: 17)
!29 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 9)
!30 = !DILocation(line: 11, column: 9, scope: !10)
!31 = !DILocation(line: 11, column: 24, scope: !32)
!32 = distinct !DILexicalBlock(scope: !33, file: !11, line: 11, column: 17)
!33 = distinct !DILexicalBlock(scope: !10, file: !11, line: 11, column: 9)
!34 = !DILocation(line: 11, column: 43, scope: !32)
!35 = !DILocation(line: 0, scope: !22)
!36 = !DILocation(line: 12, column: 5, scope: !22)
!37 = !DILocation(line: 13, column: 12, scope: !10)
!38 = !DILocation(line: 13, column: 29, scope: !10)
!39 = !DILocation(line: 13, column: 27, scope: !10)
!40 = !DILocation(line: 13, column: 44, scope: !10)
!41 = !DILocation(line: 13, column: 5, scope: !10)
!42 = !DILocation(line: 12, column: 43, scope: !24)
!43 = !DILocation(line: 0, scope: !24)
!44 = !DILocation(line: 12, column: 62, scope: !24)
!45 = !DILocation(line: 12, column: 59, scope: !24)
!46 = !DILocation(line: 12, column: 28, scope: !25)
!47 = !DILocation(line: 12, column: 23, scope: !25)
!48 = distinct !{!48, !36, !49, !50, !51}
!49 = !DILocation(line: 12, column: 77, scope: !22)
!50 = !{!"llvm.loop.mustprogress"}
!51 = !{!"llvm.loop.unroll.disable"}
!52 = !DISubprogram(name: "cq_theta_i1", scope: !53, file: !53, line: 32, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!54 = !DISubroutineType(types: !55)
!55 = !{!19, !19, !56}
!56 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!57 = !DISubprogram(name: "cq_measure_si32", scope: !53, file: !53, line: 83, type: !58, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!58 = !DISubroutineType(types: !59)
!59 = !{!14, !14}
!60 = !DISubprogram(name: "cq_measure_i1", scope: !53, file: !53, line: 77, type: !61, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!61 = !DISubroutineType(types: !62)
!62 = !{!19, !19}

; ---- The whole emitted stream, instruction for instruction.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_ry_i1(i32 %[[H2]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i1_controlled(i32 %[[H]], i32 %[[H2]], double -5.000000e-01)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H]])
; CHECK:      %[[M3:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
; CHECK:      %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_cnot(i32 %[[H2]], i32 %[[BF]])
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_xorc_i32_controlled(i32 %[[BF]], i32 %[[OUT]], i32 %7)
; CHECK:      call void @cqrt_x(i32 %[[BF]])
; CHECK:      call void @cqrt_xorc_i32_controlled(i32 %[[BF]], i32 %[[OUT]], i32 5)
; CHECK:      call void @cqrt_x(i32 %[[BF]])
; CHECK:      call void @cqrt_cnot(i32 %[[H2]], i32 %[[BF]])
; CHECK:      call void @cqrt_free(i32 %[[BF]])
; CHECK:      %[[M4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])

; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive
; line inside one WINDOWS every negative after it — the 3qlq F-L6-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: cqrt_toffoli
; NOROUTE-NOT: call i1 @cq_theta_i1(
; NOROUTE-NOT: cq_phi
; NO `cqrt_x` ON A USER REGISTER, EVER — the two `cqrt_x` per merge are on
; the copy ancilla. The handles are named because a pure-negative prefix
; cannot bind a capture; they are DERIVED from the pass output.
; NOX-NOT: call void @cqrt_x(i32 %h)
; NOX-NOT: call void @cqrt_x(i32 %h2)
; The MERGE-OUT rail too (round-2 finding F2-3): it is the register the
; source's variable ends up in and the one this fixture MEASURES, so an X
; landing on it is a basis flip of the user's answer.  An EXTRA x is caught
; by the count prefix and a SUBSTITUTED one by the ordered positive stream;
; this closes the gap where neither is looking.
; NOX-NOT: call void @cqrt_x(i32 %out)
; NO USER REGISTER IS FREED — `Ry(θ)|0⟩ ≠ |0⟩` (Rule 6). Only ancillas and
; stripped compare flags are.
; NOFREE-NOT: call void @cqrt_free(i32 %h)
; NOFREE-NOT: call void @cqrt_free(i32 %h2)
; NOFREE-NOT: call void @cqrt_free(i32 %out)
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CNOTCNT-COUNT-2: call void @cqrt_cnot(
; CNOTCNT-NOT:     call void @cqrt_cnot(
; (bd dm7f.81: a constant or classical merge arm is a literal operand of cqrt_xorc_<W>_controlled, no longer an alloc'd rail + cqrt_copy_<W>_controlled; a zero arm emits no gate and no bracket. Counts below re-measured.)
; CPCNT-NOT: call void @cqrt_copy_
; CPCNT-COUNT-2: call void @cqrt_xorc_
; CPCNT-NOT: call void @cqrt_xorc_
; CPCNT-NOT:     call void @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
