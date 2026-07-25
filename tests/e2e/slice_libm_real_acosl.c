/* slice_libm_real_acosl.c — bd 3c6m.60 (real-openlibm VERIFIED promotion of the
   ld80 census cell acosl.f80, which census-COMPILES post the keep-set harness
   fix): the REAL openlibm acosl body over x86_fp80 `long double`.
   FreeBSD/fdlibm-derived (Sun/SunSoft e_acos.c, converted to long double by
   David Schultz), BSD-licensed.

   CORPUS FILES VENDORED (from the intact clone at /private/tmp/openlibm_reclone):
     - src/e_acosl.c        the acosl body itself, plus its file-scope
                            `one` and the non-i386 `pi` long-double constant.
     - ld80/invtrig.c       the shared inverse-trig coefficient tables: the
                            pS0..pS6 / qS1..qS5 scalars consumed by P and Q,
                            and the atanhi[4] / atanlo[4] tables that back the
                            pio2_hi / pio2_lo names.
     - ld80/invtrig.h       the BIAS and ACOS_CONST thresholds, the
                            pio2_hi = atanhi[3] and pio2_lo = atanlo[3] aliases,
                            and the P and Q Horner helpers.
     - src/amd64_fpmath.h   union IEEEl2bits (both the .bits and .xbits views)
                            and LDBL_NBIT.
   The atanhi / atanlo table block and the union IEEEl2bits block are reused
   BYTE-IDENTICALLY from the already-verified slice_libm_real_atanl.c, which
   vendors the same two corpus files for the same ld80 conventions.

   MECHANICAL EDITS ONLY (libm-real-slice-recipe; NO constant, branch, or
   expression changed — every literal was checked in order against the corpus):
     - include lines, the license and FBSDID header blocks, cdefs-compat, and
       the OLM_DLLEXPORT marker deleted.
     - the `#ifdef __i386__` pi workaround block deleted; x86-64 takes the
       `#else` arm, so `pi` is the single long-double constant verbatim.
     - the macro closure this body needs inlined as #defines carrying their
       real openlibm values: LDBL_NBIT from src/amd64_fpmath.h, LDBL_MAX_EXP
       from <float.h>, BIAS / ACOS_CONST / pio2_hi / pio2_lo from
       ld80/invtrig.h. The other invtrig.h thresholds (ASIN_LINEAR, ATAN_*,
       THRESH, MANH_SIZE) belong to sibling entry points acosl never reads and
       are not vendored. The invtrig.h name-mangling defines that rewrite the
       body-visible pS/qS/atanhi/atanlo spellings onto the underscored library
       symbols are resolved away, so the tables carry their body-visible names.
     - the coefficient tables and scalars, extern `const` in the library, are
       made `static const` so the slice is self-contained; names unchanged (no
       collision arose, so no uniquifying was needed).
     - the public `acosl` entry renamed `olm_acosl`; it and the two invtrig.h
       helpers P and Q are marked `__attribute__((always_inline)) static inline`
       so plain -O1 collapses the closure to one straight-line body (the 20xt.2
       recipe lesson).
     - the sole library callee `sqrtl` written `__builtin_sqrtl`, at BOTH of its
       call sites: `sqrtl(z)` in the x < -0.5 arm and `sqrtl(z)` in the x > 0.5
       arm (2 corpus call sites -> 2 `__builtin_sqrtl(z)`, 1:1).
   The x86_fp80 union is kept VERBATIM — the promoteFp80Union pass owns it, and
   ld80 word access is never memcpy-shimmed (the 3c6m.51 ld80 convention).

   WHY __builtin_sqrtl IS NOT A BODY SUBSTITUTION: `sqrtl` is a Rule-18 HARDWARE
   KEEP. The census corpus was built with a blanket -fno-builtin, so the inner
   sqrtl resolved to openlibm's SOFTWARE square-root body and dragged its
   normalize loop into this cell. At the real ship floor — plain `clang -O1`,
   builtins ON — the named call folds to @llvm.sqrt.f80 BEFORE codegen and
   cq-lowering rewrites it to cq_template_sqrt_f80. A keep has no injectable
   body by definition, so `__builtin_sqrtl` is exactly the construct the ship
   floor emits for the named call, not a stand-in for one. The emitted trace
   confirms this: cq_template_sqrt_f80 appears (twice — once per surviving
   sqrt arm), and no software-sqrt loop exists anywhere in the cell.

   LOWERING EXERCISED (observed in the lowered IR and the 222-line trace, not
   assumed):
     - the tainted fp80 argument is decomposed through the union IEEEl2bits
       .xbits.expsign / .bits.manh / .bits.manl views. SROA does NOT promote
       that union and this slice is NOT evidence that it does: stage-1 IR
       (plain `clang -O1`, before the plugin) still carries the union in
       MEMORY — exactly one `alloca %union.IEEEl2bits`, with every field access
       a load/store off it — because the offset-8 word straddles the fp80
       padding bytes [10,16) that SROA correctly refuses to invent. What
       registerizes it is CQ's OWN peephole, promoteFp80Union (bd 3c6m.51,
       ir-pass/src/Fp80Union.cpp, run inside cq-lowering), so the word extract
       lowers as an i80/i64/i32 bitcast-shift-truncate chain
       (cq_template_bitcast_f80_to_i80, lshr_i80_hl, trunc_i80_to_i16,
       zext_i16_to_i64, trunc_i64_to_i32, shl/ashr/and_i32_hl) — NOT a QRAM
       access: the lowered module contains zero cqrt_qram_* calls and zero
       allocas (stage-1 has exactly one). The golden is therefore an e2e
       exercise of promoteFp80Union, not of SROA.
     - the four-way classification cascade (|x| >= 1 NaN-or-exact / |x| < 0.5 /
       x < -0.5 / x > 0.5) becomes a tainted-word integer-compare ladder
       (icmp eq / ne / ule / ugt / uge / slt / sgt / sge over i32 _hl, each
       paired with its _inv strip) which PredMux flattens completely: @slice in
       the lowered module has no conditional branch, no phi, and no surviving
       `select` instruction — it is straight-line.
     - the fp80 arm results merge through the kjd1 fp-select controlled-copy
       family: 12 cqrt_copy_f80_controlled over 12 cqrt_alloc_i1 flag rails,
       with cqrt_x polarity brackets, cqrt_toffoli flag conjunctions, and
       cqrt_cnot routing.
     - the P and Q Horner polynomials ride the fp80 arithmetic templates —
       clang contracts them to @llvm.fmuladd.f80, which lowers to the
       cq_template_fma_f80 / _qql / _qll family (38 calls), alongside
       fmul/fadd/fsub/fdiv/fneg_f80 and their _hl/_lh mixed forms.
     - the `u.bits.manl = 0` mantissa truncation in the x > 0.5 arm likewise
       reaches cq-lowering as a MEMORY read-modify-write on that same alloca
       (`store x86_fp80` / `load i64` / `and i64 -4294967296` / `store i64` /
       `load x86_fp80`); promoteFp80Union's field-insert pack is what rewrites
       it into the register bit-mask form on the i80 pun (and_i80_hl /
       trunc_i80_to_i64 / and_i64_hl / lshr_i64_hl / zext_i64_to_i80 / or_i80 /
       bitcast_i80_to_f80).
     - `sqrtl` rides cq_template_sqrt_f80, exactly twice.
   The probe pins the census cell acosl.f80: x = theta-tainted. This slice is
   the LINK-layer proof (Rule 2) that every emitted symbol resolves and
   signature-matches and that the trace is stable and deterministic: exactly one
   cqrt_ry_f80 and exactly one cqrt_measure_f80 (Rule 5 — no compiler-inserted
   measurement), all 29 cqrt_free operands distinct (Rule 6/8 — no double free),
   the measured handle never freed, and two runs byte-identical. */
