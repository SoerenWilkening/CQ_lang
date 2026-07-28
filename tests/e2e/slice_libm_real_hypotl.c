/* slice_libm_real_hypotl.c — bd 3c6m.60: the REAL openlibm hypotl body over
   x86_fp80 `long double`.

   Corpus files vendored (intact clone /private/tmp/openlibm — NOT the
   /private/tmp/openlibm_reclone the parked header cited, which lacks
   src/e_hypotl.c and src/amd64_fpmath.h entirely; corrected 2026-07-28 after a
   Rule-13 lens found the citation unreproducible at the stated path). NB two
   hypotl variants exist in the corpus, src/e_hypotl.c and ld80/e_hypotl.c, and
   they DIFFER; the one vendored here is src/, which is the one openlibm's own
   CMakeLists.txt:284 puts in the build (ld80/e_hypotl.c appears in no build
   list). Re-verified 2026-07-28: the body and all four vendored macro/union
   blocks are byte-identical to the corpus after normalising comments,
   whitespace and the two keep-set spellings.
     - src/e_hypotl.c   : the whole algorithm — the local GET_LDBL_MAN /
                          GET_HIGH_WORD / SET_HIGH_WORD / DESW / ESW / MANT_DIG /
                          MAX_EXP macro block, the man_t typedef, and the
                          hypotl() body (verbatim, constant for constant).
     - src/amd64_fpmath.h : union IEEEl2bits (both the bits and xbits views) and
                          LDBL_NBIT, kept VERBATIM.
     - src/math_private.h : GET_LDBL_EXPSIGN / SET_LDBL_EXPSIGN (verbatim), which
                          e_hypotl.c redirects GET_HIGH_WORD / SET_HIGH_WORD to.
   FreeBSD/fdlibm-derived, BSD-licensed.

   Mechanical edits ONLY (libm-real-slice-recipe; NO constant, branch, or
   expression changed): the include lines, the license/FBSDID header block and
   OLM_DLLEXPORT deleted; LDBL_MANT_DIG (64) and LDBL_MAX_EXP (16384) written as
   their x86_fp80 <float.h> values; the LDBL_MANL_SIZE conditional collapsed to
   its x86-64 arm (LDBL_MANL_SIZE == 32, so man_t is u_int32_t) with a local
   u_int32_t typedef; the public entry `hypotl` renamed
   `__attribute__((always_inline)) static inline olm_hypotl` (force-inlining
   reproduces the census inline shape at plain -O1 and collapses the closure into
   one straight-line body — recipe lesson bd 20xt.2). The x86_fp80 unions are
   kept VERBATIM — the promoteFp80Union pass owns them, never a memcpy word shim
   (3c6m.51 ld80 convention).

   KEEP-SET CALLS: the only libm calls in the closure are fabsl (3 sites) and
   sqrtl (2 sites). Both are Rule-18 HARDWARE KEEPS: at the ship floor (plain
   `clang -O1`, builtins ON) the named calls fold to @llvm.fabs.f80 /
   @llvm.sqrt.f80 before codegen, and cq-lowering rewrites those to
   cq_template_fabs_f80 / cq_template_sqrt_f80. `__builtin_fabsl` /
   `__builtin_sqrtl` are the deliberate spelling of that SAME construct (no libm
   declaration needed); this is not a body substitution — a keep has no
   injectable body by definition. That fold is exactly what the fixed harness
   restored: under the old blanket -fno-builtin census these resolved to
   openlibm's SOFTWARE bodies and dragged their loops into the cell.

   STATUS — SHIPS AT THE PLAIN -O1 SHIP FLOOR since bd 3c6m.61 (2026-07-28).
   This file was parked as `.c.DECLINED` from 2026-07-25 until then; it is now
   wired into tests/e2e/CMakeLists.txt with a golden, and it was the LAST
   census-pipeline-only cell (a cell the census scored COMPILES that did not
   actually ship). With it, injection-covered and verified coincide again.

   WHAT ACTUALLY BLOCKED IT — and what did not. The parked header and the
   original bd 3c6m.61 description both blamed the CONTROL SHAPE: a 5-way
   multi-exit funnel with the `(manh|manl)==0` condition re-used below its
   merge, "outside every shipped accept shape". That was the pre-q2wk PredMux
   leave reason, and it was WRONG as a diagnosis of the residual. Measured with
   CQ_PREDMUX_DBG on the -O1 IR, the ROOT region (entry -> the 5-incoming exit
   phi, i.e. the whole funnel) passes E1/E2/E3 outright: PredMux's grammar DOES
   reduce this funnel. Its one leave was `E4-dataflow`, and every other
   `E3-sideentry`/`E3-mergepred` line in the trace is a SUB-region candidate
   probed after the root was left — a consequence, not an independent blocker.

   The real gate was one instruction: the Inf/NaN arm's

       GET_LDBL_MAN(manh, manl, a);
       if (manh == LDBL_NBIT && manl == 0) w = a;

   which clang -O1 + promoteFp80Union fuse into
       icmp eq i80 (and i80 %bits, 0xFFFF'FFFF'FFFF'FFFF), 0x8000'0000'0000'0000
   feeding an f80 select. PredMux's E4 clause blanket-excluded EVERY i80
   compare, on a comment that asserted "the canonical promotion never puts
   those inside an arm" — a claim this body falsifies. 3c6m.61 admits the
   provably-`_hl` form (exactly one ConstantInt operand), which lowers on the
   already-frozen §6.0 grid: `cq_template_icmp_eq_i80_hl` + its void `_unc`
   twin. NO new gate sequence, NO new frozen symbol, NO YAML edit. The Q+Q i80
   compare stays declined, as does an i80 BRANCH condition and an i80 compare
   inside a speculated pure CALLEE body — see the three decline fixtures
   ir-pass/test/control_predmux_reject_i80_cmp_{qq,branchcond,purecallee}.ll.
   (Precisely, since an earlier draft of this header got it wrong: i80 DOES ship
   a QQ compare row and a Q+Q i80 compare in the DATA position lowers fine; what
   is fenced is the SELECT-LEAF flag mint, `qqSelectLeafWidth`. The one-
   ConstantInt gate is a single conservative rule covering both positions,
   because PredMux cannot cheaply tell them apart pre-flatten.)

   So this was a WIDTH-axis gap wearing a control-shape costume, exactly as the
   post-q2wk bd note concluded. It is a recognizer gap, never a physics wall
   (Bennett.jl ground truth, 3c6m.50: zero C-physics walls in this surface).

   WHAT THE CELL EXERCISES (1207 trace lines, 249 cqrt_free sites, all
   free-pairing verified): the tainted `xbits.expsign` extract of x (the
   classical y = 0.5L one const-folds); the three SET_LDBL_EXPSIGN exponent
   read-modify-writes on a and b, which survive -O1 as alloca/gep/store/load
   pairs and are consumed by promoteFp80Union; the
   bits.manh/manl subnormal and Inf/NaN mantissa tests (the two i80 compares
   this ticket unblocked — one plain, one under a `cqrt_toffoli` AND with the
   `hb >= ESW(MAX_EXP)` i32 flag); the w>b two-product split with its
   `bits.manl = 0` i80 mask truncations; and cq_template_fabs_f80 /
   cq_template_sqrt_f80 for the two curated keep-intrinsics.

   IT DOES *NOT* EXERCISE THE SHADOW STORE PATH. The parked header predicted it
   would ("a second reason to keep the artifact"), and an earlier draft of THIS
   header repeated that prediction as fact until a Rule-13 lens checked it: the
   LOWERED module contains ZERO `cqrt_qram_*` symbols and zero store/load/alloca.
   promoteFp80Union rewrites every union RMW to pure bitcast/lshr/and/or/shl/
   zext/trunc, so nothing reaches the Shadow model; only the two
   `@llvm.lifetime.*` markers survive, and they are no-ops.

   WHAT THE GOLDEN DOES AND DOES NOT WITNESS. It witnesses that every emitted
   symbol resolves, signature-matches, links and runs, and that the gate stream
   is byte-deterministic — which, together with stage 2b's rail-level free
   pairing, is the Rule-2 contract. It does NOT witness VALUE ROUTING: the
   runtime is trace-only (no simulation at this stage, owner decision
   2026-06-10), and for this cell's concrete arguments the source-level Inf/NaN
   branch — the sole home of BOTH newly-admitted i80 compares — is not the taken
   path. Post-flatten every arm's gates execute unconditionally, so the compares
   ARE minted, stripped and freed, and that pairing IS pinned here. Which value
   the merge selects rests on the analytic argument plus the Rule-13 round, not
   on this trace. That is true of every slice in this corpus; it is spelled out
   here because this is the cell that motivated the increment. */
