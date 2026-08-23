/* slice_libm_real_nexttowardl.c — bd 3c6m.67: census cell nexttowardl.f80.
 *
 * *** THIS CELL IS `nextafterl`. *** openlibm defines no separate body for it:
 * `src/s_nextafterl.c:80` ends with
 *
 *     openlibm_strong_reference(nextafterl, nexttowardl);
 *
 * so `nexttowardl` is an ALIAS SYMBOL onto the identical machine code. The
 * vendored body below is therefore byte-identical to
 * `slice_libm_real_nextafterl.c`, renamed at the entry point only, and the two
 * goldens are expected to differ in nothing but nothing at all — they are the
 * same gate stream. That is the honest modelling of the alias: the census scores
 * two CELLS because `math.h` declares two names, and both resolve to one body.
 * (bd `census-module-asm-set-alias` records the general gotcha — a
 * strong_reference emits the public name only from the definer's TU.)
 *
 * It declined, and now lowers, for exactly the reason recorded in
 * `slice_libm_real_nextafterl.c`: the ulp-direction test at src/s_nextafterl.c:55
 * is `if((x>0.0) ^ (x<y))`, an `xor i1` of two tainted compares in branch-
 * condition position, admitted to the condition-tree grammar by bd 3c6m.67.
 * Read that file's header for the full account; it is not repeated here.
 *
 * Mechanical edits ONLY, identical to the nextafterl slice, plus the entry
 * rename to `olm_nexttowardl`.
 */
#include <stdint.h>

/* src/amd64_fpmath.h — verbatim (x86-64 long double = x86_fp80). */
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
#define	mask_nbit_l(u)	((u).bits.manh &= ~LDBL_NBIT)

__attribute__((always_inline)) static inline long double olm_nexttowardl(long double x, long double y)
{
	volatile long double t;
	union IEEEl2bits ux, uy;

	ux.e = x;
	uy.e = y;

	if ((ux.bits.exp == 0x7fff &&
	     ((ux.bits.manh&~LDBL_NBIT)|ux.bits.manl) != 0) ||
	    (uy.bits.exp == 0x7fff &&
	     ((uy.bits.manh&~LDBL_NBIT)|uy.bits.manl) != 0))
	   return x+y;	/* x or y is nan */
	if(x==y) return y;		/* x=y, return y */
	if(x==0.0) {
	    ux.bits.manh = 0;			/* return +-minsubnormal */
	    ux.bits.manl = 1;
	    ux.bits.sign = uy.bits.sign;
	    t = ux.e*ux.e;
	    if(t==ux.e) return t; else return ux.e; /* raise underflow flag */
	}
	if((x>0.0) ^ (x<y)) {			/* x -= ulp */
	    if(ux.bits.manl==0) {
		if ((ux.bits.manh&~LDBL_NBIT)==0)
		    ux.bits.exp -= 1;
		ux.bits.manh = (ux.bits.manh - 1) | (ux.bits.manh & LDBL_NBIT);
	    }
	    ux.bits.manl -= 1;
	} else {				/* x += ulp */
	    ux.bits.manl += 1;
	    if(ux.bits.manl==0) {
		ux.bits.manh = (ux.bits.manh + 1) | (ux.bits.manh & LDBL_NBIT);
		if ((ux.bits.manh&~LDBL_NBIT)==0)
		    ux.bits.exp += 1;
	    }
	}
	if(ux.bits.exp==0x7fff) return x+x;	/* overflow  */
	if(ux.bits.exp==0) {			/* underflow */
	    mask_nbit_l(ux);
	    t = ux.e * ux.e;
	    if(t!=ux.e)			/* raise underflow flag */
		return ux.e;
	}
	return ux.e;
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_nexttowardl(q, 0.5L));
}
int main(void) { (void) slice(); return 0; }
