/* tests/calls probe (cq-il07; CR rules 18, 19, 23 at CQ_spec f684858): musl llrintl (FENV_ACCESS ON) converts
 * LLONG_MAX / LLONG_MIN with fpexcept.strict sitofp, classical host ops of the clone; its twin replays them
 * between a save and a restore of the host flags (calls::finalize), so the replay raises nothing.
 * Regenerate: the musl sweep (wt/musl_sweep sweep.py caller for llrintl), linked with musl b1efda5's libm (built as
 * CQ_spec LIBC_COVERAGE.md: -frounding-math -O1, the _tools/musl_arch_cq headers), internalized to
 * sweep_llrintl and globaldce'd into libm_musl_llrintl.O1.ll. */
long llrintl(long double);
long sweep_llrintl(long double a0) { long double buf[4] = {0}; cq_theta(&a0, 0.3); return cq_measure(llrintl(a0)); }
