# Scoped candidate libraries (not yet wired)

The coverage harness ([`probe.py`](probe.py)) currently wires **`math.h`** (flagship)
and the numeric island of **`stdlib.h`**. This file records the scouting of further C
standard-library headers as demonstrator candidates — which functions are taint-relevant,
and what each header would *need* before it produces meaningful quantum coverage. (Scouted
2026-06-30 by running clang `-O1` on this darwin/x86_64 + LLVM-19 box; dispositions are
empirical, not guessed.)

A header is wired into `LIBRARIES` only when it has a real, **golden-verifiable** island.
Everything else is honest future work, gated on a named capability — never papered over.

## Disposition legend
- **compiles-intrinsic** — clang `-O1` emits an `@llvm.*` intrinsic CQ's curated path already lowers.
- **declines-unknown-callee** — stays a direct `@libc` call → loud decline; fixable via a curated name-matcher + reversible template (cf. `math.h`'s `nyww`, epic `3c6m.2`).
- **needs-pointer-shadow** — operates through pointers/arrays/global tables → needs the QRAM/Shadow memory model (Phase 7.5 and beyond).
- **needs-new-source-type** — input is a type `cq_theta` cannot taint yet (`_Complex`, `long double`).
- **by-design-no-taintable-input** — no scalar taintable input at all (`char*`/`void*`/`FILE*`/void).

## Candidates

| Header | Fit | Disposition tally | Verdict |
|---|---|---|---|
| `stdlib.h` | mixed | 3 verified · 3 needs-aggregate · 25 needs-shadow · 8 by-design | **WIRED** (full 39-fn surface; `abs` island verified, rest classified) |
| `ctype.h` | later | 1 intrinsic · 2 decline · 11 shadow | LATER — memory-model gated |
| `string.h` | later | 1 decline · 11 shadow · 10 by-design | LATER — the polar opposite of `math.h` |
| `complex.h` | later | 22 needs-`_Complex`-source | LATER — needs a `_Complex` taint source first |

### `ctype.h` — memory-model gated (a deceptive "scalar" surface)
Looks like a clean `int→int` scalar header, but on this libc 11/12 classification functions
inline to a **tainted-indexed load from the external `@_DefaultRuneLocale` rune-type table**
under a tainted branch (+ a `__maskrune` fallback) — squarely QRAM/Shadow territory, and
`@_DefaultRuneLocale` is an external *mutable* global, so it is even beyond Phase 7.5's
const-global QROM read. `tolower`/`toupper` stay direct `@__tolower`/`@__toupper` calls
(decline). Only **`isdigit`** is a clean win (`-O1` const-folds it to `(unsigned)(c-48) < 10`
= stock `add`/`icmp ult`/`zext` on CQ's existing path). **Wire it only to exercise QRAM table
reads**, not to grow intrinsic coverage.

### `stdlib.h` — full surface wired (WIRED)
The whole ~39-function header is modeled so the denominator is honest (not a cherry-picked
island). Only **`abs`/`labs`/`llabs`** lower and golden-verify today (→ `@llvm.abs.iN`, the
integer analog of `fabs`). The rest is classified by a structural signature fact, never a
compile claim: `div`/`ldiv`/`lldiv` return a `div_t` **struct** → *needs-aggregate*; the
`atoi`/`strto*` parsers, `malloc`/`free` family, `getenv`/`system`, `qsort`/`bsearch`, and the
multibyte routines are pointer/buffer operations → *needs-shadow*; `rand`/`srand`,
`exit`/`abort`/`_Exit`/`quick_exit`, and `atexit`/`at_quick_exit` have no quantum meaning →
*by-design*. Net: **3/39 golden-verified**, 28 fixable (3 aggregate + 25 Shadow), 8 by-design.

### `string.h` — pointer/Shadow demonstrator (LATER)
Every function's meaning is carried by `char*`/`void*` buffers CQ cannot taint. The only
taintable scalars are the search/fill byte `c` (`memchr`/`memset`) and the length `n`, but
the operation is a memory traversal → needs the QRAM/Shadow memory model. The right header to
showcase **tainted-index memory access**, not arithmetic.

### `complex.h` — needs a `_Complex` taint source (LATER)
Uniformly source-type-blocked: all 22 C11 functions (×3 with `f`/`l` variants) take a
`_Complex` argument, and `_Complex` is outside `cq_theta`'s 15-scalar-type source set. None has
a taintable scalar input today. Unblocking it needs a **`_Complex` taint source** in `CQ.h`
(plausibly a pair-of-reals decomposition) — a frontend capability, not a lowering one.

## Takeaway
`math.h` is genuinely the best demonstrator (pure numerical, intrinsic-backed). `stdlib.h`'s
`abs` island is the clean second. `ctype.h`/`string.h` are the **memory-model** showcases (wire
them when QRAM/Shadow table-read coverage lands), and `complex.h` waits on a `_Complex` source
type. Each is a real, named future step — recorded here so the adaptable format has a populated
backlog.
