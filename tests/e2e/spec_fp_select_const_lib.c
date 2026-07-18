/* spec_fp_select_const_lib.c — the CLASSICAL library TU for the 20xt.3
   const/const fp-select golden. Compiles WITHOUT CQ.h (C18; the tripwire fails
   loudly if the harness force-includes it). `mhelper` is the atan2l -> inner
   `atanl` |x|>=2^64 overflow-arm shape: `z = (expsign<0) ? -pi/2 : +pi/2`
   (s_atanl.c block %20), a CONST/CONST fp80 select returned directly (so clang
   -O1 keeps `select(icmp slt n,0, x86_fp80 const, x86_fp80 const)` rather than
   sinking an fptosi and const-folding the fp away). The synthetic ±const stands
   in for ±pi/2. The specializer lifts mhelper to __cq_q_mhelper_1; the 20xt.3
   widening materializes EACH ConstantFP arm to its own `cqrt_alloc_f80(<const>)`
   |const> rail (LEFT allocated, leaked, Rule 6) and controlled-copies it into the
   |0> out rail; the fp80 return copies out (uncontrolled `cqrt_copy_f80`, 3c6m.54)
   and the Bennett wrap reverse-plays the copies + flag and frees the two tainted
   rails on |0>. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

long double mhelper(int n) {
    return (n < 0) ? -1.5L : 2.5L;   /* const/const fp80 select — atanl ±const arm */
}
