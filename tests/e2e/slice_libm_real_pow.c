/* slice_libm_real_pow.c — bd 3c6m.60: the REAL openlibm pow body, vendored.

   Cell: pow   width: f64   return: double

   SCOPE CAVEAT UP FRONT: the probe passes the CLASSICAL constant 0.5 as y,
   which const-folds pow's entire numeric core away (measured: stage-1 IR has
   ZERO fmul and ZERO globals). This golden verifies the classification /
   merge skeleton and the link layer ONLY — it is NOT evidence about pow's
   arithmetic. See "WHAT THIS PROBE ACTUALLY REACHES" below before trusting it.

   Entry corpus file: /private/tmp/openlibm_reclone/src/e_pow.c
       contributes: the whole __ieee754_pow algorithm — corpus lines 65-313,
       249 lines: every file-scope static (bp[], dp_h[], dp_l[], zero, one,
       two, two53, huge, tiny, L1..L6, P1..P5, lg2, lg2_h, lg2_l, ovt, cp,
       cp_h, cp_l, ivln2, ivln2_h, ivln2_l) plus the full 216-line body
       (corpus lines 98-313). 317 is the corpus FILE length, not the
       vendored region.
   Dep corpus file:   /private/tmp/openlibm_reclone/src/s_scalbn.c
       contributes: olm_scalbn (the subnormal-output tail call at the end of
       pow). Copied from the already-verified
       tests/e2e/slice_libm_real_scalbn.c, which vendors s_scalbn.c.
   Dep corpus file:   /private/tmp/openlibm_reclone/src/s_copysign.c
       contributes: olm_copysign (called only from olm_scalbn). Also copied
       from slice_libm_real_scalbn.c.

   DECLARED MECHANICAL EDITS (and no others — this list is the faithfulness
   contract; every textual difference from the corpus is named here):
     - deleted the license/SMI header blocks, the FBSDID comment, the #include
       lines, OLM_DLLEXPORT, and the trailing LDBL_MANT_DIG weak-reference
       block (x86-64 long double has 64 mantissa bits, so that block is dead).
     - added `#include <stdint.h>` plus the two shim typedefs u_int32_t and
       u_int64_t that math_private.h/sys types would otherwise supply. Only
       u_int32_t is actually used by e_pow.c (the `lx,ly` declaration and the
       `((u_int32_t)hx>>31)-1` cast); the u_int64_t typedef is UNUSED here.
     - stripped trailing whitespace on 11 lines of the vendored e_pow.c
       region. After reversing the renames below and stripping trailing
       whitespace on both sides, the vendored region below (the `static const
       double` block through the closing brace of olm_pow) is BYTE-IDENTICAL
       to corpus e_pow.c lines 65-313 (measured, not asserted).
     - entry point __ieee754_pow renamed to olm_pow and marked
       always_inline static inline; likewise scalbn -> olm_scalbn and
       copysign -> olm_copysign, and the intra-body calls renamed to match.
       Force-inlining reproduces the census inline shape at plain -O1.
     - the math_private.h word macros (EXTRACT_WORDS / GET_HIGH_WORD /
       SET_HIGH_WORD / SET_LOW_WORD) are redefined below over the
       __builtin_memcpy 8-byte pun, which clang -O1 folds to the same
       bitcast/shift IR the taint pass lowers. This lets the olm_pow body
       stay textually verbatim. olm_scalbn/olm_copysign instead carry the
       already-verified inline-memcpy spelling of slice_libm_real_scalbn.c
       (the same mixed convention slice_libm_real_scalbln.c uses). That dep
       region is NOT byte-identical to slice_libm_real_scalbn.c: undoing the
       sn_ rename leaves 5 lines differing in interior whitespace only (the
       two static decls lost their column alignment, 3 trailing comments
       shifted left); `diff -w` between the two regions is EMPTY.
     - NAME UNIQUIFICATION: s_scalbn.c's file-scope `huge` and `tiny` collide
       with e_pow.c's `huge` and `tiny`, so the scalbn pair was renamed to
       sn_huge / sn_tiny (2 declarations + 7 references inside olm_scalbn).
       The initializers are identical in the two corpus files (1.0e+300 and
       1.0e-300), so the rename is a pure scoping edit with no value change.
       e_pow's own statics keep openlibm's names. two54/twom54/two53 do not
       collide.

   KEEP-SET CALLS (Rule 18): e_pow.c calls sqrt(x) (the y==0.5 fast path) and
   fabs(x). Both are Rule-18 KEEPS — NOT because openlibm lacks a body for
   them (it ships src/e_sqrt.c and src/s_fabs.c), but because they meet the
   two keep conditions: at plain clang -O1 the NAMED call folds to
   @llvm.sqrt.f64 / @llvm.fabs.f64 before codegen (the IR construct the pass
   sees), and Bennett.jl backs that construct. So they are spelled
   __builtin_sqrt / __builtin_fabs here. That is not a body substitution: the
   __builtin_ spelling emits the identical intrinsic the named call folds to
   and needs no libm declaration, and cq-lowering rewrites it to
   cq_template_sqrt_f64 / cq_template_fabs_f64. This cell is exactly the
   harness bug bd 3c6m.60 fixes: under the old blanket -fno-builtin corpus
   build the sqrt call could NOT fold to the intrinsic, so it bound to
   openlibm's SOFTWARE sqrt body (src/e_sqrt.c, whose __ieee754_sqrt
   math_private.h maps onto the public name `sqrt`) and dragged that body's
   subnormal-normalize loop into the cell. scalbn, by contrast, IS a library
   function under Rule 18 (it folds to no intrinsic), so its real source is
   vendored transitively (and its own copysign with it) — the closure is
   closed: no other call remains.

   PROBE (the mandated census convention): arg0 tainted, arg1 the classical
   literal 0.5 — cq_measure(olm_pow(q, 0.5)).

   WHAT THIS PROBE ACTUALLY REACHES — read this before trusting the golden.
   Because y is the CLASSICAL constant 0.5, clang -O1 const-folds the whole
   y-side classification (ly==0, iy==0x3fe00000, hy>=0) and pow's numeric core
   becomes provably dead, along two paths that between them cover every basis
   state of x:
     - hx >= 0: the `hy==0x3fe00000` arm returns sqrt(x) directly;
     - hx <  0: iy==0x3fe00000 is below 0x3ff00000, so yisint stays 0, and
       n = ((u_int32_t)hx>>31)-1 == 0, hence (n|yisint)==0 and the body
       returns the NaN form (x-x)/(x-x).
   So EVERYTHING after the special-value nest is unreachable at this probe.
   Measured on the emitted IR, not assumed: stage-1 IR contains ZERO `fmul`
   and emits NO globals at all — the L1..L6 / P1..P5 polynomials, the
   cp/ivln2/lg2 splitting, the bp[k] / dp_h[k] / dp_l[k] table reads, the
   z>=1024 over/underflow ladder, the |z|>0.5 rounding arm, and the
   olm_scalbn subnormal tail are all constant-folded away. There is NO QROM /
   const-global table read and NO scalbn remnant in this trace. The full
   tables and olm_scalbn/olm_copysign are still vendored above because Rule 18
   requires the real source to be PRESENT (so the pass sees stock opcodes and
   never an unresolved external call) — they simply do not survive this probe.

   What the trace therefore pins is the surviving tainted-on-x skeleton: the
   `x==1` filter, the NaN filter, the tainted `hx>=0` guard on the sqrt
   fast-path return, `fabs(x)`, the `lx==0` special-value nest (a 6-case
   tainted switch on the high word plus an i1 select), and the 6-way
   floating-point merge phi that joins all of those returns into the single
   user-written cq_measure. cq-lowering flattens that whole region to
   STRAIGHT-LINE code — the lowered @slice has 0 phi, 0 select, 0 switch and
   one trailing block — merging the fp arms with cqrt_copy_f64_controlled over
   the cqrt_cnot/cqrt_toffoli conjunction substrate.

   This slice is the LINK-layer proof (Rule 2) that every emitted symbol
   resolves and signature-matches and that the trace is stable; it is NOT
   evidence about pow's numeric core, which this probe cannot reach. */
