/* slice_libm_real_asinl.c — bd 3c6m.60: the REAL openlibm asinl body over
   x86_fp80 `long double`, minted to turn the census-COMPILES cell asinl.f80 into
   a VERIFIED one (Rule 2 — census-compiles is not evidence; the linked golden
   trace is).

   CORPUS FILES VENDORED (from the intact clone /private/tmp/openlibm_reclone):
     - src/e_asinl.c        — the asinl() algorithm itself (fdlibm-derived via
                              e_asin.c, converted to long double by David
                              Schultz; BSD-licensed). Contributes the whole body
                              plus its two file-scope statics `one` and `huge`.
     - ld80/invtrig.h       — the BIAS / MANH_SIZE / ASIN_LINEAR / THRESH
                              thresholds, the pio2_hi / pio2_lo / pio4_hi
                              aliases onto atanhi[3] / atanlo[3] / atanhi[1],
                              and the P() / Q() Horner helpers.
     - ld80/invtrig.c       — the shared inverse-trig coefficient tables:
                              pS0..pS6, qS1..qS5 (the P/Q numerator/denominator)
                              and atanhi[4] / atanlo[4] (which is where asinl's
                              pio2_hi / pio2_lo / pio4_hi actually live).
                              The same file's aT[13] and pi_lo are atanl-only and
                              are NOT referenced by asinl, so they are omitted.
     - src/amd64_fpmath.h   — union IEEEl2bits (both the .bits and the .xbits
                              views; asinl uses BOTH) plus LDBL_NBIT and
                              LDBL_MANH_SIZE.
   LDBL_MAX_EXP (16384) is the x86-64 <float.h> value, inlined as a #define
   because no libm/float header may be included here.

   MECHANICAL EDITS DECLARED (libm-real-slice-recipe; NO constant, branch, or
   expression was changed — every coefficient literal was checked individually,
   in order, against ld80/invtrig.c):
     - deleted the include lines, the license / FBSDID header blocks, and the
       OLM_DLLEXPORT marker;
     - the public entry `asinl` renamed `olm_asinl`; it and the two vendored
       helpers P / Q are marked `__attribute__((always_inline)) static inline`,
       which reproduces the census inline shape at plain -O1 and collapses the
       closure to one straight-line body (recipe lesson, bd 20xt.2);
     - the invtrig.h `_ItL_*` table-name indirection is resolved, so the tables
       carry the names the body actually reads (pS0.., qS1.., atanhi, atanlo),
       and the tables are made `static const` (single translation unit);
     - the vendored macro closure is inlined as #defines carrying their real
       openlibm values (LDBL_NBIT / LDBL_MANH_SIZE from src/amd64_fpmath.h,
       LDBL_MAX_EXP from <float.h>, BIAS / MANH_SIZE / ASIN_LINEAR / THRESH and
       the pio2_hi / pio2_lo / pio4_hi aliases from ld80/invtrig.h);
     - NO memcpy word shim: the x86_fp80 `union IEEEl2bits` is kept VERBATIM,
       because the promoteFp80Union peephole owns ld80 word access (the 3c6m.51
       ld80 convention, same as slice_libm_real_atanl.c / erfl.c / fdiml.c).
       The f64/f32 GET_/SET_WORD memcpy idiom does not apply to this cell.
     - no static-const name collisions arose (only e_asinl.c contributes
       `one`/`huge`, and no vendored object is `volatile`);
     - trailing whitespace was stripped from 4 lines of the e_asinl.c body (2
       diff hunks). A reverse-rename diff of the vendored body against
       src/e_asinl.c:33-77 shows those 4 [[:space:]]*$ hunks and NOTHING else;
       the other 9 vendored regions are byte-identical to the corpus.

   KEEP-SET CALLS (Rule 18 — the ship-floor fold, NOT a body substitution):
   asinl's only two library-looking inner calls are `fabsl(x)` and `sqrtl(t)`.
   Both are HARDWARE KEEPS: at the real ship floor (plain `clang -O1`, builtins
   ON) each folds to `@llvm.fabs.f80` / `@llvm.sqrt.f80` BEFORE codegen and
   cq-lowering rewrites it to cq_template_fabs_f80 / cq_template_sqrt_f80. They
   have no injectable body by definition, so they are written `__builtin_fabsl`
   / `__builtin_sqrtl` — the identical construct the named call produces, with
   no libm declaration needed. This is exactly the harness bug bd 3c6m.60 fixes:
   the old census built the corpus with a blanket -fno-builtin, so `sqrtl`
   resolved to openlibm's SOFTWARE body and dragged its loops into this cell.
   Every other name in the closure (P, Q, the tables) is vendored real source.

   LOWERING EXERCISED: the tainted fp80 argument is decomposed through the
   union's `xbits.expsign` (16-bit) AND `bits.manh` / `bits.manl` (32-bit) views
   — two different promoteFp80Union extract shapes over the same value; the
   |x|>=1 / |x|<0.5 / |x| close-to-1 classification cascade flattens through
   PredMux onto the select substrate carried by the kjd1 fp-select controlled-
   copy family (cqrt_copy_f80_controlled); the P/Q Horner polynomials ride the
   fp80 arithmetic/fma templates; `u.e = s; u.bits.manl = 0; w = u.e;` is an
   fp80 union read-modify-write rather than a pure extract, and lowers to a
   register-level FIELD INSERT (and_i64_hl + and_i80_hl + zext_i64_to_i80 +
   or_i80 + bitcast_i80_to_f80); and both keep-intrinsics appear as
   cq_template_fabs_f80 / cq_template_sqrt_f80. All coefficient reads are
   CONSTANT-index (pio2_hi = atanhi[3], pio2_lo = atanlo[3], pio4_hi =
   atanhi[1]) so they const-fold — there is no tainted-index QROM read here,
   unlike atanl (0 cqrt_qram_* in the golden).

   NO MEMORY SURVIVES: promoteFp80Union canonicalizes the union access and hands
   the fresh alloca to LLVM's PromoteMemToReg, so the lowered IR contains ZERO
   alloca / load / store. This cell therefore exercises the 3c6m.51 fp80-union
   i80 peephole ONLY — it does NOT exercise a surviving Shadow store/load and
   does NOT touch the 7.5 QRAM Shadow memory model. Do not read the union RMW
   above as evidence for either.

   GOLDEN LIMITATION (pre-existing runtime printer, not a defect in this slice):
   runtime/cq_templates.c prints an i80 classical operand with %lld of an
   __int128, so the i80 field-insert mask — correctly `i80
   -18446744073709551616` in the lowered IR, i.e. clear the low 64 mantissa
   bits and keep exponent+sign — prints in the golden as
   `cq_template_and_i80_hl(h40, 0)`. THIS GOLDEN CANNOT DISTINGUISH A CORRECT
   i80 MASK FROM A ZERO MASK; that one constant is verifiable only in the
   lowered IR, never in the trace. The companion `and_i64_hl(h41,
   -4294967296)` — the actual `u.bits.manl = 0` — prints correctly, and the
   only other i80 literal in this module, `lshr_i80_hl(h1, 64)`, fits in 64
   bits and so also prints correctly. The truncation is a property of the
   printer, not of this cell: it blinds every golden to the bits above 63 of
   any i80 classical operand.

   This slice is the LINK-layer proof (Rule 2) that every emitted symbol
   resolves and signature-matches and that the trace is stable + deterministic.
   The probe pins the census cell asinl.f80: x = theta-tainted. */
