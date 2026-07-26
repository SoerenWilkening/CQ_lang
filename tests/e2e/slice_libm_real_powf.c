/* slice_libm_real_powf.c — bd 3c6m.60: the REAL openlibm powf body, census
   cell powf.f32.

   VENDORED CORPUS FILES (from the intact clone /private/tmp/openlibm_reclone):
     src/e_powf.c      -> the whole algorithm: its `static const float`
                          coefficient block (bp, dp_h, dp_l, zero, half, qrtr,
                          thrd, one, two, two24, L1..L6, P1..P5, lg2, lg2_h,
                          lg2_l, ovt, cp, cp_h, cp_l, ivln2, ivln2_h, ivln2_l)
                          and the complete __ieee754_powf body, lines 23-253.
     src/s_scalbnf.c   -> olm_scalbnf, the subnormal-output rescale powf calls
                          at its very last step. This is a LIBRARY function
                          (Rule 18): it has an injectable body, so a body is
                          injected as source, never name-recognized. Reused
                          BYTE-IDENTICALLY from the sibling slice
                          tests/e2e/slice_libm_real_scalbnf.c (bd 3c6m.53),
                          together with that slice's word-macro prelude —
                          re-measured byte-identical after the bd tkju keep
                          rewrite, which in BOTH slices respelled copysignf as
                          the keep builtin and dropped the olm_fabs/olm_fabsf/
                          olm_copysign/olm_copysignf shim block.
                          CAVEAT — do NOT restate this as "the real body", and
                          do not propagate that phrasing to sibling cells: the
                          portable C in src/s_scalbnf.c is NOT what openlibm
                          builds on this target. amd64/Make.files lists
                          s_scalbnf.S, an x87 fildl/flds/fscale routine — a
                          DIFFERENT ALGORITHM. A .S file has no injectable
                          source, so vendoring the portable C is the only
                          Rule-18-compatible option available, but it is a
                          different implementation from the one amd64 ships.
                          That has zero effect on THIS cell only because
                          olm_scalbnf is 100% dead-stripped here and
                          contributes 0 lines to the golden (see WHAT THIS CELL
                          ACTUALLY LOWERS below). Any cell where scalbnf is
                          LIVE must re-open this question before its trace is
                          trusted as openlibm-faithful on amd64.

   DECLARED MECHANICAL EDITS (and no others):
     - deleted the #include lines, the license and FBSDID header blocks, the
       OLM_DLLEXPORT storage marker, and the openlibm strong-reference line.
     - entry points renamed and force-inlined:
       __ieee754_powf -> always_inline static inline olm_powf;
       scalbnf -> always_inline static inline olm_scalbnf (bd 20xt.2: forcing
       the inline reproduces the census inline shape at plain -O1 and collapses
       the closure to one straight-line body).
     - the math_private.h word macros replaced by the __builtin_memcpy shim.
       powf and scalbnf use only GET_FLOAT_WORD and SET_FLOAT_WORD; per bd
       3c6m.53 both go through a uint32_t temp memcpy'd against a genuine
       `float` object — e_powf.c declares no `double`, so the f32 implicit-
       conversion hazard cannot arise here.
     - nan_mix is reproduced from math_private.h line 249 with exactly ONE
       whitespace byte changed: the corpus writes a tab after `#define`, this
       file a space. The preprocessor token stream is identical. It keeps its
       long-double mixing step; that is the real source, otherwise unchanged.
     - COLLISION: e_powf.c and s_scalbnf.c each define a file-scope
       `static const float huge` and `tiny`, with IDENTICAL type and value
       (1.0e30f and 1.0e-30f in powf, 1.0e+30f and 1.0e-30f in scalbnf — the
       same two floats). Resolved by MERGE rather than rename: the two
       duplicate lines were deleted from powf's const block and scalbnf's
       definitions serve both, so neither vendored function body needed an
       identifier substitution and both bodies stay textually verbatim. Every
       other file-scope constant was checked literal-by-literal, in order,
       against the corpus.
     - KEEP-SET CALLS rewritten to their __builtin_ spelling, because at the
       real ship floor (plain `clang -O1`, builtins ON) the named call folds to
       the @llvm intrinsic for f32 BEFORE codegen and cq-lowering rewrites it
       to cq_template_<fn>_f32 (Rule 18 — the keep set has no injectable body
       by definition, so this is a route pin, not a body substitution):
         __ieee754_sqrtf(x)  ->  __builtin_sqrtf(x)
           (math_private.h line 311 literally defines __ieee754_sqrtf as
            sqrtf, UNCONDITIONALLY on every arch — the only #if open at that
            line is the file's own _MATH_PRIVATE_H_ include guard — so the
            corpus call IS the named sqrtf call;
            the census had built it with a blanket -fno-builtin, which dragged
            in openlibm's SOFTWARE e_sqrtf normalize loop — that is exactly the
            harness bug this ticket fixes.)
         fabsf(x)            ->  __builtin_fabsf(x)
         copysignf(v,x)      ->  __builtin_copysignf(v,x)
           (the 3 sites in olm_scalbnf's overflow/underflow arms. An earlier
            draft instead routed them through a hand-written olm_copysignf
            memcpy shim, inherited from the sibling 3c6m.53 scalbnf slice; a
            shim is a SOFTWARE body for a keep, i.e. the same Rule-18
            misrepresentation the sqrtf pin above exists to remove, so it was
            deleted and the sites keep-routed with it — bd tkju.)
       scalbnf is NOT in the keep set and is therefore vendored, not builtin'd.
       The copysignf fix does not move this cell's golden — 152 trace lines
       before and after, byte-identical — because olm_scalbnf is dead-stripped
       before cq-lowering, so no copysign path reaches the golden at all.

   PROBE: arg0 tainted, arg1 the classical literal 0.5f —
   cq_measure_f32(olm_powf(q, 0.5f)).

   WHAT THIS CELL ACTUALLY LOWERS — read this before trusting the golden.
   The census probe convention pins arg1 to the literal 0.5f, and 0.5f is
   exactly the value that trips powf's y==0.5 fast path. Every y-derived test
   in the body therefore const-folds at plain -O1, and clang PROVES the log/exp
   core unreachable before cq-lowering ever runs. Verified in the frontend IR:
   zero file-scope globals survive (bp / dp_h / dp_l and the L, P, lg2, cp,
   ivln2 coefficients are all DCE'd), and the vendored olm_scalbnf body — which
   is present and compiles, so the injection closure IS closed at the C level —
   is dead-stripped with the core that calls it. The surviving, and hence the
   trace-verified, region is powf's tainted classification prologue:
     - hx == 0x3f800000            -> the `1**y = 1` early return;
     - ix > 0x7f800000             -> nan_mix, which really does promote through
                                      x86_fp80 (fpext f32->f80, two fadds, and
                                      fptrunc f80->f32 — the f80 leg of the
                                      width grid, exercised for real here);
     - hy == 0x3f000000 folds TRUE -> `if (hx >= 0) return sqrtf(x)`, the
                                      Rule-18 hardware-keep route this ticket
                                      exists to pin;
     - ax = fabsf(x)               -> the second hardware keep;
     - the special-value cascade ix==0x7f800000 || ix==0 || ix==0x3f800000,
       which -O1 canonicalises into `ix==0` OR `(ix & 0x3fffffff)==0x3f800000`,
       and its nested `hx<0 && ix==0x3f800000` NaN sub-case;
     - the `(x<0)**(non-int) is NaN` return, reached because yisint const-folds
       to 0 and the hx>=0 half already returned via sqrtf.
   So the lowering under test is a six-way tainted merge over that cascade:
   PredMux flattens it to nested cqrt_toffoli flag conjunctions feeding
   cqrt_copy_f32_controlled route-merges — 6 candidate values through 5 binary
   route-merges = 10 cqrt_copy_f32_controlled calls in the golden. TWO distinct
   flag-cleanup mechanisms are at work here, not one: the 18 compare flags are
   stripped by their compare `_inv` twins (18 forward cq_template_icmp_*_i32_hl
   against 18 _inv), while the 13 cqrt_alloc_i1 conjunction rails are
   uncomputed by REPLAYING their own self-inverse cqrt_toffoli (26 toffoli =
   13 forward + 13 replayed; the single OR rail additionally replays 2 of the 4
   cqrt_cnot). 18 + 13 = 31, exactly the 31 cqrt_free calls over 31 distinct
   handles in the 152-line golden.
   This slice is the LINK-layer proof (Rule 2) that
   every emitted symbol resolves and signature-matches and that the trace is
   stable; it is NOT a proof that powf's log/exp core lowers, and a reviewer
   should not read it as one. */
