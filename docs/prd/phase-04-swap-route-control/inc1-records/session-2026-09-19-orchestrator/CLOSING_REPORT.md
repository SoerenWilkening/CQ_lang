# CLOSING REPORT — session 2026-09-19 — bd `zujr`, THE LOOP-CARRIED HANDLE VARIABLE

`main` `89b8a649`, pushed. Primary `build/` rebuilt once at the close and
**bit-identical** to the gated worktree binary: `cq-opt`
`e7bbfd69a9e25d383237…`, `libCQPass.so` `84061321f9d6f9747b80…`.

## THE HEADLINE

**`example/grover/grover_oracle_uncompute.c` in its LOOP form compiles as
written.** `int a = 5; bool b0[3]; for (i<3) { if (a>=3) b0[i]=cq_theta(b0[i],.5);
if (b0[i]) a-=3; }` — no source change, no new `cq_*` function, no `int`
workaround. `opt` exit 0, **stderr 0 bytes**, **50 trace lines**, STRICT stage 2b
`2 verified, 0 violation(s), 0 unproven`, **K-INDEPENDENT** (75 lowered lines at
K=3 and at K=1000).

## GATES (all on `e7bbfd69…`)

| gate | result |
|---|---|
| full `ctest -j6` on the PRIMARY after the merge | **464/464 in 579.63 s** |
| full `ctest -j6` on the gate worktree | **464/464 in 561.64 s** (load 6.5) |
| `cq-opt-equivalence-full` | **2106 / 0** |
| `e2e-loop-twin-matrix` | all 312 cells match; 70 quarantined at pinned signatures; 4/4 boundary controls |
| corpus A/B, all 2106 fixtures | **15 movers — 12 D→A, 3 D→D with a moved string, ZERO A→D** |
| conjunct mutant matrix | **1:1, MISSED 0** |
| twin-matrix header preservation (bd `gfsk`) | 493 header lines byte-for-byte; `^#` diff EMPTY |

## TRACKER

**Closed:** bd `8h7d.11` (the (c3) over-decline), bd `ej5w` (X1 at both sites),
bd `8h7d.12` (the honest (c3) diagnostic).
**Closed and REOPENED the same day, by measurement:** bd `832l` — its literal
subject (a loop-carried `_Bool` mutated IN PLACE by a chained theta) is refused by
two conjuncts and is **unmoved on both binaries**. The charter named it as item 1;
the increment built the promotion for a different kind. ⚠ Recorded rather than
quietly left closed.
**Still open:** bd `zujr` itself — its DONE-MEANS asks for ≥3 Rule-13 rounds and
ONE ran.
**Filed:** bd `h7ee` (rounds 2 and 3, P1, blocks `zujr`), bd `h1ip` (the guarded /
rotated loop), bd `11qv` (the narrow-width carried handle), bd `3slt` (the Rule-8
tripwire, against bd `s82e`), bd `hyhl` (the F-5 diagnostic residue).

## THE FIVE THINGS WORTH CARRYING FORWARD

1. **There are THREE kinds of loop-carried register, not two**, and the loop layer
   knew two. `ControlDetect.cpp` had named the third in prose for the value arm
   since before the loop layer existed — *"the loop-carried register is a
   different handle every trip"* — and nobody read it as a kind.
2. **A retirement trigger that names the NEXT wall is only ever a LOWER BOUND on
   how many are left.** Eleven fixtures moved; every one carried an L8 trigger
   predicting this increment; **every trigger named the wrong next wall.**
3. **A postcondition cannot be found by reading decline strings.** Wall 3 was
   `declineUnmarkedRolledIterLocal`'s conjunct 2; the ladder came out of an
   env-gated peel instrument that turns each candidate decline into a skip,
   because `LLVMContext::diagnose` EXITS on the first `DS_Error`.
4. **Two of eight conjuncts exist only to protect a DIAGNOSTIC**, and both were
   found by probe rather than by review. Both shapes decline either way; the
   conjuncts decide *which owner speaks*.
5. **A true conclusion on the wrong ground is still L7.** The (L3) exemption's
   first safety argument cited `railStoredToRailBank` — which guards the TERMINAL
   partition while the marking unlocks the INTERIOR one. Round 1 caught it.

## ⚠ ERRATUM OWED TO LAB ENTRY 012

Entry 012's header records the close hash as **`e2fd1a16`**, the merge commit as
it stood before `git pull --rebase` linearised it. That commit is no longer
reachable from `main`; the correct close hash is **`89b8a649`**. The entry is
SEALED, so this is not editable — **entry 013 owes the dated erratum**
(`docs/labreport/README.md`: corrections are errata in a later entry, never edits
to a sealed one).

## WHAT WAS NOT DONE

* **Rule-13 rounds 2 and 3** (bd `h7ee`). Round 1 ran no ctest entry and no full
  suite, by instruction, and named three things it did not attack.
* **bd `x5fp` stays parked** — measured: the §3c clobber never fires on this
  program, so it still has no first accept.
* **bd `tu9q` P0+P3 stay parked** on `tu9q-p0-p3-wip`; the composition against
  them is part of bd `h7ee`.