#include <stdint.h>

/* openlibm src/amd64_fpmath.h (verbatim — BOTH views; the fp80 pass owns the
   union, never a memcpy word shim). */
union IEEEl2bits {
	long double	e;
	struct {
		unsigned int	manl	:32;
		unsigned int	manh	:32;
		unsigned int	exp	:15;
		unsigned int	sign	:1;
		unsigned int	junkl	:16;
		unsigned int	junkh	:32;
	} bits;
	struct {
		unsigned long	man	:64;
		unsigned int	expsign	:16;
		unsigned long	junk	:48;
	} xbits;
};
#define	LDBL_NBIT	0x80000000
#define	LDBL_MANH_SIZE	32
#define	LDBL_MAX_EXP	16384

/* openlibm ld80/invtrig.h thresholds (verbatim). */
#define	BIAS		(LDBL_MAX_EXP - 1)
#define	MANH_SIZE	LDBL_MANH_SIZE

/* Approximation thresholds. */
#define	ASIN_LINEAR	(BIAS - 32)	/* 2**-32 */

/* 0.95 */
#define	THRESH	((0xe666666666666666ULL>>(64-(MANH_SIZE-1)))|LDBL_NBIT)

/* openlibm ld80/invtrig.c — asinl()/acosl() coefficients (verbatim ld80
   values). aT[] and pi_lo from the same file are atanl-only and unused here. */
