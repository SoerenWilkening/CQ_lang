# CQ_lang Phase 3 PRD — Full Operator Set

## Goal

Extend Phase 2's `+`-only operator slice to the **complete LLVM data-opcode surface** Clang emits for the C arithmetic / bitwise / comparison / unary / cast operator families. The pipeline shape, intrinsic surface, and runtime ABI established in Phases 1–2 are unchanged; Phase 3 is "more opcodes" along one axis (taint coverage in the IR pass) and "more AST shapes the rewriter passes through" along another. **No new mechanism** beyond Phase 2 — the existing taint propagation, mid→handle rebinding, and Q+Q / Q+C dispatch generalize to the broader opcode set without architectural change.

**Backend implementation remains out of scope.** All new `cq_template_*` symbols added in Phase 3 are trace-only `printf` stubs declared in `runtime/cq_templates.h`. The actual reversible-circuit bodies belong to the post-Phase-10 backend implementation per [`ROADMAP.md`](../../ROADMAP.md) §"Design principles" #1.

## Scope

Phase 3 broadens Phase 2 along three orthogonal axes:

1. **Operator coverage** — every LLVM data opcode Clang emits at `-O1` for the supported C operator surface (arithmetic, bitwise, comparison, unary, cast). Enumerated in §"Operator surface" below.
2. **AST patterns** — four new patterns beyond Phase 2's six: plain assignment, compound assignment, unary operators on quantum operands, and Q→Q casts (explicit + implicit).
3. **Template variants** — forward Q+Q, forward Q+C (`_hl`), inverse Q+Q (`_inv`), inverse Q+C (`_hl_inv`) per binary opcode; forward + inverse per unary/cast opcode. Declared as the **full grid** up front (frontend-complete contract).

Plus, derived from those:

4. **Comparison flag-handle contract** — comparators (`icmp`, `fcmp`) produce a quantum flag handle as the result; Phase 4's `cq_when_*` lowering will consume this contract.
5. **Mixed-width type promotion** absorbs into normal cast-template coverage — Clang lowers C standard widening to `sext` / `zext` / `trunc`, taint propagates through them, the new cast templates handle the rest. No separate "3.4" sub-item; falls out from §"Operator surface" automatically. One acceptance fixture demonstrates the chain works end-to-end.

**Explicitly deferred from Phase 3 vs. the ROADMAP wording:**

- **Controlled-forward variants** — Phase 4 owns these alongside the IR-pass `cq_when_*` region detection that consumes them. See §"Roadmap discrepancy".
- **3.3 classical-mask views (`q & C` zero-cost bit views)** — moved out of frontend scope. From the IR pass's perspective, `q & C` is just another tainted `and` opcode lowered to `cq_template_and_<W>_hl`; whether the backend's template body implements that via bit-aliasing optimization or full CNOT fan-out is a *backend* concern that emerges with real template bodies post-Phase-10. The IR-pass-level "view aliasing + bind-site detection" mechanism the ROADMAP sketched is unnecessary at the frontend layer. See §"Roadmap discrepancy".
- **Structural ops (XOR-copy, swap)** — Phase 7 surfaces the first context where assignments survive SROA (function call boundaries); the copy-template family belongs there. C has no `swap` operator. See §"Roadmap discrepancy".

## Marker syntax (input)

Unchanged from Phase 2. `quantum` is the macro from `<CQ.h>`; the rewriter matches `AnnotateAttr("quantum")` on `VarDecl`s and `ParmVarDecl`s (the latter still unused in Phase 3 — Phase 7 brings quantum parameters).

## Supported source patterns and rewrites

Phase 2's six patterns are preserved verbatim. Phase 3 adds four new patterns and generalizes the operator in Patterns 3–4 from `+` to any supported operator.

| # | Source | Rewritten output | Phase |
|---|---|---|---|
| 1 | `quantum T x;` | `qT_mid_t x = cq_init_<sfx>(0);` | 2 |
| 2 | `quantum T x = E;` (E classical) | `qT_mid_t x = cq_init_<sfx>(E);` | 2 |
| 3 | `quantum T z = a OP b;` (both quantum, OP ∈ supported) | `qT_mid_t z; z.val = a.val OP b.val;` | 2 (generalized) |
| 4 | `quantum T z = a OP E;` (a quantum, E classical) | `qT_mid_t z; z.val = a.val OP E;` | 2 (generalized) |
| 5 | `(T) q` (q quantum T, T classical) | `cq_measure_<sfx>(q)` | 2 |
| 6 | `quantum T b = a;` (a quantum T) | `qT_mid_t b; b.val = a.val;` | 2 |
| 7 | `z = expr;` (z existing quantum var) | rewrite quantum sub-exprs to `.val` form; preserve assignment structure | **3 — new** |
| 8 | `a OP= b;` (compound assign, a quantum) | `a.val = a.val OP <b.val or b>;` (expanded for clarity; compound `a.val OP= …` form is equivalent) | **3 — new** |
| 9 | `OP a` / `a OP` (unary on quantum a; OP ∈ `-` `~` `!` `++` `--`) | `OP a.val` / `a.val OP` — stock C; Clang's lowering does the rest | **3 — new** |
| 10 | `(quantum T) q_other` (explicit Q→Q cast) | `qT_mid_t z; z.val = (T) q_other.val;` — stock C cast on `.val` | **3 — new** |
| 11 | `quantum T z = q_other;` (implicit cross-width Q→Q) | Same as pattern 10 — rewriter routes via destination-quantum-ness discriminator (see §"On the Q→Q vs Q→C discriminator") | **3 — new** |

