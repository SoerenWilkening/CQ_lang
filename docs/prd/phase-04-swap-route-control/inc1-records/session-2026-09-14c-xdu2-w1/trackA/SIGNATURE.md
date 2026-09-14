# Track A — the PUBLISHED SIGNATURE (bd `xdu2` / L-1a, clauses C1–C4, C2′, C6)

Published 2026-09-14, hour 1, against BRIEF_A §1's strawman. Track B codes against **this** file.
Header: `ir-pass/include/QramLowering.h` (appended beside `qramCarveVerdict`).
TU: `ir-pass/src/QramLowering.cpp` (so the classifier can call the file-local `walkPtrOrigin`,
`isDirectOriginPtr`, `matchAddressGep` without exporting them — SCOPE_L1a §0 H4).

```cpp
// ── bd xdu2 / L-1a: the rail-bank CARVE CLASSIFIER ─────────────────────────────
enum class RailBankCarve {
  NotBank,          // not a rail-bank cell write — fall through to the existing owners
  Bank,             // C1–C4, C2', C6 all hold. ⚠ STILL FALLS THROUGH TO kMsgStore (staging)
  RejectShape,      // C1  — provenance / escape / mixed access / non-zero initializer
  RejectIndex,      // C2' — index is not an injective {0,+,1} over the enclosing loop
  RejectWidth,      // C3  — cell width has no reversible copy
  RejectAlias,      // C4  — the cell address has aliasing fan-out
  RejectTotality,   // C6  — N != the proven trip count, or a cell no iteration writes
};

// The resolved bank on a `Bank` verdict — so no consumer re-derives it (Rule 14).
struct RailBankShape {
  llvm::AllocaInst *Alloca = nullptr;  // the bank object
  llvm::Loop *L = nullptr;             // the loop whose {0,+,1} index walks the cells
  llvm::Value *RawIndex = nullptr;     // the store gep's trailing (classical) index
  llvm::Type *CellTy = nullptr;        // the cell scalar type
  llvm::StringRef ElemAbi;             // "i1"/"i8"/"i16"/"i32"/"i64"
  uint64_t Count = 0;                  // N
  uint64_t Trips = 0;                  // the proven constant trip count (== Count on Bank)
};

RailBankCarve railBankCarveVerdict(const llvm::StoreInst *SI, const TaintSet &taint,
                                   llvm::DominatorTree &DT, llvm::LoopInfo &LI,
                                   llvm::ScalarEvolution &SE, const char *&outMsg,
                                   RailBankShape *outShape = nullptr);
```

## The five deviations from the strawman, each with its reason

**(1) `RailBankShape *outShape = nullptr` ADDED.** Track B's promoter must know *which* alloca,
*which* loop and *which* index it is promoting. Handing it back from the one predicate that proved
it is the Rule-14 discipline (`ask by CALLING the one owner, never by re-deriving its answer`);
without it Track B would re-spell the origin walk, which is the drbq Inc-3 (b′) defect verbatim.

**(2) `isRailBankAlloca` / `railStoredToRailBank` are NOT shipped this session.** They are the
FREEZE's membership record (SCOPE_L1a §4.3), and the freeze — the D1/D6 doors — is in the deferred
half together with the taint rule and the type rewrite. Shipped now they would have **no caller**,
which is Rule 12 hygiene defect (c) in its purest form: *"a fixture that goes green because its
subject no longer exists pins nothing"*, here a subject that does not exist **yet**. The design is
unchanged and recorded in `IMPL_A.md` §7: `!cq.railbank` metadata on the `AllocaInst`, minted by the
**type rewriter** (the only stage that both proves the bank and mutates it), read by a
demand-driven `railStoredToRailBank(H)` that CALLS `walkPtrOrigin`. Nothing about that design
depends on the metadata existing today.

**(3) C4 ADMITS a cell address used by BOTH a load and the store** (the read-modify-write gep), where
`matchQramAccess`'s `GEP->hasOneUse()` (`QramLowering.cpp:467-469`) would reject it. **This is the
deviation that makes ONE predicate serve both Track B and the carve**, and without it the two tracks
would need two spellings:
* Track B's promoter runs in the `-O1`-repair normaliser fixpoint, so it sees the **RAW** shape where
  the cell is read and written through the same (or an equal-SCEV) address — `a_loop_n3.c` block 8:
  `%9 = gep …; %10 = load i8, ptr %9; … store i8 %13, ptr %9`;
* the carve runs after that fixpoint, so on the merged tree it sees the **PROMOTED** shape where the
  gep has exactly one use (`L1_promoted_store.c` at `-O1`, block 10: `%14 = gep …; store i8 %15, ptr %14`).
`hasOneUse` answers the **tainted-index** aliasing question (two superposed addresses the tape cannot
keep coherent). A rail bank's index is **classical**, so one address is one definite cell and a
read-modify-write of it is the customer, not a hazard. What C4 refuses instead is stated positively:
every user of every access gep must be a *simple load or store of the cell type through that gep*,
and the classified store must be the **only store anywhere in the bank**.

**(4) `matchQramAccess` is NOT called.** BRIEF_A §1.2 C4 instructs "CALL `matchQramAccess`". Measured,
it cannot be called for a bank store without becoming two functions in one: three of its gates reject
**every** rail-bank store outright (`LInfo.getLoopFor(MemOp->getParent())` — a bank store is always in
a loop; `instUnderTaintedControl` — the raw arm store; `requireTaintedIndex`), and a fourth
(`hasOneUse`) answers a different question, see (3). The Rule-14 content the instruction is protecting
— *"do not re-spell the provenance walk"* — **is** honoured: `walkPtrOrigin`, `isDirectOriginPtr` and
`matchAddressGep` are all CALLED. The four conjuncts genuinely replicated (the pun fence, the
origin-array/cell-type agreement, `N != 0`, scalar cell) are cross-referenced in **both** directions
with a retirement trigger. Full argument + the exact line pairs: `IMPL_A.md` §4.

**(5) `const llvm::StoreInst *SI`, and the verdict is a PURE PREDICATE.** No mutation, no metadata
mint, no taint growth — which is what makes the L1 round-2 answer trivial (`IMPL_A.md` §5).

## What a `Bank` verdict does this session — READ BRIEF_A §0

It **falls through to the existing generic `kMsgStore` decline**, exactly as `QramCarve::NotQram` does
today. The accept path does not exist until the taint rule + type rewrite + D5 allow-list land. The
verdict is pinned non-vacuously by an env-gated anchor on the existing `CQ_CTRL_DBG` channel:

```
CQ_CTRL_DBG: railbank [Bank] cells=<N> abi=<W> trips=<K> at: <the store>
```

`env CQ_CTRL_DBG=1 not %cq-opt …` in the fixture RUN line; the anchor is byte-absent on the ORACLE.
