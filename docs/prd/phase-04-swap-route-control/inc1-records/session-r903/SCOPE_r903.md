# SCOPE — bd `test_C_libtooling-r903`, Inc 1b follow-on: the negated nest level, NOT-carrying rail leaves, derived-`i1` conditions — plus the two PARITY residuals its NOTES record

Session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-11, measured on **`main` @ `0c7380c`** with the
build already in the tree (`build/ir-pass/cq-opt`). `git status --porcelain` was clean at the
start and nothing under `ir-pass/`, `include/`, `runtime/`, `tests/` or `tools/` was touched:
**READ-ONLY, no build, no commit.** Probes and their measured verdicts are transcribed into
`probes/` with a `README.md`; every line number below was `grep`'d at `0c7380c` and must be
re-grepped before editing.

Style model: `inc1-records/session-r9e5/SCOPE_B2.md`. Companions: PRD
`retire-swap-route-PRD.md` §13 (the rail-leaf grammar, §13.3 the ladder, §13.4 the decline
partition, §13.6 F-1b-1, §13.7 round 2) and §14 (1b-B.1, the `CopyRailRoot` flag and the
round-2 `reverifyRailCondReads` stage).

---

## 0. HEADLINE — three of the five items shrink under measurement, and one grows

### 0.0 The one thing to read first

**No confirmed silent miscompile was found in this session.** One measured, decisive
**fence-level over-accept** was found for parity residual (a) and is graded **ARGUED**, not
confirmed: `w6` vs `w7` (`probes/`) differ by ONE instruction that lowers to the SAME gate,
and the condition-wire fence REFUSES `w7` and GRANTS `w6`. `w6` is then caught one stage
later by `lowerLoops`' `kMsgCrossIter`, so no wrong unitary is emitted at `0c7380c` — which
is exactly the third of the three **retirement triggers** `WireWalk.h:180-187` already writes
down for this predicate. It is hand-IR-only today (`clang -O1` canonicalises `q - 9` to
`add i32 %q, -9`). Details: §4(a) and H-1.

### 0.1 The measurement table

All from plain C at `-O1` unless the probe name ends `.ll` (HAND IR — the shape `-O1` does
not produce). Commands in `probes/README.md`.