`OP` ranges over the supported operator set; the rewriter does *not* enumerate per operator. The transform is uniform: rewrite quantum `DeclRefExpr`s to `.val` access; let Clang's normal lowering produce the LLVM opcodes; the IR pass picks them up via taint propagation.

**No QQ/QC dispatch in the rewriter.** As in Phases 1–2, taint propagation in the IR pass handles QQ / QC / mixed uniformly. The rewriter has no per-operand-shape code paths.

## On the Q→Q vs Q→C discriminator

The rewriter's `CastRewrite` module gains a one-line conditional: emit `cq_measure_<sfx>` iff the cast's destination type is **not** quantum-annotated; otherwise emit a stock C cast on `.val`. The same discriminator handles four cases:

| Case | Source shape | Destination | Rewriter emits |
|---|---|---|---|
| Q→C explicit | `(int) q` | classical | `cq_measure_si32(q)` — measurement intrinsic |
| Q→C implicit | `int x = q;` | classical | `cq_measure_si32(q)` |
| Q→Q explicit | `(quantum long) q_int` | quantum | `(long) q_int.val` — stock cast on `.val` |
| Q→Q implicit | `quantum long z = q_int;` | quantum | `qlong_mid_t z; z.val = (long) q_int.val;` |

**Why the rewriter must discriminate** (and the IR pass cannot recover from a wrong emission): the LLVM IR for a Q→C cast and a Q→Q cast at the same width pair is identical — both produce a tainted cast opcode (`trunc` / `sext` / `zext` / `sitofp` / etc.) with an SSA result of the destination width. The "this value is classical now" signal is not visible in the IR; only the AST carries the destination-quantum-ness information. The rewriter has it; the IR pass doesn't. Once the rewriter emits the right marker, the IR pass detects tainted casts trivially and lowers via the per-(cast-kind, from-width, to-width) template (§"Operator surface", §"IR pass changes").

**Edge case — quantum expression flowing to classical destination.** `int x = (a == b);` (where `a`, `b` are quantum) is a quantum *expression* (not a single `DeclRefExpr`) flowing into a classical VarDecl. The rewriter's discriminator at the VarDecl level handles single-DeclRefExpr sources cleanly (Pattern 11), but recursively detecting "any sub-expression touches a quantum operand → wrap entire expression in measure" is more invasive than Phase 3's "stock C on `.val` everywhere" posture warrants. **Resolution:** Phase 3 requires explicit measurement-by-cast for quantum-expression-into-classical-destination cases. `int x = (int) (a == b);` works (CStyleCastExpr at the boundary triggers the discriminator). `int x = (a == b);` produces a tainted-value-flowing-into-classical-store IR shape that the IR pass diagnoses as unsupported. See §"Known soft-failure modes".

## Operator surface

The complete LLVM data-opcode surface Phase 3 supports. Width applicability is implicit: integer opcodes at `i1`/`i8`/`i16`/`i32`/`i64` (5 widths), floating-point opcodes at `f32`/`f64` (2 widths), cast opcodes per the cross-pair tables below.

### Integer arithmetic (sign-aware where C distinguishes)

| LLVM opcode | C operator | Notes |
|---|---|---|
| `add` | `+`, `+=`, unary `++` | already in Phase 2; unary `++` lowers to `add … 1` |
| `sub` | `-`, `-=`, unary `-`, `--` | unary minus lowers to `sub 0, x`; existing operand-swap in `OpcodeLowering` puts the handle on lhs |
| `mul` | `*`, `*=` | |
| `sdiv` | `/`, `/=` (signed types) | |
| `udiv` | `/`, `/=` (unsigned types) | |
| `srem` | `%`, `%=` (signed types) | |
| `urem` | `%`, `%=` (unsigned types) | |

### Integer bitwise

| LLVM opcode | C operator | Notes |
|---|---|---|
| `and` | `&`, `&=` | |
| `or` | `\|`, `\|=` | |
| `xor` | `^`, `^=`, unary `~` | unary `~` lowers to `xor x, -1` |
| `shl` | `<<`, `<<=` | |
| `lshr` | `>>`, `>>=` (unsigned operand) | |
| `ashr` | `>>`, `>>=` (signed operand) | sign-aware |

### Integer comparison

`icmp <pred>` with 10 predicates:

| Predicate | C operator(s) | Notes |
|---|---|---|
| `eq` | `==` | |
| `ne` | `!=`, unary `!` (`icmp eq … 0`-derived; Clang chooses) | |
| `slt` / `sgt` / `sle` / `sge` | `<` / `>` / `<=` / `>=` (signed operands) | |
| `ult` / `ugt` / `ule` / `uge` | `<` / `>` / `<=` / `>=` (unsigned operands) | |

