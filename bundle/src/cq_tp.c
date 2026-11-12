/* The one thread's TLS object (CQ_spec LIBC_COVERAGE.md and _tools/musl_arch_cq/pthread_arch.h: __cq_tp,
 * "provided by the bundle"). As musl's __init_tp leaves it: zero, but struct pthread's `locale` (offset 168,
 * checked in cq_count.c) at a zero locale_t, what libc.global_locale holds at startup (the C locale). The same
 * object checker/cqcheck/user.py defines for a module that only declares it. No musl header: they declare
 * __cq_tp as `extern char []`. */
static void *cq_locale[6];

struct cq_tp {
	char head[168];
	void *locale;
	char tail[3920];
};

__attribute__((aligned(16))) struct cq_tp __cq_tp = { .locale = cq_locale };
