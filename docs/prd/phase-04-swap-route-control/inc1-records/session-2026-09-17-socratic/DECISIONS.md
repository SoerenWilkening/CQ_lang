# Owner decisions — session 2026-09-17 (socratic, no tracks, no code)

The session was a design discussion with the owner about quantum operations inside classical
loops, prompted by the state of `example/grover/grover_oracle_uncompute.c` (loop form). Rulings are
also in bd memory `owner-ruling-loop-carried-handle-2026-09-17`. Nothing here is a rule; CLAUDE.md
and ROADMAP.md remain the operating manual and the plan of record.

## S1 — the owner's runtime-taint FLAG idea: **assessed REDUNDANT, not adopted**

Proposal: for a value whose taint is not known at compile time, emit a classical flag and branch
(`br %flag → classical op / cq_template op`). Assessment, accepted by the owner: taint is a
may-analysis at fixpoint, and a basis-state rail through reversible templates computes the classical
function exactly, so over-approximating "maybe tainted" to "tainted" is semantically free. The flag's
classical select between handles is already free at runtime (a handle is an `i32`). What is unknown
at compile time in a rolled loop is **rail identity** (which allocation a header φ denotes on trip
*i*), not taint. Nothing was filed for the flag.

## S2 — trip-1 PROMOTION: **ACCEPTED**

A loop-carried classical entry value that becomes quantum gets `cqrt_alloc_<W>(entry)` in the
preheader. Owner's words: *"trip-1 promotion might lead to slightly less efficient code, but for now
I am okay with it. we aim for correctness first and the ability to properly compile code."* This is
the fix bd `832l` (L-3) was waiting on.

## S3 — BYTE-IDENTITY with the hand-unrolled twin is an INSTRUMENT, not the target

The rolled form emits a real compare + strip on every trip (clang `-O1` stamps
`llvm.loop.unroll.disable` and does not peel; measured on the stage-1 IR), while `-O1` folds the flat
twin's trip-1 compare to `true` and trip-2 to `¬b0`. Same unitary, different bytes. The witness for
loop work of this kind is a **per-trip unitary argument** in a Rule-13 round plus a **quarantined
divergence** in `tools/loop_twin_matrix.quarantine.txt` carrying that argument. Owner: *"the
operations should do the correct work"* — correctness, not identity, is the claim.

## S4 — reaffirmed: *"we do what is necessary to properly compile EVERYTHING THAT IS NOT FORBIDDEN BY PHYSICS"*

Consequences drawn in-session: (a) bd `tu9q`'s hoisted-template half (IMPL_T2.md §6) is **wanted
now** — it is the correctness boundary for the full Grover iteration; (b) the loop-carried handle
variable is filed as bd `zujr` (P1) and is the next headline; (c) over-declines stay defects.

## S5 — the tracker was stale in the closed direction; verify-by-measurement before closing

Ten issues the lab report / CLAUDE.md said were landed were still OPEN or IN_PROGRESS. Each was
re-measured on the fresh binary before closing (GATES.md): `hn29`, `leyd`, `52og` (probes accept),
`hrts`, `l3i1`, `dpau` (6/6 tripwire fixtures), `7845`, `c767`, `2g52` (rolled == twin), `ti5o`
(duplicate of closed `emkg`; n1/n2/n3 now decline). ⚠ `bd update --notes` REPLACES existing notes
(it cost one restore from `dolt_history_issues` this session); use `--append-notes`.

## S6 — environment facts that are not rulings but will bite the next session

* The repository **moved** to `/Users/sorenwilkening/Desktop/Projects/CQ_lang`. Every prior
  `PROTOCOL.md` names the old path. The primary `build/` had a `CMakeCache.txt` pointing at the old
  source dir and refused to build; it was reconfigured in place (cache + `CMakeFiles/` dropped,
  `cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release`)
  and rebuilt with `-j8` (both targets).
* Before that rebuild the primary `cq-opt` was the **2026-09-14 oracle** (`0e280fc6…`), three
  landings stale. Any decline the owner measured by hand before 2026-09-17 10:26 was measured on it.
