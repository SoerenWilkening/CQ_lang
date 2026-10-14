; spec_accept_phantom_arg_read_exact_record_g1c.ll — ACCEPT, and the CLONE reads nothing the caller did not pass (bd
; test_C_libtooling-sqjq; bd vsfp Rule-13 r3A F-XA-2, probe `g1c`; hand-written IR).
;
; The callee's read of the dead slot is `-g`: the same chain with debug records. `buildClone` records the slot dead (no live root
; reads it) but round 3 left the dead instruction standing, so the clone's `lowerOps` lowered
; it: once the caller's slot was neutralised to `0`, the clone operated on runtime handle h0 —
; a register the caller never passed. Round 4 deletes the dead cone of every recorded-dead
; parameter right after taking the record (an inner clone call inherits the dead slot as a
; constant — `rewriteRecordedDeadSlotUse`, the one spelling of that rewrite). The CLONE prefix
; pins that `@__cq_q_h_*` contains no template call at all (and, for the nested probes, that the
; inner clone call passes `0` in the inherited dead slot); the main CHECKs pin the caller's
; stream (TRACE-IDENT with the hand-inlined twin, measured).
;
;
; bd p3kd.21 R11 r2 F1 (bd r2j3.35, 2026-10-15): `main` now MEASURES the value it
; returns. A register returned from `main` reaches the process exit status without
; `cq_measure`, which NORTHSTAR goal 1 forbids and the pass now refuses
; (spec_reject_gate_sub_main_return.ll); the measurement is outside this fixture's
; subject, which is unchanged.
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @atoi(ptr nocapture noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %{{[a-zA-Z0-9_.]+}}) #4
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_xor_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 10)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_rz_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 3.141590e+00), !dbg !44, !cq.branchphase !45
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 10)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_xor_i32_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_mul_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3FE6666666666666)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
; NODROP-NOT: CQ_DEADARG_DBG
;
; The clone body reads nothing the caller did not pass: no template call (bd sqjq):
; CLONE-LABEL: define {{.*}}@__cq_q_h_
; CLONE-NOT: cq_template_
; CLONE: ret 

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@K = internal global i32 7, align 4, !dbg !0

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 !dbg !17 {
    #dbg_value(i32 %0, !24, !DIExpression(), !31)
    #dbg_value(ptr %1, !25, !DIExpression(), !31)
  %3 = getelementptr inbounds i8, ptr %1, i64 8, !dbg !32
  %4 = load ptr, ptr %3, align 8, !dbg !32, !tbaa !33
  %5 = tail call i32 @atoi(ptr nocapture noundef %4), !dbg !37
    #dbg_value(i32 %5, !26, !DIExpression(), !31)
  %6 = and i32 %5, 7, !dbg !38
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #4, !dbg !38
    #dbg_value(i32 %7, !27, !DIExpression(), !31)
  %8 = mul nsw i32 %7, 3, !dbg !39
    #dbg_value(i32 %8, !28, !DIExpression(), !31)
  %9 = tail call i32 @h(i32 noundef %8, i32 noundef %5) #4, !dbg !40
    #dbg_value(i32 %9, !29, !DIExpression(), !31)
  %10 = xor i32 %8, %7, !dbg !41
    #dbg_value(i32 %10, !30, !DIExpression(), !31)
  %11 = icmp eq i32 %10, 10, !dbg !42
  br i1 %11, label %12, label %13, !dbg !44

12:                                               ; preds = %2
  tail call void @cq_phi(double noundef 3.141590e+00) #4, !dbg !45
  br label %13, !dbg !45

13:                                               ; preds = %12, %2
  %14 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 0x3FE6666666666666) #4, !dbg !46
    #dbg_value(i32 %14, !27, !DIExpression(), !31)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4, !dbg !47
  %16 = add nsw i32 %15, %9, !dbg !48
  %cq.main.m = call i32 @cq_measure_si32(i32 %16)
  ret i32 %cq.main.m, !dbg !49
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare !dbg !50 i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare !dbg !56 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare !dbg !61 void @cq_phi(double noundef) local_unnamed_addr #2

