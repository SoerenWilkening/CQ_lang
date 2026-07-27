/* Empirical validation of the reconstructed <machine/ieee.h> fp80 layout.
   Compares the struct-field view against the raw 10 significant bytes of the
   x86 long double for a set of known values. Exits non-zero on any mismatch. */
#include <machine/ieee.h>
#include <stdio.h>
#include <string.h>

union u { long double e; struct ieee_ext bits; unsigned char b[sizeof(long double)]; };

static int fail = 0;

static void chk(const char *name, long double v,
                unsigned sign, unsigned exp, unsigned frach, unsigned fracl) {
	union u u;
	memset(&u, 0, sizeof u);
	u.e = v;
	/* raw view: bytes 0..7 = 64-bit significand (incl. explicit integer bit),
	   bytes 8..9 = sign(1) | exponent(15) */
	unsigned long long sig;
	unsigned short se;
	memcpy(&sig, u.b, 8);
	memcpy(&se, u.b + 8, 2);
	unsigned raw_sign = se >> 15, raw_exp = se & 0x7fff;
	unsigned raw_frach = (unsigned)(sig >> 32), raw_fracl = (unsigned)sig;

	int ok = u.bits.ext_sign == raw_sign && u.bits.ext_exp == raw_exp &&
	         u.bits.ext_frach == raw_frach && u.bits.ext_fracl == raw_fracl &&
	         raw_sign == sign && raw_exp == exp && raw_frach == frach &&
	         raw_fracl == fracl;
	printf("%-10s struct(s=%u e=%u h=%08x l=%08x) raw(s=%u e=%u h=%08x l=%08x) expect(s=%u e=%u h=%08x l=%08x) %s\n",
	       name, u.bits.ext_sign, u.bits.ext_exp, u.bits.ext_frach, u.bits.ext_fracl,
	       raw_sign, raw_exp, raw_frach, raw_fracl, sign, exp, frach, fracl,
	       ok ? "OK" : "MISMATCH");
	if (!ok) fail = 1;
}

int main(void) {
	printf("sizeof(long double)=%zu sizeof(struct ieee_ext)=%zu\n",
	       sizeof(long double), sizeof(struct ieee_ext));
	if (sizeof(struct ieee_ext) > sizeof(long double)) {
		printf("STRUCT LARGER THAN long double -- union aliasing invalid\n");
		fail = 1;
	}
	/* 1.0L  = +, exp 16383, significand 0x8000000000000000 */
	chk("1.0",  1.0L, 0, 16383, 0x80000000u, 0x00000000u);
	/* 2.0L  = +, exp 16384 */
	chk("2.0",  2.0L, 0, 16384, 0x80000000u, 0x00000000u);
	/* -1.0L */
	chk("-1.0", -1.0L, 1, 16383, 0x80000000u, 0x00000000u);
	/* 0.5L  = exp 16382 */
	chk("0.5",  0.5L, 0, 16382, 0x80000000u, 0x00000000u);
	/* 1.5L  = exp 16383, significand 0xC000000000000000 */
	chk("1.5",  1.5L, 0, 16383, 0xC0000000u, 0x00000000u);
	/* smallest low-word bit set: 1.0 + 2^-63 */
	chk("1+2^-63", 1.0L + 0x1p-63L, 0, 16383, 0x80000000u, 0x00000001u);
	/* +0.0 */
	chk("0.0",  0.0L, 0, 0, 0x00000000u, 0x00000000u);
	printf(fail ? "RESULT: FAIL\n" : "RESULT: PASS\n");
	return fail;
}
