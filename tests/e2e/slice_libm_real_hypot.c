/* slice_libm_real_hypot.c — bd 3c6m.60: the REAL openlibm hypot body.

   CORPUS VENDORED (one file, the whole closure):
     /private/tmp/openlibm_reclone/src/e_hypot.c — __ieee754_hypot(x,y), the
     entire algorithm (exponent-word ordering/swap, the 2**60 ratio early-out,
     the Inf/NaN arm, the 2**-600 / 2**600 / 2**1022 rescalings, the two
     extended-precision sqrt forms, and the k-exponent rescale of the result).
     There is no other openlibm .c in the closure: after the keep-set rewrite
     below, e_hypot.c calls nothing but hardware keeps.

   MECHANICAL EDITS (declared; no algorithmic change — every constant, branch,
   comparison and expression is byte-for-byte the corpus text):
     - deleted, in corpus order: the SCCS/license header block (corpus lines
       2-12), the 4 include lines (cdefs-compat.h line 14, float.h line 49,
       openlibm_math.h line 50, math_private.h line 52), the //__FBSDID comment
       (line 15), the Method / Special cases / Accuracy algorithm comment
       (lines 17-47), the OLM_DLLEXPORT storage marker (line 54), and the
       trailing LDBL_MANT_DIG == 53 weak-reference block (lines 129-131;
       x86-64 long double has 64 mantissa bits, so that block does not apply
       here). Every one of these is comment, include, storage-class or
       not-taken-preprocessor text; none removes an executable statement.
     - entry point __ieee754_hypot renamed to olm_hypot and marked
       always_inline static inline (forces the census inline shape at plain -O1,
       collapsing the closure into ONE FUNCTION — recipe lesson bd 20xt.2). It
       is NOT straight-line at that point: pre-pass @slice still has 16 basic
       blocks and 15 br (8 of them conditional). The straight line is produced
       later, by the pass's PredMuxFlatten stage; the lowered @slice retains
       exactly 1 br, an unconditional edge into the measure block.
     - the math_private.h word macros GET_HIGH_WORD / GET_LOW_WORD /
       SET_HIGH_WORD expanded to the __builtin_memcpy 8-byte-pun shim that
       clang -O1 folds to the same bitcast IR (same idiom as the acos/atan
       slices). All 3 GET_HIGH_WORD, 3 GET_LOW_WORD and 9 SET_HIGH_WORD sites
       are expanded in place, in source order, preserving the value read/written
       (a SET expansion is the macro's read-modify-write pair, so it is 2
       memcpys: 24 memcpys in the body total). The macro-local union temp is
       replaced by one function-scope `uint64_t bits`; every expansion is a
       self-contained read-then-write with no intervening use, so that sharing
       is semantically identical.
     - the BSD type spelling u_int32_t replaced by uint32_t (stdint.h); no
       other type changed. There are no file-scope static const tables in
       e_hypot.c, so there are no coefficient literals to carry over.

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution):
     e_hypot.c calls fabs (4 sites: fabs(a), fabs(b), and the two in the
     NaN-quieting w = fabs(x+0.0) - fabs(y+0.0)) and sqrt (2 sites, one per
     branch of the medium-size split). Both are HARDWARE KEEPS: at the real
     ship floor (plain clang -O1, builtins ON) the named calls fold to
     @llvm.fabs.f64 / @llvm.sqrt.f64 before codegen, and cq-lowering rewrites
     those to cq_template_fabs_f64 / cq_template_sqrt_f64. The __builtin_fabs /
     __builtin_sqrt spellings emit exactly that construct and need no libm
     declaration. By definition a keep has no injectable body, so vendoring
     openlibm's software e_sqrt.c/s_fabs.c here would MISREPRESENT the ship
     floor — that blanket -fno-builtin resolution is the census bug this
     ticket fixes.

   LOWERING EXERCISED (all figures below MEASURED on the lowered IR / trace,
   not asserted): a tainted-x / classical-y (0.5) hypot. The magnitude ordering
   `if(hb > ha) {a=y;b=x;...}` is a tainted-condition swap of two fp registers,
   and the rescale cascade (2**500 / 2**-500 / subnormal) plus the `w > b`
   medium-size split are nested tainted classifications — all of it flattens
   through PredMux onto the select substrate: 32 cqrt_copy_f64_controlled + 20
   cqrt_copy_i32_controlled merges, 222 cqrt_toffoli flag conjunctions, and
   fcmp/icmp templates each paired with their _inv strip. The SET_HIGH_WORD
   sites become bitcast/shift/mask template chains after SROA. Every llvm.*
   construct clang -O1 hands the pass is lowered 1:1, nothing dropped:
   3 llvm.fabs.f64 -> 3 cq_template_fabs_f64, 1 llvm.sqrt.f64 -> 1
   cq_template_sqrt_f64, 5 llvm.fmuladd.f64 -> 5 cq_template_fma_f64 (clang's
   default fp-contract fuses the extended-precision products; fma/fmuladd is
   likewise a Rule-18 keep).
   Those template counts sit BELOW the 4 fabs / 2 sqrt SOURCE sites for two
   different -O1 reasons, NEITHER of which is an arm the pass dropped:
     - fabs 4 -> 3: the classical-y site fabs(y+0.0) const-folds away, because
       y is the literal 0.5 (it is absorbed into the -5.000000e-01 addend).
       The other three fabs sites survive.
     - sqrt 2 -> 1: SimplifyCFG TAIL-MERGED the two identical sqrt calls into
       their common successor and applied the one surviving call to the merge
       phi. BOTH arms of the `w > b` medium-size split SURVIVE -O1 intact and
       BOTH are lowered — the true (w > b) arm carries 2 of the fmuladds and
       the else arm carries the other 3, which is exactly the 5 fma templates
       counted above. NO branch of the medium-size split was resolved or
       folded away.
   Two further keeps in the trace come from clang, not from the corpus text:
   clang -O1 synthesizes llvm.umax.i32 / llvm.umin.i32 out of the source's own
   `if(hb > ha) {a=y;b=x;...}` magnitude swap (legal because both words are
   pre-masked with 0x7fffffff, so signed and unsigned compare alike), and they
   lower to 1 cq_template_umax_i32_hl + 1 cq_template_umin_i32_hl. Those are
   clang canonicalizations of stock C comparisons, NOT a library body swapped
   in by a name recognizer — Rule 18 is not in play for them.
   The lowered module has ZERO residual cq_* intrinsic calls and ZERO llvm.*
   CALL SITES — but 5 now-unused `declare @llvm.*` lines do survive in the
   lowered module with no uses, so a bare grep for @llvm. is not a refutation
   of that claim. This slice is the LINK-layer proof (Rule 2) that every emitted
   symbol resolves, signature-matches, and the trace is stable. */
