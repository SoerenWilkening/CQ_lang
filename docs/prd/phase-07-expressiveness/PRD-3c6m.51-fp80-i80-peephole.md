# PRD — 3c6m.51: x86_fp80 libm via **i80 width + union-promotion peephole**

**Status:** READY to implement (scoping verified + owner-approved 2026-07-15). **Rule-13 HIGH.**
**Approach:** the MINIMAL path — add i80 as an intermediate width + a small promotion peephole. This
SUPERSEDES the rejected "de-union pre-pass / new `@cq_f80_word_*` intrinsics" rework (that PRD was reverted).
**Ground truth:** Bennett.jl (`/tmp/Bennett.jl`; `docs/design/bennett-parity/PARITY_MAP.md`).
**Memory of record:** `bd recall fp80-ld80-i80-minimal-3c6m51`.
**First cell:** `fdiml.f80`.

---

## 1. Problem (verified)

The 37 long-double (ld80) libm cells decline on `kMsgStore` — "tainted value stored to memory" — on the
`union IEEEl2bits` idiom: `store x86_fp80 %seed, ptr %u` then bit-inspection via `load i64` at const byte
offsets. This is NOT the 38t2 tainted-index array cell (orthogonal), NOT a copy-fence widen (the f80 ABI
already exists), and NOT a de-union rework (rejected). The real gap has two parts, both proven empirically:

1. **CQ lacks i80.** `abiWidthFromType` knows `{i1,i8,i16,i32,i64,i128,f16,f32,f64,f80}` but not `i80`.
2. **The x86_fp80 union stays in memory at CQ's -O1 floor.** LLVM SROA promotes the *within-value*
   accesses (offset-0 mantissa) to `bitcast x86_fp80 to i80` + `and i80` at -O2/-O3 — but it leaves the
   **offset-8 `load i64`** in memory at EVERY opt level (it straddles the undefined padding bytes 10–15;
   LLVM correctly refuses to invent a value). Proven: `load i16@8` (within value) promotes at -O3;
   `load i64@8` (straddles padding) does not, at -O2 or -O3. So no opt floor removes this — CQ must.

**Decisive test:** manually rewriting the fdiml union to i80 register form (`bitcast x86_fp80 to i80`,
`lshr`/`trunc` for offset-8, `and i80`, `icmp i80`) makes `kMsgStore` VANISH — the only remaining issue is
the ordinary control axis (PredMux), which already lowers the register-resident f64/f32 siblings
(`fdim.f64`, `logb.f64`, `scalbn.f64` all COMPILE at -O1).

## 2. Bennett.jl alignment

Bennett (a) runs `sroa/mem2reg/simplifycfg/instcombine` preprocessing (`src/memssa.jl`) to promote the
union, (b) treats `bitcast` (ANY width incl. i80) as a zero-gate **identity relabel** at extraction
(`src/extract/instructions.jl:259`, next to `addrspacecast`), (c) supports **arbitrary bit widths**. Its
memory model is strictly homogeneous (`src/lowering/memory.jl` rejects width-mismatched load/store), so the
type-pun is resolved to registers upstream. CQ's peephole does that upstream promotion itself (LLVM won't
finish it for x86_fp80), and the i80 ops then lower as reversible relabels/permutations — the same model.

## 3. The plan — two pieces

### Piece A — add `i80` as an intermediate wide-int width (mirror i128 / bd n0ui)

i80 is intermediate-only (produces the isnan FLAG, never a control-merged data value), so it keeps the
`>64` copy fence. Edit sites (each mirrors the existing `i128` line):

- `ir-pass/src/OpcodeSupport.cpp`
  - width-string→bits helper (`:30`, `if (w == "i128") return 128;`) → add `i80 → 80`.
  - `abiWidthFromType` (Type→width string) → map `IntegerType(80)` → `"i80"`.
- `ir-pass/src/WidthDispatch.cpp`
  - `typeForAbiWidth` (`:57`, `if (W == "i128") return Int128;`) → add `i80 → Type::getIntNTy(Ctx, 80)`.
  - NO theta/measure suffix row needed (intermediate-only, like i128 — see the `:43` suffix table comment).
  - The `>64` copy fence (`:149`) stays — do NOT admit i80 to `copyFn`.