static const long double
pS0 =  1.66666666666666666631e-01L,
pS1 = -4.16313987993683104320e-01L,
pS2 =  3.69068046323246813704e-01L,
pS3 = -1.36213932016738603108e-01L,
pS4 =  1.78324189708471965733e-02L,
pS5 = -2.19216428382605211588e-04L,
pS6 = -7.10526623669075243183e-06L,
qS1 = -2.94788392796209867269e+00L,
qS2 =  3.27309890266528636716e+00L,
qS3 = -1.68285799854822427013e+00L,
qS4 =  3.90699412641738801874e-01L,
qS5 = -3.14365703596053263322e-02L;

static const long double atanhi[] = {
	 4.63647609000806116202e-01L,
	 7.85398163397448309628e-01L,
	 9.82793723247329067960e-01L,
	 1.57079632679489661926e+00L,
};

static const long double atanlo[] = {
	 1.18469937025062860669e-20L,
	-1.25413940316708300586e-20L,
	 2.55232234165405176172e-20L,
	-2.50827880633416601173e-20L,
};

/* openlibm ld80/invtrig.h — the shared inverse-trig aliases (verbatim). */
#define	pio2_hi	atanhi[3]
#define	pio2_lo	atanlo[3]
#define	pio4_hi	atanhi[1]

/* openlibm ld80/invtrig.h P/Q (verbatim). */
__attribute__((always_inline)) static inline long double
P(long double x)
{

	return (x * (pS0 + x * (pS1 + x * (pS2 + x * (pS3 + x * \
		(pS4 + x * (pS5 + x * pS6)))))));
}

__attribute__((always_inline)) static inline long double
Q(long double x)
{

	return (1.0 + x * (qS1 + x * (qS2 + x * (qS3 + x * (qS4 + x * qS5)))));
}

/* openlibm src/e_asinl.c (verbatim; fabsl -> __builtin_fabsl, sqrtl ->
   __builtin_sqrtl — the same @llvm.fabs.f80 / @llvm.sqrt.f80 the ship floor
   emits for the named calls). */
static const long double
one =  1.00000000000000000000e+00,
huge = 1.000e+300;

__attribute__((always_inline)) static inline long double
olm_asinl(long double x)
{
	union IEEEl2bits u;
	long double t=0.0,w,p,q,c,r,s;
	int16_t expsign, expt;
	u.e = x;
	expsign = u.xbits.expsign;
	expt = expsign & 0x7fff;
	if(expt >= BIAS) {		/* |x|>= 1 */
		if(expt==BIAS && ((u.bits.manh&~LDBL_NBIT)|u.bits.manl)==0)
		    /* asin(1)=+-pi/2 with inexact */
		    return x*pio2_hi+x*pio2_lo;
	    return (x-x)/(x-x);		/* asin(|x|>1) is NaN */
	} else if (expt<BIAS-1) {	/* |x|<0.5 */
	    if(expt<ASIN_LINEAR) {	/* if |x| is small, asinl(x)=x */
		if(huge+x>one) return x;/* return x with inexact if x!=0*/
	    }
	    t = x*x;
	    p = P(t);
	    q = Q(t);
	    w = p/q;
	    return x+x*w;
	}
	/* 1> |x|>= 0.5 */
	w = one-__builtin_fabsl(x);
	t = w*0.5;
	p = P(t);
	q = Q(t);
	s = __builtin_sqrtl(t);
	if(u.bits.manh>=THRESH) { 	/* if |x| is close to 1 */
	    w = p/q;
	    t = pio2_hi-(2.0*(s+s*w)-pio2_lo);
	} else {
	    u.e = s;
	    u.bits.manl = 0;
	    w = u.e;
	    c  = (t-w*w)/(s+w);
	    r  = p/q;
	    p  = 2.0*s*r-(pio2_lo-2.0*c);
	    q  = pio4_hi-2.0*w;
	    t  = pio4_hi-(p-q);
	}
	if(expsign>0) return t; else return -t;
}

long double slice(void) {
    long double q = 0.5L; cq_theta(&q, 0.5);
    return cq_measure(olm_asinl(q));
}

int main(void) {
    (void) slice();
    return 0;
}
