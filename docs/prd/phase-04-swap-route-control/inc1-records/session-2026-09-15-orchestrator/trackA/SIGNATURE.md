# Track A — the PUBLISHED SIGNATURE after bd `de8n` / bd `n74d` (session 2026-09-15)

Supersedes `…/session-2026-09-14c-xdu2-w1/trackA/SIGNATURE.md` **on one point only**: there are now
**two** accept-shaped verdicts where there was one. Everything else in that file — the struct, the
function signature, the five deviations, the four self-attack conjuncts of its addendum — is
unchanged and still the contract.

Header: `ir-pass/include/QramLowering.h`. TU: `ir-pass/src/QramLowering.cpp`.
Subject binary for every measurement below: `cq-opt`
`b65549356168354626a7f09c748e35e43f9fba186ae7ede8dab6a31fd3aae2bf`,
`libCQPass.so` `1c7df31bf95268089ffb10775240339764f91bf4d5a53c6186c1178e06e6093a`.
ORACLE: `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`.

---

## 1. WHAT CHANGED — one enumerator, and it changes what `Bank` MEANS

```cpp
enum class RailBankCarve {
  NotBank,
  Bank,             // C1–C4, C2′, C6 AND C7 — the TYPE-REWRITABLE shape
  BankRaw,          // C1–C4, C2′, C6 hold, C7 does NOT — the PROMOTER'S INPUT, never an accept
  RejectShape, RejectIndex, RejectWidth, RejectAlias, RejectTotality,
};
```

`railBankCarveVerdict`'s signature is **byte-identical** to last session's. `RailBankShape` is
**unchanged** and is now filled on `BankRaw` as well as on `Bank` (the promoter needs the same seven
fields for its input).

### C7 — the new clause, in the two properties it actually states

* **C7(a) NO IN-LOOP READ SURVIVES.** No load of the bank lies inside the walk loop `L`.
* **C7(b) THE WRITE IS TOTAL PER TRIP.** `L->getExitingBlock() == L->getLoopLatch()` **and** the
  store's block dominates that latch.

`Bank` iff C1–C6 ∧ C7(a) ∧ C7(b). `BankRaw` iff C1–C6 ∧ ¬(C7(a) ∧ C7(b)).

---

## 2. WHAT `Bank` NOW GUARANTEES — this is the list Track B may rely on, and it is closed

