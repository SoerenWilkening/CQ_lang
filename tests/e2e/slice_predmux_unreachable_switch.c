/* slice_predmux_unreachable_switch.c — bd 20xt.5 (d) e2e smoke: the PredMux
   unreachable-tolerance capability driven through the full clang -O1 → opt
   cq-lowering → link → run pipeline (the only layer that LINKS, Rule 2/16).

   SOURCE INTENT (the atan2l top-level shape, minimized): a tainted special-case
   branch nests an EXHAUSTIVE `switch` over a 2-bit pack whose default clang -O1
   proves dead and lowers to a shared `unreachable` block:

       q : tainted quantum handle (cq_theta == Ry)
       if (q > 100) r = q*2;                    // tainted special-case branch
       else switch (q & 3) {                    // exhaustive {0,1,2,3}
              case 0: r = q + 10;
              case 1: r = q * 5;
              case 2: r = q ^ 7;
              case 3: r = q - 4;
              default: __builtin_unreachable();  // -> default.unreachable block
            }
       measure r

   WHY (d) IS EXERCISED: LLVM's PostDominatorTree treats the `unreachable`
   default as a SECOND function exit alongside `ret`, so the special-case
   branch's immediate post-dominator is the VIRTUAL ROOT — PredMux's standard
   merge lookup bails and the whole nest declines as `nested control flow`. (d)
   recomputes the merge IGNORING the unreachable exit (pure analysis), so the
   nest flattens: the `unreachable` arm is a dead sink (UB — no basis state
   enters it, Rule 5), erased with NO merge-phi incoming and NO moved body; the
   reachable special + case edges become eq-flag controlled copies over the
   4.4 select-merge substrate.

   WHY THE TRACE IS DETERMINISTIC: the runtime is trace-only and the nest is
   flattened to straight-line code, so every emitted gate fires unconditionally
   regardless of q. The `& 3` pack keeps case 3 the sound chain FALLBACK (the
   unreachable default is never a merge incoming). r, q, and every eq-flag /
   out-rail are subject to the standard 4.4 select bookkeeping. cq_theta/
   cq_measure resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int q = 5;
    cq_theta(&q, 0.5);                 /* taint q -> handle (alloc, ry)          */
    int r;
    if (q > 100) {                     /* tainted special-case branch (region root) */
        r = q * 2;
    } else {
        switch (q & 3) {               /* exhaustive 2-bit switch, dead default   */
            case 0:  r = q + 10; break;
            case 1:  r = q * 5;  break;
            case 2:  r = q ^ 7;  break;
            case 3:  r = q - 4;  break;
            default: __builtin_unreachable();
        }
    }
    return cq_measure(r);              /* reads the flattened select-chain answer */
}
int main(void) { (void) slice(); return 0; }
