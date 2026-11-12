/* musl's src/fenv/fenv.c and fegetexceptflag.c shapes for an arch without fenv (the module's bodies, never lifted). */
typedef unsigned short fexcept_t;
typedef struct fenv fenv_t;
int fetestexcept(int m) { (void)m; return 0; }
int fegetexceptflag(fexcept_t *fp, int m) { *fp = (fexcept_t)fetestexcept(m); return 0; }
int fegetenv(fenv_t *e) { (void)e; return 0; }
