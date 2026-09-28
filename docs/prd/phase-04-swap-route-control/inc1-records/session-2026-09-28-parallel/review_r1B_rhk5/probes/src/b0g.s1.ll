; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 %0, !17, !DIExpression(), !23)
  %2 = and i32 %0, 7, !dbg !24
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #5, !dbg !24
    #dbg_value(i32 %3, !18, !DIExpression(), !23)
  %4 = mul nsw i32 %3, 3, !dbg !25
    #dbg_value(i32 %4, !19, !DIExpression(), !23)
  %5 = xor i32 %4, %3, !dbg !26
    #dbg_value(i32 %5, !20, !DIExpression(), !23)
  %6 = tail call i32 @h(i32 noundef %0, i32 noundef %3) #5, !dbg !27
    #dbg_value(i32 %6, !21, !DIExpression(), !23)
  %7 = icmp eq i32 %5, 10, !dbg !28
  br i1 %7, label %8, label %9, !dbg !30

8:                                                ; preds = %1
  tail call void @cq_phi(double noundef 3.141590e+00) #5, !dbg !31
  br label %9, !dbg !31

9:                                                ; preds = %8, %1
  %10 = tail call i32 @cq_measure_si32(i32 noundef %6) #5, !dbg !32
    #dbg_value(i32 %10, !22, !DIExpression(), !23)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #5, !dbg !33
    #dbg_value(i32 %11, !18, !DIExpression(), !23)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #5, !dbg !34
  %13 = add nsw i32 %12, %10, !dbg !35
  ret i32 %13, !dbg !36
}