#include <stdint.h>
typedef uint32_t u_int32_t;
typedef uint64_t u_int64_t;
/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define GET_HIGH_WORD(i,d)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)(__w>>32); }while(0)
#define SET_HIGH_WORD(d,v)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0x00000000ffffffffULL)|((uint64_t)(uint32_t)(v)<<32); __builtin_memcpy(&(d),&__w,8); }while(0)
#define SET_LOW_WORD(d,v)      do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0xffffffff00000000ULL)|(uint32_t)(v); __builtin_memcpy(&(d),&__w,8); }while(0)

/* ---- vendored VERBATIM from slice_libm_real_scalbn.c (REAL openlibm
       s_copysign.c / s_scalbn.c); `huge`/`tiny` renamed sn_huge/sn_tiny to
       avoid the collision with e_pow.c's identically-valued statics. ---- */
__attribute__((always_inline)) static inline double olm_copysign(double x, double y) {
    uint64_t bx, by;
    __builtin_memcpy(&bx, &x, 8);
    __builtin_memcpy(&by, &y, 8);
    bx = (bx & 0x7fffffffffffffffULL) | (by & 0x8000000000000000ULL);
    __builtin_memcpy(&x, &bx, 8);
    return x;
}

static const double two54  = 1.80143985094819840000e+16; /* 0x43500000, 0x00000000 */
static const double twom54 = 5.55111512312578270212e-17; /* 0x3C900000, 0x00000000 */
static const double sn_huge = 1.0e+300;
static const double sn_tiny = 1.0e-300;

