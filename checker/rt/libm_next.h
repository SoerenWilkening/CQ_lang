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
#endif
