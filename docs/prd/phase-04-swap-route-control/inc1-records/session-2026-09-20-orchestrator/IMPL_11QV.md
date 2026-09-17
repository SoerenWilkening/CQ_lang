# bd `test_C_libtooling-11qv` — THE NARROW-WIDTH LOOP-CARRIED HANDLE

**Session 2026-09-20.** Owner ruling Q2 of this session: *fold it into the bd
`h7ee` rounds*. ORACLE `cq-opt` `e7bbfd69a9e25d38…` (= `main` `00c36e93`, and the
worktree's own from-scratch build reproduced it **bit-identically**, which is
worth one line of its own: the tree and the shipped primary binary agree).

## 0. What declined, measured before a line was written

A clean width axis — one program, five carried types, condition NOT reading the
carried variable so the width is the only axis:

| carried type | ORACLE | SUBJECT |
|---|---|---|
| `_Bool` (`i8` φ) | `cq loop lowering: loop-carried tainted value crosses iterations` | **ACCEPT**, 42 trace lines |
| `char` | same decline | **ACCEPT**, 41 |
| `short` | same decline | **ACCEPT**, 41 |
| `int` | ACCEPT, 41 | ACCEPT, 41 (unmoved) |
| `long long` | same decline | **ACCEPT**, 41 |

and the owner's own cascade at every width (`owner.c` with `int` → `short` /
`long long` / `char`): ORACLE `cq controlled lowering: iteration-local value read
after the loop`, SUBJECT **ACCEPT, 50 trace lines, STRICT 2b clean** — the same 50
the `int` spelling has shipped since bd `zujr`.

⚠ **THE `_Bool` CARRIED HANDLE HAS TWO SPELLINGS AND ONLY ONE IS THIS BEAD'S.**
`_Bool acc` updated under quantum control is (Z3)'s and it now lowers. `_Bool a`
**read as the region's own condition** (`if (!a) …`) declines at
`cq controlled lowering: control flow under quantum control` on BOTH binaries —
a different wall entirely (the bare-`i1` condition family, bd `r903` / `fg9k` /
`boi6`), untouched here. Recorded because the bead's own text says *"a `_Bool`
carried handle is the shape the owner's own programs are full of"*, and half of
that shape is still declining.
**This is the lower-bound lesson again** (`$PREV` protocol item 2): the bead
predicted ONE wall for `_Bool` and there are two.

## 1. What landed

**(Z3) widened** from `isIntegerTy(32)` to `isIntegerTy()` + a resolvable ABI
width, recording `Pf.NeedsHandleRetype` for anything that is not already `i32`.

**The promotion RETYPES** — `P.mutateType(i32)` + the metadata scrub, the
`RailBankPromote.cpp` idiom (*"the load IS a rail name now"*; here the φ is).