#include <stdint.h>

typedef unsigned int u_int32_t;

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

/* x86_fp80 <float.h> values. */
#define	LDBL_MANT_DIG	64
#define	LDBL_MAX_EXP	16384

/* openlibm src/math_private.h (verbatim). */
#define	GET_LDBL_EXPSIGN(i,d)					\
do {								\
  union IEEEl2bits ge_u;					\
  ge_u.e = (d);							\
  (i) = ge_u.xbits.expsign;					\
} while (0)

#define	SET_LDBL_EXPSIGN(d,v)					\
do {								\
  union IEEEl2bits se_u;					\
  se_u.e = (d);							\
  se_u.xbits.expsign = (v);					\
  (d) = se_u.e;							\
} while (0)

/* openlibm src/e_hypotl.c macro block (verbatim). */
#define	GET_LDBL_MAN(h, l, v) do {	\
	union IEEEl2bits uv;		\
					\
	uv.e = v;			\
	h = uv.bits.manh;		\
	l = uv.bits.manl;		\
} while (0)

#undef GET_HIGH_WORD
#define	GET_HIGH_WORD(i, v)	GET_LDBL_EXPSIGN(i, v)
#undef SET_HIGH_WORD
#define	SET_HIGH_WORD(v, i)	SET_LDBL_EXPSIGN(v, i)