Each comparator produces a **quantum flag handle** — see §"Comparison contract" below.

### Floating-point arithmetic

| LLVM opcode | C operator | Notes |
|---|---|---|
| `fadd` | `+`, `+=` | already in Phase 2 |
| `fsub` | `-`, `-=` | |
| `fmul` | `*`, `*=` | |
| `fdiv` | `/`, `/=` | |
| `frem` | `%`, `%=` (no native C `%` on fp, but `fmodf`/`fmod` is the libm equivalent — out of scope until Phase 7) | |
| `fneg` | unary `-` (Clang 6+) | **the only genuinely new unary opcode** — int unary `-` reuses `sub`, but fp unary `-` is its own opcode |

### Floating-point comparison

`fcmp <pred>` — the **ordered** subset (the 6 predicates Clang reliably emits from C source comparisons):

| Predicate | C operator |
|---|---|
| `oeq` | `==` |
| `one` | `!=` |
| `olt` / `ogt` / `ole` / `oge` | `<` / `>` / `<=` / `>=` |

Unordered fcmp predicates (`ueq`, `une`, `ult`, `ugt`, etc.) and `ord` / `uno` are out of scope unless a fixture turns up needing them. Documented as "not exercised at `-O1` from C source"; can be added later without disturbing the convention.

### Integer width casts

`sext` / `zext` / `trunc` over the 5 int widths. The supported (from, to) width pairs:

| Cast kind | From → To pairs |
|---|---|
| `sext` | `i1→i8`, `i1→i16`, `i1→i32`, `i1→i64`, `i8→i16`, `i8→i32`, `i8→i64`, `i16→i32`, `i16→i64`, `i32→i64` (10 pairs) |
| `zext` | same 10 pairs as `sext` |
| `trunc` | `i8→i1`, `i16→i1`, `i16→i8`, `i32→i1`, `i32→i8`, `i32→i16`, `i64→i1`, `i64→i8`, `i64→i16`, `i64→i32` (10 pairs) |

### Floating-point width casts

| Cast kind | From → To |
|---|---|
| `fpext` | `f32→f64` |
| `fptrunc` | `f64→f32` |

### Cross-domain casts (int ↔ fp)

| Cast kind | From → To pairs |
|---|---|
| `sitofp` | `i8→f32`, `i8→f64`, `i16→f32`, …, `i64→f64` (4 int × 2 fp = 8 pairs) |
| `uitofp` | `i1→f32`, `i1→f64`, `i8→f32`, …, `i64→f64` (5 int × 2 fp = 10 pairs) |
| `fptosi` | `f32→i8`, `f32→i16`, …, `f64→i64` (2 fp × 4 int = 8 pairs) |
| `fptoui` | `f32→i1`, `f32→i8`, …, `f64→i64` (2 fp × 5 int = 10 pairs) |

### Out of scope (not Phase 3)

LLVM opcodes:

- `bitcast`, `ptrtoint`, `inttoptr` — pointer-domain casts; Phase 8 introduces pointer-to-quantum.
- `addrspacecast` — not used in CQ.
- `load`, `store`, `getelementptr` — Phase 8 memory model.
- `phi`, `select` — Phase 4 region handling introduces tainted control flow that produces these.
- `br i1` on a tainted condition — quantum control flow; Phase 4 (`cq_when_*` regions).
- `llvm.memcpy` / `llvm.memset` / `llvm.ctpop` / vector intrinsics — Phase 8+ or backend.

C operators that lower to quantum control flow (deferred to Phase 4):

- **`&&`, `||`** (short-circuit logical AND / OR). Clang lowers these to `icmp ne` + tainted `br i1` + `phi` — the same control-flow shape as `IfStmt`. When operands are quantum, the branch is tainted and belongs inside a `cq_when_*` region. Note for Phase 4 PRD: extend the `IfStmt` rewriter pattern to also handle `BinaryOperator(BO_LAnd, …)` and `BinaryOperator(BO_LOr, …)` on quantum operands.
- **Ternary `a ? b : c`** (`ConditionalOperator`). Same lowering family as `&&` / `||` — branch on condition with a phi at the merge. Phase 4 PRD scope.
- Note: the **bitwise** `&` / `|` *are* in Phase 3 (no short-circuit, no branching — just `and` / `or` opcodes). The distinction is short-circuit semantics, not the operator's symbol.

## Comparison contract

Locked here as a stable contract Phase 4 consumes.

**Template signature:**
```c
int32_t cq_template_icmp_<pred>_<W>(int32_t a_handle, int32_t b_handle);
int32_t cq_template_icmp_<pred>_<W>_hl(int32_t a_handle, <W-typed> b_classical);
int32_t cq_template_fcmp_<pred>_<W>(int32_t a_handle, int32_t b_handle);
int32_t cq_template_fcmp_<pred>_<W>_hl(int32_t a_handle, <W-typed> b_classical);
```

