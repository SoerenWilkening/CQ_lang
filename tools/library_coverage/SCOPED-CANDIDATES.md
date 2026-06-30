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
| `stdlib.h` | mixed | 3 intrinsic · 7 decline · 15 shadow · 14 by-design | **WIRED** (abs/labs/llabs island); rest deferred |
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

### `stdlib.h` — a small high-value `abs` island (WIRED)
The conversion (`atoi`/`strto*`), allocation, env, and search/sort families are all
pointer/struct/stateful. The one clean scalar island is **`abs`/`labs`/`llabs`** → `@llvm.abs.iN`,
which CQ's curated reversible-intrinsic path already handles (the integer analog of `fabs`).
`div`/`ldiv`/`lldiv` take taintable int pairs but return a `div_t` **struct** (CQ cannot taint/
produce aggregates) and stay opaque `@div` calls → decline. The abs island is wired; the rest
is deferred.

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
