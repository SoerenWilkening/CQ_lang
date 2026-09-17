# bd `test_C_libtooling-h1ip` — THE GUARDED LOOP-CARRIED HANDLE (a RUNTIME trip bound)

**Session 2026-09-20.** OWNER RULING Q1, taken at session open: *hoist the
promotion's `cqrt_alloc` above the zero-trip guard and ACCEPT THE DEAD ALLOC.*

## 1. What landed

The mint point for a GUARDED loop is the **guard's own terminator**, not the
preheader's, and every out-of-loop φ incoming that carries the SEED on the
guard's edge is rewritten to that handle and recorded in the promotion's own
`PromotedCarriedHandlePhis` — the set `declineClassicalMuxes` accepts. The exit φ
then muxes two `i32` HANDLES under the loop's own CLASSICAL guard, which is the
identical argument the header φ already stands on.

**THE COST, TAKEN EXPLICITLY.** A loop that runs zero times allocates a register
it never uses. Left allocated, never freed dirty (Rule 6).
⚠ And on the zero-trip path that register is not waste — it is **the answer**.
Measured (`probes/h1f_zerotrip.c`, one binary, three trip counts):

```
ZERO TRIP (no args, n = 0):   cqrt_alloc_i32(7) -> h0
                              cqrt_measure_i32(h0) -> 0
TWO TRIPS (two args, n = 2):  the full per-trip chain twice, h0 -> h3 -> h7
```

A loop that never runs leaves the variable at its seed, and the program measures
exactly that. The allocation is what makes the zero-trip path EXPRESSIBLE.

## 2. ⚠ THE WALL THE BEAD DID NOT NAME, AND IT CONTRADICTS A CORRECTION IN `CLAUDE.md`

bd `h1ip` names clause (Z8). With (Z8) widened, the IR fixture lowered — and the
**C spelling still declined**, at clause **(Z1)**.

`clang -O1` on `for (int i = 0; i < n; ++i)` with a runtime `n` emits, measured
(`probes/h1e_guarded_live.c`):

```llvm
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %7, label %4        ; straight into the HEADER
```

**There is no preheader at all**, so `getLoopPreheader()` returns null and (Z1)
refused before (Z8) was ever asked.

`CLAUDE.md` §4e records the opposite as a round-1 correction: *"clause (Z1)'s
comment claimed a rotated loop has no preheader; **false** (`-O1` emits one with
a single successor)"*. **BOTH THE ORIGINAL SENTENCE AND ITS CORRECTION ARE
OVER-GENERAL.** `-O1` emits a preheader SOMETIMES — with a preheader for the
hand-written IR shape the fixture pins, without one for the C shape a real
program produces. A predicate may not depend on which.

(Z1) is therefore relaxed to what the promotion actually needs: a **SINGLE
external entry block** for the header. A second external predecessor is a
multi-entry shape and is refused as it always was.

**THE LESSON IS THE SESSION'S THIRD INSTANCE OF ONE PATTERN** (`$PREV` protocol
item 2): a retirement trigger, or a bead, that names the NEXT wall is only ever a
LOWER BOUND. bd `zujr` predicted one wall for `_Bool` and there are two; bd
`11qv` predicted one wall for the narrow width and the `_Bool` CONDITION spelling
has another; bd `h1ip` predicted (Z8) and (Z1) was in front of it.

## 3. ⚠ THE (Z1) RELAXATION IS PINNED BY NOTHING IN THE CORPUS, SO IT GOT A FIXTURE

Measured: the relaxation moved **ZERO** of 2107 fixtures. A widening the corpus
cannot see is a widening the corpus cannot defend, so
`loop_carried_handle_accept_guarded_no_preheader.ll` was written to hold exactly
the shape `-O1` produces. Non-vacuous: it DECLINES on the ORACLE.

## 4. The owed probe (carried protocol item 4), and its answer

*"An accept-direction widening of a CONDITION fence owes one rolled-vs-unrolled
probe with a trailing non-diagonal gate on every register the condition reads."*

| probe | rolled | flat twin |
|---|---|---|
| `h1g` — condition READS the carried register, trailing `cq_theta` on it | **DECLINE** `operand predates a non-diagonal gate` | **DECLINE** `condition predates a non-diagonal gate` |
| `h1h` — condition does NOT read it, trailing `cq_theta` on it | **DECLINE** `operand predates a non-diagonal gate` | **ACCEPT** (8 rails, **1 template rail left DIRTY**) |

**The rolled form is strictly MORE CONSERVATIVE than the flat form in both**, so
this increment does not widen the bd `s82e` class. ⚠ The flat twin's accept in
row 2 IS that class and it reproduces **on the ORACLE** — pre-existing, not this
increment's, and recorded here so the table is not misread as a new leak.

## 5. What this does NOT cover, stated so it is not later cited as though it did

The **MULTI-EXIT** carried handle (bd `h7ee` Rule-13 round 2, finding R2-3) is a
DISTINCT shape — it has no guard, so this hoist does not reach it, and it still
declines. Round 2 said so in advance and it is true on the landed binary.