- **Return value:** an `int32_t` handle (the **flag handle**) — opaque, indistinguishable at the ABI from any other handle. The runtime knows it indexes a logically-1-bit register; nothing in IR-emitted code or the template library needs to.
- **One symbol per (predicate, width).** No predicate-enum dispatch — the predicate is part of the LLVM opcode identity (`icmp slt` and `icmp sgt` are distinct opcodes at the IR level), so one C symbol per predicate matches the convention of "one template per LLVM opcode flavor."
- **Q+C variant** (`_hl`) follows the existing binary-op convention: handle on lhs, classical scalar on rhs. The IR pass's existing operand-swap logic (`OpcodeLowering.cpp:194` — `BTainted` branch) handles classical-on-lhs cases by swapping at lowering time.
- **Lifetime:** the flag handle is just another tainted SSA value. Phase 5's auto-uncomp will treat it identically to any other quantum handle at its last use. No special story.

## Naming convention

Uniform across opcode families:

```
cq_template_<opcode>[_<predicate>]_<width>[_<from→to>][_hl][_inv]
```

Concrete forms:

| Shape | Example |
|---|---|
| Forward Q+Q binary | `cq_template_sub_i32(int32_t, int32_t)` |
| Forward Q+C binary | `cq_template_sub_i32_hl(int32_t, int32_t)` |
| Inverse Q+Q binary | `cq_template_sub_i32_inv(int32_t, int32_t, int32_t result)` (void return) |
| Inverse Q+C binary | `cq_template_sub_i32_hl_inv(int32_t, int32_t, int32_t result)` (void return) |
| Forward unary | `cq_template_fneg_f64(int32_t)` |
| Inverse unary | `cq_template_fneg_f64_inv(int32_t, int32_t result)` (void return) |
| Forward int compare Q+Q | `cq_template_icmp_slt_i32(int32_t, int32_t)` — returns flag handle |
| Forward int compare Q+C | `cq_template_icmp_slt_i32_hl(int32_t, int32_t)` |
| Inverse int compare Q+Q | `cq_template_icmp_slt_i32_inv(int32_t, int32_t, int32_t flag)` |
| Forward fp compare | `cq_template_fcmp_oeq_f64(int32_t, int32_t)` |
| Forward int width cast | `cq_template_sext_i8_to_i32(int32_t)` |
| Inverse int width cast | `cq_template_sext_i8_to_i32_inv(int32_t, int32_t result)` |
| Forward cross-domain cast | `cq_template_sitofp_i32_to_f64(int32_t)` |
| Inverse cross-domain cast | `cq_template_sitofp_i32_to_f64_inv(int32_t, int32_t result)` |

**Inverse-signature rationale.** Inverses take the inputs *plus* the result handle (the handle to uncompute) and return `void`. Phase 5's auto-uncomp emits these calls at SSA live-range ends; the inverse stub's job is to consume the result handle and emit the adjoint gate sequence (post-backend). At Phase 3, the stub body just printfs its name and arguments.

**Inverse Q+C variants.** Declared symmetrically with the forward Q+C variants. Same rationale as forward: trace-only stubs; Phase 5 selects the right symbol at the call site based on operand-taint dispatch.

## Template surface (parametric)

The full grid up front, declared in `runtime/cq_templates.h`. Total estimated declarations: **~600–700 symbols** (~half binary opcodes × 5 widths × 4 variants; ~half compare predicates × widths × 4 variants; ~quarter casts × pairs × 2 variants).

Implementation note (PLAN-stage): the symbol list is large enough that hand-listing every declaration in `cq_templates.h` is impractical; PLAN will pick between (a) hand-written but table-generated (a Python or shell script in `tools/` produces the `.h` + `.c` from a YAML/CSV table), or (b) macro-expansion via `X-macros` in `cq_templates.h`. Either way the *contract* is the parametric naming scheme above; the *generation* is a PLAN detail.

## Intrinsic surface (cq_mid.h additions)

**No new intrinsics in Phase 3.** All of Phase 3's new functionality flows through stock LLVM opcodes (taint propagation) and the existing `cq_init_<sfx>` / `cq_measure_<sfx>` families from Phase 2. The intrinsic-surface count remains at 28 (14 init + 14 measure).

Region-bracket intrinsics (`cq_when_*`, `cq_invert_*`) and rotation intrinsics (`cq_theta`, `cq_phi`) are introduced by the phases that consume them (4 and 2/7 respectively) — Phase 3 doesn't touch them.

## Stub `libcq_runtime`

**No changes from Phase 2.** Phase 2 already covers all 7 widths' `cqrt_alloc_<W>` / `cqrt_measure_<W>` + `cqrt_free` + `cqrt_alloc_handle`. Phase 3 introduces no new runtime symbols (templates expand, runtime ABI does not).

## Stub template library

Grows from Phase 2's 28 symbols (`cq_template_add_<W>` × 7 widths × {Q+Q, Q+C} = 14, plus … actually Phase 2 ships only `add` Q+Q/Q+C × 7 widths = 14, no inverses yet) to ~600–700 symbols, all `printf`-name stubs. See §"Naming convention" and §"Operator surface" for the parametric description.