| # | probe | source shape | what `-O1` hands the pass | `main` 0c7380c |
|---|---|---|---|---|
| 1 | `n1_nest_neg_outer.c` | `if (!a) { φ; if (b) φ; }`, `a`,`b` bare `_Bool` | 2 `br i1`, rail at BOTH levels, outer arm on the FALSE successor | DECLINE `branch phase on a bare i1 condition` |
| 1 | `n2_nest_neg_inner.c` | `if (a) { φ; if (!b) φ; }` | 2 `br i1` | DECLINE `branch phase on a bare i1 condition` |
| 1 | `n0_nest_plain.c` | the same nest, no negation | 2 `br i1` | **ACCEPT** — `toffoli(h_a,h_b,g); rz(g,·); toffoli; free(g)` |
| 1 | `n3_…_cmp_twin.c` | the negated nest with `int`/compare levels | 2 `br i1` | **ACCEPT** — `x(h_cmp); toffoli(…); x(h_cmp)` |
| 1 | `n4_…_tree_root.c` | negated OUTER level whose root is `a && a2` (a NODE) | 2 `br i1`, 1 select | **ACCEPT** — the root is an ancilla |
| 1 | `n5_…_inner_cmp_outer_rail.c` | compare outer, `!b` rail inner | 2 `br i1` | DECLINE `branch phase on a bare i1 condition` |
| 2 | `g1_notb_and_cmp.c` | `if (!b && q == 5) φ` | `icmp **ne**` + `select %b, true, %cmp`, arm on FALSE | **ACCEPT** |
| 2 | `g2_notb_or_cmp.c` | `if (!b \|\| q == 5) φ` | `icmp **ne**` + `select %b, %cmp, false`, arm on FALSE | **ACCEPT** |
| 2 | `g7_notb_and_cmp_ne.c` | `if (!b && q != 5) φ` | as `g1` | **ACCEPT** |
| 2 | `g8_flat_notb.c` | `if (!b) φ` | `br i1 %b`, arm on FALSE | **ACCEPT** — 4 calls, `rz(h,−θ)` |
| 2 | `g3_notb_and_c.c` | `if (!b && c) φ`, **two rails** | `xor i1 %c, true` under `select %b, true, %notc` | DECLINE **`control flow`** |
| 2 | `g4_b_and_notc.c` | `if (b && !c) φ` | `xor i1 %b, true` under an or-node | DECLINE **`control flow`** |
| 2 | `g5_notb_or_c.c` | `if (!b \|\| c) φ` | same, arm on TRUE | DECLINE **`control flow`** |
| 2 | `g6_…_and_d.c` | `if (!b && c && d) φ` | **two** `xor …, true` children under a right-leaning or-chain | DECLINE **`control flow`** |
| 3 | `e1_b_eq_c.c` | `if (b == c) φ` | `xor i1 %b, %c`, arm on **FALSE** | **ACCEPT** (the node root is an ancilla; `cqrt_x` on `g`) |
| 3 | `e2_b_ne_c.c` | `if (b != c) φ` | `xor i1 %b, %c`, arm on **TRUE** | **ACCEPT** |
| 2 | `x1_select_complement_false_arm.ll` | HAND IR `select %b, false, %c` | — | DECLINE `control flow` |
| 2 | `x2_select_complement_true_arm.ll` | HAND IR `select %b, %c, true` | — | DECLINE `control flow` |
| 2 | `x3_xor_rail_true_child.ll` | HAND IR `and i1 (xor %b, true), %c` | — | DECLINE `control flow` |
| 4 | `t1`/`t4` | `int t = q & 1; if (t)` / `bool t = q & 1; if (t)` | `and` + **`icmp eq …, 0`** | **ACCEPT** — a COMPARE leaf |
| 4 | `t2`/`t3` | `bool t = q; if (t)` / `if ((bool)q)` | **`icmp eq i32 %q, 0`** | **ACCEPT** |
| 4 | `t5` | `int t = b; if (t)` | folded back to `br i1 %b` | **ACCEPT** (rail root) |
| 4 | `t6`/`t7`/`t8` | `b ^ 1` / a `bool` array slot / `unsigned char` LSB | `br i1 %b` / `br i1` on the rail / `and`+`icmp` | **ACCEPT** |
| 4 | `t9_trunc_i1_data.ll` | HAND IR: tainted `trunc i32 → i1` used as DATA | — | **ACCEPT** — `cq_template_trunc_i32_to_i1(%h)` mints a FRESH i1 rail |
| 5 | `m1_cmp_measured_before.c` | `int m = cq_measure(q); if (q > 3) φ` | `br i1 %cmp` | **ACCEPT** — the flag is minted from the COLLAPSED register |
| 5 | `m4_…_crossblock.c` | `m1` + a classical block after | `br i1 %cmp` | **ACCEPT** — same |
| 5 | `m3_rail_measured_before.c` | the `_Bool` twin of `m1` | `br i1 %b` | DECLINE `condition measured before the control route` |
| 5 | `m2_select_measured_before.c` | `int m = cq_measure(q); int a = (q>3)?2:5;` | `select` | **ACCEPT** — bd `r10v`'s territory; measured here, **not scoped here** |
| 6 | `w0_loop_plain_control.c` | the shipped rolled in-loop kickback | 2 `br i1` | **ACCEPT** (8 calls) |
| 6 | `w1_loop_sibling_template.c` | in-loop sibling thetas over an `xor` parent | 2 `br i1` | DECLINE `condition predates a non-diagonal gate` |
| 6 | `w3`/`w4` | over an `and` / `mul` parent | 2 `br i1` | DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` |
| 6 | `w5` | `w3` with the sibling spelled CHAINED (control) | 2 `br i1` | same string — **not** a discriminator |
| 6 | **`w6_…_sub_parent.ll`** | HAND IR: siblings over an **in-place `sub`** parent, in a loop | — | DECLINE at `lowerLoops` (`kMsgCrossIter`) — **the condition-wire fence GRANTED it** |
| 6 | **`w7_…_add_parent_control.ll`** | `w6` with `add %q, -9` instead of `sub %q, 9` | — | DECLINE **`condition predates a non-diagonal gate`** — the fence REFUSES |

### 0.2 Three consequences, and they change the shape of the increment

**(A) Item (2)'s headline spelling is NOT the one the bead names.** The bead says
"`select i1 %b, i1 false, i1 %x`"; measured, `clang -O1` **never produced that form** in any
probe. It applies De Morgan and keeps the in-grammar `or`/`and` logical-select, hoisting the
NOT into a separate **`xor i1 %rail, true`** child (`g3`/`g4`/`g5`/`g6`). The two
complement-selects `decomposeCondNode` refuses at `SelectClassify.cpp:538-540` are
**hand-IR-only** (`x1`, `x2` — both still decline, so the fence is real; it is just not what
the customer hits). The reachable refusal is the **`xor` constant-operand bail** at
`SelectClassify.cpp:693-695`.

**(B) The NOT is only ever un-absorbable on a RAIL.** A NOT on a compare leaf is folded into
the predicate (`g1`/`g2`/`g7`: `icmp eq` became `icmp ne`); a NOT at the *root* is folded into
branch polarity (`g8`, `e1`, `n3`). What survives as an explicit `xor …, true` is precisely a
NOT on a leaf that has **no predicate to invert and no polarity slot** — i.e. a rail leaf
below the root. So item (2) is the *same* capability gap as item (1), one level down: a
**negated control on a user's register**.

**(C) Item (3) has no plain-C customer at LLVM 19.** Every natural `int → bool` conversion
arrives as a `CmpInst` (`t1`–`t4`, `t8`), and `zext i1 → i32` round-trips fold back to the
rail (`t5`, `t6`). A `trunc iN → i1` condition is HAND IR at `-O1` today. ⚠ And note the
type algebra the bead's "(trunc/zext/sext)" phrasing hides: **only `trunc` can produce an
`i1`.** `zext`/`sext` widen, so they can never be the *condition*; the derived-`i1` cast
family is exactly `trunc i{8,16,32,64,80,128} → i1`, all six pairs shipping `fwd`/`inv`/`unc`
(`tools/opcode_table.yaml:291-325`, symbols measured present in `runtime/cq_templates.h:2093-2098`).

---

## 1. Anchors — every site, quoted

### 1.1 The grammar (`ir-pass/src/SelectClassify.cpp`, `ir-pass/include/SelectClassify.h`)

| line | site | what it does |
|---|---|---|
| `SelectClassify.cpp:490-541` | `decomposeCondNode` | THE ONE place a node is taken apart. `and`/`or`/`xor` `BinaryOperator` on `i1`; then, under `AllowLogicalSelect`, `select %C,%T,false → and(C,T)` and `select %C,true,%F → or(C,F)`. |
| `:509-510` | `if (!AllowLogicalSelect) return false;` | the 4.4 DATA select's grammar stops here; the branch-phase callers pass `true`. |
| `:538-540` | the closing comment + `return false` | *"Everything else is a general i1 combinator (incl. the two NOT-carrying complements `select %C, false, %F` and `select %C, %T, true`) — off-grammar."* **MEASURED hand-IR-only** (`x1`,`x2`). |
| `:543-549` | `isCondRailLeaf` | `CallInst`, type `i1`, callee name **exactly** `cq_theta_i1`. Deliberately that narrow (§13.4). |
| `:551-741` | `collectCondTree` | the two-phase post-order walk; `:568-571` records a rail leaf into `Tree.RailLeaves`; `:739` returns `!Leaves.empty() \|\| !RailLeaves.empty()`. |
| **`:693-695`** | `if (NodeOpc == Instruction::Xor && (isa<Constant>(NodeL) \|\| isa<Constant>(NodeR))) return false;` | **THE REACHABLE ITEM-(2) REFUSAL.** The comment calls it "`xor X, 1` (the logical NOT) accordingly stays declined here exactly as before", pinned by `control_swap_reject_select_xor_notform.ll`, and notes the deliberate asymmetry with PredMux's E6 which DOES admit it. |
| `:733-734` | `if (NodeL == NodeR) return false;` | the self-operand node fence (untouched by any item here). |
| `SelectClassify.h:78-88` | `RailLeaves` + its obligation | *"⚠ EVERY CONSUMER THAT READS `Leaves` MUST DECIDE ON `RailLeaves` EXPLICITLY."* |
| `SelectClassify.h:111` | `kBareRailCondReason = "bare i1 register condition"` | |
| `SelectClassify.h:119`, `:141-151` | the `AllowLogicalSelect` doctrine | one grammar, two verdicts. |

### 1.2 The network emitter (`ir-pass/src/CondTreeEmit.cpp`, `ir-pass/include/CondTreeEmit.h`)

| line | site | what it does |
|---|---|---|
| `CondTreeEmit.cpp:53-63` | `bracket(N, csyms, B, DL)` | **THE ONE NEGATION MECHANISM TODAY**: `if (N.NegL) x(N.L); if (N.NegR) x(N.R);` — a `cqrt_x` on the CONTROL. Called at `:90` and `:114`, i.e. before and after the node's gates. |
| `:67-115` | `emitCondNode` | AND ⇒ one `toffoli(L,R,G)`; OR ⇒ `cnot(L,G); cnot(R,G); toffoli(L,R,G)`; XOR ⇒ the two cnots only. `Inverse` re-emits the exact adjoint. `:78-84` is `markRailCondRead` (the F-B1R2-1 record) for any rail in a CONTROL slot. |
| `:117-248` | `emitCondNetwork` | `:136` `CopyRoot = CopyRailRoot && isCondRailLeaf(Root)`; `:176` mints the node ancilla `g`; `:196-199` a rail leaf is its own flag (`FlagOf[V] = V`); `:219` `Out.RootIsRail`; `:232-246` the **B.1 `CopyRailRoot` CNOT copy** (`bf = alloc_i1(0); cnot(rail,bf)`), recorded at `:241`. |
| `:250-300` | `stripCondNetwork` | exact LIFO: the rail-root copy first (`:267-270`), nodes in reverse post-order, leaves last. |
| `CondTreeEmit.h:32-40`, `:99-100` | `NegL`/`NegR` | *"POLARITY (`NegL`/`NegR`, **P4 only**)"* — i.e. the depth-2 nest's conjunction and nothing else. |

**MEASURED**: `grep -rn "NegL\|NegR" ir-pass/src` returns **exactly two writers**,
`SwapRouteEmit.cpp:2009` and `:2010`. `emitCondNetwork` never sets either — a tree node built
by the walk is always un-negated. So today the ONLY negated control in the whole pass is the
nest's conjunction.

### 1.3 The phase emitters (`ir-pass/src/SwapRouteEmit.cpp`)

| line | site | what it does |
|---|---|---|
| `:1464-1498` | `emitKickbackGroup` | the ONE spelling of "fire `P(θ)` when `ctl == v`". `:1475` `Bracket = Neg && !CtlIsRail`; `:1480` `Neg && CtlIsRail ? B.CreateFNeg(Angle) : Angle`. **The negated-RAIL case is already solved here** — `rz(h, −θ)`. |
| `:1506+` | `emitPhaseKickbackRegion` | flat; re-derives the tree at `:1525` with `AllowLogicalSelect=true`. |
| `:1859+` | `emitPhaseKickbackNestRegion` | the depth-2 nest. |
| `:1932-1940` | the emitter's own drift-guard copy of the negated-rail refusal | `OuterRootIsRail = OuterTree.Nodes.empty() && !OuterTree.RailLeaves.empty()` (and the inner twin); either one negated ⇒ `diagnoseUnderControl(BI, "branch phase on a bare i1 condition")` **before the first emission**. |
| `:1941-1960` | `emitArm` | `emitKickbackGroup(B, Rz, X, Ctl, CtlIsRail, angles, Neg, DL, taint)` — the OUTER arm already rides a negated rail root correctly via `rz(−θ)`. |
| `:2001-2023` | the CONJUNCTION | `Conj.Opc = And; Conj.L = OuterNet.Root; Conj.R = InnerNet.Root; Conj.NegL = R.ArmNegated; Conj.NegR = R.InnerArmNegated;` then `emitCondNode(Conj, …, /*Inverse=*/false, &taint)`. |

### 1.4 The classifier (`ir-pass/src/ArmClassify.cpp`)

| line | site | what it does |
|---|---|---|
| `:4415+` | `classifyPhaseKickbackNest` | |
| `:4697-4705` | the negated-rail decline | `if ((OuterRootIsRail && OuterNeg) \|\| (InnerRootIsRail && InnerNeg))` ⇒ `branch phase on a bare i1 condition`. Its comment already names the lift: *"`Toff(¬a,b,g) = CNOT(b,g)·Toff(a,b,g)` would lift it with no gate on `a`; filed, not built"*. |
| `:4436`, `:4445-4452`, `:4550-4551` | `OuterNeg`/`InnerNeg` → `Region.ArmNegated` / `InnerArmNegated` | |
| `:3875+` | `classifyPhaseKickback` (flat) | `:4073` the tree bail; `:4057-4073`'s comment is the TWO-MESSAGE split — *"a condition TREE the grammar refuses takes the pre-existing `control flow` message"*. **My measurements confirm it: every item-(2) shape takes `control flow`, not the bare-i1 string.** |
| `:1868-1897` | `railWireNamesBackward` | the rail's wire by `lowerRotations`' own `Chained` relation. |
| `:1915-1953` | `railMeasuredBeforeReadPoint` | rung (ii). Its header (`:1824-1837`) says outright: *"Strictly stricter than the compare path, which (measured, F-1b-2) mints a flag from a register measured **UNCONDITIONALLY** before the branch — a pre-existing gap recorded with bd `test_C_libtooling-r903`, not widened here."* |
| `:2195-2260+` | `condDataUseDisposition` | **residual (b)'s site.** `:2234` `if (CI->getParent() == RouteBlock) return MeasuredEarly;` else `continue`. |
| `:2060+` | `reverifyRailCondReads` | the B.1 round-2 tripwire (relevant to item (1)/(2): a new rail READ site must call `markRailCondRead`). |

### 1.5 The wire walk (`ir-pass/src/WireWalk.cpp`, `ir-pass/include/WireWalk.h`)

| line | site | what it does |
|---|---|---|
| `WireWalk.cpp:64-131` | `collectWireValues(Seed, CrossValueRouting, Out)` | **file-local.** Backward: `cq_phi_` hops (`:76-81`, VACUOUS since 3qlq Inc 1) and the **narrow** chained-theta hop `:82-99` (`isCallToPrefix(CI,"cq_theta_") && (isCallToPrefix(Arg0,"cq_theta_") \|\| isCallToPrefix(Arg0,"cq_phi_"))`) — **no `TaintSet`**, the documented r903 parity gap, with the comment naming it. Forward: phi/select routing (`:105-114`) and `:116-120` **`BO->getOpcode() == Instruction::Add \|\| Instruction::Xor`** — and NOT `Sub`. |
| `:160-197` | `thetaOnPathToImpl` | |
| `:199-218` | `thetaOnPathTo(V, Target)` | the ONLY caller of `collectWireValues` (`:215`). |
| `:329-364` | `gateIsHarmless` | leg 2; calls `phiTracksWire` at `:340` (the seed) and `:356` (superseding phis). |
| `:367-379` | `phiTracksWire(P)` | the ONLY caller of `thetaOnPathTo` (`:375`). |
| `ArmClassify.cpp:699` | `recordLivePerActivation`'s `if (!phiTracksWire(DP)) return false;` | the SECOND `phiTracksWire` caller. |
| `WireWalk.h:76-82`, `:155-190` | the polarity + vocabulary doctrine and the **three retirement triggers** | |

**THE COMPLETE NULL-`TaintSet` CALL CHAIN — every site, or none (measured with `grep -rn`):**

```
collectWireValues   (WireWalk.cpp:64, file-local; NOT declared in WireWalk.h)
  └─ ONE caller: thetaOnPathTo          (WireWalk.cpp:215)
       └─ ONE caller: phiTracksWire     (WireWalk.cpp:375)
            ├─ WireWalk::gateIsHarmless            (WireWalk.cpp:340, :356)   ← BARRIER
            └─ ArmClassify::recordLivePerActivation(ArmClassify.cpp:699)      ← PRECONDITION
