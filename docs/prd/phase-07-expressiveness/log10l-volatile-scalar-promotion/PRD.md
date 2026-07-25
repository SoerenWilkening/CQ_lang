# PRD — `log10l.f80` census unblock: volatile scalar-local SSA promotion

**Status:** **Inc 1 DONE + Rule-13 CLEARED (2026-07-24)** — owner-approved 2026-07-23.
Follow-on to the **20xt** ld80 census campaign; sibling of bd **`etiq`**
(`foldVolatileConstAllocaLoads`, closed 2026-07-16) and the **7.5** Shadow model.
Bennett-parity consulted (owner standing instruction).

> **Inc-1 outcome (empirical, Rule 11):** `promoteVolatileScalarLocals` shipped and
> ADVANCES `log10l.f80` from the volatile-`z` `kMsgStore` (e_log10l.c:156) to the
> `ldexpl` unknown-callee (e_log10l.c:177) — exactly as §7 predicted. 5-lens Rule-13
> clearance = **0 silent miscompiles / 0 blocking** (soundness backbone confirmed
> byte-for-byte against the non-`volatile` mem2reg twin). **NEW FINDING that revises
> Inc 2 (§7):** promoting `z` does NOT yield straight-line SSA — `z` is stored on
> BOTH arms of the tainted `if (frac < SQRTH)` argument-reduction branch (the real
> body's `%40`/`%41` are BOTH tainted: `icmp` on the frexpl exponent, `fcmp` on the
> frexpl fraction), so `PromoteMemToReg` mints an **x86_fp80 merge phi UNDER TAINTED
> CONTROL** (the "fp phi is an angle" family). The existing control machinery
> **loud-declines** that shape ("control flow under quantum control" — verified,
> byte-identical to its non-`volatile` twin).
>
> **SUPERSEDED by the bd `vyqi` investigation (2026-07-24 —
> `docs/prd/phase-07-expressiveness/3c6m.14-L6-control-predication/W5-fp-solephi-diamond.md`):**
> the fp-merge decline was NOT MUX-EXCH-class — it was the PredMux claim-witness
> fence leaving the flat SOLE-2-incoming-phi diamond unclaimed (the same body with
> ≥2 merge phis already flattened + lowered via the kjd1 fp controlled-copy merge).
> **W5** (a ~10-line witness widening, shipped + Rule-13-cleared under bd `vyqi`)
> now claims it; the distilled `z` shape COMPILES end-to-end
> (`lowering_volatile_scalar_promote_fpphi_tainted.ll`, converted from the old
> safety-net decline pin, + the `slice_predmux_fp_diamond_volatile` e2e golden).
> **But the REAL log10l z-merge never needed W5** — it is a 3-phi merge, claimed by
> the pre-existing multi-phi witness (verified on the dumped injected body: the
> post-PredMux dump shows the z selects minted). `log10l.f80` remains blocked, in
> order, on: (1) the `ldexpl` closure — a CENSUS-INFRA gap (openlibm ships `ldexpl`
> only as module-asm `.set ldexpl, scalbnl`, invisible to the defmap regex);
> (2) the `__isnanl` early-exit value region (s_isnan.c:63); (3) the sign/zero/inf
> early-exit chain feeding a 5-incoming fp return merge with a theta-passthrough
> incoming; (4) frexpl's tainted 3-way switch (non-empty default C5, memory-writing
> type-pun arms, nested br, undef incoming); (5) the outer diamond's arms each
> containing two rolled `__polevll`/`__p1evll` loops (the `8h7d` loops-under-control
> campaign) + the in-arm `ldexpl`. ⇒ **log10l's census +1 stays DEFERRED** (a
> multi-increment early-exit + switch + loops campaign — the broad control
> neighborhood, though not literally Payne–Hanek MUX-EXCH). Inc 1's promotion and
> the W5 widening both stand on their own (the volatile-single-accumulator idiom
> class is now covered end-to-end module-wide).

---

## 1. Goal

