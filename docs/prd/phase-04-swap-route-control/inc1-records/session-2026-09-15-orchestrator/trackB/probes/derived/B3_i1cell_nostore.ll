; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.NLDo95TvLa/s1.ll'
source_filename = "example/grover/grover_oracle_uncompute.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = alloca [3 x i8], align 1
    #dbg_value(i32 5, !15, !DIExpression(), !23)
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #3, !dbg !24
    #dbg_declare(ptr %1, !16, !DIExpression(), !25)
    #dbg_value(i32 0, !21, !DIExpression(), !26)
    #dbg_value(i32 5, !15, !DIExpression(), !23)
  br label %21, !dbg !27

2:                                                ; preds = %28
  %3 = load i8, ptr %1, align 1, !dbg !28, !tbaa !29, !range !33, !noundef !34
  %4 = trunc nuw i8 %3 to i1, !dbg !28
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #3, !dbg !28
  %6 = zext i1 %5 to i32, !dbg !28
  %7 = getelementptr inbounds i8, ptr %1, i64 1, !dbg !35
  %8 = load i8, ptr %7, align 1, !dbg !35, !tbaa !29, !range !33, !noundef !34
  %9 = trunc nuw i8 %8 to i1, !dbg !35
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9) #3, !dbg !35
  %11 = zext i1 %10 to i32, !dbg !35
  %12 = add nuw nsw i32 %11, %6, !dbg !36
  %13 = getelementptr inbounds i8, ptr %1, i64 2, !dbg !37
  %14 = load i8, ptr %13, align 1, !dbg !37, !tbaa !29, !range !33, !noundef !34
  %15 = trunc nuw i8 %14 to i1, !dbg !37
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15) #3, !dbg !37
  %17 = zext i1 %16 to i32, !dbg !37
  %18 = add nuw nsw i32 %12, %17, !dbg !38
  %19 = tail call i32 @cq_measure_si32(i32 noundef %31) #3, !dbg !39
  %20 = add nsw i32 %18, %19, !dbg !40
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #3, !dbg !41
  ret i32 %20, !dbg !42

21:                                               ; preds = %28, %0
  %22 = phi i64 [ 0, %0 ], [ %32, %28 ]
  %23 = phi i32 [ 5, %0 ], [ %31, %28 ]
    #dbg_value(i64 %22, !21, !DIExpression(), !26)
    #dbg_value(i32 %23, !15, !DIExpression(), !23)
  %24 = icmp sgt i32 %23, 2, !dbg !43
  br i1 %24, label %25, label %28, !dbg !47

25:                                               ; preds = %21
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3, !dbg !48
  br label %28, !dbg !51

28:                                               ; preds = %25, %21
  %cq.bank = phi i1 [ %26, %25 ], [ false, %21 ]
  %30 = add nsw i32 %23, -3
  %31 = select i1 %cq.bank, i32 %30, i32 %23, !dbg !54
    #dbg_value(i32 %31, !15, !DIExpression(), !23)
  %32 = add nuw nsw i64 %22, 1, !dbg !55
    #dbg_value(i64 %32, !21, !DIExpression(), !26)
  %33 = icmp eq i64 %32, 3, !dbg !56
  br i1 %33, label %2, label %21, !dbg !27, !llvm.loop !57
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !61 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare !dbg !66 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

declare !dbg !69 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!8 = !DIFile(filename: "example/grover/grover_oracle_uncompute.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "34b6744f028f8e5faabab83a616be848")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 86, type: !11, scopeLine: 86, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !21}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 87, type: !13)
!16 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 88, type: !17)
!17 = !DICompositeType(tag: DW_TAG_array_type, baseType: !18, size: 24, elements: !19)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !{!20}
!20 = !DISubrange(count: 3)
!21 = !DILocalVariable(name: "i", scope: !22, file: !8, line: 90, type: !13)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 90, column: 5)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 88, column: 5, scope: !10)
!25 = !DILocation(line: 88, column: 10, scope: !10)
!26 = !DILocation(line: 0, scope: !22)
!27 = !DILocation(line: 90, column: 5, scope: !22)
!28 = !DILocation(line: 130, column: 12, scope: !10)
!29 = !{!30, !30, i64 0}
!30 = !{!"_Bool", !31, i64 0}
!31 = !{!"omnipotent char", !32, i64 0}
!32 = !{!"Simple C/C++ TBAA"}
!33 = !{i8 0, i8 2}
!34 = !{}
!35 = !DILocation(line: 130, column: 32, scope: !10)
!36 = !DILocation(line: 130, column: 30, scope: !10)
!37 = !DILocation(line: 130, column: 53, scope: !10)
!38 = !DILocation(line: 130, column: 51, scope: !10)
!39 = !DILocation(line: 130, column: 73, scope: !10)
!40 = !DILocation(line: 130, column: 71, scope: !10)
!41 = !DILocation(line: 131, column: 1, scope: !10)
!42 = !DILocation(line: 130, column: 5, scope: !10)
!43 = !DILocation(line: 91, column: 15, scope: !44)
!44 = distinct !DILexicalBlock(scope: !45, file: !8, line: 91, column: 13)
!45 = distinct !DILexicalBlock(scope: !46, file: !8, line: 90, column: 33)
!46 = distinct !DILexicalBlock(scope: !22, file: !8, line: 90, column: 5)
!47 = !DILocation(line: 91, column: 13, scope: !45)
!48 = !DILocation(line: 92, column: 21, scope: !49)
!49 = distinct !DILexicalBlock(scope: !44, file: !8, line: 91, column: 20)
!50 = !DILocation(line: 92, column: 19, scope: !49)
!51 = !DILocation(line: 93, column: 9, scope: !49)
!52 = !DILocation(line: 94, column: 13, scope: !53)
!53 = distinct !DILexicalBlock(scope: !45, file: !8, line: 94, column: 13)
!54 = !DILocation(line: 94, column: 13, scope: !45)
!55 = !DILocation(line: 90, column: 28, scope: !46)
!56 = !DILocation(line: 90, column: 23, scope: !46)
!57 = distinct !{!57, !27, !58, !59, !60}
!58 = !DILocation(line: 95, column: 5, scope: !22)
!59 = !{!"llvm.loop.mustprogress"}
!60 = !{!"llvm.loop.unroll.disable"}
!61 = !DISubprogram(name: "cq_theta_i1", scope: !62, file: !62, line: 32, type: !63, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!62 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!63 = !DISubroutineType(types: !64)
!64 = !{!18, !18, !65}
!65 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!66 = !DISubprogram(name: "cq_measure_i1", scope: !62, file: !62, line: 77, type: !67, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!67 = !DISubroutineType(types: !68)
!68 = !{!18, !18}
!69 = !DISubprogram(name: "cq_measure_si32", scope: !62, file: !62, line: 83, type: !70, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!70 = !DISubroutineType(types: !71)
!71 = !{!13, !13}

