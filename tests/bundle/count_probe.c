/* tests/bundle: the bundle's result entries and string formatters, run natively against the bundle's own bodies
 * (cq-cdf9z, cq-2s5ho; owner ruling 2026-11-12 item 5). Linked with bundle/cq_bundle_v1.bc by check_bundle.py;
 * the bundle's two bodiless boundaries are stubbed here (__cq_syscall) or the host's (malloc, free, realloc).
 * The bundle's TLS object holds the C locale, so a character above 0x7f does not encode (musl's C locale). */
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <wchar.h>

int __cq_count_snprintf(char *, size_t, const char *, ...);
int __cq_count_vsnprintf(char *, size_t, const char *, va_list);
int __cq_count_wprintf(const wchar_t *, ...);
int __cq_count_vwprintf(const wchar_t *, va_list);
int __cq_count_wctomb(char *, wchar_t);
size_t __cq_count_wcsrtombs(char *, const wchar_t **, size_t, mbstate_t *);
long __cq_syscall(long n, long a, long b, long c, long d, long e, long f) { return -38; /* ENOSYS */ }

static int vs(const char *fmt, ...) { va_list ap; va_start(ap, fmt); int r = __cq_count_vsnprintf(0, 0, fmt, ap); va_end(ap); return r; }
static int vw(const wchar_t *fmt, ...) { va_list ap; va_start(ap, fmt); int r = __cq_count_vwprintf(fmt, ap); va_end(ap); return r; }

int main(void)
{
	int bad = 0;
	char buf[64], mb[8];
	const wchar_t *ws = L"abc", *wbad = L"a\xe9";
	wchar_t wbuf[16];
#define EXPECT(e, v) do { long long g_ = (long long)(e); if (g_ != (long long)(v)) { bad = 1; \
	fprintf(stderr, "FAIL %s = %lld, want %lld\n", #e, g_, (long long)(v)); } } while (0)
	EXPECT(__cq_count_snprintf(0, 0, "%d %s|%5.2f", 42, "ab", 3.14159), 11);
	EXPECT(vs("%x%c", 255u, 'z'), 3);
	EXPECT(__cq_count_wprintf(L"ab%d%ls", 123, L"xy"), 7);
	EXPECT(vw(L"%s!", "hi"), 3);
	EXPECT(__cq_count_wprintf(L"\xe9"), -1);
	EXPECT(__cq_count_wctomb(mb, L'A'), 1);
	EXPECT(__cq_count_wctomb(mb, 0xe9), -1);
	EXPECT(__cq_count_wcsrtombs(0, &ws, 0, 0), 3);
	EXPECT(__cq_count_wcsrtombs(0, &wbad, 0, 0), (size_t)-1);
	EXPECT(sprintf(buf, "%05d|%s", -12, "q"), 7);
	EXPECT(strcmp(buf, "-0012|q"), 0);
	EXPECT(swprintf(wbuf, 16, L"%d", 77), 2);
	int x = 0; EXPECT(sscanf("  91 z", "%d", &x), 1); EXPECT(x, 91);
	return bad;
}