**Forward and inverse declared together in Phase 3.** Per the user-confirmed design discussion: all backend functions are trace-only stubs declared in their first introducing phase; Phase 5 plugs into the declared inverse symbols when it adds the auto-uncomp IR-pass logic.

**Controlled-forward variants are not in Phase 3.** Phase 4 owns adding `cq_template_*_ctrl` / `cq_template_*_hl_ctrl` declarations alongside its `cq_when_*` region detection. Recorded here for traceability; not a Phase 3 deliverable.

## Rewriter changes

Additive on Phase 2's modules. Four new AST patterns (Patterns 7–11 above), one discriminator extension in `CastRewrite`. No new files; no new architectural mechanism.

| Module | Change |
|---|---|
| `Matcher` | Extend AST pattern matchers to recognize: (a) `BinaryOperator(BO_Assign, …)` with quantum LHS — Pattern 7; (b) `CompoundAssignOperator(…)` with quantum LHS — Pattern 8; (c) `UnaryOperator(…)` with quantum operand — Pattern 9. The recognition is mechanical AST-shape inspection; no semantic novelty. |
| `Codegen` | New emission paths for Patterns 7–9: rewrite quantum `DeclRefExpr`s to `.val` access; preserve the assignment / unary structure. For Pattern 8 (compound assign), expand to the equivalent simple-assign form (`a OP= b` → `a.val = a.val OP <b>`) for the canonical generated output; the compound-on-`.val` form (`a.val OP= b.val`) is semantically equivalent and may be preferred at PLAN time. |
| `CastRewrite` | Destination-quantum-ness discriminator: if destination type is quantum-annotated, emit stock C cast on `.val` (Patterns 10–11); else emit `cq_measure_<sfx>` (Pattern 5, existing Phase 2 behavior). |
| `DeclStmtRewrite` | Extend keyword recognition? **No change** — Phase 2 already covers all 14 mid-struct types. Phase 3 reuses. |
| `TypeMap` | **No change** — same 14-type table, same suffix selectors. |
| `QuantumAttr` | **No change** — attribute recognition is type-agnostic. |
| `OperandClass` | May need extension to classify operand quantum-ness for Patterns 7–9 (Phase 2 uses it for binop operand classification); audit at PLAN time. |

**No new rewriter mechanism.** Pattern recognition is mechanical AST inspection; transforms are uniform "convert quantum DeclRefExpr to `.val`" rewrites. The Phase 1/2 architectural decisions (no per-operator code paths, no QQ/QC dispatch, no inverse emission, no specialization) are preserved.

## IR pass changes

Productionizes Phase 2's hardcoded `add`/`fadd`-only `OpcodeLowering` into a **table-driven dispatch** covering the full §"Operator surface". Exact table representation and dispatch architecture are PLAN-stage decisions (see §"Open items"); the PRD locks the *contract*:

| Stage | Phase 2 | Phase 3 |
|---|---|---|
| Forward taint propagation | Loops over all `@cq_init_<sfx>` symbols; propagates monotonically over SSA DAG | **Unchanged** — taint is opcode-agnostic |
| Mid → handle rebinding | 14-type lookup; rebinds `@cq_init_<sfx>` returns and `extractvalue`s | **Unchanged** |
| Tainted opcode lowering | Hardcoded switch on `Instruction::Add` / `Instruction::FAdd` (`OpcodeLowering.cpp:127-133`) | **Table-driven**: dispatch on `Instruction::Opcode` (and `CmpInst::Predicate` for compares) → template-symbol-stem. Q+Q / Q+C operand dispatch via the existing taint-set check (no change). |
| Comparison lowering | not in Phase 2 | New: dispatches `icmp <pred>` / `fcmp <pred>` to per-predicate symbol; result type is `int32_t` flag handle |
| Cast lowering | not in Phase 2 | New: dispatches `sext` / `zext` / `trunc` / `fpext` / `fptrunc` / `sitofp` / `uitofp` / `fptosi` / `fptoui` to per-(from, to)-width symbol |
| Unary lowering | not in Phase 2 | Almost free — Clang lowers `-x`/`~x`/`!x`/`++x`/`x++` to existing binary opcodes (`sub 0, x`, `xor x, -1`, `icmp + zext`, `add x, 1`). The only genuinely new opcode dispatch is `fneg`. |
| `@cq_measure_<sfx>` lowering | Per-suffix rule → `cqrt_measure_<W>` | **Unchanged** |

**Operand-swap canonicalization** for Q+C (existing logic in `OpcodeLowering.cpp:194` — `BTainted` branch swaps classical-on-lhs to handle-on-lhs) generalizes uniformly: every binary opcode in the new table inherits the same dispatch.

**Width-resolution.** Per Phase 2's discipline (`OpcodeLowering.cpp:49-65` — `abiWidthFromType`): `IntegerType::getBitWidth()` for ints, `isFloatTy`/`isDoubleTy` for fp, restricted to the supported widths. Phase 3 extends to cast widths via `getSourceElementType` / equivalent — the (from, to) pair becomes part of the lookup key.

