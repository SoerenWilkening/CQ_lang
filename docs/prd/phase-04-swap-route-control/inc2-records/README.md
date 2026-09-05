# inc2-records — reproducers filed by the Inc-2 Rule-13 round-1 review

bd epic `test_C_libtooling-3qlq` (retire the swap route), increment 2 (value arms
by controlled-copy merge). These files are **records**, not tests: they are the
reproducers a round-1 finding rests on, kept where the finding's issue can point
at them. Nothing in `ir-pass/test` or `tests/e2e` runs them.

## The tainted `icmp i128` branch condition (finding F-V1-9 → bd `test_C_libtooling-3qlq.8`)

`CLAUDE.md` Rule 1: *"a tainted `br` / `select` / `switch` is **never** silently
passed to the backend … `ControlDetect` either hands the region to the swap-route
emitter or declines it loudly; there is no third path."* A tainted `icmp i128`
used as a branch condition took a third path.

| file | shape | disposition |
|---|---|---|
| `f1_i128cond.ll` | VALUE arm (`p*5; p+15`) under `icmp sgt i128` | pre-3qlq oracle `52d7764` **and** Inc 2 @ `8c526d9`: rc=1 with `no template for opcode 'icmp i1' in tainted context` and **zero** `cq controlled lowering:` diagnostics. **Since the Inc-2 round-1 fix** (`emitValueRegion`'s pre-mutation flag-mintability fence): rc=1 with `cq controlled lowering: control flow under quantum control` at the compare. Pinned by `ir-pass/test/control_swap_value_reject_i128_cond.ll`. |
| `f2_i128cond_phase.ll` | PHASE arm (`cq_phi`) under the same condition | **unchanged on every binary**: only the template error, no control diagnostic. THE GAP IS STILL OPEN on this half. |
| `e1_i128cond.c` | the plain-C spelling | does not compile: `cq_theta`'s `_Generic` has no `__int128` association (`controlling expression type '__int128' not compatible with any generic association type`). So the shape is reachable only from hand IR at this frontend — which is why it is a filed record and not an e2e slice. |

`opt` exits non-zero in every row and no gate is emitted, so nothing wrong is
*compiled*; what was wrong is that the control layer neither claimed nor declined
the region. Reproduce with either binary:

```
<cq-opt> -load-pass-plugin <libCQPass.so> -passes=cq-lowering -S f1_i128cond.ll -o /dev/null
CQ_CTRL_DBG=1 <cq-opt> ... f1_i128cond.ll -o /dev/null     # names the declining instruction
```
