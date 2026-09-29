; ModuleID = 'b0.c'
source_filename = "b0.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !21)
  %2 = and i32 %0, 7, !dbg !22
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4, !dbg !22
    #dbg_value(i32 %3, !16, !DIExpression(), !21)
  %4 = mul nsw i32 %3, 3, !dbg !23
    #dbg_value(i32 %4, !17, !DIExpression(), !21)
  %5 = xor i32 %4, %3, !dbg !24
    #dbg_value(i32 %5, !18, !DIExpression(), !21)
  %6 = tail call i32 @h(i32 noundef %0, i32 noundef %3) #4, !dbg !25
    #dbg_value(i32 %6, !19, !DIExpression(), !21)
  %7 = icmp eq i32 %5, 10, !dbg !26
  br i1 %7, label %8, label %9, !dbg !28

8:                                                ; preds = %1
  tail call void @cq_phi(double noundef 3.141590e+00) #4, !dbg !29
  br label %9, !dbg !29

9:                                                ; preds = %8, %1
  %10 = tail call i32 @cq_measure_si32(i32 noundef %6) #4, !dbg !30
    #dbg_value(i32 %10, !20, !DIExpression(), !21)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #4, !dbg !31
    #dbg_value(i32 %11, !16, !DIExpression(), !21)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4, !dbg !32
  %13 = add nsw i32 %12, %10, !dbg !33
  ret i32 %13, !dbg !34
}

declare !dbg !35 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !40 i32 @h(i32 noundef, i32 noundef) local_unnamed_addr #1

declare !dbg !43 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !46 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 !dbg !47 {
    #dbg_value(i32 %0, !54, !DIExpression(), !56)
    #dbg_value(ptr %1, !55, !DIExpression(), !56)
  %3 = getelementptr inbounds i8, ptr %1, i64 8, !dbg !57
  %4 = load ptr, ptr %3, align 8, !dbg !57, !tbaa !58
  %5 = tail call i32 @atoi(ptr nocapture noundef %4), !dbg !62
  %6 = tail call i32 @slice(i32 noundef %5), !dbg !63
  %7 = and i32 %6, 1, !dbg !64
  ret i32 %7, !dbg !65
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare !dbg !66 i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
!8 = !DIFile(filename: "b0.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r1B_rhk5/probes/src", checksumkind: CSK_MD5, checksum: "6f1be7448111d6fbe3219cc610381f6b")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19, !20}
!15 = !DILocalVariable(name: "m", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "p", scope: !10, file: !8, line: 5, type: !13)
!18 = !DILocalVariable(name: "u", scope: !10, file: !8, line: 6, type: !13)
!19 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!20 = !DILocalVariable(name: "ms", scope: !10, file: !8, line: 9, type: !13)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 4, column: 11, scope: !10)
!23 = !DILocation(line: 5, column: 13, scope: !10)
!24 = !DILocation(line: 6, column: 13, scope: !10)
!25 = !DILocation(line: 7, column: 11, scope: !10)
!26 = !DILocation(line: 8, column: 9, scope: !27)
!27 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 7)
!28 = !DILocation(line: 8, column: 7, scope: !10)
!29 = !DILocation(line: 8, column: 16, scope: !27)
!30 = !DILocation(line: 9, column: 12, scope: !10)
!31 = !DILocation(line: 10, column: 7, scope: !10)
!32 = !DILocation(line: 11, column: 15, scope: !10)
!33 = !DILocation(line: 11, column: 13, scope: !10)
!34 = !DILocation(line: 11, column: 3, scope: !10)
!35 = !DISubprogram(name: "cq_theta_si32", scope: !36, file: !36, line: 38, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!37 = !DISubroutineType(types: !38)
!38 = !{!13, !13, !39}
!39 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!40 = !DISubprogram(name: "h", scope: !8, file: !8, line: 2, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13, !13}
!43 = !DISubprogram(name: "cq_phi", scope: !36, file: !36, line: 73, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{null, !39}
!46 = !DISubprogram(name: "cq_measure_si32", scope: !36, file: !36, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !48, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !53)
!48 = !DISubroutineType(types: !49)
!49 = !{!13, !13, !50}
!50 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !51, size: 64)
!51 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !52, size: 64)
!52 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!53 = !{!54, !55}
!54 = !DILocalVariable(name: "argc", arg: 1, scope: !47, file: !8, line: 13, type: !13)
!55 = !DILocalVariable(name: "argv", arg: 2, scope: !47, file: !8, line: 13, type: !50)
!56 = !DILocation(line: 0, scope: !47)
!57 = !DILocation(line: 13, column: 53, scope: !47)
!58 = !{!59, !59, i64 0}
!59 = !{!"any pointer", !60, i64 0}
!60 = !{!"omnipotent char", !61, i64 0}
!61 = !{!"Simple C/C++ TBAA"}
!62 = !DILocation(line: 13, column: 48, scope: !47)
!63 = !DILocation(line: 13, column: 42, scope: !47)
!64 = !DILocation(line: 13, column: 63, scope: !47)
!65 = !DILocation(line: 13, column: 35, scope: !47)
!66 = !DISubprogram(name: "atoi", scope: !67, file: !67, line: 155, type: !68, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!67 = !DIFile(filename: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/_stdlib.h", directory: "", checksumkind: CSK_MD5, checksum: "3d0c06785d9f6367bf8af617fa81283d")
!68 = !DISubroutineType(types: !69)
!69 = !{!13, !70}
!70 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !71, size: 64)
!71 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !52)