**Diagnostics.** The existing "no template for opcode" diagnostic (`OpcodeLowering.cpp:83-89` — `DiagnosticInfoUnsupported`) becomes a *positive coverage signal*: when it fires after Phase 3, something Clang emitted is genuinely outside the declared surface. PRD-level expectation: with the full-grid table in place, the diagnostic should not fire for any program built from the C operator families in §"Operator surface".

## Known soft-failure modes

Carried forward from Phase 2 + new Phase-3-specific limitations. Acceptable for Phase 3; revisit at later phases as flagged.

- **`_Bool` (i1) opcodes rarely exercised at `-O1`.** Clang's `-O1` lowers `_Bool` arithmetic patterns to `i8` operations *before* the IR pass sees them (e.g., `_Bool b + 1` becomes `or i8` rather than `add i1`). The i1 templates are declared symmetrically (the full grid does not special-case i1), but most are dead surface in practice. Documented; not a bug. Phase 2's `_Bool` shared-handle fixture (`tests/e2e/fixtures/types/i1/`) carries forward.
- **Expression statements without assignment.** `a + b;` standalone (no LHS, gates execute, result discarded) is **out of scope** for Phase 3. The rewriter does not pattern-match on `ExprStmt` containing a quantum BinaryOperator. Documented; reintroduce if a future phase finds it useful.
- **Quantum expression flowing to classical destination without explicit cast.** `int x = (a == b);` and similar — quantum *expression* (not single DeclRefExpr) into classical destination. **Out of scope** for Phase 3; users write the explicit `(int)` cast: `int x = (int) (a == b);` which routes through the CastRewrite discriminator (Q→C case, emits `cq_measure_i1`). Documented; see §"On the Q→Q vs Q→C discriminator".
- **Mixed-width compound assignment to narrower quantum LHS.** `quantum int a; quantum long b; a += b;` — Clang inserts implicit narrowing on `b`. The rewriter rewrites operands to `.val` access and the implicit conversion becomes a `trunc i64 to i32` in IR; Phase 3 covers the `trunc` template, so this should work mechanically. Worth a fixture but not a new mechanism.
- **fcmp unordered predicates** (`ueq`/`une`/`ult`/`ugt`/`ule`/`uge`/`ord`/`uno`) — Clang doesn't emit these from natural C comparisons at `-O1`, so templates are not declared in Phase 3. If a future fixture surfaces a need, add per the convention (declarations only, no source changes).
- **Address-taken quantum variables** (`&q_var`) — Phase 8 territory. Phase 3 doesn't exercise; an attempt would produce SSA values that don't fit the existing rebinding rules.

## Testing

Three layers, same as Phase 2; volumes adjusted for the broader surface.

### Layer 1 — End-to-end (acceptance contract)

Fixture set organized by **operator family** rather than per-(opcode, width) pair (the latter would be ~200 fixtures, impractical). Proposed structure:

```
tests/e2e/fixtures/phase3/
  int_arith/         — sub, mul, sdiv, udiv, srem, urem at i32 representative; spot-check i8, i64
  int_bitwise/       — and, or, xor, shl, lshr, ashr at i32; spot-check i8, i64
  int_compare/       — all 10 icmp predicates at i32; spot-check at i8 (slt/sgt only)
  fp_arith/          — fsub, fmul, fdiv, fneg at f32 + f64
  fp_compare/        — 6 ordered fcmp predicates at f32 + f64
  cast_int_widths/   — sext/zext/trunc representative pairs (incl. the §"3.4 absorbed" mixed-width chain)
  cast_fp_widths/    — fpext + fptrunc
  cast_cross_domain/ — sitofp + fptoui representative (one each direction)
  unary/             — `-a` (int + fp), `~a`, `!a`, `++a` / `a++`
  compound_assign/   — `+=`, `*=`, `<<=`, `&=` (representative)
  plain_assign/      — `z = a + b;` to existing quantum z
  qq_cast/           — `(quantum long) q_int` and `quantum long z = q_int;` (Pattern 10/11)
```

Roughly **30–40 e2e fixtures**, each with `input.c` + golden `expected.log`. Phase 2's 21 fixtures continue passing without modification.

### Layer 2 — Rewriter unit tests

Per-pattern goldens for the 4 new AST patterns (Patterns 7–11). Mechanical extension of `transpiler/tests/unit/`. Roughly **20–30 new unit goldens**:

- Patterns 7 / 8 / 9 / 10 / 11 each at several operator/operand combinations
- CastRewrite discriminator: explicit Q→Q, implicit Q→Q, explicit Q→C, implicit Q→C — 4 cases per representative width pair

### Layer 3 — IR pass LIT/FileCheck

**This is the full-grid coverage assertion.** One LIT fixture per (opcode, width) — or per (opcode, predicate, width) for compares, per (cast-kind, from-width, to-width) for casts. Hand-written `.ll` fragments asserting the right template symbol is called. Estimated **~300 small LIT fixtures**, each 5–10 lines.

Generation strategy (PLAN-stage detail): a script in `tools/` may auto-generate these fixtures from the same opcode/width tables that drive the template-stub generation, so the harness scales without per-fixture authoring cost.

## `cqc` driver

