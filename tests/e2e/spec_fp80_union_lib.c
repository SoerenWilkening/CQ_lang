/* spec_fp80_union_lib.c — the CLASSICAL library TU for the bd vqlq e2e golden
   (fp80-union RMW inside a Phase-6 specialized callee). Like the other spec
   libs it MUST compile WITHOUT the CQ.h intrinsic surface (C18 —
   run_slice_multi.sh applies `-include CQ.h` to the CQ TU only); the tripwire
   fails LOUDLY if the harness ever force-includes CQ.h into a lib TU.

   `qpack` is int(int) — the x86_fp80 exists ONLY as an internal bit-pattern
   intermediate: seed via `(long double)a` (sitofp of the to-be-quantum
   param), an offset-8 exponent field-insert (`u.bits.exp = a & 0x7fff`), and
   a LIVE reload consumed by fp80 arithmetic back down to int. At -O1 the
   union stays in MEMORY (the offset-8 word straddles the padding [10,16));
   the vqlq argument-derived OPPORTUNISTIC seed lets promoteFp80Union rewrite
   the body to register form BEFORE detectSpecializations, and the vqlq
   scanBody value-bitcast carve admits the promoted `bitcast f80<->i80`
   relabels (Rule-14 mirror of castInScope). The driver then clones
   @__cq_q_qpack_1, seeds the param taint, and the Bennett wrap reverse-plays
   the ENTIRE i80 write surface — the `_unc` family fires inside a specialized
   callee (bd szpr's route (a), delivered by vqlq). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

union IEEEl2bits {
    long double e;
    struct {
        unsigned int manl : 32;
        unsigned int manh : 32;
        unsigned int exp  : 15;
        unsigned int sign : 1;
        unsigned int junkl : 16;
        unsigned int junkh : 32;
    } bits;
};

int qpack(int a) {
    union IEEEl2bits u;
    u.e = (long double)a;    /* fp80 seed from the to-be-quantum int param */
    u.bits.exp = a & 0x7fff; /* offset-8 field-insert (the i80 write surface) */
    return (int)(u.e * 4.0L);/* LIVE reload of the packed fp80 -> int out */
}