__attribute__((always_inline)) static inline double olm_scalbn(double x, int n) {
    int32_t k, hx, lx;
    uint64_t bits;
    __builtin_memcpy(&bits, &x, 8);                      /* EXTRACT_WORDS */
    hx = (int32_t)(bits >> 32);
    lx = (int32_t)bits;
    k = (hx & 0x7ff00000) >> 20;                         /* extract exponent */
    if (k == 0) {                                        /* 0 or subnormal x */
        if ((lx | (hx & 0x7fffffff)) == 0) return x;     /* +-0 */
        x *= two54;
        __builtin_memcpy(&bits, &x, 8);                  /* GET_HIGH_WORD */
        hx = (int32_t)(bits >> 32);
        k = ((hx & 0x7ff00000) >> 20) - 54;
        if (n < -50000) return sn_tiny * x;              /* underflow */
    }
    if (k == 0x7ff) return x + x;                        /* NaN or Inf */
    k = k + n;
    if (k > 0x7fe) return sn_huge * olm_copysign(sn_huge, x);  /* overflow */
    if (k > 0) {                                         /* normal result */
        __builtin_memcpy(&bits, &x, 8);                  /* SET_HIGH_WORD */
        bits = (bits & 0xffffffffULL) |
               ((uint64_t)(uint32_t)((hx & 0x800fffff) | (k << 20)) << 32);
        __builtin_memcpy(&x, &bits, 8);
        return x;
    }
    if (k <= -54) {
        if (n > 50000)                                   /* n+k overflowed */
            return sn_huge * olm_copysign(sn_huge, x);   /* overflow */
        else
            return sn_tiny * olm_copysign(sn_tiny, x);   /* underflow */
    }
    k += 54;                                             /* subnormal result */
    __builtin_memcpy(&bits, &x, 8);                      /* SET_HIGH_WORD */
    bits = (bits & 0xffffffffULL) |
           ((uint64_t)(uint32_t)((hx & 0x800fffff) | (k << 20)) << 32);
    __builtin_memcpy(&x, &bits, 8);
    return x * twom54;
}

/* ---- vendored from openlibm src/e_pow.c (REAL __ieee754_pow) ---- */
static const double
bp[] = {1.0, 1.5,},
dp_h[] = { 0.0, 5.84962487220764160156e-01,}, /* 0x3FE2B803, 0x40000000 */
dp_l[] = { 0.0, 1.35003920212974897128e-08,}, /* 0x3E4CFDEB, 0x43CFD006 */
zero    =  0.0,
one	=  1.0,
two	=  2.0,
two53	=  9007199254740992.0,	/* 0x43400000, 0x00000000 */
huge	=  1.0e300,
tiny    =  1.0e-300,
	/* poly coefs for (3/2)*(log(x)-2s-2/3*s**3 */
