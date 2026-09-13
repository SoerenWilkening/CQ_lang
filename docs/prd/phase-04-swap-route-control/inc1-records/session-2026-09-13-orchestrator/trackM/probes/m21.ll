; m21 — a tainted i1 `xor` as a select condition: no region claims it, so this is
; the shape a DEFERRED select would look like at `declineClassicalMuxes`.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %nt = xor i1 %t, true
  %sel = select i1 %nt, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
