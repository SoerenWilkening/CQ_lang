/* j_gzgs_x5b_LIVE_merge.c — bd `test_C_libtooling-gzgs`, the NON-VACUOUS twin.
   VERBATIM COPY of session-2026-09-14c/trackX/probes/fp_x5b_m28_positive_delta3.c.

   m28 with the THIRD region's polarity flipped (`if (a < 3)`), so b1 is
   prepared on the b0==1 branch and |b0=1,b1=1> carries amplitude
   sin(0.25)^2 = 0.0612 (probability 0.0037). The merged arm ACTUALLY FIRES.

   MEASURED on the session ORACLE cq-opt 0e280fc62a91cec2:
     opt exit 0; 28 trace lines (j_gzgs_x5b.trace)
     STRICT 2b: 8 rail mint(s) of which 6 left allocated,
                1 template rail mint(s) of which 1 left dirty,
                2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven
     the ONLY trace difference from m28 is the prep spelling —
       m28: cqrt_ry_i1(h1,0.5); cqrt_ry_i1_controlled(h0,h1,-0.5)
       x5b: cqrt_ry_i1_controlled(h0,h1,0.5)
     and the DOWNSTREAM IS BYTE-IDENTICAL (diff of m28 lines 6..29 against x5b
     lines 5..28 is empty).

   ⚠ NOT PROMOTED TO AN e2e SLICE, deliberately. A golden would pin this
   stream as correct, and the F x P composition still has NO RULE-13 OPINION
   (MERGE_FILINGS.md F-1/F-2 of 2026-09-14: Track F cleared a binary on which
   Track P's leaf does not exist and vice versa). Rule 2 — a byte-identical
   golden proves every symbol resolves, never that the unitary is right. This
   probe makes the composition REVIEWABLE; it does not clear it. */

#include "CQ.h"
/* m28 with the THIRD region's polarity flipped, so b1 is prepared on the
   b0==1 branch and |b0=1,b1=1> has NON-ZERO amplitude.  m28 itself prepares b1
   on the NEGATED branch, so its fourth region (the one the F x P composition
   newly enables) acts on a ZERO-amplitude subspace. */
int main(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a < 3){ b1 = cq_theta(b1, 0.5); }
    if (b1 && b0) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