> **STATUS (2026-07-24, do not misread §1/§9 as delivered):** this section states the
> *original* goal. Inc 1's promotion **shipped** and advances `log10l.f80` one blocker
> (volatile-`z` `kMsgStore` → `ldexpl` unknown-callee), but the **census +1 itself is
> DEFERRED** — see the Inc-1 outcome note at the top of this file and the still-OPEN bd
> `zco4` tracker. `log10l.f80` still records `status=decline` in the committed census.

Move the **real-openlibm census number by +1**: `log10l.f80` **decline → COMPILES →
VERIFIED** (a committed real-openlibm golden per `libm-real-slice-recipe`), by handling
the OpenBSD/Moshier **"\*\*\*CAUTION\*\*\*" `volatile`-accumulator idiom**. Unlike the
`lgammal` hybrid (a disjoint authored-leaf artifact with **no** census delta), this is a
**genuine census cell move** — the compiler lowers openlibm's *real* `log10l` body.

## 2. Measured blocker (Rule 11 — probed 2026-07-23, O1 ship floor, real source injection)

`wprobe.probe('log10l','f80',[('q','f80')],0)` at `CENSUS_OPTLEVEL=O1`:

- **`log10l.f80` → decline**, `"cq taint escape: tainted value stored to memory"`, at
  **`e_log10l.c:156`** (`z = x - 0.5L`).
- **Root:** `volatile long double z;` (`e_log10l.c:125`) — the source's own
  *"\*\*\*CAUTION\*\*\* … may be horribly defeated by some compiler optimizers"*
  anti-reassociation guard. The `volatile` qualifier blocks clang `mem2reg`/SROA from
  promoting the scalar `z` to a register, leaving **~14 `store volatile x86_fp80
  <tainted>, ptr %z`** in the `-O1` IR (the `z = …` re-assignments + the `z += …`
  reconstruction accumulator at lines 156–202).
- **The IR (dumped, confirmed):** `%3 = alloca x86_fp80` — a **single scalar**,
  **non-escaping** (its only users are the volatile loads/stores + a `#dbg_declare`;
  **no** gep, call-arg, ptrtoint, phi, or select on the address).
- **Contrast (measured, not assumed):** `log10.f64` / `log10f.f32` **COMPILE** (their
  fdlibm bodies have no volatile accumulator); `cbrtl.f80` **COMPILES** (bd `etiq`
  shipped the volatile-**constant** fold). The `frexpl(x,&e)` by-ref store is **not**
  the first blocker — it lowers before `z`.
- **Secondary blocker (behind `z`):** `ldexpl(x,±1)` survives as `"tainted value
  consumed by an unknown callee"` (`scalbnl.f80` COMPILES; `ldexpl` needs closure/inline
  resolution). Addressed in Inc 2.

## 3. Root cause (precise)

`declineTaintEscapes` (`TaintPropagation.cpp:522`) → `qramCarveVerdict`
(`QramLowering.cpp:820`) returns **`NotQram`** for the `z` store because the store's
**pointer is classical** (`if (!taint.Tainted.count(PtrOp)) return NotQram`) — the `z`
alloca is a classical stack address; only the *value* stored is tainted. That verdict is
**correct**: the QRAM/Shadow model (`matchQramAccess`) targets a **tainted-index array**
(a quantum-indexed memory access), **not** a classical-address scalar local. A
non-`volatile` `z` would be `mem2reg`-promoted to SSA (no store, no escape) and lower via
ordinary SSA taint flow; **only the `volatile` qualifier forces it into memory** and
into the generic `kMsgStore` decline.

⇒ The fix is **not** a Shadow-model extension. It is a **targeted SSA promotion** of the
volatile scalar local — precisely what `mem2reg` would do if the `volatile` were absent.

## 4. Proposed fix — `promoteVolatileScalarLocals` (mem2reg sibling of `foldVolatileConstAllocaLoads`)

Run **before** `declineTaintEscapes`, alongside the `etiq` fold in the pass order. For
each `AllocaInst A`:

