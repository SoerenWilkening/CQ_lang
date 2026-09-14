# Session 2026-09-14 — orchestrator decision log

## Owner rulings taken this session

* **Q2 — loop spelling (bd `xdu2`): (i) the bounded rail ARRAY.** The scalar-`b` spelling (ii) is not
  pursued: four walls instead of one, and it denotes a DIFFERENT circuit (`a` goes negative, −1 at N=2,
  −4 at N=3). Track L scopes L-1a this session (read-only).
* **Q3 — bd `3d8q` gets a track this session.** Correctness over expressiveness. Grounds accepted: the
  population has been widened twice (`b6ap`, then Track M `59ac5b7`), and Track M's F-M3 decline is pinned
  with this fence as its retirement trigger, so the miscompile now blocks a filed widening too.
* **Q1 — bd `om35`: build the φ-DESCENDANT predicate, NOT R-2′.** Asked only after Track F's table existed,
  as the prompt required. The table changed the question: R-2′ flips **25** shipped decline fixtures, not 11
  (13 of them say CONFIRMED MISCOMPILE in their own headers), and Track F surfaced a strictly narrower rule —
  at `ArmClassify.cpp:1682-1683`, *`V` is not a collider if the region's own state-prep merge φ is in `V`'s
  transitive operand closure* — which flips **zero** fixtures and closes all three customers.
  The owner's question, verbatim: *"which one would result in a more general method not over-declining, so
  compiling code that actually leads to valid quantum circuits?"* The answer they accepted: R-2′ admits more
  program classes by raw count, but its safety rests on two **capability** fences (R3 `:4168-4170`,
  F1 `:3906-3915`) this project is actively removing — so its margin **expires on our own roadmap** — and
  HOLE-1 shows it already has none in fp. The φ-descendant rule is narrow in *fixtures touched* and general
  over the **whole cascade family** (any N, any threshold, constant or runtime register), which is the
  program family the owner writes. R-2′ stays FILED as a costed capability with T1/T2 pinned.
* **Loop re-ordering (after Track L's scoping falsified bd `xdu2`'s premise): build `wx8g` (W2) FIRST.**
  Track L measured THREE walls, not one; the array carve alone does not compile the owner's loop, it hands
  the program to `wx8g`. `wx8g` is the cheapest (~120–180 lines / 3 rounds), is W2 on the array path anyway,
  and has its own standalone customer that `CLAUDE.md` records as compiling in **no** spelling on **any**
  binary today.
* **The loop twin matrix is widened to `i1` FIRST** (bd `uq96`): all 288 cells emit 2 `bool` tokens, so the
  witness of record for in-loop work cannot see the width of the owner's entire cascade. Track T lands
  before Track W, in the same group.

Carried, from 2026-09-14 before the session: the **bd `z9t1`** ruling in five clauses (undef seed → 0 at
qubit allocation, normalized EARLY, silent, `cq_measure`'s `21mg` fence untouched, not total) — Track U.

## Tracks launched (wave 1 + D)

| track | bd | kind | worktree / branch | launched |
|---|---|---|---|---|
| U | `z9t1` | impl | `../CQ_undef` / `undef-seed-zero` | wave 1 |
| P | `3qps` + `4aiu` | impl | `../CQ_phiphase` / `mergephi-phase-leaf` | wave 1 |
| F | `om35` | **scope** (read-only, main checkout) | — | wave 1 |
| L | `xdu2` | **scope** (read-only, main checkout) | — | wave 1 |
| D | `3d8q` | impl | `../CQ_3d8q` / `stale-reader-fence` | after Q3 |
| T | `uq96` | impl (instrument) | `../CQ_twinbool` / `twin-matrix-bool` | wave 2 |
| W | `wx8g` | impl | `../CQ_wx8g` / `inloop-bool-prep` | wave 2 |
| F | `om35` | **impl** (same agent, resumed from its scoping) | `../CQ_f2phi` / `f2-phi-descendant` | wave 2 |

## Group partition (PROTOCOL §S1) — PROVISIONAL, to be fixed from the IMPL reports

Predicted file hotspots: U → the early normalization site (`TaintPropagation.cpp` or `RotationLowering.cpp`,
agent decides); P → `ArmClassify.cpp` (kickback classifier) + `SelectClassify` / `CondTreeEmit`; **F →
`ArmClassify.cpp` (F2's test at `:1682-1683`)** — so **P and F are ONE GROUP** by the shared file, and both
were told so; D → `OpcodeLowering.cpp`; W → `ArmClassify.cpp:4396` + `LoopLowering.cpp` — **W may join the
P/F group**; T → `tools/loop_twin_matrix*` only, but is **deliberately grouped with W** even though the files
are disjoint, because T's widened matrix is the instrument that must witness W's code, and T is squashed
first. Do not partition from this table; partition from the actual file sets each IMPL report states.

## Incidents

* **2026-09-14, orchestrator:** `bd update 3d8q --notes` **clobbered** three dated NOTES blocks. Recovered
  verbatim from the embedded Dolt (`dolt sql -q "select notes from issues as of 'HEAD~1' …"`) and restored.
  Lesson written to `bd remember --key bd-update-notes-clobbers`: use `--append-notes`.
