# PASS-2 PREPARATION — the arguments, written BEFORE the binary changes

Per the orchestrator's binding resolution plan (A)–(E) plus the G-4 addendum. Everything here is
measured at the **PASS-1** hash `96d74fe6008133b8` and is **preparation, not a pass-2 result**.

> ⚠ **EVERY SIGNATURE BELOW IS A PASS-1 SIGNATURE AND NONE OF THEM MAY BE PINNED.** The plan requires
> **freshly measured** signatures at pass 2's hash. These are recorded for one purpose: so that a
> signature which *moves* between pass 1 and pass 2 is visible as a movement rather than absorbed
> silently. The **arguments** are what carries forward; the hashes do not.

---

## (B) `q_armoncond` — the re-pin adjudication, and the shape is NOT what pass 1 reported

**Measured past the 2b abort** (`gate/probes/ctlprobe.py`, stage 2b informational instead of fatal):

| | value |
|---|---|
| PINNED in `SURFACE_CONTROL_VERDICTS['void']` | `('TRACE-DIVERGENCE', 'dbf4c162d1de5139')` |
| verdict past the abort | **`TRACE-DIVERGENCE`** — the pinned verdict, unchanged |
| trace lines | rolled **24** == unrolled **24** |
| multiset | **EQUAL** |
| rolled 2b | `4 template rail mint(s) of which 0 left dirty`, `0 violation(s)`, 6 unproven |
| unrolled 2b | `5 … of which 0 left dirty`, `10 verified, 0 unproven` |
| signature past the abort | **`3fa9d45cd851c1b3`** |

⚠ **So `HARNESS-ERROR` was a MASK, not the movement.** Once Track C teaches the checker to prove the
loop-exit discharge, this control will stop erroring and will instead report
**"BOUNDARY CONTROL still diverges but DIFFERENTLY (pinned `dbf4c162…`, got `3fa9d45c…`)"** — still a
hard failure, still a refusal to write, and still the human decision the orchestrator reserved.
**Decision (B) is therefore still owed; it is not dissolved by (A).**

**THE ADJUDICATION, in the three parts the plan requires:**

1. **The track that moved it, BY STRING.** **Group 1's P2** — the loop-exit discharge anchor
   (`Uncomputation.cpp` + `LoopLowering.cpp`), the same change that fixes class A in substance. On the
   ORACLE the rolled side left the hoisted `sitofp → fadd → sqrt` chain's top rail permanently
   allocated; P2 discharges it at the loop exit. The quarantine header already names this control as
   *"an INSTANCE of [class A] rather than a bound on it … the smallest class-A reproducer in the
   tree"*, so a class-A fix moving it is the expected direction, not a surprise.
2. **Old and new verdicts.** `TRACE-DIVERGENCE` / `dbf4c162d1de5139` → `TRACE-DIVERGENCE` /
   `3fa9d45cd851c1b3` (pass-1 measurement; **to be re-measured at pass 2**). The *verdict* is
   unchanged; only the *manifestation* moved.
3. **The per-trip argument that the new verdict is the right circuit.** 24 == 24 lines,
   **multiset-identical**, and the sole divergence is the POSITION of one `cqrt_free(h5)`:

   ```
    cq_template_fcmp_ugt_f64_hl_unc(h5, h3, 0x1.8p+1)
   -cqrt_free(h5)                      <- rolled frees here
    cq_template_sqrt_f64_unc(h3, h2)
    …
    cqrt_free(h1)
   +cqrt_free(h5)                      <- twin frees here
   ```

   `h5` is the compare flag, already returned to `|0⟩` by its own `fcmp_ugt_f64_hl_unc` immediately
   above, so its `cqrt_free` is a proven-`|0⟩` free on **both** sides. The instructions it crosses —
   `cq_template_sqrt_f64_unc(h3, h2)` and `cqrt_free(h1)` — touch **disjoint rails** (`h3`/`h2` and
   `h1`), so the two orders commute and **the unitary is identical**. `0 left dirty` on both sides;
   the rolled side's 6 `unproven` are `U3-extern-rail`, the instrument's stream model, not the rail.
   **The rolled side is no longer the deficient one** — that is precisely what changed, and it is the
   direction the class-A bead wanted.

**Recommendation: RE-PIN**, with this adjudication, once the signature is re-measured at pass 2.
⚠ If the pass-2 signature differs from `3fa9d45cd851c1b3`, **re-derive the argument before pinning** —
a third signature would mean Group 1's fix moved it again and this text would no longer describe it.

---

## (C) + (D) The 15 new divergences — all 15 now probed, and they are NOT one class

12 share one mechanism; **3 do not, and I will not assert an argument for those 3.**

### C-1. The 12 cells the owner's S3 ruling already covers

**Mechanism, measured on every one:** the ROLLED side mints a **fresh flag per trip** (a real
`cq_template_icmp_*` + `cqrt_rz_i1` + `_unc` strip + `cqrt_free`, per repetition); the UNROLLED side's
two textually identical compares are **CSE'd by `-O1` into ONE flag**, with the repetitions' `rz`s
stacked on it (`cqrt_x`-bracketed where the arm is the ¬flag one). This is the owner's S3 ruling in
its own words — *rolled emits a real compare+strip every trip, `-O1` folds the flat twin's; same
unitary* — and the flag is diagonal, minted from the same predicate and stripped to `|0⟩` on both
sides, so the accumulated conditional phase is equal.

