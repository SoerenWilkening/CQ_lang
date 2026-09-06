feat(control): 3qlq Inc 2 — VALUE arms by the controlled-copy merge: retire the value-arm `cqrt_cswap` route (hoist the pure out-of-place chain to the pred → the 4.4 `SelectMergeEmit` mechanism: two `cqrt_copy_<W>_controlled` into a |0⟩ rail → chain `_unc` → compare strip → one free), so `cqrt_cswap` is minted by `AbortParkEmit` (7.2) ONLY and the Phase-4 swap route is fully retired

V1 flat value diamond (derived bases included), V2 if/else value arms (both chains hoisted), V3 homogeneous-value `switch` by the 4.5 preload + XOR-delta controlled copy. Replaces `SwapRouteEmit`'s value path and `SwitchValueEmit`'s route; `emitRoute(` has ONE call site (`AbortParkEmit.cpp`). Measured per arm on the flagship slice: 4 `cqrt_cswap_W` + 1 `cqrt_copy_W` + a work rail → 2 `cqrt_copy_controlled_W`, no work rail. WITNESS: byte identity with the pre-hoisted `?:` select twin (`SelectMergeEmit`, Rule-13-cleared) on four `cmp` gates (`e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical`) — `-O1` erases the `if` vs `?:` distinction (SimplifyCFG's threshold), so Inc 2 UNIFIES two mechanisms the optimiser used to choose between. NO new runtime symbol (owner D3). Unchanged: the §3c clobber decline, template-only arm ops, in-loop value arms keep the loop decline, mixed (value + phase) arms decline.

Rule 13: __ROUNDS__. __FINDINGS__

Errata carried (PRD §0 E1, notes §1.4): the chain-final rail `t = R(p)` is NOT `_unc`'d and NOT freed — left ALLOCATED and ENTANGLED with `out` (sound while `p` is retained; Rule 6 holds); bd 3qlq.5 (free the value-arm source) is UNSOUND BY DEFAULT under that class. OQ-22: routing the value diamond through `emitSelectRegion` sets `HandleWidth[Out]`, so a downstream cast / Q+Q compare on the merged register now accepts where the oracle declined — KEPT and pinned (5 fixtures + 1 slice). The F-V1-2 pre-mutation fence is reachable on the value path (an i128 condition) and pinned; the PHASE half of that pre-existing Rule-1 gap is bd 3qlq.8.

Measured at the landing tree: __COUNTS__

Owner questions: OQ-11 (Q+Q condition for value arms, fenced), OQ-12 (run-time classical shift amount ≥ W passes through, pre-existing), OQ-13 (the `value-arm swap-route` decline string names a retired mechanism), OQ-23 (V2's basis-state evaluator as a `tools/` instrument), __OQS__. Rebased onto the landed Inc 1 (a3c1513) with two real conflicts (`SwapRouteEmit.cpp` one include line; `control_swap_value_diamond_derived.ll` re-derived) and three intent repairs recorded in `$RECORD/rebase_inc2.md`.

Record: docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC2_NOTES.md (§1 round 1, §2 round 2 + clearance), inc1-records/session-0a61aa31/{impl_inc2,fix_inc2_r1,review_inc2_V1,review_inc2_V2}.md, inc1-records/session-adc5590a/{rebase_inc2,review_inc2_r2,fix_inc2_r2,clearance_inc2}.md.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NHxGVinGBKbb499HFCuwhT