**ACCEPT shape — ALL gates required (Prime Directive; over-decline everything off-shape):**
1. **Single scalar.** `A->getAllocatedType()` is a scalar the pass lowers (fp/int of a
   supported width). An **array/struct** alloca is the Shadow/MUX-EXCH domain — **not**
   this fix.
2. **Address never escapes.** Every user of `A` is a direct `load`/`store` **of `A`**
   (matching type) or a `llvm.dbg.*` / `llvm.lifetime.*` intrinsic. **No** gep, call-arg,
   ptrtoint, addrspacecast, phi, or select on the address (mirror `isAllocaPromotable`
   + the `etiq` non-escape walk).
3. **≥1 access is `volatile`.** Otherwise `mem2reg` already promoted it — nothing to do.
4. **Exact-type accesses.** Every store value / load result type == the alloca type
   (no type-punning — a bit-punned union is `promoteFp80Union`'s domain, left untouched
   or declined).

**ACTION:** clear `isVolatile` on all of `A`'s loads/stores, then run LLVM
`PromoteMemToReg({A}, DT)` (`A` is now `isAllocaPromotable`). The scalar becomes SSA; the
tainted stores vanish; ordinary SSA taint flow lowers the remainder register-only.

**SOUNDNESS (the deliberate-volatile-fold choice — the Rule-13 note, mirroring `etiq`):**
`volatile` on a **private, non-escaping stack scalar** has **no external observer**; its
only effect is to defeat classical FP **reassociation** (that is exactly what the
"\*\*\*CAUTION\*\*\*" comment asks for). The CQ taint lowering lowers **each op verbatim
in program order and never reassociates**, so the "\*\*\*CAUTION\*\*\*" invariant (the
evaluation order of the `log10` reconstruction) is **preserved** by promotion. Folding
the volatile is the same deliberate, idiom-invited, Rule-13-cleared choice `etiq`
established — **generalized** here from a single-store *constant* to a multi-store
*computed accumulator*, which standard SSA reaching-definition promotion
(`PromoteMemToReg`) handles exactly.

## 5. Bennett parity (owner standing instruction — always consult Bennett.jl)

Bennett.jl lowers local mutable state (accumulators) via its **memory strategies
(Shadow / persistent)** — it ingests the *same* clang LLVM IR and lowers `store`/`load`
to reversible ops **without special-casing `volatile`** (`docs/bennett-jl-comparison.md`
§"The full Osborne stack", the memory-strategies line; `src/persistent/`). For a
**non-escaping scalar**, CQ's cleaner route is SSA promotion (what `mem2reg` would do),
reaching the **same register-only reversible flow** Bennett obtains by lowering the
memory op — no Shadow slot needed. **CAVEAT:** the live `/private/tmp/Bennett.jl`
checkout is **WIPED** (reboot-transient, like the openlibm corpus — empty `.git`, no
objects). This parity is grounded in the **in-repo** `bennett-jl-comparison.md`, not the
source `src/persistent`/`src/softfloat`. **Action:** owner to provide the Bennett.jl
remote so it can be re-cloned and the `persistent`/`softfloat` accumulator/pebbling
handling consulted directly **before the Rule-13 clearance**.

## 6. Scope boundary — what STAYS declined (Prime Directive)

Each ships a negative lit fixture mirroring the exact diagnostic (Rule 12):
- **Volatile ARRAY alloca / tainted-index access** → declined (Shadow/MUX-EXCH domain).
- **Address-escaping volatile alloca** (gep / call-arg / ptrtoint / phi / select on the
  address) → declined.
