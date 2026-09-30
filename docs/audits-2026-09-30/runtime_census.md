# Runtime-operand census

**131/180 cells have pipeline acceptance for every runtime C/Q mixture.**

This counts build, lowering, link and trace-run success. It does not certify numerical
or unitary semantics. CQ-provided leaf range contracts remain pending. No new goldens were blessed.

| Provider | Accepted for every mixture | Cells |
| --- | ---: | ---: |
| source-injected | 76 | 120 |
| CQ-provided | 6 | 6 |
| intrinsic | 39 | 42 |
| classical-only | 3 | 3 |
| macro | 10 | 12 |

Measured 483 probes: 391 accepted; 92 did not accept.
Structural free-check passes: 391. Classical-only nan accounting is separate.
The macro cells retain the historical f64 scope of the 183-cell model.

## Reproduction

```sh
git clone https://github.com/JuliaMath/openlibm.git /private/tmp/cq-northstar-openlibm
git -C /private/tmp/cq-northstar-openlibm checkout 5fe399749f9276eaa0b8403e507470da05cbbb3f
python3 tools/library_coverage/full_surface/build_corpus.py --openlibm /private/tmp/cq-northstar-openlibm --out /private/tmp/cq-northstar-bc --expect-bc 252
BC=/private/tmp/cq-northstar-bc OPENLIBM=/private/tmp/cq-northstar-openlibm python3 tools/library_coverage/runtime_census.py --output docs/audits-2026-09-30/runtime_census.json
```

Exact compiler and corpus hashes are in the adjacent JSON metadata. Classical operands
and quantum seeds are function parameters. Pointer outputs are read and explicitly measured;
signgam is preserved through internalization. fenv remains outside the CQ model (CLAUDE R16).

## Cells lacking acceptance for every mixture

