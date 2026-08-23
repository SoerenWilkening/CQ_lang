/*
 * *** RETIRED FROM THE CENSUS PIPELINE, 2026-08-23 (bd `3c6m.63`). ***
 * Nothing in the corpus build reads this header any more, and re-wiring it would
 * REINTRODUCE the defect it now records. It exists because it is solving a
 * problem that was created by building the wrong files: openlibm does NOT build
 * ld80/e_fmodl.c or ld80/s_remquol.c on any target (CMakeLists.txt:280/298 name
 * `src/e_fmodl.c` and `src/s_remquol.c`; ld80/Make.files:8 comments both out).
 * Both `src/` bodies compile cleanly under the plain corpus flag set — measured
 * 2026-08-23, rc=0 and 0 errors — because they use openlibm's own `fpmath.h`.
 * The old recipe reached the ld80 pair only because a basename collision made
 * `ld80/` win the shared output slot.
 *
 * KEPT, NOT DELETED, for one reason: the two validation programs beside it
 * (ieee_shim_check.c, fmodl_remquol_check.c) are the evidence of record for
 * measured claims that SCOPING-L3-data-dependent-trip-loops.md and bd
 * `20xt`/`tegx` still cite. Treat this directory as a historical artifact. If you
 * ever need an fp80 layout again, RE-VALIDATE it — do not assume the census
 * still exercises it, because it does not.
 *
 * ---------------------------------------------------------------------------
 * Minimal reconstruction of FreeBSD <machine/ieee.h> for x86 (i387 80-bit
 * extended), sufficient for openlibm's ld80/e_fmodl.c and ld80/s_remquol.c.
 *
 * openlibm does NOT ship this header (e_fmodl.c even has its #include
 * commented out) yet both TUs reference `struct ieee_ext` and the
 * EXT_FRAC*BITS macros, so they cannot be built from the corpus alone.
 * The layout below is validated empirically by ieee_shim_check.c: the union
 * { long double e; struct ieee_ext bits; } must reproduce the x86 fp80
 * sign/exponent/explicit-integer-bit/fraction fields exactly.
 */
#ifndef _MACHINE_IEEE_H_
#define _MACHINE_IEEE_H_

#define	EXT_EXPBITS	15
#define	EXT_FRACHBITS	32
#define	EXT_FRACLBITS	32
#define	EXT_FRACBITS	(EXT_FRACLBITS + EXT_FRACHBITS)

#define	EXT_EXP_INFNAN	32767
#define	EXT_EXP_BIAS	16383

struct ieee_ext {
	unsigned int	ext_fracl;
	unsigned int	ext_frach;
	unsigned int	ext_exp:EXT_EXPBITS;
	unsigned int	ext_sign:1;
	unsigned int	ext_pad:16;
};

#endif /* _MACHINE_IEEE_H_ */