- **Type-punned / mixed-width access** (union bit-punning) → declined
  (`promoteFp80Union`'s domain).
- **Volatile GLOBAL or heap-pointer access** → declined.

## 7. Increment plan

- **Inc 1 — `promoteVolatileScalarLocals` + re-probe. ✅ DONE + Rule-13 CLEARED
  (2026-07-24).** Implemented the promotion (`QramLowering.cpp`; gates: single int/fp
  scalar · non-escaping exact-type direct load/store + lifetime only · ≥1 volatile ·
  undef-safety `everyLoadIsStoreDefined` · not `callsFunctionThatReturnsTwice()` ·
  taint-exclusion; ACCEPT-ONLY; re-propagate fixpoint in both pipeline entry points).
  Re-probe: `log10l.f80` ADVANCES from `kMsgStore` (line 156) → `ldexpl` unknown-callee
  (line 177), as predicted. Rule-12 red-green: 1 canonical positive + 2 converted etiq
  pins (now correctly compiling via promotion) + 6 decline pins (array/escape/typepun/
  global/setjmp/undef) + 1 safety-net pin (fp-phi-under-tainted-control promotes-then-
  loud-declines). Full suite green (190/190 ctest, 878/878 ir-pass-lit). 5-lens Rule-13
  clearance: 0 blocking, 0 silent miscompiles.
- **Inc 2 — RE-SCOPED (owner decision needed; see the Inc-1 outcome note at top).** The
  original "small `ldexpl` closure fix → census +1" is **superseded** by the Inc-1
  finding: post-promotion, `log10l.f80` needs BOTH (a) the `ldexpl` closure AND (b)
  **fp80-merge-under-tainted-control** lowering (the exposed `z`-phi across the tainted
  argument-reduction branch loud-declines today). (b) is MUX-EXCH-class control work,
  coupling `log10l` to the `sinl`/`cosl`/`tanl` set — so the "clean, orthogonal +1"
  premise no longer holds. Do NOT proceed to the golden/census until the owner decides
  whether to (i) invest in the fp80-merge control work here, or (ii) defer `log10l`'s
  census +1 to the broader control campaign. The Inc-1 promotion stands on its own
  (unblocks the volatile-scalar idiom class module-wide, sound + Rule-13-cleared).

## 8. Verification (the three gates)

- **Rule 12:** red-green lit fixtures — positive (`lowering_volatile_scalar_promote.ll`)
  + the §6 decline matrix, each mirroring its diagnostic character-for-character.
- **Rule 2:** `slice_libm_real_log10l.c` + deterministic e2e golden (real body; the
  vendored `volatile` preserved).
- **Rule 13:** independent adversarial clearance — the deliberate-volatile-fold soundness
  (no reassociation, non-escape proof), the promotion gates (no silent promotion of an
  escaping/observable volatile), and census-honesty (a *real* cell move, quotable with
  the real-openlibm goldens — unlike the `lgammal` hybrid).

## 9. Census impact

> **NOT YET DELIVERED (2026-07-24):** the **+1 is DEFERRED**, not realized — Inc 1
> advanced `log10l.f80` one blocker but did not compile it (it now declines at the
> `ldexpl` unknown-callee; the committed census still records `status=decline`). The
> paragraph below is the *target*. What Inc 1 DID deliver as a standalone, verified win
> is the **volatile-single-accumulator idiom class** (`promoteVolatileScalarLocals`),
> which the lit accepts + the `slice_predmux_fp_diamond_volatile` e2e golden pin — a
> real capability, NOT a census-cell increment. Never quote `log10l.f80` as verified.

**+1** real-openlibm VERIFIED (`log10l.f80`) — a genuine census move (quotable alongside
the real goldens). Any other libm body using the same "\*\*\*CAUTION\*\*\*"
volatile-accumulator idiom becomes a follow-on probe. **Orthogonal** to the Payne–Hanek
5-cell set (`sinl`/`cosl`/`tanl`/`lgammal`/`tgammal`), which remains the separate large
MUX-EXCH investment.

## 10. Risks

- A volatile access I fail to prove non-escaping ⇒ **MUST decline** (Prime Directive);
  the gates mirror `isAllocaPromotable` + `etiq`'s proven non-escape walk.
- Folding volatile is a deliberate semantic choice — sound **only** for private,
  non-escaping scalars whose sole purpose is anti-reassociation; **never** for an
  escaping/observable volatile (I/O, MMIO — which never appears in a pure libm body).
- `PromoteMemToReg` needs a `DominatorTree` on a still-valid function — run before any
  CFG mutation (same slot as the `etiq` fold).