#include <stdint.h>
typedef uint32_t u_int32_t;
typedef uint64_t u_int64_t;
/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define GET_HIGH_WORD(i,d)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)(__w>>32); }while(0)
#define GET_LOW_WORD(i,d)      do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)__w; }while(0)
#define SET_HIGH_WORD(d,v)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0x00000000ffffffffULL)|((uint64_t)(uint32_t)(v)<<32); __builtin_memcpy(&(d),&__w,8); }while(0)
#define SET_LOW_WORD(d,v)      do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0xffffffff00000000ULL)|(uint32_t)(v); __builtin_memcpy(&(d),&__w,8); }while(0)
#define INSERT_WORDS(d,hi,lo)  do{ uint64_t __w=((uint64_t)(uint32_t)(hi)<<32)|(uint32_t)(lo); __builtin_memcpy(&(d),&__w,8); }while(0)
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)
/* nan_mix, from math_private.h:249 — identical token stream; the single byte
   that differs is the whitespace after `#define` (tab in corpus, space here). */
#define nan_mix(x, y)	(((x) + 0.0L) + ((y) + 0))
/* ---- vendored from src/s_scalbnf.c (byte-identical to the verified
   tests/e2e/slice_libm_real_scalbnf.c vendoring; also supplies huge/tiny) ---- */
