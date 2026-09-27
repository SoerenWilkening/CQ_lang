# Rule-13 review r5 — bd `test_C_libtooling-vsfp` round 5 (`a3e22f5b`)

**Verdict: NOT-CLEAR.** One P1: the round-5 liveness gate brings back bd `tzfa`'s wrong unitary for a
C spelling that round 4 compiled twin-identically. Two P3s. qce6 holds on everything I ran.

Narrow round. No sweep, no mutation matrix, no private build. I used the subject's binaries and the
kept round-4 copy only.

| tag | binary | sha-256 (16) |
|---|---|---|
| S (subject, round 5) | `<worktree>/build/ir-pass/cq-opt` | `74df1d02e7b90123` |
| R4 (round 4, kept) | `scratchpad/vsfp/bin/cq-opt.r4keep` | `829769d92e05c4e4` |
| M (oracle main `aee8f4f8`) | `scratchpad/frozen/cq-opt.main_aee8` | `69250feaf68bbe49` |
| E1 mutant (implementer's) | `scratchpad/vsfp/bin/cq-opt.E1_no_slot_eligibility` | `e1abd935a97c5180` |

Probes: `probes/csrc/` (C sources, lib TUs, IR, and the stage-1 `.ll` for `mt1`/`mtT`/`ps1`/`ps2`).
Tools: `probes/tools/{build,run,results}.sh`, all bash. `results.sh` rebuilds every probe in a scratch
directory and wrote `probes/results/results.txt`. Every probe lowers, runs stage 2b STRICT, links with
templates before runtime, runs, and compares the trace byte-for-byte with a hand-inlined twin.

---

## F-Z-1 (P1). The liveness gate turns an inner ineligible slot into an outer LIVE slot, and bd `tzfa`'s phantom read comes back (wrong unitary)

**Class.** Over-accept with a wrong unitary, reachable from C. Relative to round 4 it is INTRODUCED by this
round: R4 is twin-identical, and the E1 mutant restores twin identity. Relative to the oracle it is
PRE-EXISTING: S emits M's stream byte-for-byte. This is the r2B `k19` class, which bd `tzfa` closed.

**Repro** (`probes/csrc/mt1.c` + `mt1.lib.c`, two TUs, `build.sh` = `run_slice_multi.sh`'s recipe, args `5 7`):

```c
// mt1.lib.c
static volatile int K = 7;
__attribute__((noinline)) int h2(int a, int k) { if (a > 3) (void)K; return k + 1; }
int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }
// mt1.c  (the r2B k19 main, verbatim)
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5);
  int p = q * 3; int r = h(p, m); int u = p ^ q; if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7); return r + cq_measure(q); }
```

The twin `mtT.c` is the same program with `int r = m + 1;`. The sibling `mtN` drops `musttail` and is
otherwise identical.

| probe | S | R4 | M |
|---|---|---|---|
| `mt1` (musttail) | ACC, **1 warning**, CENSUS 5 mints / **2 dirty**, **TRACE-DIFF** vs twin | ACC, 0 warnings, **TRACE-IDENT** | ACC, 1 warning, TRACE-DIFF (S trace == M trace) |
| `mtN` (plain tail call) | TRACE-IDENT | TRACE-IDENT | TRACE-DIFF |
| E1 mutant on `mt1` | — | — | — (E1: exit 0, 0 warnings, **TRACE-IDENT**) |

On every binary, stage 2b STRICT reports `0 violation(s), 0 unproven`. S's trace is missing exactly the
twin's `cq_template_mul_i32_hl_unc(h1, h0, 3)` / `cqrt_free(h1)` before `cqrt_ry_i32(h0, 0.7)`. That is
k19's diff, line for line (r2B REVIEW F-WB-1). The only signal is the generic lyyf-(B) warning
`non-diagonal gate over a live derived record`. The unitary is wrong for the reason r2B gave: `h1 = 3q`
is a bijective which-path record, so it dephases `q` across the oracle before the `Ry`.

**Mechanism.** The two call sites in the lowered module:

```
S : call i32 @__cq_q_h_01(i32 noundef %h_op, ...)   ; inner: musttail call @__cq_q_h2_01(i32 noundef %0, ...)
R4: call i32 @__cq_q_h_01(i32 noundef 0, ...)       ; inner: musttail call @__cq_q_h2_01(i32 noundef 0, ...)
```

`h2`'s clone records slot 0 dead. Inside `h`'s clone, that slot is on a `musttail` call, so
`dropEligibleSlot` is false. Round 5's `FunctionLiveness` asks `isRewritableDeadSlot` and therefore counts
the slot as a READ. `h`'s parameter 0 then becomes LIVE in `h`'s record. At module level the slot is no
longer recorded dead, so `resolvePhantomCloneArgReads` never considers it:

- no neutralise;
- and none of round 5's new "quantum operand in an ineligible slot declines" either, because that branch
  only sees module-level ineligible slots.

The phantom consumer stays in `p`'s use list, and the spine does not discharge `h1`. That is precisely
bd `tzfa`.

**The two claims this falsifies:**

- TRACK §R5.1 and `DeadValueLiveness.{h,cpp}` say *"an ineligible slot's operand stays in place, so it
  must count as a read"*. Counting it as a read is not local. Via `deadParamMask` it propagates one clone
  level up, into a slot that IS eligible and whose record now says LIVE.
- §R5.1 says *"a QUANTUM operand in an ineligible slot declines with the phantom-read message"*. That is
  true only at module level. Inside a clone, the same operand is silently re-labelled "read" one level up.

The `musttail` refusal in `dropEligibleSlot` is a CONSERVATISM, not a soundness property.
`spec_accept_dropped_arg_musttail_kept.ll`'s own header says so: *"a constant argument changes no
signature"*. Round 5 made it load-bearing for correctness by feeding it into liveness.

**Why nothing saw it.** The only `musttail` fixture is classical. The 3672-module A/B has no nested
`musttail` forward of a quantum rail. The mutants E1/E2 test the eligibility conjunct in the rewrite
direction only.

**Scope, argued and not fully measured.** Adding `dropEligibleSlot` to liveness can only ADD reads, so
round-5 dead-bit records are a subset of round-4's. "Vice versa" (a parameter newly recorded dead) cannot
happen. Every customer is a parameter that lost its dead bit. For an INT slot in a clone call, the only
ineligible C spelling I found is `musttail`:

- clones are internal, hence exact;
- clones are never variadic (`SpecializeReject` (0a));
- clang emits only allowlisted attributes on int/fp params (measured, see attack 2).

Pointer and `byval` slots never carry quantum values, so for them the change moves only records, not
streams.

**Fix direction** (the owner's call): split `dropEligibleSlot` into two parts.

- The null-soundness part: slot type and attributes. The rewrite and the liveness rule ask only this.
- The drop-policy conservatisms: `musttail`, and the callee conjuncts. Only the pre-`specialize()` drop
  asks these.

A constant in a `musttail` slot is what round 4 emitted, verify-clean and twin-identical. Ship
`mt1`/`mtT` as the red-green pair (IR for `mt1` is in `probes/csrc/mt1.s1.ll`).

Filed: bd **`test_C_libtooling-w7nm`** (P1).

## F-Z-2 (P3; bd `test_C_libtooling-ad35`). `hasImplicitSection()` refuses objects the backend does NOT place in the named section

**Where.** `QramLowering.cpp` `foldVolatileConstGlobalLoads`: `G.hasImplicitSection()`. The comment says
the pragma's attributes are ones *"which the backend honours"*.

LLVM honours a `#pragma clang section` attribute only when the object's section KIND matches. The check
is in `TargetLoweringObjectFile::SectionForGlobal`, for example `"bss-section" && Kind.isBSS()` and
`"rodata-section" && Kind.isReadOnly()`. Clang, however, attaches the attribute to every global defined
under the pragma.

| probe | object | where it lands (`llc` + `llvm-objdump -t`) | S | R4 | pragma-free twin |
|---|---|---|---|---|---|
| `ps1` | `#pragma clang section bss="__DATA,__mybss"` + `static volatile int K = 7;` | `__DATA,__data` | DECL `control flow` | ACC, TRACE-IDENT | ACC |
| `ps2` | `#pragma clang section rodata="__TEXT,__myro"` + `static volatile double huge = 1e300;` | `__DATA,__data` | DECL `control flow` | ACC, TRACE-IDENT | ACC |
| `psC` (control) | the same pragmas on a zero-init `Z` and a `const volatile` `R` | `__mybss` / `__myro` | — | — | — |

The owner's condition is *"NOT placed in a named section"*. `K` and `huge` are not placed in one, so this
is an over-decline where the twin accepts. It is P3 because it is rare: it needs a `#pragma clang section`
whose kind the object does not have. Deciding the kind exactly needs a `TargetMachine`, and the
conservative refusal is defensible.

The owed fix is to the source comment and to §R5.3: say "conservative: any pragma attribute, whether or
not its kind matches". The current wording, "the backend honours", is false for these two.

## F-Z-3 (P3, instrument; bd `test_C_libtooling-18a7`). r4B's `all.sh` argument table is dead under `/bin/bash` 3.2

`declare -A` fails on macOS `/bin/bash` 3.2.57 (`line 4: declare: -A: invalid option`, the first line of
both the round-4 and round-5 verdict files). Every subscript of `ARG` then evaluates to index 0, so every
r4B probe runs with argv `1`, not with its table value or the default `5`. Measured:
`t1e -> 1, c1_stack3 -> 1, g_as -> 1`.

The r4 and r5 verdicts are still comparable because both ran the same way. The recorded argument of every
r4B twin pair, however, is not the one the script states. Record-only.

---

## Attack results that held

1. **The byval, pointer and nested-byval rows (91k9).** I re-ran r4A's `results.sh` under bash on S. The
   ONLY rows that differ from the round-4 original are:
   - `bv [S]`: run 139 → 5, 2 → 8 lines;
   - `bvn2 [S]`: 139 → 5, 2 → 18;
   - `pn`'s S call: `nonnull null` → `nonnull %3`.

   The binary line changes too. My run is byte-identical to the implementer's `r5_r4A_results.txt`.
2. **Attack 2, the attribute allowlist.** Clang 19 `-O1` on x86-64 Darwin emits exactly `noundef`,
   `signext` and `zeroext` on int/fp params and call sites, for every scalar type (`probes/csrc/attrs.c`:
   `_Bool` … `__int128`, `_Float16`, `long double`). All are allowlisted, and `nofpclass` (fast-math) and
   `range` are too. There is no C-level int/fp over-decline from the attribute list.

   The `k19`-shape family with slot types `_Bool`, `signed char`, `unsigned char`, `short`,
   `unsigned short`, `long long`, `int`, `float`, `double` and `long double` is TRACE-IDENT to its twin on
   S and on R4. All of these are claimed by the PRE-spec drop.

   A narrow-int POST-spec slot (IR, `ns_{sc,us,b}.ll`) declines on all three binaries at the pre-existing
   spec wall `floating-point quantum argument … no reversible copy`, the same one shipped as
   `control_classical_call_arm_reject_onward_spec_i16arg.ll`. So round 5's new step-1 decline has no
   narrow-int customer.
3. **qce6.** I re-ran r4B's `all.sh` on a scratch copy under bash. The only rows that moved from round 4
   are `g_as`, `s1_pragma`, `s2_pragma_val`, `s4_pragma_bss`, `i_dsect` and `i_relro` (SUBJ/NOFREE/LIFO:
   ACCEPT → DECLINE), plus their two twin-pair lines, which now read `(no trace pair)`. My file is
   byte-identical to the implementer's `r5_r4B_verdicts.txt`, apart from the path in line 1.
4. **The openlibm `static volatile` idiom still folds.** `ctest -R` over all 19 `e2e-slice-libm-real-*`
   slices whose source has `static volatile` (acos, acosf, asin, atan2, atan2f, atan2l, cosh, coshf, erf,
   erfc, erfcf, erff, exp, exp2, exp2f, exp2l, expf, sinh, sinhf), plus `e2e-census-slice-sync`: **20/20
   passed**. The goldens are unchanged since round 4, so the fold's behaviour is unchanged on them.
5. **The L2 sibling of qce6.** No other stage reads a global's initializer for a volatile access:
   - `Fp80Union`'s `isConstGlobalFpLoad` requires `isSimple()`;
   - the alloca folds are function-local;
   - a quantum-indexed read of a `volatile`, `section`-ed table (`qr1.c`) declines `cq taint escape` on S
     and on M.

## What I did NOT attack

- **No corpus sweep, no mutation matrix, no build of a fix.** F-Z-1's fix direction is argued, not built.
- **Module-level `musttail` into a clone with a quantum operand**, i.e. the new step-1 decline's own
  over-decline. `mt2` (int return) dies at `cq taint escape: quantum value returned …` on all three
  binaries. `mt3` (void) has its no-op call removed. I found no C spelling that reaches it.
- **A `naked` or string-attributed clone slot, and a vector (`<2 x float>` struct-by-value) quantum
  operand** in an ineligible slot.
- **The M-C (d0) / M-A `cloneArgReachesResult` consumers.** They still ask the bare `isRecordedDeadSlot`,
  while liveness now asks `isRewritableDeadSlot`: two answers for one slot, L3's shape. I found no stream
  consequence, but did not construct one for a slot that is ineligible and recorded dead.
- **Depth ≥ 3 nests, fp-ABI clones through `musttail`, and `-g` variants of `mt1`.**
- **`absolute_symbol` / address-space spellings beyond r4B's own probes.** The address-space conjunct is
  an owner decision.