L1  =  5.99999999999994648725e-01, /* 0x3FE33333, 0x33333303 */
L2  =  4.28571428578550184252e-01, /* 0x3FDB6DB6, 0xDB6FABFF */
L3  =  3.33333329818377432918e-01, /* 0x3FD55555, 0x518F264D */
L4  =  2.72728123808534006489e-01, /* 0x3FD17460, 0xA91D4101 */
L5  =  2.30660745775561754067e-01, /* 0x3FCD864A, 0x93C9DB65 */
L6  =  2.06975017800338417784e-01, /* 0x3FCA7E28, 0x4A454EEF */
P1   =  1.66666666666666019037e-01, /* 0x3FC55555, 0x5555553E */
P2   = -2.77777777770155933842e-03, /* 0xBF66C16C, 0x16BEBD93 */
P3   =  6.61375632143793436117e-05, /* 0x3F11566A, 0xAF25DE2C */
P4   = -1.65339022054652515390e-06, /* 0xBEBBBD41, 0xC5D26BF1 */
P5   =  4.13813679705723846039e-08, /* 0x3E663769, 0x72BEA4D0 */
lg2  =  6.93147180559945286227e-01, /* 0x3FE62E42, 0xFEFA39EF */
lg2_h  =  6.93147182464599609375e-01, /* 0x3FE62E43, 0x00000000 */
lg2_l  = -1.90465429995776804525e-09, /* 0xBE205C61, 0x0CA86C39 */
ovt =  8.0085662595372944372e-0017, /* -(1024-log2(ovfl+.5ulp)) */
cp    =  9.61796693925975554329e-01, /* 0x3FEEC709, 0xDC3A03FD =2/(3ln2) */
cp_h  =  9.61796700954437255859e-01, /* 0x3FEEC709, 0xE0000000 =(float)cp */
cp_l  = -7.02846165095275826516e-09, /* 0xBE3E2FE0, 0x145B01F5 =tail of cp_h*/
ivln2    =  1.44269504088896338700e+00, /* 0x3FF71547, 0x652B82FE =1/ln2 */
ivln2_h  =  1.44269502162933349609e+00, /* 0x3FF71547, 0x60000000 =24b 1/ln2*/
ivln2_l  =  1.92596299112661746887e-08; /* 0x3E54AE0B, 0xF85DDF44 =1/ln2 tail*/