#define	DESW(exp)	(exp)		/* delta expsign word */
#define	ESW(exp)	(MAX_EXP - 1 + (exp))	/* expsign word */
#define	MANT_DIG	LDBL_MANT_DIG
#define	MAX_EXP		LDBL_MAX_EXP

/* LDBL_MANL_SIZE == 32 on x86-64, so the #if arm taken is the 32-bit one. */
typedef	u_int32_t man_t;

/* openlibm src/e_hypotl.c hypotl (verbatim; fabsl -> __builtin_fabsl and
   sqrtl -> __builtin_sqrtl, the SAME @llvm.fabs.f80 / @llvm.sqrt.f80 the ship
   floor emits for the named calls). */
__attribute__((always_inline)) static inline long double
olm_hypotl(long double x, long double y)
{
	long double a=x,b=y,t1,t2,y1,y2,w;
	int32_t j,k,ha,hb;

	GET_HIGH_WORD(ha,x);
	ha &= 0x7fff;
	GET_HIGH_WORD(hb,y);
	hb &= 0x7fff;
	if(hb > ha) {a=y;b=x;j=ha; ha=hb;hb=j;} else {a=x;b=y;}
	a = __builtin_fabsl(a);
	b = __builtin_fabsl(b);
	if((ha-hb)>DESW(MANT_DIG+7)) {return a+b;} /* x/y > 2**(MANT_DIG+7) */
	k=0;
	if(ha > ESW(MAX_EXP/2-12)) {	/* a>2**(MAX_EXP/2-12) */
	   if(ha >= ESW(MAX_EXP)) {	/* Inf or NaN */
	       man_t manh, manl;
	       /* Use original arg order iff result is NaN; quieten sNaNs. */
	       w = __builtin_fabsl(x+0.0)-__builtin_fabsl(y+0.0);
	       GET_LDBL_MAN(manh,manl,a);
	       if (manh == LDBL_NBIT && manl == 0) w = a;
	       GET_LDBL_MAN(manh,manl,b);
	       if (hb >= ESW(MAX_EXP) && manh == LDBL_NBIT && manl == 0) w = b;
	       return w;
	   }
	   /* scale a and b by 2**-(MAX_EXP/2+88) */
	   ha -= DESW(MAX_EXP/2+88); hb -= DESW(MAX_EXP/2+88);
	   k += MAX_EXP/2+88;
	   SET_HIGH_WORD(a,ha);
	   SET_HIGH_WORD(b,hb);
	}
	if(hb < ESW(-(MAX_EXP/2-12))) {	/* b < 2**-(MAX_EXP/2-12) */
	    if(hb <= 0) {		/* subnormal b or 0 */
	        man_t manh, manl;
		GET_LDBL_MAN(manh,manl,b);
		if((manh|manl)==0) return a;
		t1=1;
		SET_HIGH_WORD(t1,ESW(MAX_EXP-2));	/* t1=2^(MAX_EXP-2) */
		b *= t1;
		a *= t1;
		k -= MAX_EXP-2;
	    } else {		/* scale a and b by 2^(MAX_EXP/2+88) */
		ha += DESW(MAX_EXP/2+88);
		hb += DESW(MAX_EXP/2+88);
		k -= MAX_EXP/2+88;
		SET_HIGH_WORD(a,ha);
		SET_HIGH_WORD(b,hb);
	    }
	}
    /* medium size a and b */
	w = a-b;
	if (w>b) {
	    t1 = a;
	    union IEEEl2bits uv;
	    uv.e = t1; uv.bits.manl = 0; t1 = uv.e;
	    t2 = a-t1;
	    w  = __builtin_sqrtl(t1*t1-(b*(-b)-t2*(a+t1)));
	} else {
	    a  = a+a;
	    y1 = b;
	    union IEEEl2bits uv;
	    uv.e = y1; uv.bits.manl = 0; y1 = uv.e;
	    y2 = b - y1;
	    t1 = a;
	    uv.e = t1; uv.bits.manl = 0; t1 = uv.e;
	    t2 = a - t1;
	    w  = __builtin_sqrtl(t1*y1-(w*(-w)-(t1*y2+t2*b)));
	}
	if(k!=0) {
	    u_int32_t high;
	    t1 = 1.0;
	    GET_HIGH_WORD(high,t1);
	    SET_HIGH_WORD(t1,high+DESW(k));
	    return t1*w;
	} else return w;
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_hypotl(q, 0.5L));
}

int main(void) {
    (void) slice();
    return 0;
}