static const float
two25   =  3.355443200e+07,	/* 0x4c000000 */
twom25  =  2.9802322388e-08,	/* 0x33000000 */
huge   = 1.0e+30,
tiny   = 1.0e-30;

__attribute__((always_inline)) static inline float
olm_scalbnf (float x, int n)
{
	int32_t k,ix;
	GET_FLOAT_WORD(ix,x);
        k = (ix&0x7f800000)>>23;		/* extract exponent */
        if (k==0) {				/* 0 or subnormal x */
            if ((ix&0x7fffffff)==0) return x; /* +-0 */
	    x *= two25;
	    GET_FLOAT_WORD(ix,x);
	    k = ((ix&0x7f800000)>>23) - 25;
            if (n< -50000) return tiny*x; 	/*underflow*/
	    }
        if (k==0xff) return x+x;		/* NaN or Inf */
        k = k+n;
        if (k >  0xfe) return huge*__builtin_copysignf(huge,x); /* overflow  */
        if (k > 0) 				/* normal result */
	    {SET_FLOAT_WORD(x,(ix&0x807fffff)|(k<<23)); return x;}
        if (k <= -25) {
            if (n > 50000) 	/* in case integer overflow in n+k */
		return huge*__builtin_copysignf(huge,x);	/*overflow*/
	    else return tiny*__builtin_copysignf(tiny,x);	/*underflow*/
        }
	k += 25;				/* subnormal result */
	SET_FLOAT_WORD(x,(ix&0x807fffff)|(k<<23));
        return x*twom25;
}