**⚠ AND IT WRITES THE WIDTH RECORD WHERE `RailBankPromote` ERASES IT. THIS IS THE
SAFETY ARGUMENT, NOT BOOKKEEPING, AND IT WAS FOUND BY READING BEFORE
IMPLEMENTING, NOT BY A PROBE.** `logicalOperandWidth` (`CompareLowering.cpp`)
consults `taint.HandleWidth` **before** the LLVM type, precisely because the type
may have been laundered to `i32`. With no entry, `qqSelectLeafWidth` falls back to
`abiWidthFromType(φ->getType())` — which after the retype answers **`i32`** — and
a Q+Q compare over two retyped `i16` φs would mint
`cq_template_icmp_<pred>_i32(h,h)` for two `i16` registers. Verify-clean, links,
runs, wrong. That is the class `CompareLowering.cpp` refuses in writing (*"NEVER
pick one width on disagreement … NEVER default empty -> i32 (the same class of
silent miscompile)"*). `Pf.Abi` is read off the φ's type at (Z3) **while the type
still says it**.
⚠ **REACHABILITY IS NOT CLAIMED**: every Q+Q compare shape probed under quantum
control declines identically at `i16` and `i32`
(`cq controlled lowering: quantum-quantum compare condition under quantum
control`), on both binaries. The record is therefore **defensive**, and it is
written that way rather than as a fixed bug. Its load-bearingness is measured by
peel `HW` (§3).

**Gate (P4)** — every user of a φ about to be retyped is one the lowering
rewrites (a tainted non-φ instruction, or a `cq_*`/`cqrt_*` call). A φ user is
refused even though it is tainted: a second φ carrying this one keeps its NARROW
type and nothing retypes it, so admitting it would move the invalid edge one φ
outward. **A SKIP, not a decline** (D2) — the unpromoted φ is refused by
`declineClassicalMuxes` one stage later.

**Gate (P0)** — bd `h7ee` Rule-13 ROUND 2 finding **R2-1**, fixed in the same
change rather than filed: a `use_empty()` header φ is no longer promoted. The
promotion was the LAST owner for a dead φ (`declineClassicalMuxes` opens with its
own `use_empty()` skip) and it MUTATED — a `cqrt_alloc_<W>` qubit and a trace
line for a value nothing reads, renumbering every downstream handle. **A
mutation-avoidance clause, not a fence**, and an **IR-level shape only**
(`clang -O1` deletes a dead φ).

## 2. Cross-width structural identity — the instrument, and its one artifact

The rolled traces at `i8`/`i16`/`i64`, with the carried width token normalised,
are **IDENTICAL to the `i32` trace** except for one thing, and that thing is
**PRE-EXISTING AND NOT THIS CHANGE'S**:

```
o8  : cq_template_add_i8_hl (h0, 253)    o32: cq_template_add_i32_hl(h0, -3)
o16 : cq_template_add_i16_hl(h0, 65533)  o64: IDENTICAL modulo the width token
```

`253 = 256−3` and `65533 = 65536−3`. The LOWERED IR IS CORRECT —
`call i32 @cq_template_add_i8_hl(i32 %17, i8 -3)` against
`declare i32 @cq_template_add_i8_hl(i32, i8)`. **The defect is an ABI-ATTRIBUTE
MISMATCH at the call**: the runtime's C definition is
`int32_t cq_template_add_i8_hl(int32_t, int8_t)`, and Clang's x86-64 C ABI marks
an `int8_t` parameter `signext`, so the callee does not re-truncate; the pass
emits the literal operand with **no `signext`/`zeroext` attribute**, so the
caller does not extend and the callee reads the zero-extended register.

⚠ **ATTRIBUTED BY MEASUREMENT, NOT BY ARGUMENT (Rule 11).** It reproduces on the
**ORACLE** binary with a **loop-free** program that has no carried handle at all
(`o8_unr.c`, `o16_unr.c`: `cq_template_add_i8_hl(h2, 253)`), and a direct C
driver against the same archives prints `-3`. It has nothing to do with the φ
retype. Arithmetically it is harmless **at the template's own width** (253 ≡ −3
mod 2^8), and the runtime is trace-only, so no shipped unitary is wrong — but the
goldens encode it, and a real backend's correctness would depend on its own
truncation. **FILED, not fixed here** — it is another owner's surface (Rule 14)
and fixing it would move goldens across the tree.
⚠ *"Pre-existing" is true of the defect and FALSE of its population*: this change
makes narrow-width carried handles reachable, so it adds customers.

## 3. Mutant validation — because (P4) has NO discriminating RUN line

(P4) does not change any verdict that could be pinned by a FileCheck: the LCSSA
narrow module declines at `declineClassicalMuxes` **with (P4) peeled as well as
with it in place**, because `LLVMContext::diagnose` EXITS before the verifier
runs. So (P4), (P0) and the `HandleWidth` record are validated the way bd `zujr`'s
four conjuncts were — **by SOURCE MUTATION over the whole fixture corpus**, using
the re-created env-gated peel instrument (`$PREV` protocol item 1; **SCRATCH,
removed before commit**).
⚠ The sweep's FIRST spelling reported **2065 movers of 2106** and was a LIE:
`rc=$?` after a pipeline captured `grep`'s status, not `cq-opt`'s. It was caught
by a **null-tag boundary control** (`peel NOSUCHTAG` must move 0), which is now
run on every invocation. CLAUDE.md L10, on my own instrument, within one session
of the file saying so.

Results: see `GATES.md`.
