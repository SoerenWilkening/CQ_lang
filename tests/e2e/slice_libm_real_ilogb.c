/* CQ_lang e2e verification slice — census cell ilogb.f64 (bd ww4c.3, Inc 2)
 * Vendors the REAL openlibm body of ilogb from:
 *   /private/tmp/openlibm/src/s_ilogb.c   (openlibm @82e90ae)
 * Self-contained (no dependency corpus files). Mechanical edits only:
 * #includes/license/FBSDID stripped; entry renamed to always_inline static
 * inline olm_ilogb; EXTRACT_WORDS expanded to the __builtin_memcpy idiom;
 * FP_ILOGB0 / FP_ILOGBNAN / INT_MAX spelled as their openlibm values.
 * NO constant, branch or expression changed — the two `for` loops are
 * verbatim, which is the point of this slice.
 *
 * WHAT THIS CELL PROVES (bd ww4c): both loops are COUNT-LEADING-ZEROS idioms
 * that Q1 (LoopLowering.cpp:1161) declined as "loop under quantum control"
 * until CtlzIdiomPrepass claimed them. The golden shows each loop as the
 * four-op closed form of PRD-ww4c-ctlz-idiom.md §4.3 — shl,1 -> ctlz -> and,N-1
 * -> sub C0-1,. — with NO residual loop and NO gate whose count depends on the
 * tainted word.
 *
 * WHAT THE GOLDEN CANNOT WITNESS, said plainly so the line above is not read as
 * more than it is: the `is_zero_poison` immarg. PRD §4.5(1) requires the
 * recognizer to emit `i1 false`, but Rule 15's width-only ABI DROPS the immarg,
 * so the trace reads `cq_template_ctlz_i32(h10) -> h11` and would read
 * byte-identically had the pass emitted `i1 true`. The immarg is pinned at the
 * IR layer instead, which is exactly the bd 8txa gap this project already
 * records: the golden and the IR fixtures witness different things, and neither
 * alone is the contract.
 *   NOTE (bd ww4c.4): when this comment was written the compensating control it
 * names DID NOT EXIST — no `lowering_ctlz_idiom_*.ll` contained the string
 * `i1 false`, and every positive CHECK asserted the LOWERED form, from which the
 * immarg has already been dropped. It exists now: the `IMMARG` check prefix in
 * lowering_ctlz_idiom_{unguarded_preshift,both_loops,chained}.ll reads the
 * pre-`detectSpecializations` module dump on stderr and pins `i1 false`
 * directly, mutant-validated against an `i1 true` doctoring. Cite those three
 * files, not the glob.
 *
 * Seeds, and they are DERIVED from each loop
 * rather than hardcoded: loop A `sub -1044,m` (C0=-1043) and loop B
 * `sub -1023,m` (C0=-1022), the two differing also in that only A keeps a
 * guard and only B carries a preheader pre-shift (`hx<<=11`).
 *
 * WHY THE ENCLOSING DIAMONDS FLATTEN — measured, not assumed (bd ww4c.3; PRD §7
 * item 5 listed this as an OPEN RISK and this is its answer). PredMux claims
 * this function's regions through the `(NumMergePhis == 1 && SolePhiIncomings
 * > 2)` disjunct at PredMuxFlatten.cpp:2485, which carries NO call fence: the
 * return merge here has SIX incomings. It is specifically NOT claimed by W7,
 * whose gate at :2306 requires exactly TWO incomings and whose taint-blind
 * clause (e) would reject the region for containing the substituted
 * `@llvm.ctlz` call. That is why the isolated 2-incoming spelling of loop A
 * still declines (ir-pass/test/lowering_ctlz_idiom_guarded_no_preshift.ll) while
 * this real cell lowers completely. The precondition is on the CALLER's merge
 * arity and the Z1-Z9 fence does not check it — so a future cell that claims and
 * then declines should be read as hitting clause (e), not as a fence bug.
 */
#include <stdint.h>
typedef uint32_t u_int32_t;
typedef uint64_t u_int64_t;
/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define GET_HIGH_WORD(i,d)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)(__w>>32); }while(0)
#define GET_LOW_WORD(i,d)      do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)__w; }while(0)
/* <limits.h> / openlibm_math.h values, verbatim:
     INT_MAX 2147483647 · FP_ILOGB0 (-INT_MAX) · FP_ILOGBNAN INT_MAX  */
#define INT_MAX      2147483647
#define FP_ILOGB0    (-INT_MAX)
#define FP_ILOGBNAN  INT_MAX

__attribute__((always_inline)) static inline int
olm_ilogb(double x)
{
	int32_t hx,lx,ix;

	EXTRACT_WORDS(hx,lx,x);
	hx &= 0x7fffffff;
	if(hx<0x00100000) {
	    if((hx|lx)==0)
		return FP_ILOGB0;
	    else			/* subnormal x */
		if(hx==0) {
		    for (ix = -1043; lx>0; lx<<=1) ix -=1;
		} else {
		    for (ix = -1022,hx<<=11; hx>0; hx<<=1) ix -=1;
		}
	    return ix;
	}
	else if (hx<0x7ff00000) return (hx>>20)-1023;
	else if (hx>0x7ff00000 || lx!=0) return FP_ILOGBNAN;
	else return INT_MAX;
}

int slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_ilogb(q));
}
int main(void) { (void) slice(); return 0; }
