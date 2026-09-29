; ModuleID = 'b0g.s1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 %0, !17, !DIExpression(), !23)
  %2 = and i32 %0, 7, !dbg !24
  %h = call i32 @cqrt_alloc_i32(i32 %2), !dbg !24
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !24
    #dbg_value(i32 %h, !18, !DIExpression(), !23)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3), !dbg !25
    #dbg_value(i32 %h_op, !19, !DIExpression(), !23)
  %h_op1 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op), !dbg !26
    #dbg_value(i32 %h_op1, !20, !DIExpression(), !23)
  %3 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h) #5, !dbg !27
    #dbg_value(i32 %3, !21, !DIExpression(), !23)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10), !dbg !28
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !dbg !30, !cq.branchphase !31
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10), !dbg !28
  call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op), !dbg !26
  call void @cqrt_free(i32 %h_op1), !dbg !26
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3), !dbg !25
  call void @cqrt_free(i32 %h_op), !dbg !25
  call void @cqrt_free(i32 %h_cmp), !dbg !30
  %m = call i32 @cqrt_measure_i32(i32 %3), !dbg !32
    #dbg_value(i32 %m, !22, !DIExpression(), !23)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666), !dbg !33
    #dbg_value(i32 %h, !18, !DIExpression(), !23)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !34
  %4 = add nsw i32 %m2, %m, !dbg !35
  ret i32 %4, !dbg !36
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #1 !dbg !37 {
    #dbg_value(i32 %0, !44, !DIExpression(), !46)
    #dbg_value(ptr %1, !45, !DIExpression(), !46)
  %3 = getelementptr inbounds i8, ptr %1, i64 8, !dbg !47
  %4 = load ptr, ptr %3, align 8, !dbg !47, !tbaa !48
  %5 = tail call i32 @atoi(ptr nocapture noundef %4), !dbg !52
  %6 = tail call i32 @slice(i32 noundef %5), !dbg !53
  %7 = and i32 %6, 1, !dbg !54
  ret i32 %7, !dbg !55
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare !dbg !56 i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 !dbg !62 {
    #dbg_value(i32 %0, !66, !DIExpression(), !68)
    #dbg_value(i32 %1, !67, !DIExpression(), !68)
  %3 = add nsw i32 %1, 1, !dbg !69
  ret i32 %3, !dbg !70
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_h_10(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 !dbg !71 {
    #dbg_value(i32 %0, !73, !DIExpression(), !75)
    #dbg_value(i32 %1, !74, !DIExpression(), !75)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %1, i32 1), !dbg !76
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0), !dbg !77
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out), !dbg !77
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %1, i32 1), !dbg !76
  call void @cqrt_free(i32 %h_op), !dbg !77
  ret i32 %cqq.out, !dbg !77
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_xor_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_xor_i32_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!30 = !DILocation(line: 8, column: 16, scope: !29)
!31 = !{}
!32 = !DILocation(line: 9, column: 12, scope: !12)
!33 = !DILocation(line: 10, column: 7, scope: !12)
!34 = !DILocation(line: 11, column: 15, scope: !12)
!35 = !DILocation(line: 11, column: 13, scope: !12)
!36 = !DILocation(line: 11, column: 3, scope: !12)
!37 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 13, type: !38, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !43)
!38 = !DISubroutineType(types: !39)
!39 = !{!15, !15, !40}
!40 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !41, size: 64)
!41 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !42, size: 64)
!42 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!43 = !{!44, !45}
!44 = !DILocalVariable(name: "argc", arg: 1, scope: !37, file: !1, line: 13, type: !15)
!45 = !DILocalVariable(name: "argv", arg: 2, scope: !37, file: !1, line: 13, type: !40)
!46 = !DILocation(line: 0, scope: !37)
!47 = !DILocation(line: 13, column: 53, scope: !37)
!48 = !{!49, !49, i64 0}
!49 = !{!"any pointer", !50, i64 0}
!50 = !{!"omnipotent char", !51, i64 0}
!51 = !{!"Simple C/C++ TBAA"}
!52 = !DILocation(line: 13, column: 48, scope: !37)
!53 = !DILocation(line: 13, column: 42, scope: !37)
!54 = !DILocation(line: 13, column: 63, scope: !37)
!55 = !DILocation(line: 13, column: 35, scope: !37)
!56 = !DISubprogram(name: "atoi", scope: !57, file: !57, line: 155, type: !58, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DIFile(filename: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/_stdlib.h", directory: "", checksumkind: CSK_MD5, checksum: "3d0c06785d9f6367bf8af617fa81283d")
!58 = !DISubroutineType(types: !59)
!59 = !{!15, !60}
!60 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !61, size: 64)
!61 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !42)
!62 = distinct !DISubprogram(name: "h", scope: !3, file: !3, line: 1, type: !63, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !65)
!63 = !DISubroutineType(types: !64)
!64 = !{!15, !15, !15}
!65 = !{!66, !67}
!66 = !DILocalVariable(name: "a", arg: 1, scope: !62, file: !3, line: 1, type: !15)
!67 = !DILocalVariable(name: "k", arg: 2, scope: !62, file: !3, line: 1, type: !15)
!68 = !DILocation(line: 0, scope: !62)
!69 = !DILocation(line: 1, column: 41, scope: !62)
!70 = !DILocation(line: 1, column: 32, scope: !62)
!71 = distinct !DISubprogram(name: "h", scope: !3, file: !3, line: 1, type: !63, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !72)
!72 = !{!73, !74}
!73 = !DILocalVariable(name: "a", arg: 1, scope: !71, file: !3, line: 1, type: !15)
!74 = !DILocalVariable(name: "k", arg: 2, scope: !71, file: !3, line: 1, type: !15)
!75 = !DILocation(line: 0, scope: !71)
!76 = !DILocation(line: 1, column: 41, scope: !71)
!77 = !DILocation(line: 1, column: 32, scope: !71)