declare !dbg !64 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nounwind ssp willreturn memory(readwrite, argmem: none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 !dbg !67 {
    #dbg_value(i32 %0, !71, !DIExpression(), !73)
    #dbg_value(i32 %1, !72, !DIExpression(), !73)
  %dm = mul nsw i32 %0, 3, !dbg !74
    #dbg_value(i32 %dm, !71, !DIExpression(), !73)
  %3 = icmp sgt i32 %dm, 3, !dbg !74
  br i1 %3, label %4, label %6, !dbg !76

4:                                                ; preds = %2
  br label %6, !dbg !80

6:                                                ; preds = %4, %2
  %7 = add nsw i32 %1, 1, !dbg !81
  ret i32 %7, !dbg !82
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nounwind ssp willreturn memory(readwrite, argmem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.dbg.cu = !{!7, !2}
!llvm.ident = !{!9, !9}
!llvm.module.flags = !{!10, !11, !12, !13, !14, !15, !16}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "K", scope: !2, file: !3, line: 1, type: !5, isLocal: true, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C11, file: !3, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, globals: !4, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!3 = !DIFile(filename: "g1.lib.c", directory: "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r3A/probes", checksumkind: CSK_MD5, checksum: "5c9c082371a9304c0d86ba2a726b3834")
!4 = !{!0}
!5 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !6)
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "g1.c", directory: "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r3A/probes", checksumkind: CSK_MD5, checksum: "fe95cb5e399aa57b1ee4de89b8b60793")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!11 = !{i32 7, !"Dwarf Version", i32 5}
!12 = !{i32 2, !"Debug Info Version", i32 3}
!13 = !{i32 1, !"wchar_size", i32 4}
!14 = !{i32 8, !"PIC Level", i32 2}
!15 = !{i32 7, !"uwtable", i32 2}
!16 = !{i32 7, !"frame-pointer", i32 2}
!17 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !18, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !23)
!18 = !DISubroutineType(types: !19)
!19 = !{!6, !6, !20}
!20 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !21, size: 64)
!21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !22, size: 64)
!22 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!23 = !{!24, !25, !26, !27, !28, !29, !30}
!24 = !DILocalVariable(name: "c", arg: 1, scope: !17, file: !8, line: 3, type: !6)
!25 = !DILocalVariable(name: "v", arg: 2, scope: !17, file: !8, line: 3, type: !20)
!26 = !DILocalVariable(name: "m", scope: !17, file: !8, line: 3, type: !6)
!27 = !DILocalVariable(name: "q", scope: !17, file: !8, line: 3, type: !6)
!28 = !DILocalVariable(name: "p", scope: !17, file: !8, line: 3, type: !6)
!29 = !DILocalVariable(name: "r", scope: !17, file: !8, line: 3, type: !6)
!30 = !DILocalVariable(name: "u", scope: !17, file: !8, line: 3, type: !6)
!31 = !DILocation(line: 0, scope: !17)
!32 = !DILocation(line: 3, column: 42, scope: !17)
!33 = !{!34, !34, i64 0}
!34 = !{!"any pointer", !35, i64 0}
!35 = !{!"omnipotent char", !36, i64 0}
!36 = !{!"Simple C/C++ TBAA"}
!37 = !DILocation(line: 3, column: 37, scope: !17)
!38 = !DILocation(line: 3, column: 57, scope: !17)
!39 = !DILocation(line: 3, column: 88, scope: !17)
!40 = !DILocation(line: 3, column: 101, scope: !17)
!41 = !DILocation(line: 3, column: 120, scope: !17)
!42 = !DILocation(line: 3, column: 131, scope: !43)
!43 = distinct !DILexicalBlock(scope: !17, file: !8, line: 3, column: 129)
!44 = !DILocation(line: 3, column: 129, scope: !17)
!45 = !DILocation(line: 3, column: 138, scope: !43)
!46 = !DILocation(line: 3, column: 159, scope: !17)
!47 = !DILocation(line: 3, column: 187, scope: !17)
!48 = !DILocation(line: 3, column: 185, scope: !17)
!49 = !DILocation(line: 3, column: 176, scope: !17)
!50 = !DISubprogram(name: "atoi", scope: !51, file: !51, line: 155, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DIFile(filename: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/_stdlib.h", directory: "", checksumkind: CSK_MD5, checksum: "3d0c06785d9f6367bf8af617fa81283d")
!52 = !DISubroutineType(types: !53)
!53 = !{!6, !54}
!54 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !55, size: 64)
!55 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !22)
!56 = !DISubprogram(name: "cq_theta_si32", scope: !57, file: !57, line: 38, type: !58, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DIFile(filename: "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/include/CQ.h", directory: "", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!58 = !DISubroutineType(types: !59)
!59 = !{!6, !6, !60}
!60 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!61 = !DISubprogram(name: "cq_phi", scope: !57, file: !57, line: 73, type: !62, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!62 = !DISubroutineType(types: !63)
!63 = !{null, !60}
!64 = !DISubprogram(name: "cq_measure_si32", scope: !57, file: !57, line: 83, type: !65, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!65 = !DISubroutineType(types: !66)
!66 = !{!6, !6}
!67 = distinct !DISubprogram(name: "h", scope: !3, file: !3, line: 2, type: !68, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !70)
!68 = !DISubroutineType(types: !69)
!69 = !{!6, !6, !6}
!70 = !{!71, !72}
!71 = !DILocalVariable(name: "a", arg: 1, scope: !67, file: !3, line: 2, type: !6)
!72 = !DILocalVariable(name: "k", arg: 2, scope: !67, file: !3, line: 2, type: !6)
!73 = !DILocation(line: 0, scope: !67)
!74 = !DILocation(line: 2, column: 29, scope: !75)
!75 = distinct !DILexicalBlock(scope: !67, file: !3, line: 2, column: 27)
!76 = !DILocation(line: 2, column: 27, scope: !67)
!77 = !DILocation(line: 2, column: 40, scope: !75)
!78 = !{!79, !79, i64 0}
!79 = !{!"int", !35, i64 0}
!80 = !DILocation(line: 2, column: 34, scope: !75)
!81 = !DILocation(line: 2, column: 52, scope: !67)
!82 = !DILocation(line: 2, column: 43, scope: !67)