__attribute__((always_inline)) static inline double
olm_pow(double x, double y)
{
	double z,ax,z_h,z_l,p_h,p_l;
	double y1,t1,t2,r,s,t,u,v,w;
	int32_t i,j,k,yisint,n;
	int32_t hx,hy,ix,iy;
	u_int32_t lx,ly;

	EXTRACT_WORDS(hx,lx,x);
	EXTRACT_WORDS(hy,ly,y);
	ix = hx&0x7fffffff;  iy = hy&0x7fffffff;

    /* y==zero: x**0 = 1 */
	if((iy|ly)==0) return one;

    /* x==1: 1**y = 1, even if y is NaN */
	if (hx==0x3ff00000 && lx == 0) return one;

    /* y!=zero: result is NaN if either arg is NaN */
	if(ix > 0x7ff00000 || ((ix==0x7ff00000)&&(lx!=0)) ||
	   iy > 0x7ff00000 || ((iy==0x7ff00000)&&(ly!=0)))
		return (x+0.0)+(y+0.0);

    /* determine if y is an odd int when x < 0
     * yisint = 0	... y is not an integer
     * yisint = 1	... y is an odd int
     * yisint = 2	... y is an even int
     */
	yisint  = 0;
	if(hx<0) {
	    if(iy>=0x43400000) yisint = 2; /* even integer y */
	    else if(iy>=0x3ff00000) {
		k = (iy>>20)-0x3ff;	   /* exponent */
		if(k>20) {
		    j = ly>>(52-k);
		    if((j<<(52-k))==ly) yisint = 2-(j&1);
		} else if(ly==0) {
		    j = iy>>(20-k);
		    if((j<<(20-k))==iy) yisint = 2-(j&1);
		}
	    }
	}

    /* special value of y */
	if(ly==0) {
	    if (iy==0x7ff00000) {	/* y is +-inf */
	        if(((ix-0x3ff00000)|lx)==0)
		    return  one;	/* (-1)**+-inf is NaN */
	        else if (ix >= 0x3ff00000)/* (|x|>1)**+-inf = inf,0 */
		    return (hy>=0)? y: zero;
	        else			/* (|x|<1)**-,+inf = inf,0 */
		    return (hy<0)?-y: zero;
	    }
	    if(iy==0x3ff00000) {	/* y is  +-1 */
		if(hy<0) return one/x; else return x;
	    }
            if(hy==0x40000000) return x*x;   /* y is  2 */
            if(hy==0x40080000) return x*x*x; /* y is  3 */
            if(hy==0x40100000) {             /* y is  4 */
                u = x*x;
                return u*u;
            }
	    if(hy==0x3fe00000) {             /* y is  0.5 */
		if(hx>=0)	/* x >= +0 */
                    return __builtin_sqrt(x);
	    }
	}

	ax   = __builtin_fabs(x);
    /* special value of x */
	if(lx==0) {
	    if(ix==0x7ff00000||ix==0||ix==0x3ff00000){
		z = ax;			/*x is +-0,+-inf,+-1*/
		if(hy<0) z = one/z;	/* z = (1/|x|) */
		if(hx<0) {
		    if(((ix-0x3ff00000)|yisint)==0) {
			z = (z-z)/(z-z); /* (-1)**non-int is NaN */
		    } else if(yisint==1)
			z = -z;		/* (x<0)**odd = -(|x|**odd) */
		}
		return z;
	    }
	}

    /* CYGNUS LOCAL + fdlibm-5.3 fix: This used to be
	n = (hx>>31)+1;
       but ANSI C says a right shift of a signed negative quantity is
       implementation defined.  */
	n = ((u_int32_t)hx>>31)-1;

    /* (x<0)**(non-int) is NaN */
	if((n|yisint)==0) return (x-x)/(x-x);

	s = one; /* s (sign of result -ve**odd) = -1 else = 1 */
	if((n|(yisint-1))==0) s = -one;/* (-ve)**(odd int) */

    /* |y| is huge */
	if(iy>0x41e00000) { /* if |y| > 2**31 */
	    if(iy>0x43f00000){	/* if |y| > 2**64, must o/uflow */
		if(ix<=0x3fefffff) return (hy<0)? huge*huge:tiny*tiny;
		if(ix>=0x3ff00000) return (hy>0)? huge*huge:tiny*tiny;
	    }
	/* over/underflow if x is not close to one */
	    if(ix<0x3fefffff) return (hy<0)? s*huge*huge:s*tiny*tiny;
	    if(ix>0x3ff00000) return (hy>0)? s*huge*huge:s*tiny*tiny;
	/* now |1-x| is tiny <= 2**-20, suffice to compute
	   log(x) by x-x^2/2+x^3/3-x^4/4 */
	    t = ax-one;		/* t has 20 trailing zeros */
	    w = (t*t)*(0.5-t*(0.3333333333333333333333-t*0.25));
	    u = ivln2_h*t;	/* ivln2_h has 21 sig. bits */
	    v = t*ivln2_l-w*ivln2;
	    t1 = u+v;
	    SET_LOW_WORD(t1,0);
	    t2 = v-(t1-u);
	} else {
	    double ss,s2,s_h,s_l,t_h,t_l;
	    n = 0;
	/* take care subnormal number */
	    if(ix<0x00100000)
		{ax *= two53; n -= 53; GET_HIGH_WORD(ix,ax); }
	    n  += ((ix)>>20)-0x3ff;
	    j  = ix&0x000fffff;
	/* determine interval */
	    ix = j|0x3ff00000;		/* normalize ix */
	    if(j<=0x3988E) k=0;		/* |x|<sqrt(3/2) */
	    else if(j<0xBB67A) k=1;	/* |x|<sqrt(3)   */
	    else {k=0;n+=1;ix -= 0x00100000;}
	    SET_HIGH_WORD(ax,ix);

	/* compute ss = s_h+s_l = (x-1)/(x+1) or (x-1.5)/(x+1.5) */
	    u = ax-bp[k];		/* bp[0]=1.0, bp[1]=1.5 */
	    v = one/(ax+bp[k]);
	    ss = u*v;
	    s_h = ss;
	    SET_LOW_WORD(s_h,0);
	/* t_h=ax+bp[k] High */
	    t_h = zero;
	    SET_HIGH_WORD(t_h,((ix>>1)|0x20000000)+0x00080000+(k<<18));
	    t_l = ax - (t_h-bp[k]);
	    s_l = v*((u-s_h*t_h)-s_h*t_l);
	/* compute log(ax) */
	    s2 = ss*ss;
	    r = s2*s2*(L1+s2*(L2+s2*(L3+s2*(L4+s2*(L5+s2*L6)))));
	    r += s_l*(s_h+ss);
	    s2  = s_h*s_h;
	    t_h = 3.0+s2+r;
	    SET_LOW_WORD(t_h,0);
	    t_l = r-((t_h-3.0)-s2);
	/* u+v = ss*(1+...) */
	    u = s_h*t_h;
	    v = s_l*t_h+t_l*ss;
	/* 2/(3log2)*(ss+...) */
	    p_h = u+v;
	    SET_LOW_WORD(p_h,0);
	    p_l = v-(p_h-u);
	    z_h = cp_h*p_h;		/* cp_h+cp_l = 2/(3*log2) */
	    z_l = cp_l*p_h+p_l*cp+dp_l[k];
	/* log2(ax) = (ss+..)*2/(3*log2) = n + dp_h + z_h + z_l */
	    t = (double)n;
	    t1 = (((z_h+z_l)+dp_h[k])+t);
	    SET_LOW_WORD(t1,0);
	    t2 = z_l-(((t1-t)-dp_h[k])-z_h);
	}

    /* split up y into y1+y2 and compute (y1+y2)*(t1+t2) */
	y1  = y;
	SET_LOW_WORD(y1,0);
	p_l = (y-y1)*t1+y*t2;
	p_h = y1*t1;
	z = p_l+p_h;
	EXTRACT_WORDS(j,i,z);
	if (j>=0x40900000) {				/* z >= 1024 */
	    if(((j-0x40900000)|i)!=0)			/* if z > 1024 */
		return s*huge*huge;			/* overflow */
	    else {
		if(p_l+ovt>z-p_h) return s*huge*huge;	/* overflow */
	    }
	} else if((j&0x7fffffff)>=0x4090cc00 ) {	/* z <= -1075 */
	    if(((j-0xc090cc00)|i)!=0) 		/* z < -1075 */
		return s*tiny*tiny;		/* underflow */
	    else {
		if(p_l<=z-p_h) return s*tiny*tiny;	/* underflow */
	    }
	}
    /*
     * compute 2**(p_h+p_l)
     */
	i = j&0x7fffffff;
	k = (i>>20)-0x3ff;
	n = 0;
	if(i>0x3fe00000) {		/* if |z| > 0.5, set n = [z+0.5] */
	    n = j+(0x00100000>>(k+1));
	    k = ((n&0x7fffffff)>>20)-0x3ff;	/* new k for n */
	    t = zero;
	    SET_HIGH_WORD(t,n&~(0x000fffff>>k));
	    n = ((n&0x000fffff)|0x00100000)>>(20-k);
	    if(j<0) n = -n;
	    p_h -= t;
	}
	t = p_l+p_h;
	SET_LOW_WORD(t,0);
	u = t*lg2_h;
	v = (p_l-(t-p_h))*lg2+t*lg2_l;
	z = u+v;
	w = v-(z-u);
	t  = z*z;
	t1  = z - t*(P1+t*(P2+t*(P3+t*(P4+t*P5))));
	r  = (z*t1)/(t1-two)-(w+z*w);
	z  = one-(r-z);
	GET_HIGH_WORD(j,z);
	j += (n<<20);
	if((j>>20)<=0) z = olm_scalbn(z,n);	/* subnormal output */
	else SET_HIGH_WORD(z,j);
	return s*z;
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_pow(q, 0.5));
}
int main(void) { (void) slice(); return 0; }
