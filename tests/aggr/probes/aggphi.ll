; tests/aggr probes (cq-03rdt), written by hand: an aggregate phi (rule 26, Plugin.cpp scalarizeAggregatePhis) whose
; predecessor is listed twice (two switch cases into one block). The per-field phis take one extract per predecessor
; block: LLVM requires the same incoming value for a block listed twice.
;  - a_switch: classical switch, a struct phi with a quantum field
;  - a_qswitch: the same switch on a quantum value
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%P = type { i32, i32 }

define i32 @a_switch(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %p0 = insertvalue %P poison, i32 %x, 0
  %p = insertvalue %P %p0, i32 %2, 1
  switch i32 %2, label %other [
    i32 1, label %join
    i32 2, label %join
  ]

other:
  %y = add i32 %x, 5
  %q0 = insertvalue %P poison, i32 %2, 0
  %q = insertvalue %P %q0, i32 %y, 1
  br label %join

join:
  %r = phi %P [ %p, %3 ], [ %p, %3 ], [ %q, %other ]
  %a = extractvalue %P %r, 0
  %b = extractvalue %P %r, 1
  %ab = xor i32 %a, %b
  %m = tail call i32 @cq_measure_ui32(i32 noundef %ab)
  ret i32 %m
}

define i32 @a_qswitch(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %k = and i32 %x, 3
  %p0 = insertvalue %P poison, i32 %x, 0
  %p = insertvalue %P %p0, i32 %2, 1
  switch i32 %k, label %other [
    i32 1, label %join
    i32 2, label %join
  ]

other:
  %y = add i32 %x, 5
  %q0 = insertvalue %P poison, i32 %2, 0
  %q = insertvalue %P %q0, i32 %y, 1
  br label %join

join:
  %r = phi %P [ %p, %3 ], [ %p, %3 ], [ %q, %other ]
  %a = extractvalue %P %r, 0
  %b = extractvalue %P %r, 1
  %ab = xor i32 %a, %b
  %m = tail call i32 @cq_measure_ui32(i32 noundef %ab)
  ret i32 %m
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef)
declare i32 @cq_measure_ui32(i32 noundef)
