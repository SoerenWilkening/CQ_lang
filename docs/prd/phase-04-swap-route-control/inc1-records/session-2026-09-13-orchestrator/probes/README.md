# Probes — 2026-09-13 diagnosis of the extended owner file (measured on the ORACLE `build/` at `e96f89c`)

ORACLE binaries: `build/ir-pass/cq-opt` sha256 `fbbe0820ef4b176a…`, `build/ir-pass/libCQPass.so`
`40e9c7a51e8120bb…` (built 2026-09-11 22:23 from `e96f89c`; `main` `86c0d25` is docs-only over it —
`571c7cd`'s only `ir-pass/src` change is nine comment lines in `MergePhiPeel.cpp`).

Command per probe (`LLVM=/usr/local/opt/llvm@19/bin`, run from the repo root):

```
"$LLVM/clang" -Iinclude -include CQ.h -O1 -emit-llvm -S <probe>.c -o s1.ll          # add -g for a source-located diagnostic
"$LLVM/opt" -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S s1.ll -o s2.ll; echo "opt exit=$?"
python3 tools/free_pairing_check.py s2.ll                                             # accepts only
"$LLVM/clang" s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o a && ./a   # accepts only
```

| file | shape | opt exit | first diagnostic / result |
|---|---|---|---|
| `owner_file_2026-09-13.c` | the owner's file as on disk 2026-09-13 (= the 2026-09-11 file + `if (b1) a -= 3;` at line 99) | 1 | `…:99:9: … cq controlled lowering: control flow under quantum control` — `SelectClassify.cpp:780-782` GATE 2, `collectCondTree` refuses the `phi i1` condition (`isCondRailLeaf` at `:543` admits only a `cq_theta_i1` call) |
| `owner.main.O1.ll` | the `-O1` `main` the pass receives for the file above | — | one fused diamond `br i1 %1` (b0 arm + b1 prep, gate arm = false successor), merge phis `%5` (a-mux, peelable) and `%6 = phi i1 [%3,%2],[false,%0]` (b1 prep merge, NOT peelable); line 99 = `%8 = select i1 %6, i32 %7, i32 %5` |
| `va.c` | line 99 deleted (the 2026-09-11 shape) | 0 | 19 trace lines (`va.trace`); STRICT 2b `6 rail mint(s) of which 5 left allocated, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` |
| `vb.c` | `if (b1 == 1) a -= 3;` | 1 | same string; `main` IR byte-identical to the owner's |
| `vc.c` | `int c = a; if (b1) c = a - 3; a = c;` | 1 | same string; `main` IR byte-identical to the owner's |
| `vd.c` | three bools (`b2` prep + arm, `b2` measured) | 1 | `vd.c:10:14: … state prep seed is proven equal to the condition register under quantum control` from `classifyArms` on the b0 prep (`-O1` hoists region 1's a-mux to the entry block as `select i1 %1, i32 2, i32 5`) |
| `ve.c` | `bool b[3]` in a `for` loop | 1 | `ve.c:7:26: … cq taint escape: tainted value stored to memory` |

Firing site isolated with `lldb` (breakpoint on `cq::diagnoseUnderControl`): frames
`classifySelectRegion + 602` ← `detectControlRegions + 2087` ← `CQLoweringPass::run`; the two
`collectCondTree` calls in that round returned `true` (the peeled a-mux select) then `false` (`%8`).
Cross-reference: `../session-boi6/SCOPE_boi6.md` §0.1 probe `p20` is this exact shape.
