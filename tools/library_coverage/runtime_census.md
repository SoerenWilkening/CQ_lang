# math.h coverage through cqc

**100/180 scalar-input cells compile through `tools/cqc` for every runtime C/Q mixture.**

Each probe is compiled by the user-facing driver `tools/cqc`, so this is the number a user
gets. It counts build, lowering, link and trace-run success. It does not certify numerical
or unitary semantics. No new goldens were blessed.

| Provider | Accepted for every mixture | Cells |
| --- | ---: | ---: |
| source-injected | 42 | 120 |
| intrinsic | 48 | 48 |
| classical-only | 3 | 3 |
| macro | 10 | 12 |

Measured 483 probes: 378 accepted; 105 did not accept.
Structural free-check passes: 378. The classical-only nan row is not in the scalar total.
The macro cells retain the historical f64 scope of the 183-cell model.

## Reproduction

```sh
cmake --build build -j1
python3 tools/library_coverage/runtime_census.py --output tools/library_coverage/runtime_census.json --jobs 1
```

Driver, pass and LLVM hashes are in the adjacent JSON metadata. Classical operands and
quantum seeds are function parameters. Pointer outputs are read and explicitly measured.
fenv remains outside the CQ model (CLAUDE R16).

## Cells lacking acceptance for every mixture