```

Both consumers are **accept-direction for `true`**: `gateIsHarmless` returns
`!reachesWithoutBarrier(...)`, so a phi granted barrier status makes a staling gate
*harmless*; `recordLivePerActivation` returns `false` when the fence refuses. So the
"`false` is conservative" reading in `WireWalk.h:155-162` is correct for BOTH, and widening
the closure is **decline-monotone at both callers** — the same monotonicity F-1b-1's fix had.

### 1.6 The derived-`i1` mint (`ir-pass/src/CastLowering.cpp`)

`rewriteCast` (`:50-…`) uses the COLLECTION-TIME captured widths (`:57-70`), gates on
`castInScope` (`:71-77`), and emits `CreateCall(Callee, {cast->getOperand(0)}, "h_cast")`
(`:85`) — an **out-of-place** template producing a FRESH handle, then RAUWs. Measured on
`t9_trunc_i1_data.ll`:

```
%h      = cqrt_alloc_i32(%u) ; cqrt_ry_i32(%h, 0.3)
%h_cast = cq_template_trunc_i32_to_i1(%h)      <-- a fresh 1-qubit rail
%m1     = cqrt_measure_i1(%h_cast)
```

So a derived-`i1` condition **is already a flag**, minted by the opcode layer with an
`_unc` adjoint (`cq_template_trunc_i32_to_i1_unc(out, a)`) and a spine-owned free.

---

## 2. Item (1) — the negated rail level in the depth-2 nest

### 2.1 The identity, verified on the truth table

`Toff(a,b,g)` is `g ^= a∧b`; `CNOT(b,g)` is `g ^= b`. Composing (in either order — see below):

```
g ^= (a∧b) ⊕ b  =  b·(1⊕a)  =  ¬a ∧ b
```

| a | b | a∧b | b | (a∧b)⊕b | ¬a∧b |
|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | 0 ✓ |
| 0 | 1 | 0 | 1 | 1 | 1 ✓ |
| 1 | 0 | 0 | 0 | 0 | 0 ✓ |
| 1 | 1 | 1 | 1 | 0 | 0 ✓ |

**They commute.** Both gates write ONLY `g` and read `a`,`b` read-only; each is
`g ^= f(a,b)` with `f` unchanged by the other, and XOR is commutative. So
`CNOT·Toff = Toff·CNOT` and the emission order is free.

**Each is self-inverse**, and therefore so is the product:
`(C·T)² = C·T·C·T = C·C·T·T = I`. **So the LIFO teardown is the SAME pair** — exactly the
property `bracket()` relies on today (`cqrt_x` is self-inverse, so the strip re-emits the
same bracket), and the reason the `Inverse` arm of `emitCondNode` needs no new case beyond
re-emitting these two in reverse order.

`g` returns to `|0⟩` exactly on every basis branch ⇒ its `cqrt_free` stays a clean reset
(Rule 6). Nothing is emitted ON `a` or `b`: both sit in CONTROL slots only — the read-only
class Inc 1b already allows on a register.

**The full negation algebra** (needed only if item (2) lands — see §3):

| `NegL` | `NegR` | node | emission (all writes on the ancilla `G`) |
|---|---|---|---|
| 0 | 0 | AND | `toffoli(L,R,G)` |
| 1 | 0 | AND | `cnot(R,G); toffoli(L,R,G)` |
| 0 | 1 | AND | `cnot(L,G); toffoli(L,R,G)` |
| 1 | 1 | AND | `x(G); cnot(L,G); cnot(R,G); toffoli(L,R,G)` |
| 1 | 0 | OR | `x(G); cnot(L,G); toffoli(L,R,G)`  (`¬a∨b = 1⊕a⊕(a∧b)`) |
| 1 | 0 | XOR | `x(G); cnot(L,G); cnot(R,G)`        (`¬a⊕b = 1⊕a⊕b`) |

Every row is a set of mutually-commuting involutions writing only `G`, so every row's
adjoint is the same row. **`x(G)` is on the ANCILLA — never on a register.**

### 2.2 Gate cost, measured against the shipped compare stream

`n3`'s lowered module (a COMPARE root, negated outer) emits per direction
`x(h_cmp); toffoli(h_cmp,h_cmp1,g); x(h_cmp)` — **3 gates**. The rail lift emits
`cnot(h_b1,g); toffoli(h_b,h_b1,g)` — **2 gates**. The lift is strictly CHEAPER, adds no
ancilla, and mints no new runtime symbol (`cqrt_cnot` and `cqrt_toffoli` are both already
`ControlledSymbols` members, `ControlledSymbols.h:104`/`:109`).

### 2.3 Where it slots in

The whole change is **inside `emitCondNode`** (`CondTreeEmit.cpp:67-115`), which is the ONE
node emitter both the network walk (`:184`) and the nest's conjunction
(`SwapRouteEmit.cpp:2020`) call — the `markBranchPhaseGate` / `markRailCondRead` lesson
verbatim: put it in the shared function, not at the two call sites.

1. `bracket()` (`:53-63`) gains a **rail test**: `if (N.NegL && !isCondRailLeaf(N.L)) x(N.L)`
   and the mirror. A rail control is never `cqrt_x`'d.
2. `emitCondNode` gains, immediately after `bracket()`, the **XOR-expansion prologue** for
   the rail-negated controls — for the shipped surface that is the AND row only:
   `if (N.Opc == And && N.NegL && isCondRailLeaf(N.L)) cnot(N.R, N.G);` and the mirror.
   The prologue is emitted identically on the `Inverse` path (the gates are involutions and
   commute with the node's own gates, so "same set, reverse order" and "same set, same order"
   are the same unitary — state it, and pin it with a fixture that counts both directions).
3. Both new `cnot`s take a rail in a CONTROL slot ⇒ each must be handed to
   `markRailCondRead` — which `emitCondNode`'s existing `record` lambda (`:78-84`) **already
   does for free**, because it fires on every `stamp`ed call whose arguments include a rail
   leaf. ⚠ Verify by fixture that the new calls go through `stamp`; a `B.CreateCall` that
   bypasses it re-opens F-B1R2-1 with no diagnostic anywhere.
4. `ArmClassify.cpp:4701-4705` and its emitter twin `SwapRouteEmit.cpp:1936-1940` **both**
   drop the refusal (two sites — the emitter's is a deliberate drift guard, not a duplicate).

**A negated rail at the ROOT of a nest level needs nothing — CONFIRMED by reading and by
measurement.** The level's own phases go through `emitArm` → `emitKickbackGroup`, whose
`Neg && CtlIsRail` arm is already the diagonal `rz(h, −θ)` (`SwapRouteEmit.cpp:1480`), and
`n1`'s outer arm is exactly that shape. The ONLY thing the refusal at `:4701` is protecting
is the CONJUNCTION's control slot. So item (1) is **one gate**.

---

## 3. Item (2) — NOT-carrying rail leaves

### 3.1 The grammar change

Measured (§0.2 A/B), the reachable shape is a **`xor i1 %rail, true` child of an in-grammar
`and`/`or` node**. Two ways to admit it, and they differ in where the negation lives:

**Design 2-A — a polarity flag on the leaf (RECOMMENDED).** `collectCondTree` peels
`xor X, true` when `X` is a rail leaf, records the leaf with a `Neg` bit, and the parent
node's `NegL`/`NegR` is set from it. `CondTree` gains one parallel `SmallVector<bool>` (or
`RailLeaves` becomes `SmallVector<std::pair<CallInst*,bool>>`), and **`emitCondNetwork`
becomes the first writer of `NegL`/`NegR` outside the nest** — which is why §2.1's full
negation table, not just its AND row, is then owed. For a COMPARE leaf the same peel is
**predicate inversion**, which already happens: `lowerCompareToFlag` takes an `inverse`
parameter (used by `stripCondNetwork` at `:291-296`) and `-O1` has usually done the inversion
in the source predicate already (`g1`: `icmp eq` → `icmp ne`). So the compare half needs
nothing new; only the rail half does.

**Design 2-B — a negated CNOT copy (reuses B.1 verbatim).** Mint `bf = alloc_i1(0);
cnot(rail, bf); x(bf)` ⇒ `bf = ¬rail`, an ancilla the node may bracket freely; strip
`x(bf); cnot(rail, bf); free(bf)`. This is B.1's cleared `CopyRailRoot` mechanism with one
extra self-inverse `x` on the ancilla. Cost: +1 ancilla and +4 gates per negated leaf against
2-A's +1..+3 gates and no ancilla. Its merit is that it needs **no new negation algebra at
all** and inherits B.1's Rule-6 argument unchanged.

**Recommendation: 2-A for the phase path** (it is where item (1) already puts the machinery),
**and keep 2-B written down** as the fallback the DATA-path consumers (bd `fg9k`, `54ur`)
can reuse, since those emitters already call `emitCondNetwork` with `CopyRailRoot`.

### 3.2 What must NOT change

* `AllowLogicalSelect=false` callers (the 4.4 DATA select, `Specialization`) must keep
  refusing the NOT, exactly as they refuse the logical-selects — one grammar, two verdicts
  (`SelectClassify.h:141-151`). A `Neg` bit reachable by a `false` caller is a widening as a
  side effect of a mechanism change, which is the trap `emitValueRegion:439-451` documents.
* `Specialization.cpp:288` already refuses any tree with `RailLeaves`; unchanged.
* The `xor X, true` bail at `:693-695` must stay for a **non-rail** child (a negated compare
  is folded by `-O1`; a negated *node* — `xor (and a,b), true` — is a NEW shape with no
  measurement behind it and should keep declining).
* `PredMuxFlatten`'s E6 (`PredMuxFlatten.cpp:937-947`) DOES admit `xor X, 1`; the asymmetry
  and its pin `control_swap_reject_select_xor_notform.ll` are deliberate. If item (2) lands,
  that fixture's header must be re-derived rather than deleted, and the asymmetry restated.

---

## 4. Item (3) — derived-`i1` conditions as mint+discharge flags

### 4.1 What it actually is

*"Just admitting the cast result as a compare-like leaf with its own mint"* — **yes, with one
ordering problem and one closure problem.**

`trunc iN → i1` already lowers to a fresh one-qubit rail with an `_unc` adjoint
(§1.6, `t9`). So the emitted stream is the flag pattern with a different mint:

```
%h_cast = cq_template_trunc_i32_to_i1(%h)     ← mint (instead of lowerCompareToFlag)
          cqrt_rz_i1(%h_cast, θ)  !cq.branchphase
          cq_template_trunc_i32_to_i1_unc(%h_cast, %h)   ← discharge
          cqrt_free(%h_cast)
