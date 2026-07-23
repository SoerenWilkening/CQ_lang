# PRD — `log10l.f80` census unblock: volatile scalar-local SSA promotion

**Status:** SCOPE — **AWAITING OWNER APPROVAL** (2026-07-23). Do **not** build until
approved (owner directive: "scope it first"). Follow-on to the **20xt** ld80 census
campaign; sibling of bd **`etiq`** (`foldVolatileConstAllocaLoads`, closed 2026-07-16)
and the **7.5** Shadow model. Bennett-parity consulted (owner standing instruction).

---

## 1. Goal

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

- **Inc 1 — `promoteVolatileScalarLocals` + re-probe.** Implement the promotion; re-probe
  `log10l.f80` → expect it to ADVANCE past the volatile-`z` (to the `ldexpl` secondary,
  or straight to COMPILES). Rule-12 red-green fixtures (positive: a volatile scalar
  accumulator promotes + lowers register-only; the §6 decline matrix). Rule-13 clearance.
- **Inc 2 — secondary `ldexpl` resolution + census +1.** Resolve the `ldexpl`
  closure/inline (small; `scalbnl` already COMPILES) if it blocks post-promotion; then
  `tests/e2e/slice_libm_real_log10l.c` + deterministic golden (real openlibm
  `ld80/e_log10l.c`, **mechanical edits only — the `volatile` STAYS in the vendored
  source**; the fold handles it, keeping the body faithful, exactly as `etiq` did for
  `cbrtl`). Census verified count +1. Rule-13 clearance.

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
