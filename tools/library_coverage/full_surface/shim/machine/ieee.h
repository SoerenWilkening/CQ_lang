/*
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
