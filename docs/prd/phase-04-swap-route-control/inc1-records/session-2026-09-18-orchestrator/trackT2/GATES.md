# GATES — Group-1 IMPLEMENTER (Track T2), session 2026-09-18, worktree `agent-ad443b9a480ffb751`
#
# Format (PROTOCOL §"The non-redundancy protocol"):
#   <gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>
#
# Every `cited:` line names whose GATES.md it came from. Every `ran:` line was checked
# against `$SES/GATES_INFLIGHT.md` for a matching IN-FLIGHT row at the same hash first.

## Binary chain (record the hash after EVERY rebuild — PROTOCOL)

| # | cq-opt sha256 (full) | libCQPass.so sha256 (first 16) | what is in it |
|---|---|---|---|
| B0 | `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` | `3e3dc35d471aae6b` | **CLEAN WORKTREE == SESSION ORACLE, verified before the first edit.** `cmake --build build -j2 --target CQPass cq-opt` at `cff8f7ac`. Both hashes are character-for-character the ORACLE block in `$SES/PROTOCOL.md`. |

gate | cq-opt | result | who | when
--- | --- | --- | --- | ---
clean-worktree build reproduces ORACLE | 9bd01598d574b344 | `shasum -a 256 build/ir-pass/cq-opt` = `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3`; `libCQPass.so` = `3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d`. BOTH MATCH the PROTOCOL oracle block | impl | 2026-09-17 12:47
pregroup build reproduces the 2026-09-14 oracle | 0e280fc62a91cec2 | `git archive 74eabd2c` into a scratch dir, `cmake --build build -j2 --target CQPass cq-opt`: cq-opt `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`, libCQPass.so `94602c7896e7a7ee…`. MATCHES the hash `$SES/review_r13_loopconv/REVIEW.md` F-1 names | impl | 2026-09-17 12:31
**bd 6n1s REGRESSION-vs-PRE-EXISTING (the review's owed one-command check)** | 0e280fc62a91cec2 | `t5j_twoblock_noexit_rot.c` **DECLINES** on the pre-group binary: `opt` exit 1, `cq loop lowering: rolled body leaks a rail entangled with a register rotated after the loop` (that release's spelling, pre-bd-c767) at `:8:20`. On the session ORACLE `9bd01598` it ACCEPTS at exit 0, 18 trace lines, 4 ashr mints / 0 `_unc` / 0 free. ⇒ **REGRESSION, not pre-existing** | impl | 2026-09-17 12:33
6n1s mechanism, read in source (not inferred) | — | at `74eabd2c` `markIfRailLocal` has exactly TWO call sites, both inside `collapseFlattenedLoopRails` (early-returns unless `taint.InLoopFlattenedPreds` is non-empty); `t5j` has NO tainted control flow so nothing marked it. At `cff8f7ac` there is a THIRD call site, `LoopLowering.cpp:5471-5474` (bd `tu9q`'s round-1 root-mint escape), which marks a body with no region. Conjunct (1) then suppresses | impl | 2026-09-17 12:35
t5j / t5i / t5k on the ORACLE | 9bd01598d574b344 | t5j ACCEPT 18 lines, 2b `3 template rail mint(s) of which 1 left dirty, 0 cqrt_free site(s)`, WARNING only · t5i ACCEPT 32 lines, `0 left dirty`, `2 cqrt_free site(s): 2 verified`, no warning · t5k DECLINE `rolled body leaks a rail entangled with a rotated register`. All three reproduce the review's numbers character-for-character | impl | 2026-09-17 12:22
targeted lit after 6n1s placement (`loop|uncompute|inloop|kickback_mixed|railbank|break`) | c79a290c0ac8230d | 393/393 PASS, 0 FAIL | impl | 2026-09-17 12:33
targeted lit after 6n1s placement (`lowering_`) | c79a290c0ac8230d | 798 PASS + 1 XFAIL, 0 FAIL | impl | 2026-09-17 12:35
targeted lit after the fence conjunct (union of both filters) | e6794a562e70c16e | 981 PASS + 1 XFAIL, 0 FAIL | impl | 2026-09-17 12:52
**Rule-12 RED-GREEN by BINARY MUTATION, 3 new fixtures, both binaries** | 9bd01598 vs e6794a56 | ORACLE: `loop_pairing_accept_twoblock_body_straddle` FAILS (prefix CHECK **and** prefix COUNT) · `loop_pairing_accept_oneblock_body_control` PASS · `loop_leak_dephase_reject_twoblock_unmarked_control` DECLINE+message PASS. SUBJECT: all three PASS. ⇒ the RED fixture is red on the oracle and green on the subject; the two controls are UNMOVED. Harness self-attack: `onbin.sh` with no fixture argument exits **2** rather than reporting a vacuous pass | impl | 2026-09-17 12:58
**Rule-12 MUTATION of the new fence conjunct** | 008866fac82f59b7 | `markedBodyRailsHaveInBodyDischargePoint` forced to `return false`: **17 fixtures flip** in the targeted families (967 pass vs 984). ⇒ the conjunct is LIVE, exercised code whose `true` answer is load-bearing for 17 shipped accepts. ⚠ What this does NOT show, and is stated rather than implied: no module was constructed on which it answers `false` — see IMPL_T3 §2.4 | impl | 2026-09-17 13:06
revert-to-identical check after the mutant | e6794a562e70c16e | reverting `LoopLowering.cpp` and rebuilding reproduces the pre-mutant `cq-opt` hash **bit for bit** — so the mutation left nothing behind | impl | 2026-09-17 13:09
targeted lit after the `reverseTerminalGroup` P1 mirror | 99d38adca7deca7e | 984 PASS + 1 XFAIL, 0 FAIL (the mirror is inert, as its comment predicts) | impl | 2026-09-17 13:14