**No changes from Phase 2.** The driver orchestrates pipeline stages by symbol/path; Phase 3's expansion happens entirely within the rewriter (more AST patterns) and IR pass (table-driven dispatch). The `-include cq_mid.h` thread-through continues to work — `cq_mid.h` doesn't grow in Phase 3 (no new intrinsics).

## Diagnostics baseline

Unchanged from Phase 2 — passive `SourceLocation` and `!dbg` preservation only. The existing `DiagnosticInfoUnsupported` "no template for opcode" surface in `OpcodeLowering.cpp` is the *positive coverage signal*: with the full grid declared, it should not fire for any program in the §"Operator surface" supported set. Phase 5 introduces active source-location-precise diagnostics for reversibilizability errors.

## Roadmap discrepancy

Three places where this PRD diverges from [`ROADMAP.md`](../../ROADMAP.md) §"Phase 3":

1. **Controlled-forward variants — moved to Phase 4.** ROADMAP §Phase 3 says: *"Stub templates: `cq_template_<op>_<W>` per (opcode, width); forward + controlled-forward variants (Phase 4 needs the controlled ones)."* The PRD ships forward only. Rationale: the IR-pass region detection that *consumes* controlled-forward templates lives in Phase 4; declaring the stubs alongside that work keeps the controlled-variant introduction co-located with its consumer. Phase 3 is sized down accordingly. Recorded in Phase 3 closure (forthcoming): Phase 4 PRD must include controlled-forward stub declarations in its deliverables.

2. **3.3 classical-mask views — moved out of the frontend roadmap.** ROADMAP §Phase 3 lists *"3.3 Classical-mask views (`q & C`). Zero-cost bit-view semantics … IR-pass-level responsibility; bind-site detection via SSA use position."* The PRD removes 3.3 from Phase 3 entirely. Rationale: from the IR pass's perspective, `q & C` is just another tainted `and` opcode that lowers to `cq_template_and_<W>_hl`. Whether the backend's template body implements that via bit-aliasing optimization vs. a full CNOT fan-out is a *template-implementation* concern that emerges post-Phase-10 when real bodies land. The IR-pass-level "view aliasing + bind-site detection" is unnecessary at the frontend layer. Status: deferred to post-freeze backend optimization phase.

3. **3.4 absorbed into operator coverage.** ROADMAP §Phase 3 calls out *"3.4 Mixed-width type promotion. Free under the new architecture — Clang lowers C standard widening to `sext` / `zext` / `trunc`, taint propagates through them, templates for those opcodes handle the rest."* The PRD does not carve 3.4 as a separate sub-item — it falls out automatically from shipping the §"Operator surface" cast templates. One acceptance fixture in `cast_int_widths/` demonstrates the chain end-to-end.

4. **Structural ops (XOR-copy, swap) — deferred to Phase 7.** ROADMAP §Phase 3 lists *"Structural: XOR-copy (CNOT), swap"* in the operator set. The PRD defers both. Rationale (matching Phase 2 PRD §"On assignment and surviving operations"): Phase 3 has no surviving assignments (no functions, no arrays, no struct members), so SROA erases any candidate copy or swap before the IR pass sees it. Phase 7 (functions) is the first context where assignments survive at call boundaries; the copy-template family belongs there. C has no `swap` operator at the source level.

