# math.h coverage through cqc

**71/180 scalar-input cells compile through `tools/cqc` for every runtime C/Q mixture.**

Each probe is compiled by the user-facing driver `tools/cqc`, so this is the number a user
gets. It counts build, lowering, link and trace-run success. It does not certify numerical
or unitary semantics. No new goldens were blessed.

| Provider | Accepted for every mixture | Cells |
| --- | ---: | ---: |
| source-injected | 19 | 120 |
| CQ-provided | 6 | 6 |
| intrinsic | 36 | 42 |
| classical-only | 3 | 3 |
| macro | 10 | 12 |

Measured 483 probes: 313 accepted; 170 did not accept.
Structural free-check passes: 313. The classical-only nan row is not in the scalar total.
The macro cells retain the historical f64 scope of the 183-cell model.

## Reproduction

```sh
cmake --build build -j8
python3 tools/library_coverage/runtime_census.py --output tools/library_coverage/runtime_census.json
```

Driver, pass and LLVM hashes are in the adjacent JSON metadata. Classical operands and
quantum seeds are function parameters. Pointer outputs are read and explicitly measured.
fenv remains outside the CQ model (CLAUDE R16).

## Cells lacking acceptance for every mixture

| Cell | Failing mixtures | First diagnostic |
| --- | --- | --- |
| cosf.f32 | Q | error: <unknown>:0:0: in function __cq_libm_cosf float (float): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| sinf.f32 | Q | error: <unknown>:0:0: in function __cq_libm_sinf float (float): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| tanf.f32 | Q | error: <unknown>:0:0: in function __cq_libm_tanf float (float): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| atan2f.f32 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_atan2f.c:51:6: in function __cq_libm_atan2f float (float, float): cq specialization: callee contains tainted control flow under quantum lift |
| atan2.f64 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_atan2.c:79:6: in function __cq_libm_atan2 double (double, double): cq specialization: callee contains tainted control flow under quantum lift |
| atan2l.f80 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_atan2l.c:72:6: in function __cq_libm_atan2l x86_fp80 (x86_fp80, x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| coshf.f32 | Q | error: _deps/cq_openlibm-src/src/s_expm1f.c:99:9: in function __cq_libm_expm1f float (float): cq specialization: callee contains tainted control flow under quantum lift |
| cosh.f64 | Q | error: _deps/cq_openlibm-src/src/s_expm1.c:193:9: in function __cq_libm_expm1 double (double): cq specialization: callee contains tainted control flow under quantum lift |
| coshl.f80 | Q | error: _deps/cq_openlibm-src/ld80/e_coshl.c:55:34: in function __cq_libm_coshl x86_fp80 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| sinhf.f32 | Q | error: _deps/cq_openlibm-src/src/s_expm1f.c:99:9: in function __cq_libm_expm1f float (float): cq specialization: callee contains tainted control flow under quantum lift |
| sinh.f64 | Q | error: _deps/cq_openlibm-src/src/s_expm1.c:193:9: in function __cq_libm_expm1 double (double): cq specialization: callee contains tainted control flow under quantum lift |
| sinhl.f80 | Q | error: _deps/cq_openlibm-src/ld80/e_sinhl.c:53:35: in function __cq_libm_sinhl x86_fp80 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| tanhf.f32 | Q | error: _deps/cq_openlibm-src/src/s_expm1f.c:99:9: in function __cq_libm_expm1f float (float): cq specialization: callee contains tainted control flow under quantum lift |
| tanh.f64 | Q | error: _deps/cq_openlibm-src/src/s_expm1.c:193:9: in function __cq_libm_expm1 double (double): cq specialization: callee contains tainted control flow under quantum lift |
| tanhl.f80 | Q | error: _deps/cq_openlibm-src/ld80/s_tanhl.c:62:35: in function __cq_libm_tanhl x86_fp80 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| acoshf.f32 | Q | error: _deps/cq_openlibm-src/src/s_log1pf.c:114:1: in function __cq_libm_log1pf float (float): cq specialization: callee return value denotes no value (undef/poison) |
| acosh.f64 | Q | error: _deps/cq_openlibm-src/src/s_log1p.c:175:1: in function __cq_libm_log1p double (double): cq specialization: callee return value denotes no value (undef/poison) |
| acoshl.f80 | Q | error: _deps/cq_openlibm-src/ld80/e_acoshl.c:41:15: in function __cq_libm_acoshl x86_fp80 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| asinhf.f32 | Q | error: _deps/cq_openlibm-src/src/s_log1pf.c:114:1: in function __cq_libm_log1pf float (float): cq specialization: callee return value denotes no value (undef/poison) |
| asinh.f64 | Q | error: _deps/cq_openlibm-src/src/s_log1p.c:175:1: in function __cq_libm_log1p double (double): cq specialization: callee return value denotes no value (undef/poison) |
| asinhl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_logl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| atanhf.f32 | Q | error: _deps/cq_openlibm-src/src/s_log1pf.c:114:1: in function __cq_libm_log1pf float (float): cq specialization: callee return value denotes no value (undef/poison) |
| atanh.f64 | Q | error: _deps/cq_openlibm-src/src/s_log1p.c:175:1: in function __cq_libm_log1p double (double): cq specialization: callee return value denotes no value (undef/poison) |
| atanhl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_log1pl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| expf.f32 | Q | error: _deps/cq_openlibm-src/src/e_expf.c:84:5: in function __cq_libm_expf float (float): cq specialization: callee contains tainted control flow under quantum lift |
| exp.f64 | Q | error: _deps/cq_openlibm-src/src/e_exp.c:154:5: in function __cq_libm_exp double (double): cq specialization: callee contains tainted control flow under quantum lift |
| expl.f80 | Q | error: _deps/cq_openlibm-src/src/polevll.c:78:6: in function __cq_libm___polevll x86_fp80 (x86_fp80, ptr, i32): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| exp2f.f32 | Q | error: _deps/cq_openlibm-src/src/s_exp2f.c:106:29: in function __cq_libm_exp2f float (float): cq specialization: callee contains tainted control flow under quantum lift |
| exp2.f64 | Q | error: _deps/cq_openlibm-src/src/s_exp2.c:353:34: in function __cq_libm_exp2 double (double): cq specialization: callee contains tainted control flow under quantum lift |
| exp2l.f80 | Q | error: _deps/cq_openlibm-src/ld80/s_exp2l.c:228:34: in function __cq_libm_exp2l x86_fp80 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| expm1f.f32 | Q | error: _deps/cq_openlibm-src/src/s_expm1f.c:99:9: in function __cq_libm_expm1f float (float): cq specialization: callee contains tainted control flow under quantum lift |
| expm1.f64 | Q | error: _deps/cq_openlibm-src/src/s_expm1.c:193:9: in function __cq_libm_expm1 double (double): cq specialization: callee contains tainted control flow under quantum lift |
| expm1l.f80 | Q | error: _deps/cq_openlibm-src/src/s_scalbnl.c:49:13: in function __cq_q___cq_libm_scalbnl_10 i32 (x86_fp80, i32): cq specialization: callee contains tainted control flow under quantum lift |
| logl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_logl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| log10l.f80 | Q | error: <unknown>:0:0: in function __cq_libm_log10l x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| log2l.f80 | Q | error: <unknown>:0:0: in function __cq_libm_log2l x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| log1pf.f32 | Q | error: _deps/cq_openlibm-src/src/s_log1pf.c:114:1: in function __cq_libm_log1pf float (float): cq specialization: callee return value denotes no value (undef/poison) |
| log1p.f64 | Q | error: _deps/cq_openlibm-src/src/s_log1p.c:175:1: in function __cq_libm_log1p double (double): cq specialization: callee return value denotes no value (undef/poison) |
| log1pl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_log1pl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| logbl.f80 | Q | error: _deps/cq_openlibm-src/src/s_logbl.c:28:6: in function __cq_libm_logbl x86_fp80 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| ilogbf.f32 | Q | error: _deps/cq_openlibm-src/src/s_ilogbf.c:31:5: in function __cq_q___cq_libm_ilogbf_1 i32 (i32): cq specialization: callee contains tainted control flow under quantum lift |
| ilogb.f64 | Q | error: _deps/cq_openlibm-src/src/s_ilogb.c:35:5: in function __cq_q___cq_libm_ilogb_1 i32 (i32): cq specialization: callee contains tainted control flow under quantum lift |
| ilogbl.f80 | Q | error: _deps/cq_openlibm-src/src/s_ilogbl.c:31:6: in function __cq_libm_ilogbl i32 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| ldexpf.f32 | CQ, QC | error: _deps/cq_openlibm-src/src/s_scalbnf.c:35:13: in function __cq_q___cq_libm_scalbnf_10 i32 (float, i32): cq specialization: callee contains tainted control flow under quantum lift |
| ldexp.f64 | CQ, QC | error: _deps/cq_openlibm-src/src/s_scalbn.c:39:13: in function __cq_q___cq_libm_scalbn_10 i32 (double, i32): cq specialization: callee contains tainted control flow under quantum lift |
| ldexpl.f80 | CQ, QC | error: _deps/cq_openlibm-src/src/s_scalbnl.c:49:13: in function __cq_q___cq_libm_scalbnl_10 i32 (x86_fp80, i32): cq specialization: callee contains tainted control flow under quantum lift |
| scalbnf.f32 | CQ, QC | error: _deps/cq_openlibm-src/src/s_scalbnf.c:35:13: in function __cq_q___cq_libm_scalbnf_10 i32 (float, i32): cq specialization: callee contains tainted control flow under quantum lift |
| scalbn.f64 | CQ, QC | error: _deps/cq_openlibm-src/src/s_scalbn.c:39:13: in function __cq_q___cq_libm_scalbn_10 i32 (double, i32): cq specialization: callee contains tainted control flow under quantum lift |
| scalbnl.f80 | CQ, QC | error: _deps/cq_openlibm-src/src/s_scalbnl.c:49:13: in function __cq_q___cq_libm_scalbnl_10 i32 (x86_fp80, i32): cq specialization: callee contains tainted control flow under quantum lift |
| scalblnf.f32 | CQ, QC, QQ | error: probe.c:5:13: in function probe float (float, i64): cq specialization: floating-point quantum argument or return has no reversible copy |
| scalbln.f64 | CQ, QC, QQ | error: probe.c:5:14: in function probe double (double, i64): cq specialization: floating-point quantum argument or return has no reversible copy |
| scalblnl.f80 | CQ, QC, QQ | error: probe.c:5:19: in function probe x86_fp80 (x86_fp80, i64): cq specialization: floating-point quantum argument or return has no reversible copy |
| frexpf.f32 | Q | error: _deps/cq_openlibm-src/src/s_frexpf.c:32:8: in function __cq_libm_frexpf float (float, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| frexp.f64 | Q | error: _deps/cq_openlibm-src/src/s_frexp.c:40:8: in function __cq_libm_frexp double (double, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| frexpl.f80 | Q | error: _deps/cq_openlibm-src/src/s_frexpl.c:45:2: in function __cq_libm_frexpl x86_fp80 (x86_fp80, ptr): cq specialization: callee contains tainted control flow under quantum lift |
| modff.f32 | Q | error: _deps/cq_openlibm-src/src/s_modff.c:34:10: in function __cq_libm_modff float (float, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| modf.f64 | Q | error: _deps/cq_openlibm-src/src/s_modf.c:38:10: in function __cq_libm_modf double (double, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| modfl.f80 | Q | error: _deps/cq_openlibm-src/src/s_modfl.c:67:10: in function __cq_libm_modfl x86_fp80 (x86_fp80, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| powf.f32 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_powf.c:98:6: in function __cq_libm_powf float (float, float): cq specialization: callee contains tainted control flow under quantum lift |
| pow.f64 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_pow.c:155:16: in function __cq_libm_pow double (double, double): cq specialization: callee contains tainted control flow under quantum lift |
| powl.f80 | CQ, QC, QQ | error: <unknown>:0:0: in function __cq_libm_powl x86_fp80 (x86_fp80, x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| cbrtl.f80 | Q | error: _deps/cq_openlibm-src/src/s_cbrtl.c:55:6: in function __cq_libm_cbrtl x86_fp80 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| hypotf.f32 | CQ, QC | error: _deps/cq_openlibm-src/src/e_hypotf.c:36:5: in function __cq_q___cq_libm_hypotf_10 i32 (float, i32): cq specialization: callee contains tainted control flow under quantum lift |
| hypot.f64 | CQ, QC | error: _deps/cq_openlibm-src/src/e_hypot.c:67:5: in function __cq_q___cq_libm_hypot_10 i32 (double, i32): cq specialization: callee contains tainted control flow under quantum lift |
| hypotl.f80 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_hypotl.c:71:32: in function __cq_libm_hypotl x86_fp80 (x86_fp80, x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| erff.f32 | Q | error: _deps/cq_openlibm-src/src/e_expf.c:84:5: in function __cq_libm_expf float (float): cq specialization: callee contains tainted control flow under quantum lift |
| erf.f64 | Q | error: _deps/cq_openlibm-src/src/e_exp.c:154:5: in function __cq_libm_exp double (double): cq specialization: callee contains tainted control flow under quantum lift |
| erfl.f80 | Q | error: _deps/cq_openlibm-src/src/polevll.c:78:6: in function __cq_libm___polevll x86_fp80 (x86_fp80, ptr, i32): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| erfcf.f32 | Q | error: _deps/cq_openlibm-src/src/e_expf.c:84:5: in function __cq_libm_expf float (float): cq specialization: callee contains tainted control flow under quantum lift |
| erfc.f64 | Q | error: _deps/cq_openlibm-src/src/e_exp.c:154:5: in function __cq_libm_exp double (double): cq specialization: callee contains tainted control flow under quantum lift |
| erfcl.f80 | Q | error: _deps/cq_openlibm-src/src/polevll.c:78:6: in function __cq_libm___polevll x86_fp80 (x86_fp80, ptr, i32): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| tgammaf.f32 | Q | error: _deps/cq_openlibm-src/bsdsrc/b_log.c:440:6: in function __cq_libm___log__D { double, double } (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| tgamma.f64 | Q | error: _deps/cq_openlibm-src/bsdsrc/b_log.c:440:6: in function __cq_libm___log__D { double, double } (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| tgammal.f80 | Q | error: _deps/cq_openlibm-src/ld80/e_tgammal.c:244:7: in function __cq_libm_tgammal x86_fp80 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| lgammaf.f32 | Q | error: _deps/cq_openlibm-src/src/e_lgammaf_r.c:149:12: in function __cq_libm_lgammaf_r float (float, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| lgamma.f64 | Q | error: _deps/cq_openlibm-src/src/e_lgamma_r.c:216:12: in function __cq_libm_lgamma_r double (double, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| lgammal.f80 | Q | error: _deps/cq_openlibm-src/ld80/e_lgammal_r.c:276:13: in function __cq_libm_lgammal_r x86_fp80 (x86_fp80, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| llrintf.f32 | Q | error: <unknown>:0:0: in function __cq_libm_llrintf i64 (float): cq specialization: floating-point quantum argument or return has no reversible copy |
| llrint.f64 | Q | error: <unknown>:0:0: in function __cq_libm_llrint i64 (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| llrintl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_llrintl i64 (x86_fp80): cq specialization: floating-point quantum argument or return has no reversible copy |
| lroundf.f32 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_lroundf i64 (float): cq specialization: floating-point quantum argument or return has no reversible copy |
| lround.f64 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_lround i64 (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| lroundl.f80 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_lroundl i64 (x86_fp80): cq specialization: floating-point quantum argument or return has no reversible copy |
| llroundf.f32 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_llroundf i64 (float): cq specialization: floating-point quantum argument or return has no reversible copy |
| llround.f64 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_llround i64 (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| llroundl.f80 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_llroundl i64 (x86_fp80): cq specialization: floating-point quantum argument or return has no reversible copy |
| fmodf.f32 | CQ, QC, QQ | error: <unknown>:0:0: in function probe float (float, float): no template for opcode 'frem float' in tainted context |
| fmod.f64 | CQ, QC, QQ | error: <unknown>:0:0: in function probe double (double, double): no template for opcode 'frem double' in tainted context |
| fmodl.f80 | CQ, QC, QQ | error: <unknown>:0:0: in function probe x86_fp80 (x86_fp80, x86_fp80): no template for opcode 'frem x86_fp80' in tainted context |
| remainderf.f32 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_remainderf.c:63:6: in function __cq_libm_remainderf float (float, float): cq specialization: callee contains tainted control flow under quantum lift |
| remainder.f64 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_fmod.c:42:15: in function __cq_libm_fmod double (double, double): cq specialization: callee contains tainted control flow under quantum lift |
| remainderl.f80 | CQ, QC, QQ | error: <unknown>:0:0: in function __cq_libm_remainderl x86_fp80 (x86_fp80, x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| remquof.f32 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_remquof.c:50:14: in function __cq_libm_remquof float (float, float, ptr): cq specialization: callee contains tainted control flow under quantum lift |
| remquo.f64 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_remquo.c:45:15: in function __cq_libm_remquo double (double, double, ptr): cq specialization: callee contains tainted control flow under quantum lift |
| remquol.f80 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_remquol.c:85:48: in function __cq_libm_remquol x86_fp80 (x86_fp80, x86_fp80, ptr): cq specialization: callee contains tainted control flow under quantum lift |
| nextafterf.f32 | CQ, QC, QQ | error: <unknown>:0:0: in function __cq_libm_nextafterf float (float, float): cq specialization: callee contains tainted control flow under quantum lift |
| nextafter.f64 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_nextafter.c:58:14: in function __cq_libm_nextafter double (double, double): cq specialization: callee contains tainted control flow under quantum lift |
| nextafterl.f80 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_nextafterl.c:70:5: in function __cq_libm_nextafterl x86_fp80 (x86_fp80, x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| nexttowardf.f32 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_nexttowardf.c:45:5: in function __cq_libm_nexttowardf float (float, x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| nexttoward.f64 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_nexttoward.c:62:5: in function __cq_libm_nexttoward double (double, x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| nexttowardl.f80 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_nextafterl.c:70:5: in function __cq_libm_nextafterl x86_fp80 (x86_fp80, x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| fdimf.f32 | CQ, QC | error: _deps/cq_openlibm-src/src/s_fdim.c:45:1: in function __cq_q___cq_libm_fdimf_10 i32 (float, i32): cq specialization: callee contains tainted control flow under quantum lift |
| fdim.f64 | CQ, QC | error: _deps/cq_openlibm-src/src/s_fdim.c:44:1: in function __cq_q___cq_libm_fdim_10 i32 (double, i32): cq specialization: callee contains tainted control flow under quantum lift |
| fdiml.f80 | CQ, QC | error: _deps/cq_openlibm-src/src/s_fdim.c:47:1: in function __cq_q___cq_libm_fdiml_10 i32 (x86_fp80, i32): cq specialization: callee contains tainted control flow under quantum lift |
| fmaf.f32 | CCQ | error: <unknown>:0:0: in function probe float (float, float, float): no template for opcode 'call float' in tainted context |
| fma.f64 | CCQ | error: <unknown>:0:0: in function probe double (double, double, double): no template for opcode 'call double' in tainted context |
| fmal.f80 | CCQ | error: <unknown>:0:0: in function probe x86_fp80 (x86_fp80, x86_fp80, x86_fp80): no template for opcode 'call x86_fp80' in tainted context |
| fpclassify.f64 | Q | error: probe.c:5:11: in function probe i32 (double): cq taint escape: tainted value consumed by an unknown callee |
| isnormal.f64 | Q | error: /Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/math.h:263:36: in function probe i32 (double): cq taint escape: tainted value consumed by an unknown callee |
