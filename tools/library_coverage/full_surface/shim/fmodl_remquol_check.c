/* Functional validation that the reconstructed <machine/ieee.h> yields CORRECT
   openlibm ld80 bodies (a wrong field layout would compile clean and silently
   compute garbage). The two TUs are compiled with -Dfmodl=ol_fmodl /
   -Dremquol=ol_remquol so we can diff them against the host libm. */
#include <math.h>
#include <stdio.h>
#include <string.h>

long double ol_fmodl(long double, long double);
long double ol_remquol(long double, long double, int *);

static int fail = 0, n = 0;

static int same(long double a, long double b) {
	unsigned char x[16], y[16];
	memset(x, 0, sizeof x); memset(y, 0, sizeof y);
	memcpy(x, &a, 10); memcpy(y, &b, 10);   /* 10 significant bytes */
	return memcmp(x, y, 10) == 0;
}

static void t(long double x, long double y) {
	long double got = ol_fmodl(x, y), want = fmodl(x, y);
	int qg = 0, qw = 0;
	long double rg = ol_remquol(x, y, &qg), rw = remquol(x, y, &qw);
	n++;
	if (!same(got, want)) {
		printf("FMODL   MISMATCH x=%.20Lg y=%.20Lg got=%.20Lg want=%.20Lg\n", x, y, got, want);
		fail = 1;
	}
	/* Two DOCUMENTED, shim-independent deviations are excluded:
	   (a) openlibm ld80 chooses n=31 quotient bits, the host n=3 -> compare
	       only the low 3 bits of |quo| (C11 7.12.10.3 makes n implementation-
	       defined, >= 3);
	   (b) UPSTREAM OPENLIBM BUG ld80/s_remquol.c:89 -- the |x|==|y| branch does
	       `*quo = 1;` where the f64 twin src/s_remquo.c:54 does
	       `*quo = (sxy ? -1 : 1);`, so a negative unit quotient loses its sign.
	       A literal constant with no dependence on <machine/ieee.h>. */
	int m = 7;
	int ag = qg < 0 ? -qg : qg, aw = qw < 0 ? -qw : qw;
	int sg = qg < 0, sw = qw < 0;
	int upstream_bug = (ag == 1 && aw == 1 && sg != sw && rg == 0);
	if (!same(rg, rw) || (ag & m) != (aw & m) || (!upstream_bug && qg && qw && sg != sw)) {
		printf("REMQUOL MISMATCH x=%.20Lg y=%.20Lg got=%.20Lg/%d want=%.20Lg/%d\n",
		       x, y, rg, qg, rw, qw);
		fail = 1;
	}
}

int main(void) {
	static const long double v[] = {
		1.0L, 2.0L, 3.0L, 0.5L, 1.5L, 7.0L, 10.0L, 100.0L, 1e10L, 1e-10L,
		3.14159265358979323846L, 2.718281828459045235L, 0.1L, 1.0L/3.0L,
		1e300L, 1e-300L, 0x1p-16000L, 65536.0L, 1.0L + 0x1p-63L,
	};
	const int N = (int)(sizeof v / sizeof v[0]);
	for (int i = 0; i < N; i++)
		for (int j = 0; j < N; j++) {
			t(v[i], v[j]);
			t(-v[i], v[j]);
			t(v[i], -v[j]);
			t(-v[i], -v[j]);
		}
	/* the data-dependent-trip path proper: widely separated exponents */
	for (int e = 0; e < 200; e += 7) {
		long double x = 1.7L;
		for (int k = 0; k < e; k++) x *= 2.0L;
		t(x, 1.3L);
		t(x, 0.9L);
	}
	printf("%d cases, %s\n", n, fail ? "RESULT: FAIL" : "RESULT: PASS");
	return fail;
}
