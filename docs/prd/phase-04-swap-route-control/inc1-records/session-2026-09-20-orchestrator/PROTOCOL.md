# PROTOCOL — session 2026-09-20 (a DELTA, deliberately not a copy)

⚠ **THIS FILE IS A DELTA ON PURPOSE.** The 2026-09-18 `PROTOCOL.md` opens with the
lesson that *"a protocol copied verbatim carries its predecessor's measurements
with it, and a measurement is a fact about a moment"* — and records that **two
successive sessions shipped their predecessor's hashes** and had to correct them
at the point of use. Copying it a fourth time would be the third instance. So:

**The binding protocol is
[`../session-2026-09-19-orchestrator/PROTOCOL.md`](../session-2026-09-19-orchestrator/PROTOCOL.md)**
(itself carried from 2026-09-15 / 2026-09-18) — the gate matrix, the
non-redundancy rules, §6.1's one-owner-per-gate rule, S1/S2/S3. Read it there.
**Its ORACLE BLOCK IS STALE AND MUST NOT BE USED.** This session's binaries:

```
ORACLE   cq-opt e7bbfd69a9e25d38…  libCQPass.so 84061321f9d6f974…   (main 00c36e93)
SUBJECT  cq-opt b1f3fd903e62531e…                                    (11qv-narrow-carried-handle, d79bd31a)
```

⚠ A from-scratch worktree build at `main` reproduced the ORACLE **bit-identically**,
and Rule-13 round 3 reproduced it independently. When that stops being true, it is
a finding.

## ADDITIONS THIS SESSION EARNED

1. **EVERY MUTATION/PEEL HARNESS SHIPS WITH A NULL-TAG BOUNDARY CONTROL, RUN ON
   EVERY INVOCATION, BEFORE THE FIRST REAL MEASUREMENT.** Peel a tag nothing
   uses; it MUST report 0 movers. This session's first sweep reported **2065
   movers of 2106** because `rc=$?` after a shell pipeline captured `grep`'s
   status, not `cq-opt`'s. ⚠ **The tell was that the number was implausible —
   which is exactly the tell you do not get when the harness errs the other way.**
   Write the control first.

2. **A WIDENING THAT MOVES ZERO FIXTURES OWES A FIXTURE, AND ITS RECORD OWES THE
   WORD "DEFENSIVE".** Three clauses landed at 0 movers this session ((Z1)'s
   relaxation, (P4), the `HandleWidth` record). The first got a fixture holding
   the exact shape `clang -O1` produces; the other two are recorded as
   **defensive and unreachable on today's corpus**, in those words, so neither is
   ever cited later as a tested fence. A clause with no fixture and no disclosure
   rots into an assertion.

3. **BEFORE IMPLEMENTING A "THREE-LINE" WIDENING, READ WHAT ELSE CONSUMES THE
   VALUE YOU ARE ABOUT TO MUTATE.** bd `11qv` was filed as *"three lines and an
   argument"*. The three lines were right; the argument was missing its load-
   bearing half, and `logicalOperandWidth` would have turned the widening into a
   wrong-width silent miscompile. It was found by READING the consumers, not by a
   probe — no probe in the session reached that path.

4. **A BEAD OR TRIGGER THAT NAMES THE NEXT WALL IS A LOWER BOUND** (carried from
   2026-09-19, and it held twice more). Corollary earned here: **a CORRECTION to
   such a claim is a lower bound too.** CLAUDE.md §4e's round-1 fix — *"false,
   `-O1` emits [a preheader]"* — is itself over-general; `-O1` emits one
   SOMETIMES. When you correct an over-general sentence, check whether your
   correction is over-general in the other direction.

5. **CARRIED, UNCHANGED, AND IT PAID AGAIN:** an accept-direction widening of a
   condition/reader fence owes one rolled-vs-unrolled probe with a trailing
   non-diagonal gate on every register the condition reads. bd `h1ip`'s came out
   *rolled is strictly MORE conservative than flat in both spellings*, which is
   what let the increment state that it does not widen bd `s82e`.

6. **RUN THE BEAD'S LITERAL SUBJECT ON BOTH BINARIES** (carried from 2026-09-19).
   Held: bd `h1ip`'s own pinned fixture was the first thing run after the build,
   and bd `11qv`'s width axis was measured on the oracle before a line was
   written.


7. **SEAL THE LAB ENTRY AFTER `git pull --rebase`, NEVER BEFORE** (bd `6hy4`).
   The close hash is read from `HEAD`, and a rebase rewrites every unpushed
   commit — so a hash read before the pull names a commit that will not exist.
   ⚠ **Three instances, two of them in THIS session**: entry 012 had it, entry
   013 carried the erratum for entry 012 and then repeated it ninety seconds
   after sealing. **An erratum describes the symptom and prevents nothing.**
   Order: `pull --rebase` → read `HEAD` → write the header → `--seal` → commit →
   `push`. Then run `git merge-base --is-ancestor <recorded hash> main`; a
   `false` is an erratum owed **immediately**, not next session.

8. **ASK THE QUESTION YOU MEAN, NOT A PROXY FOR IT** — round 4's P1, and the
   session's sharpest lesson. (P4) asked a callee's NAME where it meant its
   DECLARED TYPE, and the name it chose was literally the exemption list of
   another guard, so the second list trusted what the first merely tolerated.
   ⚠ **And the first CORRECTION was another proxy**: a curated membership list,
   which refused the merge emitter's own `cqrt_copy_<W>_controlled` — also
   `cqrt_*`, but with an `i32` slot where the retype is the REPAIR — and broke
   the increment's own headline. This project already had the lesson at
   `ChainWalk` (*"asked as membership of the instruction, never by name"*) and it
   did not transfer. When you reach for a name, a prefix or a curated list, write
   down the question you actually mean first and check whether it is answerable
   directly.