| cell | rolled/unrolled | PASS-1 signature (do not pin) |
|---|---|---|
| `m_none_eq_none` | 11 / 8 | `a70745d8b5defa38` |
| `m_none_eq_none_postmark` | 12 / 9 | `a70745d8b5defa38` |
| `m_none_eq_none_premark` | 12 / 9 | `a70745d8b5defa38` |
| `m_none_gt_none` | 11 / 8 | `baa9feb7b9d496b5` |
| `m_none_eq0_none` | 11 / 8 | `4cb084b8b6ee4b49` |
| `m_none_eq_none_bodyread` | 13 / 10 | `960513c78aaa71a3` |
| `m_none_eq_rz` | 11 / 12 | `14ce13d04bde79ca` |
| `m_none_eq0_rz` | 11 / 12 | `9703bcdf2683214a` |
| `m_none_gt_rz` | 11 / 12 | `54b16344134213ae` |
| `m_rz_eq_none` | 11 / 12 | `56a8465f86807eb7` |
| `m_rz_eq0_none` | 11 / 12 | `95b14daff3810081` |
| `m_rz_gt_none` | 11 / 12 | `00cfb6b463b6cf93` |

(Three cells share `a70745d8b5defa38` because their unified diffs are textually identical.)

**Attribution is MEASURED** (`gate/probes/cellora.py`, 3 sampled): the rolled half DECLINES on the
ORACLE with `cq controlled lowering: condition predates a non-diagonal gate` and ACCEPTS on the
combined binary, while the unrolled half already accepted — the `UNROLLED-ONLY → TRACE-DIVERGENCE`
transition, door = **Track D's P4**.

### C-2. ⚠ THREE CELLS WHOSE ARGUMENT I CANNOT WRITE — leave UNQUARANTINED and RED

`m_rz_eq_rz` · `m_rz_eq0_rz` · `m_rz_gt_rz` — exactly the cells carrying **both** the `m_rz` prefix
rotation **and** the `_rz` suffix rotation. Pass-1 signatures `8b1393ee69a8d196`,
`20f2fb03f7452234`, `fbd479cb2d4f0325`.

**They are rolled 11 vs unrolled 22 — the twin has DOUBLE the gates, not one flag fewer**, which is
the opposite of C-1's fold. `m_rz_eq_rz`'s diff:

```
 cqrt_rz_i1(h1, PI)
+cqrt_rz_i1(h1, -0x1p-3)                 <- twin only
 icmp_eq_unc(h1, h0, 5)
 …
 icmp_eq(h0,5) -> h2
-cqrt_rz_i1(h2, PI)                      <- ROLLED only, PLAIN
+cqrt_x(h2); rz(h2,-0x1p-3); cqrt_x(h2); rz(h2, 0x1p-3)   <- twin only, BRACKETED
 icmp_eq_unc(h2,h0,5); free(h2)
+[an ENTIRE THIRD flag group h3: icmp, x, rz(1/8), x, rz(PI), unc, free]   <- twin only
 measure(h0)
```

The twin emits a **third** flag group and `cqrt_x`-bracketed prefix/suffix rotations that the rolled
side does not emit at all. **That is not a fold of identical work — the two sides emit different gate
counts on the flag wire**, and whether the rolled side legitimately folds the `m_rz`/`_rz` rotations
or is **dropping** them is a question I cannot answer from the trace. Asserting "same unitary" here
would be an unearned clearance of exactly the kind Rule 2 forbids.

**Disposition per the plan: these three stay UNQUARANTINED and RED, listed here.** They need either
the owning track's per-trip record or an independent reading before any pin. ⚠ If the rolled side is
dropping the prefix/suffix rotations, this is **not** a quarantine item at all — it is a P1.

---

## (G-4 addendum) The `--allow-unproven` BEFORE baseline

`tests/e2e/slice_loop_hoisted_chain_exit_discharge.c`, STRICT stage 2b at the pass-1 hash:

```
UNPROVEN U3-extern-rail @slice line 21 [%h_intr]: … minted outside it (by @cq_template_sqrt_f64)
UNPROVEN U3-extern-rail @slice line 23 [%h_op]:   … minted outside it (by @cq_template_fadd_f64_hl)
UNPROVEN U3-extern-rail @slice line 25 [%h_cast]: … minted outside it (by @cq_template_sitofp_i32_to_f64)
free_pairing_check: 1 file(s), 2 rail mint(s) of which 2 left allocated,
  4 template rail mint(s) of which 0 left dirty, 4 cqrt_free site(s):
  1 verified, 0 violation(s), 3 unproven
strict rc=1
```

**All three unproven are `U3-extern-rail`** — a handle written in one stream and minted in another,
which is exactly the loop-exit-discharge shape Track C's rule targets (mint dominates the loop,
in-loop uses read-only, adjoint + free post-dominate the exit). `0 violation(s)` and `0 left dirty`
already. **If Track C's rule proves these three, the flag comes off and the count returns to 4.**
If any survives, the U-class to report is named above, per handle and per minting template.

---

## Pass-2 execution order (from the plan, so it is on record before it runs)

1. Merge Group 1's fix tip **and** Track C's `freepair-loop-exit-discharge`; post-union checks;
   L8 duplicate-body scan if fixtures moved.
2. Rebuild BOTH targets; record both hashes — pass 2's identity.
3. **G-4 first** (it is cheap and it gates a CMakeLists edit): re-run the slice's 2b STRICT by hand;
   if `0 unproven`, drop `--allow-unproven` + its reason and record before/after; else leave it and
   name the surviving U-class as a finding **against Track C**.
4. Announce, then: g8 triple · `dD1`/`dD4`/`dD5` · the six `1m5p` class-A cells · `a1_apost` ·
   the `6n1s` triple · the 15 divergence cells **re-signed** · `q_armoncond` **re-signed**.
5. ONE full `ctest -j6`; matrix to GREEN via the header contract (re-pin (B), quarantine C-1's 12,
   leave C-2's 3 red if still unargued); equivalence **only** if a decline string or analysis site
   moved; corpus re-sweep; blast-radius probe half completed or its absence bounded.
