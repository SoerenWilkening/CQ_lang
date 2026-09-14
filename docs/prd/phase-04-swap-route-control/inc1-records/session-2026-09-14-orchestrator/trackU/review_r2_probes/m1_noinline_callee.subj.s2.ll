; ModuleID = 'm1_noinline_callee.subj.s1.ll'
source_filename = "m1_noinline_callee.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call fastcc i32 @mk(double noundef 5.000000e-01), !dbg !17
    #dbg_value(i32 %1, !15, !DIExpression(), !18)
  %2 = tail call fastcc i32 @mk(double noundef 2.500000e-01), !dbg !19
    #dbg_value(i32 %2, !16, !DIExpression(), !18)
  %3 = add nsw i32 %2, %1, !dbg !20
  ret i32 %3, !dbg !21
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @mk(double noundef %0) unnamed_addr #1 !dbg !22 {
    #dbg_value(double %0, !27, !DIExpression(), !29)
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !30
  call void @cqrt_ry_i32(i32 %h, double %0), !dbg !30
  ret i32 %h, !dbg !31
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

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
!8 = !DIFile(filename: "m1_noinline_callee.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r2_probes", checksumkind: CSK_MD5, checksum: "35c3e00b4409abdbe4e97bdf10656be2")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "p", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocation(line: 5, column: 26, scope: !10)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 5, column: 43, scope: !10)
!20 = !DILocation(line: 5, column: 74, scope: !10)
!21 = !DILocation(line: 5, column: 53, scope: !10)
!22 = distinct !DISubprogram(name: "mk", scope: !8, file: !8, line: 4, type: !23, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !26)
!23 = !DISubroutineType(types: !24)
!24 = !{!13, !25}
!25 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!26 = !{!27, !28}
!27 = !DILocalVariable(name: "th", arg: 1, scope: !22, file: !8, line: 4, type: !25)
!28 = !DILocalVariable(name: "s", scope: !22, file: !8, line: 4, type: !13)
!29 = !DILocation(line: 0, scope: !22)
!30 = !DILocation(line: 4, column: 68, scope: !22)
!31 = !DILocation(line: 4, column: 61, scope: !22)
