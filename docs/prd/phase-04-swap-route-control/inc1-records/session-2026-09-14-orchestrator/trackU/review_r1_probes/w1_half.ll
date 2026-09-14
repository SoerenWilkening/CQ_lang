; the ninth reachable width, `half`, which no fixture pins.
target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"
declare half @cq_theta_f16(half, double)
declare half @cq_measure_f16(half)
define half @example() {
entry:
  %q = call half @cq_theta_f16(half undef, double 5.000000e-01)
  %m = call half @cq_measure_f16(half %q)
  ret half %m
}
