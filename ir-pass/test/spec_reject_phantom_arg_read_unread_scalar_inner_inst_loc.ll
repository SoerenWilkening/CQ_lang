; spec_reject_phantom_arg_read_unread_scalar_inner_inst_loc.ll — DECLINE, and its SOURCE LOCATION pinned (bd
; test_C_libtooling-nlfd's `buildClone` fence; Rule-13 r2 F-r2-1, probe `loc1_fence_dbg.ll`, verbatim;
; IR-only).
;
; `spec_reject_phantom_arg_read_unread_scalar_inner_inst.ll`'s program with `!dbg` on `h`: the
; `t = a * 5` at `fence.c:5:11` and the call `h2(t, k)` at `fence.c:6:22`. The fence reports the
; FIRST CALL with an argument operand live under `SlotReads::Existence` and dead under
; `SlotReads::Value` — the frontier of the same two liveness answers that decide the verdict (r1A
; F-r1A-4). The other decline fixtures carry no `!dbg`, so their `in function …` CHECK accepts
; `<unknown>:0:0`: a mutant that never sets the location, or picks the instruction (5:11) instead of
; the call, left lit green. This file pins `6:22`. ⚠ Since bd rhk5 the fence is an IR-only
; over-decline (bd test_C_libtooling-ur72, OPEN); retiring it retires this file with it.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: fence.c:6:22: in function __cq_q_h_01 {{.*}}: cq specialization: quantum argument to a parameter the lifted callee never reads

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 noundef %m7, double noundef 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %r = call i32 @h(i32 noundef %p, i32 noundef %m)
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %ph, label %j
ph:
  call void @cq_phi(double noundef 3.141590e+00)
  br label %j
j:
  %q2 = call i32 @cq_theta_si32(i32 noundef %q, double noundef 0x3FE6666666666666)
  %z = call i32 @cq_measure_si32(i32 noundef %q2)
  %zr = call i32 @cq_measure_si32(i32 noundef %r)
  %s = add nsw i32 %z, %zr
  ret i32 %s
}

define i32 @h(i32 noundef %a, i32 noundef %k) !dbg !10 {
e:
  %t = mul nsw i32 %a, 5, !dbg !12
  %r = tail call i32 @h2(i32 noundef %t, i32 noundef %k), !dbg !13
  ret i32 %r
}

define i32 @h2(i32 noundef "cq.probe.opaque" %x, i32 noundef %k) noinline {
e:
  %c = icmp sgt i32 %x, 3
  br i1 %c, label %t, label %f
t:
  br label %f
f:
  %r = add nsw i32 %k, 1
  ret i32 %r
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2}
!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "p", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "fence.c", directory: "/tmp")
!2 = !{i32 2, !"Debug Info Version", i32 3}
!10 = distinct !DISubprogram(name: "h", scope: !1, file: !1, line: 3, type: !11, scopeLine: 3, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!11 = !DISubroutineType(types: !{})
!12 = !DILocation(line: 5, column: 11, scope: !10)
!13 = !DILocation(line: 6, column: 22, scope: !10)
!14 = !DILocation(line: 4, column: 9, scope: !10)
