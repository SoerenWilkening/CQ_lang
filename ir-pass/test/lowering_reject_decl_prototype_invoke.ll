; lowering_reject_decl_prototype_invoke.ll — DECLINE: a malformed-prototype
; reserved-name decl (@cq_theta_si32 declared WITHOUT its `double` angle param;
; CQ.h declares `int cq_theta_si32(int, double)`) reached ONLY via `invoke`,
; with NO plain-`call` user (test_C_libtooling-thd7).
;
; The decline itself is unchanged — a wrong-prototype reserved name declines
; LOUDLY at collection time (resolveSources → diagnoseMalformedDecl), and a
; malformed decl never enters the FnSets, so collectAndSeed's invoke guard
; (test_C_libtooling-rzs9) never even sees it. What thd7 fixes is DIAGNOSTIC
; PRECISION: diagnoseMalformedDecl walked F->users() with `dyn_cast<CallInst>`
; to pick a call site for the function context + `!dbg`. `dyn_cast<CallInst>`
; returns null on an InvokeInst, so an invoke-only malformed decl found no
; call-site user and fell to the decl-level overload (`DiagnosticInfoUnsupported`
; on F, no instruction `!dbg`) — STILL LOUD (opt exits non-zero), but rendering
; `<unknown>:0:0: in function cq_theta_si32 ...` instead of the offending call's
; source line. The CallInst→CallBase generalization (same one rzs9 applied to
; collectAndSeed / isMeasureSink) lets the invoke supply the function context
; (the CALLER `slice`) and the source-located `!dbg` (mal.c:7:9).
;
; This is diagnostic-hardening only, NOT a soundness fix: clang -O1 on
; exception-free C never emits `invoke` for an opaque extern, and a wrong
; PROTOTYPE is orthogonal to rzs9's wrong CALL-FORM — doubly unreachable in
; practice, but pinned here so the precision cannot silently regress.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32)                ; WRONG: must be i32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @__gxx_personality_v0(...)

define i32 @slice(i32 %u0) personality ptr @__gxx_personality_v0 !dbg !4 {
entry:
  %q = invoke i32 @cq_theta_si32(i32 %u0)
          to label %cont unwind label %lpad, !dbg !7   ; malformed decl, via invoke
cont:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
lpad:
  %ex = landingpad { ptr, i32 }
          cleanup
  ret i32 0
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "cq", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "mal.c", directory: "/tmp")
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = distinct !DISubprogram(name: "slice", scope: !1, file: !1, line: 1, type: !5, scopeLine: 1, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{null}
!7 = !DILocation(line: 7, column: 9, scope: !4)

; The diagnostic is now source-located at the invoke (mal.c:7:9) in the CALLER
; `slice`, not the decl-level `<unknown>:0:0: in function cq_theta_si32`.
; CHECK: mal.c:7:9:{{.*}}cq rotation lowering: unsupported declared prototype for cq_theta_si32
