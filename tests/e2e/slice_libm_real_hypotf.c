/* slice_libm_real_hypotf.c — bd q2wk (PredMux L6 inc 5): the REAL openlibm
   hypotf body. This cell is the E6 sub-rule (B) witness — see LOWERING below.

   CORPUS VENDORED (one file, the whole closure):
     /private/tmp/openlibm_reclone/src/e_hypotf.c — __ieee754_hypotf(x,y), the
     entire algorithm (exponent-word ordering/swap, the 2**30 ratio early-out,
     the Inf/NaN arm, the 2**-68 / 2**68 / 2**126 rescalings, the two
     extended-precision sqrtf forms, and the k-exponent rescale of the result).
     There is no other openlibm .c in the closure: after the keep-set rewrite
     below, e_hypotf.c calls nothing but hardware keeps.

   MECHANICAL EDITS (declared, in corpus order; no algorithmic change — every
   constant, branch, comparison and expression is byte-for-byte the corpus text,
   and every interior comment is preserved verbatim):
     - deleted, in corpus order: the file-title comment block (corpus lines 1-3,
       "float version of e_hypot.c / Conversion to float by Ian Lance Taylor"),
       the SunPro copyright/license block (lines 5-14), the include of
       cdefs-compat.h (line 16), the //__FBSDID comment (line 17), the include
       of openlibm_math.h (line 19), the include of math_private.h (line 21),
       and the OLM_DLLEXPORT storage marker (line 23). Every one of these is
       comment, include or storage-class text; none removes an executable
       statement. e_hypotf.c has NO algorithm prose comment (it defers to
       e_hypot.c), NO file-scope static const tables, and NO trailing
       openlibm_weak_reference / LDBL_MANT_DIG block — the corpus file ends at
       line 84 with the closing brace — so there was nothing else to strip.
     - entry point __ieee754_hypotf (line 24) renamed to olm_hypotf and marked
       always_inline static inline (forces the census inline shape at plain -O1,
       collapsing the closure into ONE FUNCTION — recipe lesson bd 20xt.2). It
       is NOT straight-line at that point: pre-pass @slice has 17 basic blocks,
       16 br (8 of them conditional), 12 phi and 3 select. The straight line is
       produced later, by the pass's PredMux flatten; the lowered @slice is 2
       basic blocks with exactly 1 br, an unconditional edge into the measure
       block.
     - the math_private.h word macros GET_FLOAT_WORD (2 sites, corpus lines 29
       and 31) and SET_FLOAT_WORD (9 sites, corpus lines 48, 49, 54, 62, 63, 69,
       74, 76, 81) expanded in place, in source order, to
       the __builtin_memcpy 4-byte pun shim that clang -O1 folds to the same
       bitcast IR (same idiom as the acos/atan/hypot slices). The macro-local
       union temp is replaced by one function-scope `uint32_t word`; every
       expansion is a self-contained write-then-read (GET) or write-then-copy
       (SET) with no intervening use, so that sharing is semantically identical.
       SET_FLOAT_WORD is a pure whole-word WRITE (unlike the f64 SET_HIGH_WORD),
       so each expansion is ONE memcpy, not a read-modify-write pair.
       Every GET_/SET_FLOAT_WORD site in this file has a `float` first/second
       operand (x, y, a, b, t1, y1) — there is NO double-to-float-word site here,
       so the k_expf.c __frexp_expf narrowing hazard does not arise; the `word`
       temp is uint32_t exactly as ieee_float_shape_type.word is `unsigned int`,
       preserving the macro's implicit int32_t<->uint32_t conversions.
     - the BSD type spelling u_int32_t does not occur in this file; int32_t is
       used as in the corpus, with <stdint.h> added for it and for uint32_t.

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution):
     e_hypotf.c calls fabsf (4 sites: fabsf(a), fabsf(b), and the two in the
     NaN-quieting w = fabsf(x+0.0F) - fabsf(y+0.0F)) and __ieee754_sqrtf (2
     sites, one per branch of the medium-size split). Both are HARDWARE KEEPS:
     at the real ship floor (plain clang -O1, builtins ON) the named calls fold
     to @llvm.fabs.f32 / @llvm.sqrt.f32 before codegen, and cq-lowering rewrites
     those to cq_template_fabs_f32 / cq_template_sqrt_f32. The __builtin_fabsf /
     __builtin_sqrtf spellings emit exactly that construct and need no libm
     declaration. By definition a keep has no injectable body, so vendoring
     openlibm's software e_sqrtf.c / s_fabsf.c here would MISREPRESENT the ship
     floor — that blanket -fno-builtin resolution is the census bug bd 3c6m.60
     fixed.

   LOWERING EXERCISED (every figure below MEASURED on the lowered IR / trace,
   never asserted): a tainted-x / classical-y (0.5f) hypotf. The magnitude
   ordering `if(hb > ha) {a=y;b=x;...}` is a tainted-condition swap of two fp
   registers, and the rescale cascade (2**68 / 2**-68 / subnormal) plus the
   `w > b` medium-size split are nested tainted classifications — all of it
   flattens through PredMux onto the select substrate: 28 cqrt_copy_f32_
   controlled + 18 cqrt_copy_i32_controlled merges, 222 cqrt_toffoli flag
   conjunctions, 72 cqrt_cnot, 46 cqrt_x, and each fcmp/icmp template paired
   1:1 with its _inv strip (e.g. 50 cq_template_icmp_ule_i32_hl / 50 _inv,
   21 icmp_ugt / 21 _inv, 21 icmp_slt / 21 _inv, 1 fcmp_ogt / 1 _inv). The
   word-level integer work — the GET_/SET_FLOAT_WORD punning together with the
   corpus's own exponent-word masks, the ±0x22000000 rescales, the k<<23
   exponent build and the ha-hb difference — becomes bitcast/mask/add template
   chains after SROA; counted over the whole trace: 8 cq_template_bitcast_i32_
   to_f32, 1 cq_template_bitcast_f32_to_i32, 3 and_i32_hl, 7 add_i32_hl,
   1 shl_i32_hl, 1 or_i32_hl, 1 sub_i32.
   Rail traffic: 139 allocations (111 cqrt_alloc_i1, 17 cqrt_alloc_f32,
   11 cqrt_alloc_i32) and 227 cqrt_free, against 425 handles minted in total
   (allocs + template results), so 198 rails are left allocated at exit — the
   Rule-6 "not provably |0⟩ is left allocated, never freed dirty" leak. The
   trace is handle-linear: zero double-free, zero use-after-free, zero use of
   an unproduced handle. Exactly 1 cqrt_ry_f32 and exactly 1 cqrt_measure_f32.
   Lowered @slice holds 1040 call instructions, 2 basic blocks, 1 unconditional
   br, 0 phi and 0 select, and the golden trace is 1040 lines — the flattened
   body is straight-line, so every emitted call executes exactly once.

   THE SUB-RULE (B) WITNESS. The construct that blocked this cell before q2wk is
   in pre-pass @slice:  %89 = icmp eq i32 %54, 0  used directly as a conditional
   branch condition, where %54 = phi i32 [ %44, %41 ], [ %48, %45 ], [ %33, %30 ]
   is the corpus's `k` scale accumulator and %33 is itself phi i32 [ 68, %25 ],
   [ 0, %15 ]. Every incoming is a compile-time constant, so %54 carries NO taint
   at detection time — it is the region-internal-phi-derived condition that the
   flatten itself taints (E6 sub-rule (B)). At the ship floor `opt` now exits 0
   and the whole diamond nest collapses to the single straight-line block above.

   KEEP-SET FOLD ACCOUNTING (measured on the pre-pass IR; NEITHER shortfall is
   an arm the pass dropped):
     - 4 fabsf source sites -> 4 @llvm.fabs.f32 call sites, but NOT 1:1. -O1
       const-folded the classical site fabsf(y+0.0F) into the constant
       -5.000000e-01 addend (y is the literal 0.5f), and it expressed the
       `ha &= 0x7fffffff` word mask as bitcast(fabs(q)) — so the pre-pass entry
       block carries three llvm.fabs.f32(%q) call sites and the Inf/NaN arm
       (pre-pass block %19) carries the fourth, llvm.fabs.f32(%q + 0.0), whose
       result feeds `fadd %21, -5.000000e-01`. All 4 lower to 4
       cq_template_fabs_f32.
     - 2 __ieee754_sqrtf source sites -> 1 @llvm.sqrt.f32: SimplifyCFG
       TAIL-MERGED the two identical calls into their common successor and
       applied the one surviving call to the merge phi. BOTH arms of the `w > b`
       split SURVIVE -O1 intact and BOTH are lowered — the true (w > b) arm
       carries 2 of the fmuladds and the else arm carries the other 3, which is
       exactly the 5 cq_template_fma_f32 counted below.
     - `if(hb == 0x7f800000) w = b;` is the ONE source classification -O1 folded
       away, and it folded on the CLASSICAL operand: hb is umin(word, 0x3f000000)
       so hb <= 0x3f000000 < 0x7f800000 is provably false when y is the literal
       0.5f. Every other classification survives to the pass and is lowered: the
       (ha-hb)>0xf000000 early-out, the ha>0x58800000 / ha>=0x7f800000 Inf-NaN
       pair, the ha==0x7f800000 quieting select, the hb<0x26800000 /
       hb<=0x007fffff / hb==0 subnormal chain, the w>b medium split and the k!=0
       rescale — the 8 conditional br counted above.
   Every llvm.* construct clang -O1 hands the pass is lowered 1:1, nothing
   dropped: 4 llvm.fabs.f32 -> 4 cq_template_fabs_f32, 1 llvm.sqrt.f32 -> 1
   cq_template_sqrt_f32, 5 llvm.fmuladd.f32 -> 5 cq_template_fma_f32 (clang's
   default fp-contract fuses the extended-precision products; fma/fmuladd is
   likewise a Rule-18 keep), and 1 llvm.umax.i32 / 1 llvm.umin.i32 -> 1
   cq_template_umax_i32_hl / 1 cq_template_umin_i32_hl. Those last two are
   SYNTHESIZED BY CLANG out of the source's own `if(hb > ha) {a=y;b=x;...}`
   magnitude swap (legal because both words are pre-masked with 0x7fffffff, so
   signed and unsigned compare alike) — clang canonicalizations of stock C
   comparisons, NOT a library body swapped in by a name recognizer, so Rule 18
   is not in play for them. That is 12 llvm.* call sites in, 12 templates out.
   The lowered module has ZERO residual cq_* intrinsic calls and ZERO llvm.*
   CALL SITES — but 5 now-unused `declare @llvm.*` lines do survive in the
   lowered module with no uses, so a bare grep for @llvm. is not a refutation of
   that claim. This slice is the LINK-layer proof (Rule 2) that every emitted
   symbol resolves, signature-matches, and the trace is stable (byte-identical
   across two runs). */