| Cell | Failing mixtures | First diagnostic |
| --- | --- | --- |
| cosf.f32 | Q | error: <unknown>:0:0: in function __cq_libm_cosf float (float): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| cosl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_cosl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| sinf.f32 | Q | error: <unknown>:0:0: in function __cq_libm_sinf float (float): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| sinl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_sinl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| tanf.f32 | Q | error: <unknown>:0:0: in function __cq_libm_tanf float (float): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| tanl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_tanl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| atan2f.f32 | CQ | error: _deps/cq_openlibm-src/src/e_atan2f.c:43:20: in function __cq_q___cq_libm_atan2f_10 float (float, float): cq controlled lowering: nested control flow under quantum control |
| atan2.f64 | CQ | error: _deps/cq_openlibm-src/src/e_atan2.c:71:37: in function __cq_q___cq_libm_atan2_10 double (double, double): cq controlled lowering: control flow under quantum control |
| atan2l.f80 | CQ | error: _deps/cq_openlibm-src/src/e_atan2l.c:61:32: in function __cq_q___cq_libm_atan2l_10 x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: nested control flow under quantum control |
| coshf.f32 | Q | error: _deps/cq_openlibm-src/src/s_expm1f.c:123:1: in function __cq_libm_expm1f float (float): cq specialization: callee return value denotes no value (undef/poison) |
| cosh.f64 | Q | error: _deps/cq_openlibm-src/src/s_expm1.c:217:1: in function __cq_libm_expm1 double (double): cq specialization: callee return value denotes no value (undef/poison) |
| coshl.f80 | Q | error: _deps/cq_openlibm-src/src/polevll.c:78:6: in function __cq_libm___polevll x86_fp80 (x86_fp80, ptr, i32): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| sinhf.f32 | Q | error: _deps/cq_openlibm-src/src/s_expm1f.c:123:1: in function __cq_libm_expm1f float (float): cq specialization: callee return value denotes no value (undef/poison) |
| sinh.f64 | Q | error: _deps/cq_openlibm-src/src/s_expm1.c:217:1: in function __cq_libm_expm1 double (double): cq specialization: callee return value denotes no value (undef/poison) |
| sinhl.f80 | Q | error: _deps/cq_openlibm-src/src/polevll.c:78:6: in function __cq_libm___polevll x86_fp80 (x86_fp80, ptr, i32): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| tanhf.f32 | Q | error: _deps/cq_openlibm-src/src/s_expm1f.c:123:1: in function __cq_libm_expm1f float (float): cq specialization: callee return value denotes no value (undef/poison) |
| tanh.f64 | Q | error: _deps/cq_openlibm-src/src/s_expm1.c:217:1: in function __cq_libm_expm1 double (double): cq specialization: callee return value denotes no value (undef/poison) |
| acoshf.f32 | Q | error: _deps/cq_openlibm-src/src/s_log1pf.c:114:1: in function __cq_libm_log1pf float (float): cq specialization: callee return value denotes no value (undef/poison) |
| acosh.f64 | Q | error: _deps/cq_openlibm-src/src/s_log1p.c:175:1: in function __cq_libm_log1p double (double): cq specialization: callee return value denotes no value (undef/poison) |
| acoshl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_logl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| asinhf.f32 | Q | error: _deps/cq_openlibm-src/src/s_log1pf.c:114:1: in function __cq_libm_log1pf float (float): cq specialization: callee return value denotes no value (undef/poison) |
| asinh.f64 | Q | error: _deps/cq_openlibm-src/src/s_log1p.c:175:1: in function __cq_libm_log1p double (double): cq specialization: callee return value denotes no value (undef/poison) |
| asinhl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_logl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| atanhf.f32 | Q | error: _deps/cq_openlibm-src/src/s_log1pf.c:114:1: in function __cq_libm_log1pf float (float): cq specialization: callee return value denotes no value (undef/poison) |
| atanh.f64 | Q | error: _deps/cq_openlibm-src/src/s_log1p.c:175:1: in function __cq_libm_log1p double (double): cq specialization: callee return value denotes no value (undef/poison) |
| atanhl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_log1pl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| expl.f80 | Q | error: _deps/cq_openlibm-src/src/polevll.c:78:6: in function __cq_libm___polevll x86_fp80 (x86_fp80, ptr, i32): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| exp2.f64 | Q | error: _deps/cq_openlibm-src/src/s_exp2.c:392:1: in function __cq_libm_exp2 double (double): cq specialization: callee return value denotes no value (undef/poison) |
| exp2l.f80 | Q | error: _deps/cq_openlibm-src/ld80/s_exp2l.c:295:1: in function __cq_libm_exp2l x86_fp80 (x86_fp80): cq specialization: callee return value denotes no value (undef/poison) |
| expm1f.f32 | Q | error: _deps/cq_openlibm-src/src/s_expm1f.c:123:1: in function __cq_libm_expm1f float (float): cq specialization: callee return value denotes no value (undef/poison) |
| expm1.f64 | Q | error: _deps/cq_openlibm-src/src/s_expm1.c:217:1: in function __cq_libm_expm1 double (double): cq specialization: callee return value denotes no value (undef/poison) |
| logl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_logl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| log10l.f80 | Q | error: <unknown>:0:0: in function __cq_libm_log10l x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| log2l.f80 | Q | error: <unknown>:0:0: in function __cq_libm_log2l x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| log1pf.f32 | Q | error: _deps/cq_openlibm-src/src/s_log1pf.c:114:1: in function __cq_libm_log1pf float (float): cq specialization: callee return value denotes no value (undef/poison) |
| log1p.f64 | Q | error: _deps/cq_openlibm-src/src/s_log1p.c:175:1: in function __cq_libm_log1p double (double): cq specialization: callee return value denotes no value (undef/poison) |
| log1pl.f80 | Q | error: <unknown>:0:0: in function __cq_libm_log1pl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| logbl.f80 | Q | error: _deps/cq_openlibm-src/src/s_logbl.c:40:4: in function __cq_q___cq_libm_logbl_1 x86_fp80 (x86_fp80): cq controlled lowering: loop under quantum control |
| ilogbl.f80 | Q | error: _deps/cq_openlibm-src/src/s_ilogbl.c:41:4: in function __cq_q___cq_libm_ilogbl_1 i32 (x86_fp80): cq controlled lowering: loop under quantum control |
| scalblnf.f32 | CQ, QQ | error: probe.c:5:13: in function probe float (float, i64): cq specialization: floating-point quantum argument or return has no reversible copy |
| scalbln.f64 | CQ, QQ | error: probe.c:5:14: in function probe double (double, i64): cq specialization: floating-point quantum argument or return has no reversible copy |
| scalblnl.f80 | CQ, QQ | error: probe.c:5:19: in function probe x86_fp80 (x86_fp80, i64): cq specialization: floating-point quantum argument or return has no reversible copy |
| frexpf.f32 | Q | error: _deps/cq_openlibm-src/src/s_frexpf.c:32:8: in function __cq_libm_frexpf float (float, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| frexp.f64 | Q | error: _deps/cq_openlibm-src/src/s_frexp.c:40:8: in function __cq_libm_frexp double (double, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| frexpl.f80 | Q | error: _deps/cq_openlibm-src/src/s_frexpl.c:48:8: in function __cq_libm_frexpl x86_fp80 (x86_fp80, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| modff.f32 | Q | error: _deps/cq_openlibm-src/src/s_modff.c:34:10: in function __cq_libm_modff float (float, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| modf.f64 | Q | error: _deps/cq_openlibm-src/src/s_modf.c:38:10: in function __cq_libm_modf double (double, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| modfl.f80 | Q | error: _deps/cq_openlibm-src/src/s_modfl.c:67:10: in function __cq_libm_modfl x86_fp80 (x86_fp80, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| powl.f80 | CQ, QC, QQ | error: <unknown>:0:0: in function __cq_libm_powl x86_fp80 (x86_fp80, x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| hypotl.f80 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_hypotl.c:61:5: in function __cq_q___cq_libm_hypotl_10 x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: nested control flow under quantum control |
| erfl.f80 | Q | error: _deps/cq_openlibm-src/src/polevll.c:78:6: in function __cq_libm___polevll x86_fp80 (x86_fp80, ptr, i32): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| erfcl.f80 | Q | error: _deps/cq_openlibm-src/src/polevll.c:78:6: in function __cq_libm___polevll x86_fp80 (x86_fp80, ptr, i32): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| tgammaf.f32 | Q | error: _deps/cq_openlibm-src/bsdsrc/b_log.c:440:6: in function __cq_libm___log__D { double, double } (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| tgamma.f64 | Q | error: _deps/cq_openlibm-src/bsdsrc/b_log.c:440:6: in function __cq_libm___log__D { double, double } (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| tgammal.f80 | Q | error: <unknown>:0:0: in function __cq_libm_sinl x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| lgammaf.f32 | Q | error: _deps/cq_openlibm-src/src/e_lgammaf_r.c:149:12: in function __cq_libm_lgammaf_r float (float, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| lgamma.f64 | Q | error: _deps/cq_openlibm-src/src/e_lgamma_r.c:216:12: in function __cq_libm_lgamma_r double (double, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| lgammal.f80 | Q | error: _deps/cq_openlibm-src/ld80/e_lgammal_r.c:276:13: in function __cq_libm_lgammal_r x86_fp80 (x86_fp80, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| lroundf.f32 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_lroundf i64 (float): cq specialization: floating-point quantum argument or return has no reversible copy |
| lround.f64 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_lround i64 (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| lroundl.f80 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_lroundl i64 (x86_fp80): cq specialization: floating-point quantum argument or return has no reversible copy |
| llroundf.f32 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_llroundf i64 (float): cq specialization: floating-point quantum argument or return has no reversible copy |
| llround.f64 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_llround i64 (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| llroundl.f80 | Q | error: _deps/cq_openlibm-src/src/s_lround.c:64:3: in function __cq_libm_llroundl i64 (x86_fp80): cq specialization: floating-point quantum argument or return has no reversible copy |
| fmodf.f32 | CQ, QC, QQ | error: <unknown>:0:0: in function probe float (float, float): no template for opcode 'frem float' in tainted context |
| fmod.f64 | CQ, QC, QQ | error: <unknown>:0:0: in function probe double (double, double): no template for opcode 'frem double' in tainted context |
| fmodl.f80 | CQ, QC, QQ | error: <unknown>:0:0: in function probe x86_fp80 (x86_fp80, x86_fp80): no template for opcode 'frem x86_fp80' in tainted context |
| remainderf.f32 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_remainderf.c:40:5: in function __cq_q___cq_libm_remainderf_10 float (float, float): cq controlled lowering: nested control flow under quantum control |
| remainder.f64 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/e_remainder.c:48:5: in function __cq_q___cq_libm_remainder_10 double (double, double): cq controlled lowering: control flow under quantum control |
| remainderl.f80 | CQ, QC, QQ | error: <unknown>:0:0: in function __cq_libm_remainderl x86_fp80 (x86_fp80, x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| remquof.f32 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_remquof.c:50:11: in function __cq_libm_remquof float (float, float, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| remquo.f64 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_remquo.c:54:8: in function __cq_libm_remquo double (double, double, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| remquol.f80 | CQ, QC, QQ | error: _deps/cq_openlibm-src/src/s_remquol.c:99:8: in function __cq_libm_remquol x86_fp80 (x86_fp80, x86_fp80, ptr): cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access) |
| nextafterl.f80 | CQ | error: _deps/cq_openlibm-src/src/s_nextafterl.c:42:29: in function __cq_q___cq_libm_nextafterl_10 x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: control flow under quantum control |
| nexttowardf.f32 | CQ | error: _deps/cq_openlibm-src/src/s_nexttowardf.c:45:5: in function __cq_q___cq_libm_nexttowardf_10 float (float, x86_fp80): cq controlled lowering: control flow under quantum control |
| nexttoward.f64 | CQ | error: _deps/cq_openlibm-src/src/s_nexttoward.c:44:22: in function __cq_q___cq_libm_nexttoward_10 double (double, x86_fp80): cq controlled lowering: control flow under quantum control |
| nexttowardl.f80 | CQ | error: _deps/cq_openlibm-src/src/s_nextafterl.c:42:29: in function __cq_q___cq_libm_nextafterl_10 x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: control flow under quantum control |
| fdiml.f80 | QC | error: _deps/cq_openlibm-src/src/s_fdim.c:47:1: in function __cq_q___cq_libm_fdiml_01 x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: control flow under quantum control |
| fpclassify.f64 | Q | error: probe.c:5:11: in function probe i32 (double): cq taint escape: tainted value consumed by an unknown callee |
| isnormal.f64 | Q | error: /Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/math.h:263:36: in function probe i32 (double): cq taint escape: tainted value consumed by an unknown callee |