#include <stdint.h>

/* openlibm src/amd64_fpmath.h (verbatim — BOTH views; the fp80 pass owns the
   union, never memcpy-shim ld80 word access). */
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
    struct {
        unsigned long man     : 64;
        unsigned int  expsign : 16;
        unsigned long junk    : 48;
    } xbits;
};
#define LDBL_NBIT      0x80000000
#define LDBL_MAX_EXP   16384

/* openlibm ld80/invtrig.h thresholds (verbatim values). */
#define BIAS        (LDBL_MAX_EXP - 1)
#define ACOS_CONST  (BIAS - 65)    /* 2**-65 */

/* openlibm ld80/invtrig.c asinl()/acosl() coefficients (verbatim ld80 values). */
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

/* openlibm ld80/invtrig.c atanl() coefficient tables (verbatim ld80 values);
   acosl reads only element 3 of each, via the invtrig.h pio2_hi / pio2_lo
   aliases below. */
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

/* openlibm ld80/invtrig.h (verbatim). */
#define	pio2_hi	atanhi[3]
#define	pio2_lo	atanlo[3]

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

/* openlibm src/e_acosl.c acosl (verbatim; sqrtl -> __builtin_sqrtl). */
static const long double
one=  1.00000000000000000000e+00;

static const long double
pi =  3.14159265358979323846264338327950280e+00L;

__attribute__((always_inline)) static inline long double
olm_acosl(long double x)
{
	union IEEEl2bits u;
	long double z,p,q,r,w,s,c,df;
	int16_t expsign, expt;
	u.e = x;
	expsign = u.xbits.expsign;
	expt = expsign & 0x7fff;
	if(expt >= BIAS) {	/* |x| >= 1 */
	    if(expt==BIAS && ((u.bits.manh&~LDBL_NBIT)|u.bits.manl)==0) {
		if (expsign>0) return 0.0;	/* acos(1) = 0  */
		else return pi+2.0*pio2_lo;	/* acos(-1)= pi */
	    }
	    return (x-x)/(x-x);		/* acos(|x|>1) is NaN */
	}
	if(expt<BIAS-1) {	/* |x| < 0.5 */
	    if(expt<ACOS_CONST) return pio2_hi+pio2_lo;/*x tiny: acosl=pi/2*/
	    z = x*x;
	    p = P(z);
	    q = Q(z);
	    r = p/q;
	    return pio2_hi - (x - (pio2_lo-x*r));
	} else  if (expsign<0) {	/* x < -0.5 */
	    z = (one+x)*0.5;
	    p = P(z);
	    q = Q(z);
	    s = __builtin_sqrtl(z);
	    r = p/q;
	    w = r*s-pio2_lo;
	    return pi - 2.0*(s+w);
	} else {			/* x > 0.5 */
	    z = (one-x)*0.5;
	    s = __builtin_sqrtl(z);
	    u.e = s;
	    u.bits.manl = 0;
	    df = u.e;
	    c  = (z-df*df)/(s+df);
	    p = P(z);
	    q = Q(z);
	    r = p/q;
	    w = r*s+c;
	    return 2.0*(df+w);
	}
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_acosl(q));
}

int main(void) {
    (void) slice();
    return 0;
}
