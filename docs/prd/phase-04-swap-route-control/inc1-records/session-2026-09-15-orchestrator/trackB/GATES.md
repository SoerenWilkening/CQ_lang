# Track B — GATES (hash-keyed, session 2026-09-15)

`PROTOCOL.md`'s non-redundancy contract: **a gate result is a fact about a
BINARY, not about a moment.** Every line is

```
<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>
```

⚠ **A cited line whose hash does not match the binary on disk is a FINDING.**
Read this file before running any gate; if the hash is unchanged and the gate is
recorded, CITE it rather than re-running.

## The binaries of this track

| label | `cq-opt` sha256 | `libCQPass.so` sha256 | what it is |
|---|---|---|---|
| ORACLE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | `main` `74eabd2c`, frozen, READ-ONLY |
| BASE | `b65549356168354626a7f09c748e35e43f9fba186ae7ede8dab6a31fd3aae2bf` | `1c7df31bf95268089ffb10775240339764f91bf4d5a53c6186c1178e06e6093a` | `railbank-blockers` `9e11f524` built clean here — **BIT-IDENTICAL to Track A's SUBJECT** |
| SUBJ-1 | `fe42a9ff2b71658825d3339d64ea1fb783c66cdcf814d2129339ebca8886145d` | `54b962e5be3ef99f274467921516751d8f68acc3439bd4c69e9f974afab72ed0` | the three pieces, **before** the width fence (§11.0 of `IMPL_B2.md`) |
| SUBJ-2 | `a81c4925faa32575b495e43adfed0db8298f30f37d09b82702fe08cc95eb4c38` | `ca64ab75bf676498491ebe0b4fb01a38ed089f1d340bb98bd3eaff23cb60a0a3` | the width fence added, **before** the two self-review fixes (`IMPL_B2.md` §7) |
| SUBJ | `784c14fa05c16c501662b3814434dafb8ffb1cc2ed98a8d17986dc12a372b6ff` | `a4e4f6781524c569e7112f5809c2813dd250d8a1b9e02571a4095d2719ba65c6` | **FINAL** |

⚠ **Lines keyed to SUBJ-1 or SUBJ-2 are NOT citable for SUBJ.** They are kept because they
are what was true when they ran; every gate that matters was re-run on SUBJ and
has its own line below.

⚠ **The both-binary discriminator** (Track T's measured third form of the
false-green trap: `cq-opt` segfaulting while `libCQPass.so` from the same build
worked) was run at BASE, SUBJ-1 and SUBJ — same stage-1 module through `cq-opt`
and through `opt -load-pass-plugin libCQPass.so`; same exit code, byte-identical
stdout, all three times.

---

