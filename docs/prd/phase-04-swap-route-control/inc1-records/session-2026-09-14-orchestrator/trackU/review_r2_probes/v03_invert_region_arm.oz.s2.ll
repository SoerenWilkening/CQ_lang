; ModuleID = 'v03_invert_region_arm.zero.s1.ll'
source_filename = "v03_invert_region_arm.zero.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !15, !DIExpression(), !18)
    #dbg_value(i8 0, !16, !DIExpression(), !18)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !19
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !19
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !18)
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !18)
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !18)
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h), !dbg !22
  %1 = tail call i32 @cq_invert_i1(i32 noundef %h_cast) #2, !dbg !23
  ret i32 %1, !dbg !24
}

declare !dbg !25 i32 @cq_invert_i1(i32 noundef) local_unnamed_addr #1

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_zext_i1_to_i32(i32)

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
!8 = !DIFile(filename: "v03_invert_region_arm.zero.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r2_probes", checksumkind: CSK_MD5, checksum: "b58f139347709e6043f99496797235ac")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 7, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 8, column: 23, scope: !20)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 8, column: 17)
!21 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 9)
!22 = !DILocation(line: 9, column: 25, scope: !10)
!23 = !DILocation(line: 9, column: 12, scope: !10)
!24 = !DILocation(line: 9, column: 5, scope: !10)
!25 = !DISubprogram(name: "cq_invert_i1", scope: !8, file: !8, line: 4, type: !26, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!26 = !DISubroutineType(types: !27)
!27 = !{!13, !13}