```

**The ordering problem.** `detectControlRegions`/`lowerControlRegions` run BEFORE `lowerOps`,
so at emission time the `trunc` is still an un-lowered `CastInst`. The emitter must mint the
template itself (a third minter beside `lowerCompareToFlag` and the node ancilla) and then
make sure `lowerOps` does not mint a SECOND one — i.e. erase the cast, or record it the way
`taint.SharedCondFlags` records a shared compare flag. Either way this is a NEW mint site
inside a control emitter, which is a Rule-13-core change and the reason item (3) is not free.

**The closure problem — and this is the design question the item turns on.** Rungs (ii) and
(iii) of §13.3's ladder must be asked **of the cast's SOURCE wire**, not of the cast result:
the cast result is a fresh ancilla that nothing else can stale, while `%h` is the user's
register and is exactly what a sibling theta or a `cq_measure` can move.
`railWireNamesBackward` (`ArmClassify.cpp:1868`) is written over a `cq_theta_i1` rail and
stops at the first non-theta tainted parent; for a derived condition the seed is
`Cast->getOperand(0)` and the existing compare machinery — `condProvenance` +
`wireGainsNonDiagonalGate` — is already the right shape for it. So the honest statement is:
**item (3)'s ladder is the COMPARE ladder over the cast's operand, plus the compare path's
own two missing rungs** (residual (b), and `r10v`/`9pum`'s round-2 window). That is a
dependency, not a coincidence.

### 4.2 Cost / payoff

**Zero plain-C customers measured** (§0.2 C). The item buys hand IR and whatever a future
frontend or QRAM shape produces. **Recommend DEFER** until a customer exists, and record the
two design notes above so the next agent does not re-derive them.

---

## 5. Parity residual (a) — `collectWireValues` / `thetaOnPathTo` with a null `TaintSet`

### 5.1 What was measured

`w6` and `w7` (`probes/`) are the same module modulo ONE instruction — `sub i32 %q, 9` vs
`add i32 %q, -9` — which M-C lowers to the SAME in-place `cqrt_addc_i32(%h, -9)`
(`ArithLowering.cpp:129`, `:146-155`; the in-place opcode set is `Add`/`Sub`/`Xor`,
`:844-846`). Both put two SIBLING `cq_theta` on that one parent inside a loop whose header
phi is the condition's provenance seed.

* `w7` DECLINES `condition predates a non-diagonal gate` — the correct answer.
* `w6` PASSES the condition-wire fence and is stopped one stage later by
  `cq loop lowering: loop-carried tainted value crosses iterations`.

**The mechanism, derived and then confirmed by the pair.** `findNonDiagonalWireGate` finds the
sibling in BOTH modules (its F-1b-1 backward crossing reaches the tainted `sub`/`add` parent,
`WireWalk.cpp:437-443`) and hands it to `gateIsHarmless`, which falls to leg 2 and asks
`phiTracksWire` on the header phi. That predicate is spelled over `thetaOnPathTo` →
`collectWireValues`, whose wire of the latch incoming is built (i) BACKWARD with the **narrow**
ancestry that stops at a non-theta parent (`:82-99` — the documented r903 gap) and (ii) FORWARD
across `Add` and `Xor` only (`:116-120`). In `w7` the forward `Add` hop recovers the parent and
the sibling, so the phi is refused as a barrier. In `w6` **neither** half reaches it, the phi is
granted, and the sibling is declared harmless.

### 5.2 Two findings, not one

**(a-1) — the documented null-`TaintSet` gap is DECISIVE.** Supplying the taint set to
`collectWireValues`' backward loop (cross the arg-0 edge whenever the parent is tainted —
F-1b-1's fix verbatim) puts the `sub` result and hence the sibling into the wire, and `w6`
declines like `w7`. So `w6` is the reproducer this residual never had.

**(a-2) — NEW, and it is the same family one operand over: `collectWireValues`' forward walk
omits `Sub` while M-C's in-place set includes it.** `WireWalk.cpp:116-120` tests
`Add || Xor`; `ArithLowering.cpp:844-846` accepts `Add || Sub || Xor`. Not recorded anywhere.
It is masked at `-O1` (InstCombine canonicalises `sub X, C` → `add X, -C`) and it is
*separately* masked by (a-1) if that is fixed — but "two independent bugs that mask each
other" is exactly the shape this project's history says to write down rather than to net out.
**Both should be closed in the same change**, and the fix should be stated as *"the closure
must use the relation the lowering uses"* (`classifyInPlaceReassignment`'s opcode set, asked
once) rather than as a third hand-maintained opcode list.

### 5.3 Grade, and what stands between it and a wrong unitary

**ARGUED, not CONFIRMED.** No module in this session emitted a wrong unitary: `w6` dies at
`kMsgCrossIter`, and every plain-C construction I could build (`w1`,`w3`,`w4`) dies at the
same guard or earlier. That guard is **the third of the three retirement triggers
`WireWalk.h:180-187` already names** for this predicate:

> *"RETIREMENT TRIGGER, THREE WAYS: relax the phi-edge read-position rule, admit a non-φ `D`
> that can be frozen, or relax `LoopLowering::collapseRailPhisIn` step (1)'s LOOP-CARRIED
> guard (`kMsgCrossIter`) — any of the three makes `phiTracksWire` the ONLY wall."*

`w6` is the measurement that turns that sentence from a caution into a fact: the first wall is
already down, and only the third is holding. Anyone widening `collapseRailPhisIn` must close
(a) in the same change.

### 5.4 Fix shape and estimate

The F-1b-1 pattern verbatim: `collectWireValues` takes `const TaintSet *Taint = nullptr`,
crosses the chained-theta arg-0 edge when `Taint && Taint->Tainted.count(Arg0)`, and crosses
`Sub` in the forward walk; `thetaOnPathTo` and `phiTracksWire` each grow the parameter and
thread it; the two consumers supply the taint set they already hold
(`gateIsHarmless` is reached from `findNonDiagonalWireGate`, which already has `const TaintSet
*Taint`; `recordLivePerActivation` is in `ArmClassify` where `Taint` is in scope).

⚠ **Round 2's F-1b2-3 deleted an identical parameter once already** because *"no caller
supplied it"* — a defaulted parameter nothing supplies "reads as a fix" and is not one. So
this increment must thread it to **both** consumers in the same commit, or not add it.

Production lines: **~25-40** across `WireWalk.{h,cpp}` and two call chains (the comment
budget will be 3-4×). It IS a Rule-13-core change (`WireWalk` is on the Rule-13 list) and
needs its own round. Monotone toward decline at both callers (§1.5), so the
`main`-vs-branch whole-corpus sweep should read **0 DECLINE→ACCEPT**.

---

## 6. Parity residual (b) — the compare path's measured-before rung

### 6.1 What it actually accepts — say it precisely, because the bead's phrasing is loose

`condDataUseDisposition` (`ArmClassify.cpp:2195`) walks the users of **the COMPARE**, and
`MeasuredEarly` (`:2234`) fires when a measurement **of the flag's own data lineage** sits in
`RouteBlock`. That is the `atk9` hazard: `bool f = cq_measure(q>5)` beside `if (q>5)`.

**The question the rail ladder asks — "was the CONDITION REGISTER measured before the read
point?" — is asked by NO rung of the compare path at all.** `railMeasuredBeforeReadPoint`'s
own header says so (`:1830-1837`). `m1` is the measured witness: `int m = cq_measure(q);
if (q > 3) cq_phi(.3);` accepts, and the emitted module mints
`cq_template_icmp_sgt_i32_hl(%h, 3)` **after** `cqrt_measure_i32(%h)`. `m4` shows the same
with the measure in a dominating position. `m3`, one token away (`_Bool`), declines.

### 6.2 Is it a wrong unitary? — NO, and the report must not claim otherwise

After a projective measurement `q` is in a definite basis state, so the flag minted from it is
classical and `P(θ)` on a classical flag is a global phase (or nothing). The emitted stream is
**faithful to source order**. What is violated is the project's own **policy** — Rule 6's
"a post-measure gate is a loud reject, never a silent skip" — and the **symmetry** with the
rail path, which declines the identical program. Grade it **ARGUED / POLICY ASYMMETRY**, the
same grade the round-1 lens gave F-B1R1-1 (PRD §14.7, "graded ARGUED because the stream is
faithful to source order and the defect is the FENCE").

### 6.3 It is the same rung as bd `r10v`, and it should ride with it

bd `r10v`'s own text says: *"Same class as bd `r903`'s 'the compare path's weaker
measured-before fence' (F-1b-2), one consumer over."* The two are the **`select` half** and the
**`br` half** of ONE missing rung:

| consumer | classifier | rail rung today | compare rung today |
|---|---|---|---|
| flat kickback / nest (`br`) | `classifyPhaseKickback` / `…Nest` | `railMeasuredBeforeReadPoint(rail, Pred->getTerminator(), …)` | **none** ← residual (b) |
| 4.4 data select | `classifySelectRegion` | `railMeasuredBeforeReadPoint(rail, Sel, …)` | **none** ← bd `r10v` |

The fix is one predicate asked at two read points, exactly as B.1 generalised
`railMeasuredBeforeBranch` into `railMeasuredBeforeReadPoint`: for every `CmpInst` leaf, take
its TAINTED operand, close it backward over `railWireNamesBackward`'s relation, and refuse if
any `cq_measure` user of a wire name can reach the read point (`isPotentiallyReachable`, the
F-1b-2/F-B1-1 spelling). One helper, two call sites, one probe family, **one** Rule-13 round.

**RECOMMENDATION: fold (b) into bd `r10v`** and re-title that bead "the compare path's
missing measured-before rung, at BOTH read points". Splitting it costs two Rule-13 rounds on
one predicate and risks the 8h7d.5 F-1/F-3 failure exactly: widening the read point at one
consumer and not the other.

⚠ It will be an **over-decline** for `m1`-shaped programs whose unitary is fine. That is the
Prime Directive's safe direction and it matches what the rail path already does to `m3`, but
it should be put to the owner as a choice, with the alternative (accept on BOTH paths, i.e.
widen the rail rung) named and NOT recommended.

---

## 7. Hazards

**H-1 — `kMsgCrossIter` is the only wall left under residual (a), and it is a LOOP guard, not
a wire fence.** Evidence: `w6` vs `w7` (§5). Anyone narrowing
`LoopLowering::collapseRailPhisIn` step (1) — which is a natural next widening for in-loop
work — removes the last thing between the granted barrier and a stale condition read. Record
it in the PRD as (a)'s re-opening condition and cross-reference `WireWalk.h:180-187`.

**H-2 — a new rail READ site that forgets `markRailCondRead` re-opens F-B1R2-1 silently.**
Item (1) adds one or two `cqrt_cnot`s whose CONTROL is the user's register; item (2) adds more.
`emitCondNode`'s `record` lambda (`CondTreeEmit.cpp:78-89`) covers every call routed through
`stamp`, and the B.1 fix landed only after its **first spelling missed the nest's conjunction**
(PRD §14.8). Fixture obligation: an accept fixture per new gate asserting the re-verification
still fires (build it as a DECLINE fixture whose subject is a round-2-tainted sibling, RED
without the record).

**H-3 — item (2) makes `emitCondNetwork` the first writer of `NegL`/`NegR` outside the nest,
and `CondTreeEmit.h:32` says "P4 only".** Every reader of `CondNetwork::Node` must be re-asked.
Measured today the only readers are `bracket()` and `emitCondNode`; a header sentence that has
been true since the lift will become false, and the project's history says such a sentence
hardens into an assumption elsewhere (the `fenv` lesson). Restate it in the same commit.

**H-4 — item (2) without the full negation table is an over-accept waiting to happen.** If a
`Neg` bit can land on an OR or XOR node child and only the AND row is implemented, `emitCondNode`
would emit the un-negated network and still verify, still pair every free, and still print a
plausible trace — the textbook shape `CondTreeEmit.cpp:91-95` already warns about for the XOR
node. Either implement all rows of §2.1 or make `collectCondTree` refuse a `Neg` leaf under a
non-AND parent, loudly, with a fixture.

**H-5 — item (3) needs a THIRD mint site inside a control emitter.** `lowerCompareToFlag` and
the node ancilla are the two today. A third one that runs before `lowerOps` and must suppress
`lowerOps`' own mint is a mutate-then-decline risk (Rule 9) unless the resolvability is asked
pre-mutation — the F-V1-2 finding, one condition kind over (SCOPE_B2 §1.3 H-9 records the same
hazard for B.2).

**H-6 — item (3)'s ladder inherits the compare path's two open holes.** Its rungs must be asked
of the cast's SOURCE wire, which is the compare path's subject; so item (3) built before (b) /
`r10v` / `9pum` would ship a new consumer of a fence that is known-weak in two ways. Sequence it
after them.

**H-7 — `emitKickbackGroup`'s `Bracket = Neg && !CtlIsRail` is a leaf-level test and item (2)
makes `CtlIsRail` insufficient.** With a negated rail leaf inside a tree the ROOT handed to
`emitArm` is a node ancilla (`CtlIsRail=false`), so the arm's own brackets are correct — but
that is true only because the negation was consumed at the node. If a future shape hands a
*negated rail root* to `emitArm` through a path that does not set `Neg`, the `rz(−θ)` form is
skipped. Pin the flat negated-rail accept (`control_phase_kickback_rail_negated.ll` exists)
against any change to that expression.

**H-8 — the two `control flow` declines of item (2) are NOT `kBareRailCondReason`, and the
partition is load-bearing.** `ArmClassify.cpp:4057-4073`'s comment argues that split at length
and my measurements confirm it (`g3`–`g6`, `x1`–`x3` all say `control flow`). If item (2) lands,
the fixtures that pin those strings flip; if it does NOT, they must keep saying `control flow`
and not drift to the bare-i1 string, which is the discriminator §13.4 depends on.

---

## 8. The decline partition after each item

| shape | today | after (1) | after (2) | after (3) |
|---|---|---|---|---|
| `if (!a){…if (b)…}`, rail outer | `branch phase on a bare i1 condition` | **ACCEPT** | — | — |
| `if (a){…if (!b)…}`, rail inner | same | **ACCEPT** | — | — |
| negated level, root a NODE or a COMPARE | ACCEPT (`n3`,`n4`) | unchanged | unchanged | unchanged |
| depth ≥ 3 nest, non-homogeneous arms | `nested control flow` etc. | unchanged | unchanged | unchanged |
| `xor i1 %rail, true` as a node CHILD | `control flow` | unchanged | **ACCEPT** | — |
| `xor i1 %cmp, true` as a node CHILD | `control flow` | unchanged | **keeps declining** (no measured customer; `-O1` folds it) | — |
| `xor i1 (and …), true` (negated NODE) | `control flow` | unchanged | **keeps declining** | — |
| `select %C, false, %F` / `select %C, %T, true` | `control flow` | unchanged | owner choice — recommend **keep declining** (hand-IR-only, `x1`/`x2`) | — |
| the same NOT under `AllowLogicalSelect=false` (4.4 data select, `Specialization`) | refused | unchanged | **must stay refused** | — |
| `trunc iN → i1` condition | `branch phase on a bare i1 condition` | unchanged | unchanged | **ACCEPT** |
| `phi i1` / `Argument i1` / template-`i1` / QRAM-load `i1` condition | `branch phase on a bare i1 condition` | unchanged | unchanged | **keeps declining** (bd `boi6` and the rest of `r903`'s residual list) |
| `if (b) a -= 3` (4.4 data select on a rail) | ACCEPT since `r9e5` | unchanged | unchanged | unchanged |
| value arm / in-place Ry / state prep on a rail | `bare i1 register condition` | unchanged | unchanged | unchanged (bd `fg9k`/`54ur`/`l4x4`) |
| in-loop siblings over an in-place `sub` parent | granted by the wire fence, caught by `kMsgCrossIter` | — | — | **declines at the wire fence** after (a) |
| `cq_measure(q)` then `if (q>3) φ` | ACCEPT | — | — | **declines** after (b) |

---

## 9. Fixture families, e2e and cost

### 9.1 Item (1) — the negated nest level

**ACCEPT fixtures** (each with whole-file negative prefixes derived from the pass output,
never guessed — `NOX-NOT: cqrt_x(i32 %h_a` / `%h_b`, `NOROUTE-NOT: cqrt_cswap`, plus exact
`XCNT`/`FCNT`/`CNCNT`/`TCNT`/`RZCNT`/`MDCNT` counts):

* `control_phase_nest_rail_negated_outer.ll` (`n1`'s module), `…_negated_inner.ll` (`n2`),
  `…_negated_both.ll` (the `NegL && NegR` row — hand IR), `…_negated_outer_inner_cmp.ll`
  (a rail outer + compare inner, `n5`'s mirror).
* `control_phase_nest_rail_negated_outer_tree_inner.ll` — a negated rail outer with a TREE
  inner, so the conjunction's L is a rail and its R is an ancilla.
* The pre-existing `n3`/`n4` shapes (`control_phase_nest_*` compare/tree roots) must be
  **byte-unchanged**; add a `CHECK` to one of them if none currently counts the brackets.

**DECLINE fixtures** (mirroring the string character-for-character on a `RUN: not …` line; a
`DS_Error` decline writes 0 bytes to stdout so IR negatives are vacuous — say so in the header):

* `control_phase_nest_reject_rail_negated_{outer,inner}.ll` — the two files that exist today
  are REWRITTEN as the accepts above (`git mv` out of `reject_`), which is the shipped precedent
  (`reject_bare_i1` → `rail_diamond`).
* `control_phase_nest_reject_rail_negated_measured_early.ll`, `…_sibling_theta.ll`,
  `…_round2_sibling_theta.ll` — the §13.3 ladder is still owed at BOTH levels for the new accepts.
* `control_phase_nest_reject_rail_negated_inloop.ll` — the nest keeps its `nested control flow`
  loop decline (`ArmClassify.cpp:4713-4717`); unchanged and must stay.

**Injection matrix** (the eqpx / B.1 lesson — the FIRST run always reads MISSED): inject a
`cqrt_x(i32 %h_a …)` on a register, an extra `cqrt_free`, an extra `cqrt_ry` on either
register, a `cqrt_cswap`, a dropped `cnot`, a `toffoli` with the controls swapped; require
each to redden ≥1 prefix in EVERY accept.

**e2e (STRICT stage 2b):** `slice_control_phase_bool_nest_negated.c` + `…_negated_inner.c`,
plus — the increment's best witness — **`e2e-phase-nest-rail-negated-demorgan-identical`**, a
`compare_files` gate between `if (!a) { φ; if (b) φ; }` and its De Morgan twin
`if (a || !b) …` spelled so both lower to the same stream. ⚠ VERIFY that twin lowers on the
PRE-increment binary before promising the gate; if it does not, the honest witness is a stated
line-count reduction against the compare twin `n3` (the Inc-4 precedent), **not** a
`compare_files` gate asserting something false.

Size: **~20-35 production lines** in `CondTreeEmit.cpp` (+ 2 refusal deletions), ~10 fixtures,
2 slices, 0-1 twin gates. **No new runtime symbol, no YAML, no `include/`** (owner D3).

### 9.2 Item (2) — NOT-carrying rail leaves

~12 fixtures (5 accept: `g3`,`g4`,`g5`,`g6` + a rail-NOT under an `and`; 7 decline: the
non-rail NOT child, the negated NODE, the two hand-IR complements, the `AllowLogicalSelect=false`
consumers, the ladder rungs on a negated leaf), 2 slices, plus the `PredMuxFlatten` E6 asymmetry
re-derivation. **~40-60 production lines** across `SelectClassify.{h,cpp}` and `CondTreeEmit.cpp`
if the full negation table lands; ~25 for design 2-B.

### 9.3 Item (3)

~10 fixtures, 0 slices (no plain-C customer), **~50-80 production lines** and a Rule-13 round
for the new mint site. **Defer.**

### 9.4 Residuals (a) and (b)

(a): ~25-40 lines in `WireWalk.{h,cpp}` + 2 threading sites; fixtures `w6`/`w7` as a pinned
pair plus 2-3 accept controls (the shipped rolled loops must stay green) and a whole-corpus
`0 DECLINE→ACCEPT` sweep. (b): ~30-50 lines if built with `r10v` (one shared helper, two call
sites); ~10 accept/decline fixtures + the `m1`/`m3` pair.

### 9.5 Corpus impact estimate

`ir-pass-lit` 1776 → ~1810 if (1)+(2)+(a) all land; `ctest -N` 387 → ~392. Goldens 341 → ~345.
No `runtime/`, `tools/opcode_table.yaml` or `include/` change in ANY item.

---

## 10. Recommendation to the owner — the split

**Five items, three buckets.**

### BUCKET 1 — "the negated rail control" — ONE increment, build it next

**Items (1) and (2) together.** They are the same capability at two levels (§0.2 B), they
share one mechanism (§2.1's negation algebra), and they share one file (`CondTreeEmit.cpp`).
Splitting them means implementing the AND row for the nest and then coming back to generalise
it for the leaves — and H-4 says a half-implemented table is an over-accept shape. Item (1)
alone is the smaller, safer increment (**one gate**, two refusal deletions, no grammar change,
zero risk to the 4.4 select) if the owner wants the minimum; but the grammar half is where the
plain-C customers are (`g3`–`g6` are four honest programs; `n1`/`n2` are two).

**If the owner wants one only: take (1).** It changes no grammar, so `AllowLogicalSelect`'s
one-grammar-two-verdicts contract is untouched, and the nest's decline partition is the
narrowest surface in the file.

### BUCKET 2 — "the compare path's missing rungs" — DO NOT build under `r903`

**Residual (b) should ride with bd `r10v`**, retitled to cover both read points (§6.3). It is
one predicate, two call sites, one Rule-13 round — and building it twice is the 8h7d.5 F-1/F-3
mistake by construction. bd `9pum` (the round-2 taint window at the compare select) is the
third member of that same compare-parity family and should be sequenced with them; the PRD's
`reverifyRailCondReads` extension sketch in `9pum`'s description is the shared fix.

**Item (3) depends on this bucket** (H-6) and has zero measured customers (§0.2 C). Defer it
behind bucket 2 and record §4.1's two design notes.

### BUCKET 3 — "the wire-closure parity" — its OWN increment, with its own Rule-13 round

**Residual (a)** is a `WireWalk` change, i.e. Rule-13 core, touching an ACCEPT-direction
predicate with two consumers. It is orthogonal to buckets 1 and 2 (different file, different
question) and it now has a reproducer (`w6`) and a discriminator (`w7`). Build it as a
narrowing-only increment: monotone toward decline, whole-corpus sweep expected
`0 DECLINE→ACCEPT`, and **close (a-1) and (a-2) in the same commit** (§5.2).

### Filing

* `r903` → **`r903.a`** = items (1)+(2), the negated rail control (bucket 1).
* `r903` → **`r903.b`** = item (3), derived-`i1` conditions — **blocked on bucket 2**, no
  customer, defer.
* Residual (a) → its own bead (or `r903.c`), **`WireWalk` closure parity**, P2, with `w6`/`w7`
  committed as its reproducer pair and H-1 recorded as the re-opening condition on
  `collapseRailPhisIn`.
* Residual (b) → **MOVE into bd `r10v`**; add a NOTE to `9pum` that the three form one
  compare-parity family.

### One owner question this scoping cannot answer

**(b) is an over-decline for a correct program.** `m1`'s unitary is fine (§6.2); declining it
buys SYMMETRY with the rail path and Rule 6's stated policy, and costs a program that compiles
today. The alternative — widening the RAIL rung to accept `m3` — is cheaper in capability and
worse in policy. **Recommend the decline**, but put the choice to the owner rather than
shipping it as an implementation detail.