/* ---- vendored from src/e_powf.c ---- */
static const float
bp[] = {1.0, 1.5,},
dp_h[] = { 0.0, 5.84960938e-01,}, /* 0x3f15c000 */
dp_l[] = { 0.0, 1.56322085e-06,}, /* 0x35d1cfdc */
zero    =  0.0,
half    =  0.5,
qrtr    =  0.25,
thrd    =  3.33333343e-01, /* 0x3eaaaaab */
one	=  1.0,
two	=  2.0,
two24	=  16777216.0,	/* 0x4b800000 */
	/* poly coefs for (3/2)*(log(x)-2s-2/3*s**3 */
L1  =  6.0000002384e-01, /* 0x3f19999a */
L2  =  4.2857143283e-01, /* 0x3edb6db7 */
L3  =  3.3333334327e-01, /* 0x3eaaaaab */
L4  =  2.7272811532e-01, /* 0x3e8ba305 */
L5  =  2.3066075146e-01, /* 0x3e6c3255 */
L6  =  2.0697501302e-01, /* 0x3e53f142 */
P1   =  1.6666667163e-01, /* 0x3e2aaaab */
P2   = -2.7777778450e-03, /* 0xbb360b61 */
P3   =  6.6137559770e-05, /* 0x388ab355 */
P4   = -1.6533901999e-06, /* 0xb5ddea0e */
P5   =  4.1381369442e-08, /* 0x3331bb4c */
lg2  =  6.9314718246e-01, /* 0x3f317218 */
lg2_h  =  6.93145752e-01, /* 0x3f317200 */
lg2_l  =  1.42860654e-06, /* 0x35bfbe8c */
ovt =  4.2995665694e-08, /* -(128-log2(ovfl+.5ulp)) */
cp    =  9.6179670095e-01, /* 0x3f76384f =2/(3ln2) */
cp_h  =  9.6191406250e-01, /* 0x3f764000 =12b cp */
cp_l  = -1.1736857402e-04, /* 0xb8f623c6 =tail of cp_h */
ivln2    =  1.4426950216e+00, /* 0x3fb8aa3b =1/ln2 */
ivln2_h  =  1.4426879883e+00, /* 0x3fb8aa00 =16b 1/ln2*/
ivln2_l  =  7.0526075433e-06; /* 0x36eca570 =1/ln2 tail*/

