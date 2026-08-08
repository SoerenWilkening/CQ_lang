/* predmux_purecallee_i80cmp_lib.c — bd 3c6m.14.1, the LIB translation unit.

   The pure callee whose ONLY off-grid instruction is an x86_fp80 BIT-PATTERN
   compare: openlibm's `union IEEEl2bits` two-word mantissa test, the shape
   `hypotl` uses for its Inf/NaN case

       GET_LDBL_MAN(manh, manl, a);
       if (manh == LDBL_NBIT && manl == 0) ...

   which `clang -O1` SROAs and fuses into

       %b = bitcast x86_fp80 %a to i80
       %m = and i80 %b, 0xFFFF'FFFF'FFFF'FFFF
       %e = icmp eq i80 %m, 0x8000'0000'0000'0000

   MEASURED, so it cannot silently rot: that IS the -O1 output for this body on
   this host, and `icmp eq` is essentially the ONLY i80 compare real C produces
   — an ordered predicate on the mantissa compiles to an i64 compare, and the
   `!=`/`||` spelling canonicalizes back to `icmp eq` with the branch inverted.
   The nine other i80 predicates are reachable from hand-written IR only.
   HONEST STATE OF THAT COVERAGE (a Rule-13 lens censused it after an earlier
   draft here claimed they "are pinned"): across the whole fixture tree only two
   i80 predicates appear at all — `eq`, and one `ult` in
   control_predmux_accept_i80_cmp_const_left.ll, which belongs to the bd 3c6m.61
   ARM surface, not to any surface this increment widens. Eight of the nine are
   pinned nowhere. All ten ship with `_hl`/`_inv`/`_unc` rows (verified against
   tools/opcode_table.yaml and the built libcq_templates.a), and the shared
   `lowerCompareImpl` is predicate-generic, so this is a coverage gap rather than
   a known defect — but it should be stated as a gap, not as coverage.

   This TU is compiled WITHOUT -include CQ.h and llvm-linked with the caller, so
   `leafl` reaches cq-lowering OUTLINED — which is the whole point. Inlined, the
   compare would be an ordinary arm-resident one (bd 3c6m.61's shipped surface)
   and this slice would prove nothing new.

   The union is kept VERBATIM in the openlibm bit layout (3c6m.51 ld80
   convention: promoteFp80Union owns fp80 unions, never a memcpy word shim). */

union IEEEl2bits {
    long double e;
    struct {
        unsigned int manl :32;
        unsigned int manh :32;
        unsigned int exp  :15;
        unsigned int sign :1;
        unsigned int junk :16;
    } bits;
};
#define LDBL_NBIT 0x80000000u

/* Pure, acyclic, total, non-varargs, exact definition, template-width result —
   every clause of the pending-specialization pure-callee proof holds, and from
   bd 3c6m.14.1 the i80 `_hl` compare no longer disqualifies it. */
long double leafl(long double a)
{
    union IEEEl2bits u;
    u.e = a;
    if (u.bits.manh == LDBL_NBIT && u.bits.manl == 0u)
        return a;
    return 1.0L;
}
