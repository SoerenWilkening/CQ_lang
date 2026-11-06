; tests/loops-cutoff probe (CR rules 8, 26), written as IR: musl fmal's shape, reduced from its sweep input.
; gc_cover: block %no's classical factor is `!c1 || !c2`, c2 tested only where c1 holds, and the walk reaches it from the
; other path too: its guard reads c2 only in the cube where c1 holds.
; gc_sret: an sret callee that carries the environment (rule 23), called under a quantum predicate: its _ctl clone returns
; a value, so sret is dropped from it.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.dd = type { i64, i64, i64 }

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) strictfp
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) strictfp

define i32 @gc_cover(i32 %x0, i32 %c1, i32 %c2, i32 %c3, double %th) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %a = icmp sgt i32 %c1, 1
  br i1 %a, label %second, label %no

second:
  %b = icmp sgt i32 %c2, 1
  br i1 %b, label %yes, label %no

no:
  %mno = call i32 @cq_measure_si32(i32 %x)
  ret i32 %mno

yes:
  %bit0 = and i32 %x, 1
  %q0 = icmp eq i32 %bit0, 0
  br i1 %q0, label %early, label %next

next:
  %bit1 = and i32 %x, 2
  %q1 = icmp eq i32 %bit1, 0
  br i1 %q1, label %early, label %last

early:
  %v1 = add i32 %x, 1
  %m1 = call i32 @cq_measure_si32(i32 %v1)
  ret i32 %m1

last:
  %t = icmp eq i32 %c3, 0
  br i1 %t, label %r2, label %r3

r3:
  %v3 = add i32 %x, 3
  %m3 = call i32 @cq_measure_si32(i32 %v3)
  ret i32 %m3

r2:
  %v2 = add i32 %x, 2
  %m2 = call i32 @cq_measure_si32(i32 %v2)
  ret i32 %m2
}

define internal void @mk(ptr noalias sret(%struct.dd) align 8 %out, i32 %v) noinline strictfp {
  %f = call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %v, metadata !"round.dynamic", metadata !"fpexcept.strict") strictfp
  %i = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %f, metadata !"fpexcept.strict") strictfp
  %w = sext i32 %i to i64
  store i64 %w, ptr %out, align 8
  %p1 = getelementptr inbounds i8, ptr %out, i64 8
  %w1 = add i64 %w, 1
  store i64 %w1, ptr %p1, align 8
  %p2 = getelementptr inbounds i8, ptr %out, i64 16
  store i64 7, ptr %p2, align 8
  ret void
}

define i32 @gc_sret(i32 %x0, i32 %k, double %th) {
entry:
  %s = alloca %struct.dd, align 8
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  store i64 0, ptr %s, align 8
  %bit0 = and i32 %x, 1
  %q0 = icmp eq i32 %bit0, 0
  br i1 %q0, label %call, label %join

call:
  call void @mk(ptr sret(%struct.dd) align 8 %s, i32 %k)
  br label %join

join:
  %v = load i64, ptr %s, align 8
  %t = trunc i64 %v to i32
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
