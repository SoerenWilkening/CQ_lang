/* The host libm entry points the evaluator uses, resolved past the program's own image (cq-1jvr6).
 *
 * The built program links the module under test beside this runtime. A module that defines a libm
 * name (musl's fmal, floorl, log2 ... lowered to the rail convention, `i32 @fmal(i32, i32, i32)`)
 * would capture the runtime's own call of that name. These wrappers call the system library's
 * function through dlsym(RTLD_NEXT), which never returns a definition in the program image. */
#ifndef CQE_LIBM_NEXT_H
#define CQE_LIBM_NEXT_H
#include <dlfcn.h>

#define CQE_LIBM_NEXT(ret, name, params, args)                                                    \
  static ret cqe_next_##name params {                                                             \
    static ret (*fn) params;                                                                      \
    if (!fn) fn = (ret(*) params)dlsym(RTLD_NEXT, #name);                                         \
    return fn args;                                                                               \
  }

/* The same for the C library's floating-point environment functions, which a lifted libc module defines too
 * (musl's fesetround, fegetround, ...): the runtime's own calls name the system's (cq-sucmp). A file that
 * includes this header gets the names below as macros. */
#include <fenv.h>
CQE_LIBM_NEXT(int, fesetround, (int r), (r))
CQE_LIBM_NEXT(int, fegetround, (void), ())
CQE_LIBM_NEXT(int, fegetenv, (fenv_t * e), (e))
CQE_LIBM_NEXT(int, fesetenv, (const fenv_t *e), (e))
CQE_LIBM_NEXT(int, feclearexcept, (int m), (m))
CQE_LIBM_NEXT(int, fetestexcept, (int m), (m))
CQE_LIBM_NEXT(int, feraiseexcept, (int m), (m))
#define fesetround cqe_next_fesetround
#define fegetround cqe_next_fegetround
#define fegetenv cqe_next_fegetenv
#define fesetenv cqe_next_fesetenv
#define feclearexcept cqe_next_feclearexcept
#define fetestexcept cqe_next_fetestexcept
#define feraiseexcept cqe_next_feraiseexcept

/* cq-jp8qu: the same for the C library's string formatters. A module that defines vsnprintf (the injection bundle's
 * musl vsnprintf, which cqcc links unrenamed and external beside printf's count entry) captured the runtime's own
 * vsnprintf calls (rt_tape.c sb_printf, the trace's event text, the driver's out events): the evaluator ran the
 * lowered printf_core, all-zero mask, on its own gates, inside the sample, for every event it wrote; a sample of
 * printf("%c%n") made more than 5e8 rails before the 6 GB cap. The variadic ones go to the system's vsnprintf (vswprintf). */
#include <stdarg.h>
#include <stdio.h>
CQE_LIBM_NEXT(int, vsnprintf, (char *s, size_t n, const char *f, va_list ap), (s, n, f, ap))
static int cqe_next_snprintf(char *s, size_t n, const char *f, ...) {
  va_list ap;
  va_start(ap, f);
  int r = cqe_next_vsnprintf(s, n, f, ap);
  va_end(ap);
  return r;
}
CQE_LIBM_NEXT(int, vsprintf, (char *s, const char *f, va_list ap), (s, f, ap))
static int cqe_next_sprintf(char *s, const char *f, ...) {
  va_list ap;
  va_start(ap, f);
  int r = cqe_next_vsprintf(s, f, ap);
  va_end(ap);
  return r;
}
#include <wchar.h>
CQE_LIBM_NEXT(int, vswprintf, (wchar_t *s, size_t n, const wchar_t *f, va_list ap), (s, n, f, ap))
static int cqe_next_swprintf(wchar_t *s, size_t n, const wchar_t *f, ...) {
  va_list ap;
  va_start(ap, f);
  int r = cqe_next_vswprintf(s, n, f, ap);
  va_end(ap);
  return r;
}
#undef vsnprintf
#undef snprintf
#undef vsprintf
#undef sprintf
#define vsnprintf cqe_next_vsnprintf
#define snprintf cqe_next_snprintf
#define vsprintf cqe_next_vsprintf
#define sprintf cqe_next_sprintf
#undef vswprintf
#undef swprintf
#define vswprintf cqe_next_vswprintf
#define swprintf cqe_next_swprintf
#endif