__attribute__((always_inline)) static inline float
olm_powf(float x, float y)
{
	float z,ax,z_h,z_l,p_h,p_l;
	float y1,t1,t2,r,s,sn,t,u,v,w;
	int32_t i,j,k,yisint,n;
	int32_t hx,hy,ix,iy,is;

	GET_FLOAT_WORD(hx,x);
	GET_FLOAT_WORD(hy,y);
	ix = hx&0x7fffffff;  iy = hy&0x7fffffff;

    /* y==zero: x**0 = 1 */
	if(iy==0) return one;

    /* x==1: 1**y = 1, even if y is NaN */
	if (hx==0x3f800000) return one;

    /* y!=zero: result is NaN if either arg is NaN */
	if(ix > 0x7f800000 ||
	   iy > 0x7f800000)
	    return nan_mix(x, y);

    /* determine if y is an odd int when x < 0
     * yisint = 0	... y is not an integer
     * yisint = 1	... y is an odd int
     * yisint = 2	... y is an even int
     */
	yisint  = 0;
	if(hx<0) {
	    if(iy>=0x4b800000) yisint = 2; /* even integer y */
	    else if(iy>=0x3f800000) {
		k = (iy>>23)-0x7f;	   /* exponent */
		j = iy>>(23-k);
		if((j<<(23-k))==iy) yisint = 2-(j&1);
	    }
	}

    /* special value of y */
	if (iy==0x7f800000) {	/* y is +-inf */
	    if (ix==0x3f800000)
	        return  one;	/* (-1)**+-inf is NaN */
	    else if (ix > 0x3f800000)/* (|x|>1)**+-inf = inf,0 */
	        return (hy>=0)? y: zero;
	    else			/* (|x|<1)**-,+inf = inf,0 */
	        return (hy<0)?-y: zero;
	}
	if(iy==0x3f800000) {	/* y is  +-1 */
	    if(hy<0) return one/x; else return x;
	}
	if(hy==0x40000000) return x*x; /* y is  2 */
	if(hy==0x3f000000) {	/* y is  0.5 */
	    if(hx>=0)	/* x >= +0 */
	    return __builtin_sqrtf(x);
	}

	ax   = __builtin_fabsf(x);
    /* special value of x */
	if(ix==0x7f800000||ix==0||ix==0x3f800000){
	    z = ax;			/*x is +-0,+-inf,+-1*/
	    if(hy<0) z = one/z;	/* z = (1/|x|) */
	    if(hx<0) {
		if(((ix-0x3f800000)|yisint)==0) {
		    z = (z-z)/(z-z); /* (-1)**non-int is NaN */
		} else if(yisint==1)
		    z = -z;		/* (x<0)**odd = -(|x|**odd) */
	    }
	    return z;
	}

	n = ((u_int32_t)hx>>31)-1;

    /* (x<0)**(non-int) is NaN */
	if((n|yisint)==0) return (x-x)/(x-x);

	sn = one; /* s (sign of result -ve**odd) = -1 else = 1 */
	if((n|(yisint-1))==0) sn = -one;/* (-ve)**(odd int) */

    /* |y| is huge */
	if(iy>0x4d000000) { /* if |y| > 2**27 */
	/* over/underflow if x is not close to one */
	    if(ix<0x3f7ffff6) return (hy<0)? sn*huge*huge:sn*tiny*tiny;
	    if(ix>0x3f800007) return (hy>0)? sn*huge*huge:sn*tiny*tiny;
	/* now |1-x| is tiny <= 2**-20, suffice to compute
	   log(x) by x-x^2/2+x^3/3-x^4/4 */
	    t = ax-1;		/* t has 20 trailing zeros */
	    w = (t*t)*(half-t*(thrd-t*qrtr));
	    u = ivln2_h*t;	/* ivln2_h has 16 sig. bits */
	    v = t*ivln2_l-w*ivln2;
	    t1 = u+v;
	    GET_FLOAT_WORD(is,t1);
	    SET_FLOAT_WORD(t1,is&0xfffff000);
	    t2 = v-(t1-u);
	} else {
	    float s2,s_h,s_l,t_h,t_l;
	    n = 0;
	/* take care subnormal number */
	    if(ix<0x00800000)
		{ax *= two24; n -= 24; GET_FLOAT_WORD(ix,ax); }
	    n  += ((ix)>>23)-0x7f;
	    j  = ix&0x007fffff;
	/* determine interval */
	    ix = j|0x3f800000;		/* normalize ix */
	    if(j<=0x1cc471) k=0;	/* |x|<sqrt(3/2) */
	    else if(j<0x5db3d7) k=1;	/* |x|<sqrt(3)   */
	    else {k=0;n+=1;ix -= 0x00800000;}
	    SET_FLOAT_WORD(ax,ix);

	/* compute s = s_h+s_l = (x-1)/(x+1) or (x-1.5)/(x+1.5) */
	    u = ax-bp[k];		/* bp[0]=1.0, bp[1]=1.5 */
	    v = one/(ax+bp[k]);
	    s = u*v;
	    s_h = s;
	    GET_FLOAT_WORD(is,s_h);
	    SET_FLOAT_WORD(s_h,is&0xfffff000);
	/* t_h=ax+bp[k] High */
	    is = ((ix>>1)&0xfffff000)|0x20000000;
	    SET_FLOAT_WORD(t_h,is+0x00400000+(k<<21));
	    t_l = ax - (t_h-bp[k]);
	    s_l = v*((u-s_h*t_h)-s_h*t_l);
	/* compute log(ax) */
	    s2 = s*s;
	    r = s2*s2*(L1+s2*(L2+s2*(L3+s2*(L4+s2*(L5+s2*L6)))));
	    r += s_l*(s_h+s);
	    s2  = s_h*s_h;
	    t_h = 3+s2+r;
	    GET_FLOAT_WORD(is,t_h);
	    SET_FLOAT_WORD(t_h,is&0xfffff000);
	    t_l = r-((t_h-3)-s2);
	/* u+v = s*(1+...) */
	    u = s_h*t_h;
	    v = s_l*t_h+t_l*s;
	/* 2/(3log2)*(s+...) */
	    p_h = u+v;
	    GET_FLOAT_WORD(is,p_h);
	    SET_FLOAT_WORD(p_h,is&0xfffff000);
	    p_l = v-(p_h-u);
	    z_h = cp_h*p_h;		/* cp_h+cp_l = 2/(3*log2) */
	    z_l = cp_l*p_h+p_l*cp+dp_l[k];
	/* log2(ax) = (s+..)*2/(3*log2) = n + dp_h + z_h + z_l */
	    t = n;
	    t1 = (((z_h+z_l)+dp_h[k])+t);
	    GET_FLOAT_WORD(is,t1);
	    SET_FLOAT_WORD(t1,is&0xfffff000);
	    t2 = z_l-(((t1-t)-dp_h[k])-z_h);
	}

    /* split up y into y1+y2 and compute (y1+y2)*(t1+t2) */
	GET_FLOAT_WORD(is,y);
	SET_FLOAT_WORD(y1,is&0xfffff000);
	p_l = (y-y1)*t1+y*t2;
	p_h = y1*t1;
	z = p_l+p_h;
	GET_FLOAT_WORD(j,z);
	if (j>0x43000000)				/* if z > 128 */
	    return sn*huge*huge;			/* overflow */
	else if (j==0x43000000) {			/* if z == 128 */
	    if(p_l+ovt>z-p_h) return sn*huge*huge;	/* overflow */
	}
	else if ((j&0x7fffffff)>0x43160000)		/* z <= -150 */
	    return sn*tiny*tiny;			/* underflow */
	else if (j==0xc3160000){			/* z == -150 */
	    if(p_l<=z-p_h) return sn*tiny*tiny;		/* underflow */
	}
    /*
     * compute 2**(p_h+p_l)
     */
	i = j&0x7fffffff;
	k = (i>>23)-0x7f;
	n = 0;
	if(i>0x3f000000) {		/* if |z| > 0.5, set n = [z+0.5] */
	    n = j+(0x00800000>>(k+1));
	    k = ((n&0x7fffffff)>>23)-0x7f;	/* new k for n */
	    SET_FLOAT_WORD(t,n&~(0x007fffff>>k));
	    n = ((n&0x007fffff)|0x00800000)>>(23-k);
	    if(j<0) n = -n;
	    p_h -= t;
	}
	t = p_l+p_h;
	GET_FLOAT_WORD(is,t);
	SET_FLOAT_WORD(t,is&0xffff8000);
	u = t*lg2_h;
	v = (p_l-(t-p_h))*lg2+t*lg2_l;
	z = u+v;
	w = v-(z-u);
	t  = z*z;
	t1  = z - t*(P1+t*(P2+t*(P3+t*(P4+t*P5))));
	r  = (z*t1)/(t1-two)-(w+z*w);
	z  = one-(r-z);
	GET_FLOAT_WORD(j,z);
	j += (n<<23);
	if((j>>23)<=0) z = olm_scalbnf(z,n);	/* subnormal output */
	else SET_FLOAT_WORD(z,j);
	return sn*z;
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_powf(q, 0.5f));
}
int main(void) { (void) slice(); return 0; }
