/* The bundle-internal result entries (owner ruling 2026-11-12, item 5; cq-cdf9z). Compiled with musl's flags and
 * include paths like a musl unit; built in both bundle modes (bundle/build.py).
 *
 * The result of a deferred C library output call (rule 16, amended 2026-11-12) is the value musl's body returns when
 * every write succeeds, computed in the circuit by these lifted bodies. Each entry is a thin wrapper over the musl
 * function it is named after, under a reserved external name so that a call the pass inserts after the link
 * (pass/lib/eff/tape/Tape.cpp rewriteDeferredResults) can bind to a body whatever the program itself calls. The
 * names, signatures and the contract with consumers are listed in bundle/recipe.json "entries". */
#include "stdio_impl.h"
#include "pthread_impl.h"
#include <stdarg.h>
#include <stddef.h>
#include <stdlib.h>
#include <wchar.h>

/* bundle/src/cq_tp.c lays out the one thread's TLS object without musl's headers: keep it in step. */
_Static_assert(offsetof(struct pthread, locale) == 168, "cq_tp.c: struct pthread's locale moved");

/* printf, fprintf: the lifted snprintf(0, 0, fmt, args...) (snprintf's signature and body). */
int __cq_count_snprintf(char *restrict s, size_t n, const char *restrict fmt, ...)
{
	int ret;
	va_list ap;
	va_start(ap, fmt);
	ret = vsnprintf(s, n, fmt, ap);
	va_end(ap);
	return ret;
}

/* vprintf, vfprintf: the lifted vsnprintf(0, 0, fmt, ap) (vsnprintf's signature). */
int __cq_count_vsnprintf(char *restrict s, size_t n, const char *restrict fmt, va_list ap)
{
	return vsnprintf(s, n, fmt, ap);
}

/* The private FILE's write: discards what it is given and returns its length (every write succeeds). Like
 * vswprintf's sw_write it leaves the buffer empty for the next write. */
static size_t discard_write(FILE *f, const unsigned char *s, size_t l)
{
	f->wend = f->buf + f->buf_size;
	f->wpos = f->wbase = f->buf;
	return l;
}

/* vwprintf, vfwprintf: musl's vfwprintf (so wprintf_core) on a private FILE whose write discards. vswprintf cannot
 * serve: it returns -1 for size 0. The FILE is vsnprintf's (one-byte buffer, no buffering, no lock). */
int __cq_count_vwprintf(const wchar_t *restrict fmt, va_list ap)
{
	unsigned char buf[1];
	FILE f = {
		.lbf = EOF,
		.write = discard_write,
		.lock = -1,
		.buf = buf,
	};
	return vfwprintf(&f, fmt, ap);
}

/* wprintf, fwprintf. */
int __cq_count_wprintf(const wchar_t *restrict fmt, ...)
{
	int ret;
	va_list ap;
	va_start(ap, fmt);
	ret = __cq_count_vwprintf(fmt, ap);
	va_end(ap);
	return ret;
}

/* fputwc, putwc, putwchar: WEOF where this fails. */
int __cq_count_wctomb(char *s, wchar_t wc)
{
	return wctomb(s, wc);
}

/* fputws: -1 where this reports an encoding error. */
size_t __cq_count_wcsrtombs(char *restrict s, const wchar_t **restrict ws, size_t n, mbstate_t *restrict st)
{
	return wcsrtombs(s, ws, n, st);
}
