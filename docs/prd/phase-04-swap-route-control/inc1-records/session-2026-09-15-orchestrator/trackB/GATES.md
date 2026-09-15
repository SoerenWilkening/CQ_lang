# GATES — Track B-scoping, session 2026-09-15

`<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date time>`

⚠ **Per PROTOCOL's scoping row, the ONLY gate this track may run is the per-probe pipeline**, against
the read-only ORACLE. **No build, no `lit`, no `ctest`, no corpus sweep, no injection matrix, no twin
matrix.** Every line below is `ran:`; none is cited.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| ORACLE hash re-verify (`shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so`) | `0e280fc62a91cec2` | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  build/ir-pass/cq-opt` / `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b  build/ir-pass/libCQPass.so` — **MATCHES PROTOCOL** | trackB-scoping | 2026-09-15 |
| per-probe pipeline, `example/grover/grover_oracle_uncompute.c` | `0e280fc62a91cec2` | `error: example/grover/grover_oracle_uncompute.c:92:19: in function main i32 (): cq taint escape: tainted value stored to memory`, `opt exit=1` | trackB-scoping | 2026-09-15 |
| `CQ_CTRL_DBG=1`, same file | `0e280fc62a91cec2` | `CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i8 trips=3 at:   store i8 %cq.bank, ptr %cq.bank.addr, align 1, !dbg !50, !tbaa !29` | trackB-scoping | 2026-09-15 |
| `CQ_RAILBANK_DBG=1`, same file | `0e280fc62a91cec2` | `CQ_RAILBANK_DBG: promote bank % in @main header % cells=3 cell=i8 seed=zero loads=2 stores=1` | trackB-scoping | 2026-09-15 |
| per-probe pipeline, 14 `probes/b*.c` | `0e280fc62a91cec2` | verdicts as tabulated in `probes/README.md` §1–§6; 2 ACCEPT (`b05` 9 lines, `b09` 4 lines), 12 DECLINE | trackB-scoping | 2026-09-15 |
| `cq-opt` on 8 `probes/derived/B*.ll` | `0e280fc62a91cec2` | `B0` `kMsgStore`; `B2` `value-arm swap-route`; `B3` `control flow inside a loop body`; `B6` `loop-carried tainted value crosses iterations`; `B7` `kMsgStore` + carve `Bank`; `B8` `kMsgStore` + carve **silent** (`NotBank`); `B9` `tainted value muxed by a classical-condition phi`; `B10` `LLVM ERROR: Broken module found, compilation aborted!` | trackB-scoping | 2026-09-15 |
| `emulate_piece3.sh b12` | `0e280fc62a91cec2` | `emu ACCEPT, 6 trace lines`; 2b `1 file(s), 1 rail mint(s) of which 1 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven`; emitted symbols `cqrt_alloc_i1`, `cqrt_ry_i1` only — **no `cqrt_measure_*`** | trackB-scoping | 2026-09-15 |
| `emulate_piece3.sh b14` (noinline) | `0e280fc62a91cec2` | `emu ACCEPT, 12 trace lines`; 2b `1 rail mint(s) of which 0 left allocated, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven`; trace `ry(+0.5); ry(−0.5); cqrt_free` per cell | trackB-scoping | 2026-09-15 |
| R2 twin diff, `b12` vs `b13` under `emulate_piece3.sh` | `0e280fc62a91cec2` | `diff` empty; both `ef75e8d7936811dbaa9f600b4851feabd6dd03ea924fbaaccfabc3d50f34005a` | trackB-scoping | 2026-09-15 |
| Track I flat twin `w1_flat_prep_only.c` | `0e280fc62a91cec2` | `ACCEPT trace=9 lines`, 2b `6 rail mint(s) of which 6 left allocated, 0 cqrt_free site(s)`; gate lines byte-identical to `b12`'s emulated 6 | trackB-scoping | 2026-09-15 |
| Rule-11 re-measure of `SCOPE_L1a` §7/§9 (`a_flat_n2`, `a_flat_n3`, `a_loop_n3`, `L1_promoted_{store,nostore}`, `L7`, `L8`) | `0e280fc62a91cec2` | `a_flat_n2` **ACCEPT**; `a_flat_n3` **ACCEPT** (⚠ SCOPE_L1a records DECLINE — **STALE**, corrected in place, R4); `a_loop_n3`/`L1_promoted_store`/`L7`/`L8` `kMsgStore`; `L1_promoted_nostore` `control flow inside a loop body` | trackB-scoping | 2026-09-15 |
| F-3 trio against the real carve | `0e280fc62a91cec2` | `two_cells` → `cq rail bank: array has cells no iteration writes`; `store_outside_loop` → `cq rail bank: array is written from more than one store site`; `inloop_other_read` → `cq rail bank: array has cells no iteration writes`. **Promoter never runs on any of the three** | trackB-scoping | 2026-09-15 |
| `derive_owner_variants.sh` round-trip | `0e280fc62a91cec2` | regenerates `derived/B0,B2,B3,B6,B7,B8` and reproduces every verdict above | trackB-scoping | 2026-09-15 |
| E4 byte-identity check | n/a (no binary) | `diff <(sed -n '83,95p;129,131p' example/grover/grover_oracle_uncompute.c) <(tail -n +16 probes/b01_owner_verbatim.c)` → **empty**. ⚠ The session brief's reproduction is NOT byte-identical to the file (trailing space L89, double space L130) | trackB-scoping | 2026-09-15 |
| e2e-slice `main`-residency sample (80 slices, `clang -O1`, `cq_{theta,phi,measure}` attributed per defining function) | n/a (no plugin) | `MAIN 4, HELPER 10, MIXED 66, NONE 0` — 76/80 carry quantum work outside `main`; separately `58/60` define >1 function after `-O1` | trackB-scoping | 2026-09-15 |
