; W2 — THE CONJUNCT/PLACEMENT MISMATCH, BUILT.
;
; Clause (ii-d) checks `loopExitDischargePoint(L)` for the loop it is MARKING;
; `Uncomputation::anchorForConsumer` places the discharge at
; `loopExitDischargePoint(LOut)`, where LOut is the OUTERMOST loop enclosing the
; consumer that does not contain the mint.  IN A NEST THOSE ARE DIFFERENT LOOPS.
;
; Here the hoisted template rail `%m2 = mul i32 %q, 2` is minted OUTSIDE THE WHOLE
; NEST and read only by the INNER body.  The inner loop has a unique exit
; (`%outerlatch`), so (ii-d) grants and records an obligation.  The OUTER loop has
; TWO exit destinations (`%bailout` from the header, `%out` from the latch), so
; `getUniqueExitBlock()` is null, `anchorForConsumer` returns nullptr and the
; component is abandoned -- while conjunct (1) of `declineDephasingUnmarkedLoopRails`
; has ALREADY been silenced by the marking.  `%y` is rotated at `%out`, so a leak
; here is a Rule-8 coherent which-path record at an interference, not a mere leak.
;
; tu9q's own IMPL_T3 §3 F-R2-1 records that the genuinely MULTI-EXIT path "is owed a
; fixture and has none: three C shapes were built for it and `-O1` renormalised or
; declined every one ... a PREDICTION rather than a test".  This is that fixture.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y = call i32 @cq_theta_si32(i32 7, double 3.000000e-01)
  %m2 = mul i32 %q, 2
  br label %outer

outer:
  %o = phi i32 [ 0, %entry ], [ %o2, %outerlatch ]
  %acc = phi i32 [ 0, %entry ], [ %acc3, %outerlatch ]
  %bail = icmp eq i32 %o, %n
  br i1 %bail, label %bailout, label %inner

inner:
  %k = phi i32 [ 1, %outer ], [ %k2, %inner ]
  %acc2 = phi i32 [ %acc, %outer ], [ %s2, %inner ]
  %sh = lshr i32 %y, %k
  %an = and i32 %sh, %m2
  %ms = call i32 @cq_measure_si32(i32 %an)
  %s2 = add i32 %ms, %acc2
  %k2 = add i32 %k, 1
  %e = icmp eq i32 %k2, 3
  br i1 %e, label %outerlatch, label %inner

outerlatch:
  %acc3 = phi i32 [ %s2, %inner ]
  %o2 = add i32 %o, 1
  %done = icmp eq i32 %o2, 3
  br i1 %done, label %out, label %outer

bailout:
  br label %out

out:
  %accf = phi i32 [ %acc3, %outerlatch ], [ %acc, %bailout ]
  %y2 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %y2)
  %t = add i32 %accf, %mm
  ret i32 %t
}