#include <stdint.h>

/* openlibm src/e_hypotf.c __ieee754_hypotf (verbatim; word macros expanded to
   the __builtin_memcpy shim, fabsf/sqrtf spelled as the hardware-keep
   builtins). */
__attribute__((always_inline)) static inline float olm_hypotf(float x, float y)
{
	float a,b,t1,t2,y1,y2,w;
	int32_t j,k,ha,hb;
	uint32_t word;

	__builtin_memcpy(&word,&x,4); ha = word;	/* GET_FLOAT_WORD(ha,x) */
	ha &= 0x7fffffff;
	__builtin_memcpy(&word,&y,4); hb = word;	/* GET_FLOAT_WORD(hb,y) */
	hb &= 0x7fffffff;
	if(hb > ha) {a=y;b=x;j=ha; ha=hb;hb=j;} else {a=x;b=y;}
	a = __builtin_fabsf(a);
	b = __builtin_fabsf(b);
	if((ha-hb)>0xf000000) {return a+b;} /* x/y > 2**30 */
	k=0;
	if(ha > 0x58800000) {	/* a>2**50 */
	   if(ha >= 0x7f800000) {	/* Inf or NaN */
	       /* Use original arg order iff result is NaN; quieten sNaNs. */
	       w = __builtin_fabsf(x+0.0F)-__builtin_fabsf(y+0.0F);
	       if(ha == 0x7f800000) w = a;
	       if(hb == 0x7f800000) w = b;
	       return w;
	   }
	   /* scale a and b by 2**-68 */
	   ha -= 0x22000000; hb -= 0x22000000;	k += 68;
	   word = ha; __builtin_memcpy(&a,&word,4);	/* SET_FLOAT_WORD(a,ha) */
	   word = hb; __builtin_memcpy(&b,&word,4);	/* SET_FLOAT_WORD(b,hb) */
	}
	if(hb < 0x26800000) {	/* b < 2**-50 */
	    if(hb <= 0x007fffff) {	/* subnormal b or 0 */
	        if(hb==0) return a;
		word = 0x7e800000; __builtin_memcpy(&t1,&word,4);	/* SET_FLOAT_WORD(t1,0x7e800000);  t1=2^126 */
		b *= t1;
		a *= t1;
		k -= 126;
	    } else {		/* scale a and b by 2^68 */
	        ha += 0x22000000; 	/* a *= 2^68 */
		hb += 0x22000000;	/* b *= 2^68 */
		k -= 68;
		word = ha; __builtin_memcpy(&a,&word,4);	/* SET_FLOAT_WORD(a,ha) */
		word = hb; __builtin_memcpy(&b,&word,4);	/* SET_FLOAT_WORD(b,hb) */
	    }
	}
    /* medium size a and b */
	w = a-b;
	if (w>b) {
	    word = ha&0xfffff000; __builtin_memcpy(&t1,&word,4);	/* SET_FLOAT_WORD(t1,ha&0xfffff000) */
	    t2 = a-t1;
	    w  = __builtin_sqrtf(t1*t1-(b*(-b)-t2*(a+t1)));
	} else {
	    a  = a+a;
	    word = hb&0xfffff000; __builtin_memcpy(&y1,&word,4);	/* SET_FLOAT_WORD(y1,hb&0xfffff000) */
	    y2 = b - y1;
	    word = (ha+0x00800000)&0xfffff000; __builtin_memcpy(&t1,&word,4);	/* SET_FLOAT_WORD(t1,(ha+0x00800000)&0xfffff000) */
	    t2 = a - t1;
	    w  = __builtin_sqrtf(t1*y1-(w*(-w)-(t1*y2+t2*b)));
	}
	if(k!=0) {
	    word = 0x3f800000+(k<<23); __builtin_memcpy(&t1,&word,4);	/* SET_FLOAT_WORD(t1,0x3f800000+(k<<23)) */
	    return t1*w;
	} else return w;
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_hypotf(q, 0.5f));
}
int main(void) { (void) slice(); return 0; }