#include <stdint.h>

/* openlibm src/e_hypot.c __ieee754_hypot (verbatim; word macros expanded to the
   __builtin_memcpy shim, fabs/sqrt spelled as the hardware-keep builtins). */
__attribute__((always_inline)) static inline double olm_hypot(double x, double y)
{
	double a,b,t1,t2,y1,y2,w;
	int32_t j,k,ha,hb;
	uint64_t bits;

	__builtin_memcpy(&bits, &x, 8);			/* GET_HIGH_WORD(ha,x) */
	ha = (int32_t)(bits >> 32);
	ha &= 0x7fffffff;
	__builtin_memcpy(&bits, &y, 8);			/* GET_HIGH_WORD(hb,y) */
	hb = (int32_t)(bits >> 32);
	hb &= 0x7fffffff;
	if(hb > ha) {a=y;b=x;j=ha; ha=hb;hb=j;} else {a=x;b=y;}
	a = __builtin_fabs(a);
	b = __builtin_fabs(b);
	if((ha-hb)>0x3c00000) {return a+b;} /* x/y > 2**60 */
	k=0;
	if(ha > 0x5f300000) {	/* a>2**500 */
	   if(ha >= 0x7ff00000) {	/* Inf or NaN */
	       uint32_t low;
	       /* Use original arg order iff result is NaN; quieten sNaNs. */
	       w = __builtin_fabs(x+0.0)-__builtin_fabs(y+0.0);
	       __builtin_memcpy(&bits, &a, 8);		/* GET_LOW_WORD(low,a) */
	       low = (uint32_t)bits;
	       if(((ha&0xfffff)|low)==0) w = a;
	       __builtin_memcpy(&bits, &b, 8);		/* GET_LOW_WORD(low,b) */
	       low = (uint32_t)bits;
	       if(((hb^0x7ff00000)|low)==0) w = b;
	       return w;
	   }
	   /* scale a and b by 2**-600 */
	   ha -= 0x25800000; hb -= 0x25800000;	k += 600;
	   __builtin_memcpy(&bits, &a, 8);		/* SET_HIGH_WORD(a,ha) */
	   bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)ha << 32);
	   __builtin_memcpy(&a, &bits, 8);
	   __builtin_memcpy(&bits, &b, 8);		/* SET_HIGH_WORD(b,hb) */
	   bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)hb << 32);
	   __builtin_memcpy(&b, &bits, 8);
	}
	if(hb < 0x20b00000) {	/* b < 2**-500 */
	    if(hb <= 0x000fffff) {	/* subnormal b or 0 */
	        uint32_t low;
		__builtin_memcpy(&bits, &b, 8);		/* GET_LOW_WORD(low,b) */
		low = (uint32_t)bits;
		if((hb|low)==0) return a;
		t1=0;
		__builtin_memcpy(&bits, &t1, 8);	/* SET_HIGH_WORD(t1,0x7fd00000) */
		bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)0x7fd00000 << 32);
		__builtin_memcpy(&t1, &bits, 8);	/* t1=2^1022 */
		b *= t1;
		a *= t1;
		k -= 1022;
	    } else {		/* scale a and b by 2^600 */
	        ha += 0x25800000; 	/* a *= 2^600 */
		hb += 0x25800000;	/* b *= 2^600 */
		k -= 600;
		__builtin_memcpy(&bits, &a, 8);		/* SET_HIGH_WORD(a,ha) */
		bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)ha << 32);
		__builtin_memcpy(&a, &bits, 8);
		__builtin_memcpy(&bits, &b, 8);		/* SET_HIGH_WORD(b,hb) */
		bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)hb << 32);
		__builtin_memcpy(&b, &bits, 8);
	    }
	}
    /* medium size a and b */
	w = a-b;
	if (w>b) {
	    t1 = 0;
	    __builtin_memcpy(&bits, &t1, 8);		/* SET_HIGH_WORD(t1,ha) */
	    bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)ha << 32);
	    __builtin_memcpy(&t1, &bits, 8);
	    t2 = a-t1;
	    w  = __builtin_sqrt(t1*t1-(b*(-b)-t2*(a+t1)));
	} else {
	    a  = a+a;
	    y1 = 0;
	    __builtin_memcpy(&bits, &y1, 8);		/* SET_HIGH_WORD(y1,hb) */
	    bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)hb << 32);
	    __builtin_memcpy(&y1, &bits, 8);
	    y2 = b - y1;
	    t1 = 0;
	    __builtin_memcpy(&bits, &t1, 8);		/* SET_HIGH_WORD(t1,ha+0x00100000) */
	    bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)(ha+0x00100000) << 32);
	    __builtin_memcpy(&t1, &bits, 8);
	    t2 = a - t1;
	    w  = __builtin_sqrt(t1*y1-(w*(-w)-(t1*y2+t2*b)));
	}
	if(k!=0) {
	    uint32_t high;
	    t1 = 1.0;
	    __builtin_memcpy(&bits, &t1, 8);		/* GET_HIGH_WORD(high,t1) */
	    high = (uint32_t)(bits >> 32);
	    __builtin_memcpy(&bits, &t1, 8);		/* SET_HIGH_WORD(t1,high+(k<<20)) */
	    bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)(high+(k<<20)) << 32);
	    __builtin_memcpy(&t1, &bits, 8);
	    return t1*w;
	} else return w;
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_hypot(q, 0.5));
}
int main(void) { (void) slice(); return 0; }