| Cell | Failing mixtures | First diagnostic |
| --- | --- | --- |
| cosf.f32 | Q | error: openlibm/src/k_rem_pio2.c:310:54: in function probe float (float): cq taint escape: tainted value reaches an unsupported instruction |
| sinf.f32 | Q | error: openlibm/src/k_rem_pio2.c:310:54: in function probe float (float): cq taint escape: tainted value reaches an unsupported instruction |
| tanf.f32 | Q | error: openlibm/src/k_rem_pio2.c:310:54: in function probe float (float): cq taint escape: tainted value reaches an unsupported instruction |
| atan2f.f32 | CQ, QC | error: openlibm/src/e_atan2f.c:43:20: in function probe float (float, float): cq controlled lowering: nested control flow under quantum control |
| atan2.f64 | CQ, QC | error: openlibm/src/e_atan2.c:71:37: in function probe double (double, double): cq controlled lowering: control flow under quantum control |
| atan2l.f80 | CQ, QC | error: openlibm/src/e_atan2l.c:61:32: in function probe x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: nested control flow under quantum control |
| logbl.f80 | Q | error: openlibm/src/s_logbl.c:40:4: in function probe x86_fp80 (x86_fp80): cq controlled lowering: loop under quantum control |
| ilogbl.f80 | Q | error: openlibm/src/s_ilogbl.c:41:4: in function probe i32 (x86_fp80): cq controlled lowering: loop under quantum control |
| ldexpf.f32 | CQ, QC | error: openlibm/src/s_scalbnf.c:40:17: in function probe float (float, i32): cq controlled lowering: control flow under quantum control |
| ldexp.f64 | CQ, QC | error: openlibm/src/s_scalbn.c:44:17: in function probe double (double, i32): cq controlled lowering: control flow under quantum control |
| ldexpl.f80 | CQ, QC | error: openlibm/src/s_scalbnl.c:53:17: in function probe x86_fp80 (x86_fp80, i32): cq controlled lowering: control flow under quantum control |
| scalbnf.f32 | CQ, QC | error: openlibm/src/s_scalbnf.c:40:17: in function probe float (float, i32): cq controlled lowering: control flow under quantum control |
| scalbn.f64 | CQ, QC | error: openlibm/src/s_scalbn.c:44:17: in function probe double (double, i32): cq controlled lowering: control flow under quantum control |
| scalbnl.f80 | CQ, QC | error: openlibm/src/s_scalbnl.c:53:17: in function probe x86_fp80 (x86_fp80, i32): cq controlled lowering: control flow under quantum control |
| scalblnf.f32 | CQ, QC | error: openlibm/src/s_scalbnf.c:40:17: in function probe float (float, i64): cq controlled lowering: control flow under quantum control |
| scalbln.f64 | CQ, QC | error: openlibm/src/s_scalbn.c:44:17: in function probe double (double, i64): cq controlled lowering: control flow under quantum control |
| scalblnl.f80 | CQ, QC | error: openlibm/src/s_scalbnl.c:53:17: in function probe x86_fp80 (x86_fp80, i64): cq controlled lowering: control flow under quantum control |
| powf.f32 | CQ, QC | error: openlibm/src/e_powf.c:72:5: in function probe float (float, float): cq controlled lowering: nested control flow under quantum control |
| pow.f64 | CQ, QC | error: openlibm/src/e_pow.c:112:5: in function probe double (double, double): cq controlled lowering: control flow under quantum control |
| powl.f80 | CQ, QC, QQ | error: openlibm/src/s_frexpl.c:45:2: in function powil x86_fp80 (x86_fp80, i32): cq specialization: callee contains tainted control flow under quantum lift |
| tgammaf.f32 | Q | error: openlibm/src/s_logb.c:36:5: in function large_gam { double, double } (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| tgamma.f64 | Q | error: openlibm/src/s_logb.c:36:5: in function large_gam { double, double } (double): cq specialization: floating-point quantum argument or return has no reversible copy |
| tgammal.f80 | Q | error: <unknown>:0:0: in function stirf x86_fp80 (x86_fp80): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction) |
| lgammaf.f32 | Q | error: openlibm/src/e_lgammaf_r.c:151:5: in function probe float (float): cq controlled lowering: nested control flow under quantum control |
| lgamma.f64 | Q | error: openlibm/src/e_lgamma_r.c:218:5: in function probe double (double): cq controlled lowering: nested control flow under quantum control |
| lgammal.f80 | Q | error: openlibm/src/s_frexpl.c:45:2: in function logl x86_fp80 (x86_fp80): cq specialization: callee contains tainted control flow under quantum lift |
| fmodf.f32 | CQ, QC, QQ | error: openlibm/src/e_fmodf.c:57:6: in function probe float (float, float): cq controlled lowering: loop under quantum control |
| fmod.f64 | CQ, QC, QQ | error: openlibm/src/e_fmod.c:97:2: in function probe double (double, double): cq loop lowering: multiple early-break sites |
| fmodl.f80 | CQ, QC, QQ | error: openlibm/src/e_fmodl.c:121:2: in function probe x86_fp80 (x86_fp80, x86_fp80): cq loop lowering: multiple early-break sites |
| remainderf.f32 | CQ, QC, QQ | error: openlibm/src/e_fmodf.c:57:6: in function probe float (float, float): cq controlled lowering: loop under quantum control |
| remainder.f64 | CQ, QC, QQ | error: openlibm/src/e_fmod.c:97:2: in function probe double (double, double): cq loop lowering: multiple early-break sites |
| remainderl.f80 | CQ, QC, QQ | error: openlibm/src/s_remquol.c:130:2: in function probe x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: loop under quantum control |
| remquof.f32 | CQ, QC, QQ | error: openlibm/src/s_remquof.c:81:2: in function probe float (float, float): cq controlled lowering: loop under quantum control |
| remquo.f64 | CQ, QC, QQ | error: openlibm/src/s_remquo.c:106:2: in function probe double (double, double): cq controlled lowering: loop under quantum control |
| remquol.f80 | CQ, QC, QQ | error: openlibm/src/s_remquol.c:130:2: in function probe x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: loop under quantum control |
| nextafterf.f32 | CQ, QC | error: openlibm/src/s_nextafterf.c:34:21: in function probe float (float, float): cq controlled lowering: nested control flow under quantum control |
| nextafter.f64 | CQ, QC | error: openlibm/src/s_nextafter.c:41:22: in function probe double (double, double): cq controlled lowering: nested control flow under quantum control |
| nextafterl.f80 | CQ, QC | error: openlibm/src/s_nextafterl.c:44:29: in function probe x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: nested control flow under quantum control |
| nexttowardf.f32 | CQ, QC | error: openlibm/src/s_nexttowardf.c:36:37: in function probe float (float, x86_fp80): cq controlled lowering: nested control flow under quantum control |
| nexttoward.f64 | CQ, QC | error: openlibm/src/s_nexttoward.c:45:29: in function probe double (double, x86_fp80): cq controlled lowering: nested control flow under quantum control |
| nexttowardl.f80 | CQ, QC | error: openlibm/src/s_nextafterl.c:44:29: in function probe x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: nested control flow under quantum control |
| fdimf.f32 | CQ, QC | error: openlibm/src/s_fdim.c:45:1: in function probe float (float, float): cq controlled lowering: control flow under quantum control |
| fdim.f64 | CQ, QC | error: openlibm/src/s_fdim.c:44:1: in function probe double (double, double): cq controlled lowering: control flow under quantum control |
| fdiml.f80 | CQ, QC | error: openlibm/src/s_isnan.c:63:30: in function probe x86_fp80 (x86_fp80, x86_fp80): cq controlled lowering: nested control flow under quantum control |
| fmaf.f32 | CCQ | error: <unknown>:0:0: in function probe float (float, float, float): no template for opcode 'call float' in tainted context |
| fma.f64 | CCQ | error: <unknown>:0:0: in function probe double (double, double, double): no template for opcode 'call double' in tainted context |
| fmal.f80 | CCQ | error: <unknown>:0:0: in function probe x86_fp80 (x86_fp80, x86_fp80, x86_fp80): no template for opcode 'call x86_fp80' in tainted context |
| fpclassify.f64 | Q | error: openlibm/src/s_fpclassify.c:38:6: in function __fpclassifyd i32 (double): cq specialization: callee contains tainted control flow under quantum lift |
| isnormal.f64 | Q | error: /Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/math.h:263:36: in function probe i32 (double): cq taint escape: tainted value consumed by an unknown callee |