declare !dbg !37 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !42 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !45 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 !dbg !46 {
    #dbg_value(i32 %0, !53, !DIExpression(), !55)
    #dbg_value(ptr %1, !54, !DIExpression(), !55)
  %3 = getelementptr inbounds i8, ptr %1, i64 8, !dbg !56
  %4 = load ptr, ptr %3, align 8, !dbg !56, !tbaa !57
  %5 = tail call i32 @atoi(ptr nocapture noundef %4), !dbg !61
  %6 = tail call i32 @slice(i32 noundef %5), !dbg !62
  %7 = and i32 %6, 1, !dbg !63
  ret i32 %7, !dbg !64
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare !dbg !65 i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 !dbg !71 {
    #dbg_value(i32 %0, !75, !DIExpression(), !77)
    #dbg_value(i32 %1, !76, !DIExpression(), !77)
  %3 = add nsw i32 %1, 1, !dbg !78
  ret i32 %3, !dbg !79
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.dbg.cu = !{!0, !2}
!llvm.ident = !{!4, !4}
!llvm.module.flags = !{!5, !6, !7, !8, !9, !10, !11}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!1 = !DIFile(filename: "b0.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r1B_rhk5/probes/src", checksumkind: CSK_MD5, checksum: "6f1be7448111d6fbe3219cc610381f6b")
!2 = distinct !DICompileUnit(language: DW_LANG_C11, file: !3, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!3 = !DIFile(filename: "b0.lib.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r1B_rhk5/probes/src", checksumkind: CSK_MD5, checksum: "2a4bd99bc8fe3c947e7fd846fb7d645d")
!4 = !{!"Homebrew clang version 19.1.7"}
!5 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!6 = !{i32 7, !"Dwarf Version", i32 5}
!7 = !{i32 2, !"Debug Info Version", i32 3}
!8 = !{i32 1, !"wchar_size", i32 4}
!9 = !{i32 8, !"PIC Level", i32 2}
!10 = !{i32 7, !"uwtable", i32 2}
!11 = !{i32 7, !"frame-pointer", i32 2}
!12 = distinct !DISubprogram(name: "slice", scope: !1, file: !1, line: 3, type: !13, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15, !15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19, !20, !21, !22}
!17 = !DILocalVariable(name: "m", arg: 1, scope: !12, file: !1, line: 3, type: !15)
!18 = !DILocalVariable(name: "q", scope: !12, file: !1, line: 4, type: !15)
!19 = !DILocalVariable(name: "p", scope: !12, file: !1, line: 5, type: !15)
!20 = !DILocalVariable(name: "u", scope: !12, file: !1, line: 6, type: !15)
!21 = !DILocalVariable(name: "s", scope: !12, file: !1, line: 7, type: !15)
!22 = !DILocalVariable(name: "ms", scope: !12, file: !1, line: 9, type: !15)
!23 = !DILocation(line: 0, scope: !12)
!24 = !DILocation(line: 4, column: 11, scope: !12)
!25 = !DILocation(line: 5, column: 13, scope: !12)
!26 = !DILocation(line: 6, column: 13, scope: !12)
!27 = !DILocation(line: 7, column: 11, scope: !12)
!28 = !DILocation(line: 8, column: 9, scope: !29)
!29 = distinct !DILexicalBlock(scope: !12, file: !1, line: 8, column: 7)
!30 = !DILocation(line: 8, column: 7, scope: !12)
!31 = !DILocation(line: 8, column: 16, scope: !29)
!32 = !DILocation(line: 9, column: 12, scope: !12)
!33 = !DILocation(line: 10, column: 7, scope: !12)
!34 = !DILocation(line: 11, column: 15, scope: !12)
!35 = !DILocation(line: 11, column: 13, scope: !12)
!36 = !DILocation(line: 11, column: 3, scope: !12)
!37 = !DISubprogram(name: "cq_theta_si32", scope: !38, file: !38, line: 38, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!39 = !DISubroutineType(types: !40)
!40 = !{!15, !15, !41}
!41 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!42 = !DISubprogram(name: "cq_phi", scope: !38, file: !38, line: 73, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{null, !41}
!45 = !DISubprogram(name: "cq_measure_si32", scope: !38, file: !38, line: 83, type: !13, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 13, type: !47, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !52)
!47 = !DISubroutineType(types: !48)
!48 = !{!15, !15, !49}
!49 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !50, size: 64)
!50 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !51, size: 64)
!51 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!52 = !{!53, !54}
!53 = !DILocalVariable(name: "argc", arg: 1, scope: !46, file: !1, line: 13, type: !15)
!54 = !DILocalVariable(name: "argv", arg: 2, scope: !46, file: !1, line: 13, type: !49)
!55 = !DILocation(line: 0, scope: !46)
!56 = !DILocation(line: 13, column: 53, scope: !46)
!57 = !{!58, !58, i64 0}
!58 = !{!"any pointer", !59, i64 0}
!59 = !{!"omnipotent char", !60, i64 0}
!60 = !{!"Simple C/C++ TBAA"}
!61 = !DILocation(line: 13, column: 48, scope: !46)
!62 = !DILocation(line: 13, column: 42, scope: !46)
!63 = !DILocation(line: 13, column: 63, scope: !46)
!64 = !DILocation(line: 13, column: 35, scope: !46)
!65 = !DISubprogram(name: "atoi", scope: !66, file: !66, line: 155, type: !67, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!66 = !DIFile(filename: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/_stdlib.h", directory: "", checksumkind: CSK_MD5, checksum: "3d0c06785d9f6367bf8af617fa81283d")
!67 = !DISubroutineType(types: !68)
!68 = !{!15, !69}
!69 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !70, size: 64)
!70 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !51)
!71 = distinct !DISubprogram(name: "h", scope: !3, file: !3, line: 1, type: !72, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !74)
!72 = !DISubroutineType(types: !73)
!73 = !{!15, !15, !15}
!74 = !{!75, !76}
!75 = !DILocalVariable(name: "a", arg: 1, scope: !71, file: !3, line: 1, type: !15)
!76 = !DILocalVariable(name: "k", arg: 2, scope: !71, file: !3, line: 1, type: !15)
!77 = !DILocation(line: 0, scope: !71)
!78 = !DILocation(line: 1, column: 41, scope: !71)
!79 = !DILocation(line: 1, column: 32, scope: !71)