These divergences will be reflected in the ROADMAP closure-note update at Phase 3 sign-off (matching Phase 2's pattern — minor wording correction at closure, not a mid-phase deliverable).

## Out of scope (deferred to later phases)

| Phase | Item |
|---|---|
| 4 | Controlled-forward template variants (`_ctrl` / `_hl_ctrl`); `cq_when_*` region detection in IR pass; quantum-condition `if` rewriter pattern |
| 5 | Auto uncomputation IR-pass logic that *consumes* the `_inv` stubs declared in Phase 3; active source-location diagnostics for non-reversibilizable use |
| 6 | `for` loops with classical bounds (mostly free; validation phase) |
| 7 | User-defined quantum functions + inversion; **XOR-copy template family + IR-pass copy detection at call boundaries** (the first phase with surviving assignments) |
| 8 | Arrays/pointers; QRAM; copy emission for memory-stored quantum |
| 9 | `struct` / `union` / `_Complex` / remaining C surface |
| 10 | Quantum-conditioned `while` |
| 11 | Frontend freeze; ABI lock |
| Backend | Real `cq_template_*` and `cqrt_*` bodies; backend optimization including 3.3-style classical-mask bit-view materialization |
| Backend | `_Float16` / `long double` templates |
| Backend | fcmp unordered predicates / `ord`/`uno` if/when needed |

## Deliverables

### New files

- `phases/phase3/PRD.md` — this document
- `phases/phase3/PLAN.md` — implementation plan (forthcoming, post-PRD acceptance)
- `tests/e2e/fixtures/phase3/<family>/` — ~30–40 e2e fixtures (directory structure under §"Testing L1")
- `ir-pass/test/<opcode>/` — ~300 LIT fixtures (per §"Testing L3"); generation strategy in PLAN
- `tools/<script>` — opcode/width-table-driven generator for `cq_templates.h` + LIT fixtures (PLAN decides exact form: Python / shell / X-macros)

### Modified files

- `runtime/cq_templates.h` + `runtime/cq_templates.c` — grows from 28 symbols to ~600–700 stub declarations + `printf`-name bodies; generated form preferred over hand-listing
- `transpiler/src/Matcher.cpp` + `Matcher.h` — new AST pattern matchers for Patterns 7–9
- `transpiler/src/Codegen.cpp` — new emission paths for Patterns 7–11
- `transpiler/src/CastRewrite.cpp` — destination-quantum-ness discriminator
- `transpiler/src/OperandClass.cpp` — audit for Patterns 7–9 extension (PLAN decides)
- `transpiler/tests/unit/` — ~20–30 new per-pattern goldens
- `ir-pass/src/OpcodeLowering.cpp` — table-driven dispatch replacing the hardcoded switch
- `ir-pass/include/OpcodeLowering.h` + new modules (e.g., `CastLowering.cpp`, `CompareLowering.cpp` if PLAN splits the table) — PLAN decides decomposition

### No renames

Phase 3 is purely additive. No symbol renames, no breaking changes to Phase 2's intrinsic surface or runtime ABI.

## Acceptance criteria

Phase 3 is done when **all** of the following hold:

1. The §"Operator surface" opcode set lowers end-to-end through the pipeline for representative widths of each family.
2. The ~30–40 e2e fixtures under `tests/e2e/fixtures/phase3/` produce byte-exact golden call logs.
3. The mixed-width "3.4 absorbed" acceptance fixture demonstrates `sext`/`zext`/`trunc` chains compose with arithmetic templates correctly.
4. The comparison contract is exercised: each predicate produces a flag handle that flows through subsequent ops or measurement.
5. The Q→Q cast discriminator (Patterns 10–11) is exercised: explicit `(quantum T) q_other` and implicit `quantum T z = q_other;` both produce stock-cast IR with no spurious `cq_measure` calls.
6. The Q→C cast discriminator continues to route `(T) q` correctly (Phase 2 Pattern 5 unchanged).
7. All Phase 1 and Phase 2 e2e fixtures pass without modification.
8. Layer 2 (rewriter unit) and Layer 3 (IR pass LIT, full-grid coverage) tests are green.
9. The `OpcodeLowering` "no template for opcode" diagnostic does not fire for any program in the supported operator surface.
10. No regression in Phase 1/2 fixture build performance beyond expected linear growth in the (much larger) Phase 3 template-stub compilation.

## Open items (decided at PLAN time)

These do not block PRD acceptance. Canonical disposition lives in [`PLAN.md`](PLAN.md) once authored.

- **Template-stub generation mechanism.** Hand-written (impractical at this scale), table-driven generation script in `tools/` (Python or shell, driven by a YAML/CSV opcode/width table), or X-macros in the `.h`. Trade-off: build-system dependency vs. preprocessor complexity vs. opaque generated artifacts. PLAN decides.
- **IR-pass table representation.** Single flat table keyed by `(Opcode, Type, [Predicate], [from-type, to-type])`, or split tables per opcode family (arith / bitwise / compare / cast)? Affects code organization (`OpcodeLowering.cpp` monolithic vs. split into `CompareLowering.cpp` / `CastLowering.cpp`).
- **`OperandClass` evolution.** Whether Patterns 7–9 reuse the existing Phase 2 classifier or require extension. Likely reuse with minor additions.
- **Unary increment/decrement representation in transpiled C.** `c.val++` vs `c.val += 1` vs `c.val = c.val + 1` — all semantically equivalent at LLVM IR after `-O1`; PLAN picks the canonical generated form.
- **Compound-assign representation in transpiled C.** `a.val += b.val` vs `a.val = a.val + b.val` — same.
- **LIT fixture auto-generation.** Whether ~300 LIT fixtures are hand-written (consistent with Phase 2's manual goldens) or auto-generated from the same opcode/width table. Recommendation: auto-generate; spot-check by hand.
- **Inverse Q+C variant naming order.** `cq_template_sub_i32_hl_inv` vs `cq_template_sub_i32_inv_hl`. PRD picks the former (modifier-then-variant ordering); PLAN confirms.

## References

- [`ROADMAP.md`](../../ROADMAP.md) §Phase 3 — phase definition (with the divergences called out in §"Roadmap discrepancy" above)
- [`docs/architecture.md`](../../docs/architecture.md) §5 (rewriter), §6 (intrinsic surface), §7 (IR pass), §12 (open design questions)
- [`docs/backend.md`](../../docs/backend.md) §5.6 (template selection), §5.7 (lowering map), §5.8 (inverse generation), §7 (template library)
- [`docs/quantum-classical-handling.md`](../../docs/quantum-classical-handling.md) — taint-propagation rationale
- [`phases/phase2/PRD.md`](../phase2/PRD.md) — predecessor; Phase 3 generalizes Phase 2's `+`-only slice across operators
- [`phases/phase1/PRD.md`](../phase1/PRD.md) — original vertical-slice contract

## Task tracking

Implementation work is tracked in **beads** (`bd`) per project convention. See [`CLAUDE.md`](../../CLAUDE.md).