A `Bank` verdict guarantees, for the module **as `declineTaintEscapes` sees it** (i.e. after the
promoter's fixpoint):

1. everything the 2026-09-14c signature guaranteed — C1 (static, non-escaping `alloca [N x cell]`,
   zero or absent initializer, no off-shape user), C2 (classical index; a tainted one is 7.5's axis),
   C2′ (non-self-wrapping affine `{0,+,1}` over an **outermost** loop with a proven constant trip
   count ≤ N), C3 (a cell width with a reversible copy), C4 (no aliasing fan-out; exactly ONE store
   site in the whole bank), C6 (`Trips == N`; every in-loop read is of the cell this trip writes;
   every other read is after the loop);
2. **NEW — C7(a): no load of the bank is inside `L`.** So there is no PARTIALLY AVAILABLE per-trip
   read for the `[N x cell]` → `[N x i32]` rewrite to turn into a read of handle `0`
   (`SCOPE_L1a.md` §0 H3). Every surviving load of the bank is outside the walk loop;
3. **NEW — C7(b): the store executes on every trip that reaches the latch, and the latch is the only
   way out of the loop.** So `Trips == N` is a statement about WRITES and not merely about index
   visits, and every cell read after the loop was written by the trip that owned it.

**The proof for (3), because "obviously executes every iteration" is how a wrong totality claim gets
into a Release build.** The store's block `B` is in `L`; `L` is a NATURAL loop, so its header
dominates every block of `L` and `B` (if not the header) cannot be reached before the header on any
path into the loop; if some header→latch path avoided `B`, prefixing it with entry→preheader→header
would be an entry→latch path avoiding `B`, contradicting `B` dom latch. So every header→latch path
contains `B`. And the latch being the only exiting block means the only way to reach the code after
the loop is through it — a trip that never reaches the latch (a `noreturn` call, `unreachable`, a
`ret`/`resume` inside `L`, an infinite inner loop) does not reach the after-loop reads either, and an
`invoke` whose unwind destination leaves `L` makes its own block exiting, which `getExitingBlock()`
then refuses by returning null.

---

## 3. WHAT IT DOES **NOT** GUARANTEE — read this before assuming

* **`Bank` does NOT mean "the promoter ran".** It is a statement about the SHAPE, and a bank can
  reach it without the promoter touching the module at all. The witness is a shipped fixture:
  `lowering_railbank_bank_anchor_unpromoted.ll` — an unconditional per-trip write with no in-loop
  read, `carve=[Bank] promo=0` on BOTH binaries. Do not restate the invariant backwards.
* **The implication that DOES hold is one-directional:** *the promoter's INPUT is `BankRaw`, its
  OUTPUT is `Bank`* (`RailBankPromote.cpp` B6 requires `BankRaw`; `applyBank` produces a latch store
  and erases every in-`L` load, which is C7(a) ∧ C7(b) by construction).
* **`BankRaw` is NOT a decline.** `outMsg` stays null and the caller keeps the generic
  `cq taint escape: tainted value stored to memory` it would have fired anyway. Measured: **0 verdict
  movers and 0 stderr-byte movers over 5582 corpus modules** (`probes/corpus_b6554935.txt`). The only
  observable is the env-gated `CQ_CTRL_DBG` anchor.
* **`BankRaw` must NEVER become an accept**, in any future half. The L8 retirement trigger reaches
  `Bank` only, and that is now written at both consumption sites. A widening that wants a `BankRaw`
  program to compile must move it into `Bank` — by teaching the PROMOTER to normalise it — never by
  adding an accepting arm at the consumer.
* C7 says nothing about **taint**: no clause here makes a bank load tainted. That is still Track B's
  deferred piece 1.
* C7 says nothing about the **freeze / membership record**. `isRailBankAlloca` /
  `railStoredToRailBank` / the `!cq.railbank` mint are still NOT shipped (2026-09-14c deviation (2),
  unchanged).

---

## 4. WHAT TRACK B MUST DO DIFFERENTLY

1. **The type rewrite and the D5 allow-list gate on `Bank`, never on "a bank".** `BankRaw` is
   reachable from plain `-O1` C (three measured families: a second bank loop with no dedicated
   preheader; an in-loop whole-array re-zero; in-loop lifetime markers) and it must keep declining.
2. **The taint rule may claim a load only on a `Bank` bank.** On `BankRaw` the in-loop read is the
   §0 H3 partially-available one and tainting it is the silent miscompile.
3. **THE OWNER'S PROGRAM IS ON THE ACCEPTING SIDE — MEASURED, so the split does not block the
   headline.** `example/grover/grover_oracle_uncompute.c`, ORACLE vs SUBJECT, identical:
   `exit 1 · cq taint escape: tainted value stored to memory · carve=[Bank] cells=3 · promo=1`.
   The promoter normalises it and the carve then calls the result `Bank`.
4. **If you widen C7, widen B6 in the same change.** If a shape the promoter still wants to normalise
   ever classifies `Bank`, B6 silently stops promoting it with **no diagnostic anywhere**.

---

## 5. RETIREMENT TRIGGERS THIS TRACK LEAVES BEHIND

| # | trigger | what must be re-derived |
|---|---|---|
| T1 | the promoter is taught to normalise a shape C7 still calls `BankRaw` | C7 against the promoter's NEW postcondition, in the same change; the invariant is *input `BankRaw`, output `Bank`* and `railbank_promote_*` pin it from the other side |
| T2 | anything other than the promoter may produce a `Bank` bank | (a) and (b) are the only two properties the type rewrite may assume — add the third at C7, not at the consumer |
| T3 | B6's `BankRaw` requirement is relaxed or C7 widened without it | the promoter silently stops firing, no diagnostic (measured as mutant M7: 10 fixtures red, so it is not silent to the SUITE — but it is silent to `opt`) |
| T4 | `BankUse::Read` admits a user that is not a load | enumerate ITS observation points in B4′ too; the invariant is *every instruction that OBSERVES the object*, and a gep observes nothing |
| T5 | C6's in-loop-read test is widened (e.g. to admit `if (b[i-1]) …`) | B4′ becomes the SOLE defence against the store move, and `railbank_promote_reject_inloop_hoisted_read.ll` becomes an ISOLATING negative — change its DECLINE line then |
| T6 | C4 or B9 admits a two-writer bank | `applyBank`'s several-stores `SSAUpdater` merge must come BACK (register the last cell store of every block; canonical store by dominance) **with** a red-green pair — the deleted spelling is in this commit's `git` history |

---

## 6. THE FIXTURES THAT PIN IT (5 new, 46 railbank fixtures green in total)

| fixture | pins | red on ORACLE? |
|---|---|---|
| `lowering_railbank_bankraw_inloop_read.ll` | C7(a) in isolation (control: `probes/p4_noread_uncond_nopreheader.ll`) | yes |
| `lowering_railbank_bankraw_cond_store.ll` | C7(b) in isolation, `-O1` floor (control: `probes/p2_uncond_store_no_read.c`) | yes |
| `lowering_railbank_bankraw_toptest_exit.ll` | C7(b)'s single-exiting-block conjunct — an unwritten cell C6's counting misses | yes |
| `lowering_railbank_bank_anchor_unpromoted.ll` | `Bank` WITHOUT promotion — the anti-over-decline control | no, by design (mutant M12 validates it) |
| `railbank_promote_reject_inloop_hoisted_read.ll` | the `-O1` hoisted-address shape B4′ is about | n/a (both decline; mutant M11 validates it) |