```
both-binary discriminator (b12 s1)          | b6554935 | cq-opt exit=1, opt+so exit=1, same string   | impl | 2026-09-15 03:31
probe set (9 probes, run.sh)                | b6554935 | 9/9 DECLINE kMsgStore; carve [Bank] on 4    | impl | 2026-09-15 03:33
RED: emulate_piece3 b12 (the miscompile)    | b6554935 | opt 0, 2b 0 violation(s), 6 trace lines, ZERO measures for 3 written cq_measure | impl | 2026-09-15 03:35
RED: emulate_piece3 b14 (the spine)         | b6554935 | opt 0, 2b 1 verified/0 violation(s), 12 lines: ry(+.5);ry(-.5);cqrt_free per cell | impl | 2026-09-15 03:35
R2 pre-measure b12 vs b13 (emulated)        | b6554935 | equal sha256 ef75e8d7…, diff empty          | impl | 2026-09-15 03:35
both-binary discriminator (b12 s1)          | fe42a9ff | cq-opt exit=0, opt+so exit=0, IDENTICAL out  | impl | 2026-09-15 05:10
lit --filter railbank                       | fe42a9ff | 55/55 pass (before the width-pun fixtures)   | impl | 2026-09-15 05:55
ctest -R '^e2e-(slice-)?railbank' -j2       | fe42a9ff | 8/8 pass                                    | impl | 2026-09-15 05:20
injection matrix (M1..M8b, 9 mutants)       | fe42a9ff | 9 mutations, MISSED 2 (M2, M8) — SUPERSEDED  | impl | 2026-09-15 06:05
both-binary discriminator (b12 s1)          | a81c4925 | cq-opt exit=0, opt+so exit=0, IDENTICAL out  | impl | 2026-09-15 06:40
both-binary discriminator (b12 s1)          | 784c14fa | cq-opt exit=0, opt+so exit=0, IDENTICAL out  | impl | 2026-09-15 07:50
injection matrix (M1..M10, 11 mutants)      | 784c14fa | 11 mutations, MISSED 2 (M2 unreachable, M10 by design) | impl | 2026-09-15 08:35
adversarial write-side probes d5i/d5j/d5k/d5l | 784c14fa | d5i/d5l/d5k DECLINE (safe over-declines); d5j scalar control ACCEPTs WITH cq_template_trunc_i32_to_i8 | impl | 2026-09-15 08:40
ctest -R 'ir-pass-lit|frontend-lit'          | 784c14fa | 2/2 Passed (ir-pass-lit 98.72 s, frontend-lit 4.43 s) | impl | 2026-09-15 08:55
lit ir-pass/test (full, counts)              | 784c14fa | 2054 passed, 1 XFAIL, 0 failed of 2055; 88.25 s | impl | 2026-09-15 08:58
ctest -R '^e2e-(slice-)?railbank' -j2        | 784c14fa | 8/8 pass, 6.32 s                            | impl | 2026-09-15 08:56
R2 on the REAL accept (slice traces)         | 784c14fa | diff EMPTY, equal sha256 0eaaad13…, 0 divergences | impl | 2026-09-15 08:58
flat-twin byte identity (slice traces)       | 784c14fa | equal sha256 0eaaad13… (bank == 3 scalar _Bools) | impl | 2026-09-15 08:58
K-independence (N=3 vs N=1000, no -g)        | 784c14fa | 83 lowered non-blank lines at BOTH; 2 alloc sites at both | impl | 2026-09-15 08:58
corpus sweep ORACLE-vs-SUBJECT, 5557 rows    | 784c14fa | inputs=5586 rows=5557 (29 = the `*_lib.c` link-partner skips); 86 MOVERS: 27 D->A (ALL rail-bank programs), 59 D->D (34 kMsgStore->wall 3, 15 kMsgStore->the new D5 string, 6 kMsgStore->X1, 2 kMsgStore->classical-condition phi, 1 truncated tag, 1 pre-existing hand-derived ABORT on BOTH binaries), **0 A->D** | impl | 2026-09-15 09:30
probe set (7 probes, run.sh)                | a81c4925 | 5 ACCEPT 9-line/2b clean; d5g DECLINE width pun; b01 DECLINE wall 3 | impl | 2026-09-15 06:35
injection matrix (M1..M10, 11 mutants)      | a81c4925 | 11 mutations, MISSED 2 (M2 unreachable, M10 by design) | impl | 2026-09-15 06:38
ctest -R ir-pass-lit                        | a81c4925 | Passed 70.58 s, 1/1                         | impl | 2026-09-15 06:44
lit ir-pass/test (full, counts)             | a81c4925 | 2054 passed, 1 XFAIL, 0 failed of 2055; 69.96 s | impl | 2026-09-15 06:46
ctest -R '^e2e-(slice-)?railbank' -j2       | a81c4925 | 8/8 pass, 6.78 s                            | impl | 2026-09-15 06:46
ctest -R frontend-lit                       | a81c4925 | 1/1 pass, 3.91 s                            | impl | 2026-09-15 06:46
R2 on the REAL accept (slice traces)        | a81c4925 | diff EMPTY, equal sha256 0eaaad13…, 0 divergences over 3 program pairs | impl | 2026-09-15 06:46
flat-twin byte identity (slice traces)      | a81c4925 | equal sha256 0eaaad13… (bank == 3 scalar _Bools) | impl | 2026-09-15 06:46
K-independence (N=3 vs N=1000, no -g)       | a81c4925 | 83 lowered non-blank lines at BOTH; 2 alloc sites at both | impl | 2026-09-15 06:20
E4 byte identity (owner file vs slice body) | n/a      | diff EMPTY; sha256 bf3b96de04ef60e5…         | impl | 2026-09-15 05:40
tests/e2e/CMakeLists.txt post-union checks  | n/a      | 0 duplicate add_test names; 440 add_test; sweep still LAST | impl | 2026-09-15 05:25
```

## CITED, not re-run

```
corpus sweep O-vs-BASE, 5582 modules        | b6554935 | rows=5582 verdict-movers=0 stderr-byte-movers=0 | trackA GATES.md line 33 | 2026-09-15 01:50
```

⚠ **That line is what makes an ORACLE-vs-SUBJECT sweep equivalent to a
BASE-vs-SUBJECT one for attribution**: Track A measured BASE ≡ ORACLE on the
corpus (0 verdict movers, 0 stderr-byte movers), and this track's BASE binary is
**bit-identical** to the binary that line is keyed to. The three-way attribution
the brief asks for is therefore ORACLE→SUBJ, with BASE pinned to ORACLE by
citation rather than by a second sweep.

## NOT RUN, and owed

```
full ctest -j6                              | —        | merge-and-gate agent's, ONCE per landing (PROTOCOL S1)
cq-opt-equivalence-full                     | —        | OWED: this increment adds two decline strings and stops one arm declining
twin matrices                               | —        | not owed: no in-loop CONTROL code landed (SCOPE_B §7.3)
```