- `tools/opcode_table.yaml` (Rule 15 — edit YAML, regenerate; `gen_templates.py --check` gates drift)
  - widths block: `i80: { bits: 80, c_type: "__int128", domain: "int" }` (the immediate rides `__int128`;
    i80 isn't a C type — **verify the trace prints the literal faithfully**, esp. `and i80 %h, 0x7fff…`).
  - add `i80` to the `widths:` list of exactly the ops fdiml needs: `and`, `icmp` (eq/ult…), `lshr`, `shl`,
    `trunc` (the `i80→i64` cast pair), and a `bitcast` reinterpret pair `f80 ↔ i80`. (Do NOT add i80 to
    cross-domain int↔fp casts — mirror the i128 exclusion.)
  - regenerate: `python3 tools/gen_templates.py --output-dir runtime` then `--check`.

### Piece B — the union-promotion peephole (`promoteFp80Union`)

A small structural rewrite (new fn in TaintPropagation.cpp or a tiny new file, style of `foldIdentityBitcasts`
/ `foldVolatileConstGlobalLoads`). **Slot:** early rewrite zone in `CQLoweringPass::run` — after
`foldVolatileConstGlobalLoads` (`:110`) and BEFORE `flattenPredMuxRegions` (`:127`), then re-`propagate`
(PredMux won't claim a region containing loads/stores, so the union must be gone first).

Recognize: a single-cell `alloca {x86_fp80}` (or bare `x86_fp80`, align 16) that is **stored-once** with an
`x86_fp80` value (tainted OR classical) and whose every other use is a `load iN` at a **constant** byte
offset (via `getelementptr i8, %u, C`) or a **dead** store-back (masked write never reloaded), plus
lifetime markers. Decline (leave untouched / fall to existing declines) on anything off-pattern.

Rewrite each `load iN, ptr (gep i8 %u, off)`:
- `%bc = bitcast x86_fp80 %v to i80`  (once per cell)
- `%sh = lshr i80 %bc, off*8` (omit if off==0)
- `%tr = trunc i80 %sh to iN`  → RAUW the load with `%tr`.
- For the **padding-straddle** case (`iN` reads bytes ≥10): trunc to the meaningful width then `zext` to iN,
  i.e. **padding modeled as 0**. This is the ONLY thing LLVM won't do; it is the sound completion (§4).

Erase the store, dead store-backs, dead geps, and the alloca. Emits **standard LLVM ops** — identical to
LLVM's own SROA output for the within-value loads (proven), so it is not a bespoke lowering. **Level-agnostic:**
handles both loads at -O1, just the residual offset-8 load at -O2 — one peephole, both paths free.

## 4. Correctness fences (Rule-13 HIGH — what clearance MUST verify)

1. **Padding-as-0** is sound ONLY because the source masks the padding bits (fdiml: `and i64 %hi, 32767` →
   only bits 0–14 survive). The peephole MUST prove every offset-8 word's observable users mask bits ≥16;
   an **unmasked padding observation → loud decline** (this is the central silent-miscompile fence).
2. **Angle fence unchanged.** These are fp-DATA bit-pattern relabels, never rotation angles. An f80 used as a
   rotation arg-1 angle must still decline (`declineTaintedAngle`); the peephole only fires on the
   bit-pattern-memory idiom, so it never launders an angle.
3. **i80 immediate representation** in the trace runtime (`__int128` c_type) — the golden must show the
   literal printed faithfully.
4. **Padding non-bijectivity under uncompute** — the `f80→i80` extract loses the padding, so the extract's
   `_unc`/`_inv` adjoint is not a clean inverse. **VERIFIED 2026-07-15 (Inc-2 feasibility): this does NOT bite
   the RMW cells either, for the same reason as `fdiml`.** Every census slice is `cq_measure(fn(q))`, and
   `FreePoint.cpp:212` classifies a measured terminal as `FreePointKind::Measured`, so `Uncomputation` skips it
   — **no `_unc`/`cqrt_free` ever fires** on the promoted RMW (the reload is the sole terminal, and it is
   measured). The scary padding-non-bijectivity is a NON-ISSUE for the measured cells (the fp80 padding is
   dropped exactly ONCE, at the forward `bitcast f80→i80`, and never reaches an observable). If a future cell
   RETURNED/left-dead the reload (uncompute WOULD fire), the i80 ops' void `_unc` twins ARE genuine adjoints
   (Bennett out-of-place recompute-and-XOR — `EmitInverse.cpp:68`), reversible as long as the sources stay live;
   the `%bc` fan-out (read by both the extraction and the field-insert) is handled by the DAG `Seen`/visited
   dedup (once-per-gate), not a Rule-8 bail. Still route the real cells through an e2e golden in Inc 3.
5. **Passthrough:** the peephole fires only on theta-reachable f80 union cells (a classical-only module stays
   byte-identical); a classical union with a constant value folds to dead code after promotion.

## 5. Increments

- **Inc 1 — `fdiml.f80`** (flat, read-only, measured; control already lowers per `fdim.f64`): Piece A + the
  read-only peephole. Handles the classical 2nd union too (fdiml has `isnan(y)` on a const `0.5L`; promote it
  → `bitcast`/`and` fold `isnan(0.5)=false` → dead branch). Red-green: minimal positive `.ll` fixture (single
  tainted fp80 union) + the §4 decline matrix (unmasked-padding, angle, off-pattern) + e2e golden
  `slice_libm_real_fdiml`. Independent Rule-13 clearance. **DONE 2026-07-15.**

- **Inc 2 RE-SCOPED (2026-07-15) — the ticket model vs. the real -O1 IR.** Rule 11 (dump the real -O1 IR
  before implementing) uncovered a **model↔cell inconsistency**: the ticket models `scalbnl` as a SINGLE-BLOCK
  RMW (`u.e=x; u.bits.exp=k; return u.e`), but the real clang -O1 IR is **MULTI-BLOCK** — one union alloca
  threaded across **5 basic blocks** (an fp80 re-store `u.e*=2^128` in a non-entry block + **two** separate
  offset-8 field-insert PACK arms, joined by a merge phi). `SROA`/`-O2` both leave it in memory (the offset-8
  word straddles the padding). A structural census of all 40 ld80 cells found **ZERO** single-block fp80-seed
  RMW cells (every ld80 fn guards on nan/inf/zero, so the pack always lands in a branch arm). So the
  single-block peephole cannot reach `scalbnl`, and no alternate real single-block cell exists. The RMW work
  therefore splits (owner-approved 2026-07-15):

  - **Inc 2 — i80 field-insert (WRITE) width surface** (groundwork; **DONE 2026-07-15**). The reusable
    prerequisite: add the three missing i80 write-path ops the RMW pack emits — `zext {i1..i64}→i80` (widen the
    store-back word), `shl i80` (position), `or i80` (combine) — **each with its `_unc` twin** (never fwd-only:
    `isInverseEmittable` returns true for every `cq_template_`, so a fwd-only op would mint a dangling `_unc`
    extern = Stage-3 link fail). Lift exactly two OpcodeSupport gates (`ArithLowering` i80 allow-set → and/lshr/
    or/shl; `castInScope` → `zext→i80` DEST, keeping `sext→i80` + cross-domain excluded). **No union accept-set
    change this increment** (the RMW still declines at `kMsgStore`), so no new silent-miscompile surface. +40
    gen symbols → 2479. Red-green: positive `lowering_fp80_i80_field_insert.ll` (the hand-promoted RMW form,
    pre-validating the Inc-3 template stream) + the `lowering_reject_i80_{add,sext,sitofp}.ll` invariants
    (add/sub/mul/xor/ashr/div/rem, sext, cross-domain still decline char-for-char).

  - **Inc 3 — the multi-block union promotion** (the *proper implementation*; landed `scalbnl`/`ldexpl`/
    `scalblnl` real goldens — **DONE 2026-07-16, bd `3vdz`**; `cbrtl`'s union axis CLEARS but the cell
    stays declined on the ORTHOGONAL volatile-const-LOCAL rounding idiom — the alloca sibling of the
    3c6m.14 volatile-const-global fold, filed as a follow-up). Shipped exactly as scoped below, plus:
    the §4.1 fence is the forward per-bit padding-taint walk (`PaddingWalk` in Fp80Union.cpp — content
    landings, carry-upward, poison-flag guard with the zero-monotone or-disjoint/trunc-nuw/zext-nneg
    acceptance proofs; every `exact` shift/div on a diverged operand DECLINES — over-safe by choice);
    DEAD field-inserts are elided (Inc-1 parity — fdiml's golden stays
    byte-identical, and every shipped i80 trace literal stays inside the 64-bit faithful print range of
    the __int128 trace label); a dominance-CSE keeps one `bitcast f80->i80` relabel per SSA value;
    PredMux's E4 gained the narrow i80 clauses (castInScope / i80BinaryInScope mirrors — the canonical
    insert packs live inside claimed arms); and the i80-merge fence is a post-promotion `phi i80` scan
    (`kMsgFp80I80Merge`). Fixtures: `lowering_fp80_union_{rmw,multiblock,crossunion,padding_flow,
    dead_insert}.ll` + `lowering_reject_fp80_union_{padding_carry,padding_insert,i80_merge,loop,
    unseeded_read,fpstore_off8}.ll` + `control_predmux_reject_i80_arm_op.ll`.

    **Rule-13 clearance of record (2026-07-16, two rounds):** round 1 (7 lenses + 3-vote adversarial
    refutation panels + completeness critic, 26 agents) CONFIRMED one verify-clean silent miscompile —
    the dead-insert elision used intra-block lexical `comesBefore`, which erased a LIVE loop-carried
    field-insert store-back (a loop-body load lexically before the store reads the previous iteration's
    store via the back-edge; reproduced end-to-end at exit 0). FIX: the ACYCLIC+REACHABLE access gate
    (`collectCycleBlocks` scc twin + `DT.isReachableFromEntry`; loop unions are Phase-7.3 scope and fall
    to the loud kMsgStore) plus `isPotentiallyReachable`-based deadness (conservative-TRUE keeps stores
    live). Round 2 (3 independent reviewers: re-attack incl. irreducible/self-loop/unreachable-cycle
    probes + the original repro, regression envelope with golden re-derivation + mutation-tested decline
    reasons, fresh code read) — CLEAN, 0 critical findings. Known accepted limitations (documented, not
    defects): >64-bit i80 literals and sub-1e-6 fp literals print truncated in the trace label (the
    deterministic gate-sequence contract; no shipped golden affected); duplicate decline diagnostics can
    repeat across fixpoint turns in multi-function modules (opt exits non-zero on the first). Follow-ups:
    bd `etiq` (volatile-const-LOCAL fold — the last cbrtl blocker; **DONE 2026-07-16**, below), bd `szpr`
    (trace-verify the i80 field-insert `_unc` adjoints via a specialized-callee slice + the critic's minor
    hardening notes).

  - **Follow-on — the volatile-const-LOCAL fold (bd `etiq`, DONE 2026-07-16): lands `cbrtl.f80`.**
    `foldVolatileConstAllocaLoads` (QramLowering.cpp) — the alloca sibling of the 3c6m.14
    volatile-const-global fold, run immediately after it in BOTH pipeline entry points (pre-Fp80Union,
    pre-PredMux). The openlibm rounding idiom (`volatile double vd2 = 0x1.0p32; volatile double vd1 =
    0x1.0p-31;` in s_cbrtl.c) survives -O1 as a volatile store/load pair on a classical entry-block
    alloca (mem2reg skips volatile) and blocked the tainted region at PredMux E4. The fold's proof:
    static entry-block alloca whose ONLY direct users are exactly one non-atomic store of a `Constant`
    (pointer-operand A), non-atomic exact-type loads each DOMINATED by that store, and lifetime markers —
    ≥1 access volatile — then every load observes exactly the stored constant; loads RAUW to the
    constant and the loads/store/markers/alloca are ERASED (unlike the global fold, a surviving volatile
    store would still block E4). NARROWER than the global fold by design: direct users only (any gep —
    even offset 0 — forfeits), exact-type only, per-load dominance (an alloca has no initializer; an
    undominated load reads uninitialized memory). The single-`Constant`-store gate structurally excludes
    tainted / shadow-QRAM / by-ref / union allocas (a tainted value is never a `Constant`); `nextafterl`'s
    `t = x*x` volatile anti-fold idiom stays declined by the same gate (runtime store value). Red-green:
    `lowering_volatile_local_fold.ll` + 7 `lowering_reject_volatile_local_*` decline probes
    (two-stores / nonconst-store / escape / load-before-store / atomic / typepun / gep-user), all on the
    claimable nested-W1 skeleton so an over-firing fold makes the negatives FAIL (a single fp diamond is
    never PredMux-claimable — hand-written probe shapes on it would be vacuous; at real -O1 that shape
    arrives as a `select`). e2e: `slice_libm_real_cbrtl` (both unions promote, the two tainted switches
    route, the vd2/vd1 constants ride as classical fp literals; 539-line deterministic golden).
    **Rule-13 clearance (2026-07-16, 2 independent reviewers): CLEAR, 0 blocking findings** —
    adversarial counterexample lens (14 hand-built probes: loop-backedge/conditional-store dominance,
    unreachable-block store and load, unordered-atomic, cascaded allocas both orders, ConstantExpr store
    value, fp80 padding, dbg.declare metadata user, oversized store; every attack either declined or was
    proven value-identical; end-to-end classical-value diff of the volatile-drop vs plain clang -O1:
    byte-identical) + pipeline-interaction lens (twin-parity, TaintSet dangling-pointer audit over ALL
    members at fold time, subsystem-theft matrix — shadow-QRAM/by-ref/fp80-union each excluded
    STRUCTURALLY, fixture-discrimination audit, golden determinism re-derivation). Both optional
    hardenings applied post-review: the in-slot store-size gate (posture symmetry with the global fold's
    in-bounds proof — never refine UB IR) and the documented-convention comments (unreachable-use
    dominance; single-pass cascade order). Accepted-benign notes: a crafted
    `store C; lifetime.end; lifetime.start; load` folds to `C` (legal undef/UB refinement; clang never
    emits it single-store); a dbg.declare on a folded alloca degrades to `ptr undef` (the standard
    stack-slot-elimination behavior); and the fold is module-wide past the passthrough early-out
    (consistent with the global fold; fenv/MMIO out of scope project-wide).

    Original scope (implemented): **`canonicalize + PromoteMemToReg`** (Bennett's `sroa/mem2reg`-preprocess,
    §2): rewrite each union access to a full-width `x86_fp80` load/store on a fresh promotable alloca (the i80
    extract/field-insert kept LOCAL around each access), delete the original union, then call LLVM's own
    battle-tested `PromoteMemToReg` to build the phis — **NOT** a hand-rolled SSA construction. The cross-arm
    merge is already `phi x86_fp80` at -O1/-O2 (evidence: `scalbn.f64` — the same algorithm — already compiles
    at -O1 with fp64/i64 phis under the same tainted control), so the i80 stays intra-arm (intermediate-only,
    invariant preserved). **Safety fence:** if canonicalization would ever require an i80 value to cross a
    tainted control merge (an i80 phi), DECLINE loudly (never mux an i80). Plus the analyze() broadening
    (recognize the `load x86_fp80` reload PACK + a live field-insert store-back) and the §4.1 fence-widening
    (§4.4 below). Deep Rule-13 clearance.

- **Later:** `lroundl`/`llroundl` (integer-SEEDED reload packs — a DISTINCT shape from the fp80-seed idiom),
  `nextafterl` (`volatile` store — hard decline until volatile handling), the loop cells (`logbl` etc. — 19 of
  the 40 ld80 cells are loop-gated, on Phase 7.3 / `799w`).

## 6. Done criteria (Inc 1)

`fdiml.f80` compiles + LINKS + runs a real trace (`cqrt_ry_f80` … `cqrt_measure_f80` with the i80 template
stream); i80 templates lower; the padding fence + §4 decline probes green (message char-for-char, Rule 12);
`ctest` green; `gen_templates.py --check` clean; ≥1 e2e golden; **independent Rule-13 clearance**.

## 7. Repro / evidence (regenerate if `/tmp` was cleared)

- Corpus: `/tmp/openlibm` (openlibm source) + `/tmp/bc` (241 `.bc` files). Bennett: `git clone --depth 1
  https://github.com/tobiasosborne/Bennett.jl /tmp/Bennett.jl`.
- Probe machinery: `tools/library_coverage/full_surface/wprobe.py` (`export BC=/tmp/bc OPENLIBM=/tmp/openlibm`):
  `python3 -c "import wprobe as W; d=W.build_defmap(); print(W.probe('fdiml','f80',[('q','f80'),('c:long double:0.5L',)],0,d)[:2])"`
- LLVM at `/usr/local/opt/llvm@19/bin` (not on PATH). Dump fdiml -O1 IR: compile the probe `-O1 -emit-llvm`,
  closure-link the openlibm body, `opt -passes='internalize,always-inline,globaldce,default<O1>'`.
- Decisive proofs (re-runnable): `opt -passes='default<O2>'` promotes offset-0→i80 but leaves `load i64@8` in
  memory; `load i16@8` promotes, `load i64@8` does not (padding). Manually-i80'd fdiml → `kMsgStore` gone,
  only the control axis remains.

## 8. Do NOT

- Do NOT re-add the de-union pre-pass or the `@cq_f80_word_*` / `cqrt_f80_word_*` intrinsics (rejected — the
  peephole emits STANDARD `bitcast`/`trunc`/`lshr`, no new ABI beyond the i80 width templates).
- Do NOT admit i80 to `copyFn` (keep the `>64` fence) or to cross-domain int↔fp casts (mirror i128).
- Do NOT migrate the pass to an -O2 floor for this (a separate, large Rule-9 re-validation; the peephole
  handles the padding load that -O2 can't anyway).
