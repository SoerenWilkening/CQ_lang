# `eqpx_reproducers_r1` — the ROUND-1 LENS's programs (session `7bbdb89e`, 2026-09-06)

The bd `test_C_libtooling-eqpx` investigation (session `82e6b530`) shipped **43** reproducers,
copied at `../../session-82e6b530/eqpx_reproducers/`. THIS directory is the **round-1
adversarial lens's own corpus**, built independently on top of them while reviewing the fix
(the consumer tripwire at `lowerOps` Phase 1 — notes §3.16). It is kept because two of its
findings are RECORD, not just verification:

* the class has **15 more measured members** than the investigation's census found, and
* **two of them were never a silent miscompile at all** — at i8/i16 the same defect is a
  BROKEN MODULE and a hard abort, which is a different (and louder) failure face.

Read the whole lens report in `../review_eqpx_r1.md`; this file is the index.

## How to run one

    W=<your work dir> <harness>/run.sh <this dir>/x01_cast_short.c <main|fix> [<...>/tu_extf.c]

Every program that calls an `ext_*` function is a TWO-TU program and needs that function's
one-line definition as the extra TU (the harness `llvm-link`s them). **There are exactly two
such symbols in this directory** (MEASURED, `grep -oh 'ext_[a-z_0-9]*' *.c | sort -u`), and
they live in different places:

| symbol | extra TU | which programs |
|---|---|---|
| `ext_f` | `../../session-82e6b530/eqpx_reproducers/tu_extf.c` | 15 programs — `x01`–`x04`, `x08`–`x12`, `x14`, `x15`, `y05`–`y08` |
| `ext_h` | `tu_exth.c` — **here, beside the programs** | 2 programs — `d03_classical_phi_imm.c`, `d05_classical_call_imm.c` |

⚠ `tu_exth.c` was missing from the first publication of this directory, so `d03`/`d05` were not
reproducible from the record (`Undefined symbols … "_ext_h"` at link); found by the round-2 lens
(F-E2-1, `../review_eqpx_r2.md`) and fixed here. `main` = the pre-fix baseline `main`@16b15b3;
`fix` = branch `eqpx-fix`.

## THE 15 NEW MEMBERS — accept on `main` with a rail in the immediate slot, decline on `fix`

Every row RE-MEASURED for this record by `fix_eqpx_b` (`$W/attack_{main,fix}.txt`) on the same
two binaries, independently of the lens's own run; the two runs agree on all 15.
`imm` is `immcheck.py`'s `railInImm` — the count of `cqrt_{xorc,addc}_<W>` calls whose
CLASSICAL-IMMEDIATE operand is a quantum rail handle. Every one declines on `fix` with the
mirrored `cq loop lowering: in-place rail op no longer provable at lowering`.

| program | what makes the immediate quantum | `main` | `fix` |
|---|---|---|---|
| `x01_cast_short.c` | `(int)(short)y` — a CAST off the 6.5 `%out` | ACCEPT 24 lines, **imm=1** | DECLINE |
| `x02_cast_long.c` | `(int)((long long)y & 7)` | ACCEPT 21, **imm=1** | DECLINE |
| `x03_cast_uchar.c` | `(unsigned char)y` | ACCEPT 21, **imm=1** | DECLINE |
| `x04_bswap.c` | `__builtin_bswap32(y)` — a CURATED reversible intrinsic, i.e. a real rail | ACCEPT 21, **imm=1** | DECLINE |
| `x08_break_imm_in_cond.c` | W1 break loop whose derived immediate is ALSO read by the break condition | ACCEPT 223, **imm=2** | DECLINE |
| `x11_phi_imm.c` | a CLASSICAL `phi` of `y&7` / `y&3` | ACCEPT 21, **imm=1** | DECLINE |
| `x12_two_ops_same_imm.c` | TWO rail ops (`r^w`, `r+w`) sharing one immediate | ACCEPT 24, **imm=2** | DECLINE |
| `x14_shift_imm.c` | `(y>>1)&7` | ACCEPT 24, **imm=1** | DECLINE |
| `x15_deep_derived.c` | a 4-hop chain `((y*3+1)^2)&7` | ACCEPT 29, **imm=1** | DECLINE |
| `y05_arm_then_two_loops.c` | one member loop beside one clean loop | ACCEPT 27, **imm=1** | DECLINE |
| `y06_imm_arg_and_out.c` | `(y&7) ^ n` — `%out` MIXED with a function Argument | ACCEPT 24, **imm=1** | DECLINE |
| `y07_add_commuted_derived.c` | **the COMMUTED `add`, from PLAIN C** (`r = w + r`) | ACCEPT 24, **imm=1** | DECLINE |
| `y08_nested_region_loop.c` | an in-body region plus 2 rail ops | ACCEPT 53, **imm=1** | DECLINE |
| `x09_i8.c` | i8 rail, `(signed char)(y&7)` | **rc 134 `LLVM ERROR: Broken module found`** | DECLINE (rc 1) |
| `x10_i16.c` | i16 rail | **rc 134 `LLVM ERROR: Broken module found`** | DECLINE (rc 1) |

### `x09`/`x10` — the BROKEN-MODULE face, which nothing in the record had

MEASURED on `main`@16b15b3 (`$W/out/x09_i8.main.diag`, first four lines):

    Call parameter type does not match function signature!
      %h_op = call i32 @cq_template_and_i8_hl(i32 %h_cast, i8 7)
     i8  call void @cqrt_xorc_i8(i32 %h2, i32 %h_op)
    LLVM ERROR: Broken module found, compilation aborted!

At i8/i16 the in-place ABI's immediate parameter has the RAIL's logical width, so substituting
an `i32` handle for it does not even type-check. **At those widths the class was a loud crash,
not a verify-clean silent miscompile** — the i32 flagship is silent only because the handle and
the immediate happen to share a width there. Nothing in `investigate_eqpx.md` or notes §3.12
records this face.

### `y07` — half of "the commuted spelling is hand-IR-only" is RETIRED

`investigate_eqpx.md` §2 and notes §3.12 say the commuted form is reachable only from hand IR
because `clang -O1` canonicalises the operand order back. That is TRUE of the **wrong-REGISTER**
face and FALSE of the **wrong-IMMEDIATE** face: `y07_add_commuted_derived.c` writes
`r = w + r` in plain C, `-O1` canonicalises it to `r + w`, and the rail op is still marked and
still hands the now-quantum `w` to the immediate slot. So the commuted `add` IS a plain-C
member; only its register-swap face needs the hand-IR fixture
(`lowering_reject_inplace_rail_stale_w2_xor_commuted_handir.ll`).

## THE 20 OVER-DECLINE BOUNDARY CONTROLS — `d01`..`d20`

Purpose-built around the ACCEPT boundary, to catch the widening direction. **All 20 ACCEPT on
BOTH binaries with identical `lines`/`imm` and a byte-identical trace (`cmp` 20/20).
ZERO over-declines.** Re-measured for this record; agrees with the lens.

| program | the immediate class it defends |
|---|---|
| `d01_loopvariant_imm.c` | a LOOP-VARIANT classical immediate (`r ^= i`) |
| `d02_select_two_consts.c` | a `select` of two constants |
| `d03_classical_phi_imm.c` | a classical `phi` |
| `d04_zext_imm.c` | a `zext`ed classical |
| `d05_classical_call_imm.c` | a classical call result, NOT under quantum control |
| `d06_switch_classical_imm.c` | a `switch`-folded classical |
| `d07_i8_const.c` / `d08_i16_const.c` / `d09_i64_const.c` | constant immediates at i8 / i16 / i64 |
| `d10_add_arg_body_gate.c` / `d18_add_const_body_gate.c` | `add` stem with a body gate, Argument / constant immediate |
| `d11_break_const_imm.c` / `d12_break_arg_imm.c` | **W1's own lane** — a break loop with a constant / Argument immediate |
| `d13_two_rails.c` | two independent rails in one loop |
| `d14_region_const_imm.c` / `d15_region_arg_imm.c` | a rail op INSIDE a control region |
| `d16_unrolled_twin_ctlA.c` | the hand-unrolled twin of `ctlA` |
| `d17_global_imm.c` | a global's value as the immediate |
| `d19_preheader_const.c` | **W4's own lane** — a preheader op with a constant immediate |
| `d20_xor_then_add_const.c` | both stems in one loop |

⚠ `d01`, `d05`, `d10`/`d18`, `d11`/`d12`, `d15` are the rows that make the fix's shape a
DECISION rather than a habit: they are exactly the non-Constant classical immediates a
writer-side `isa<Constant>(Imm)` fence would have refused. Their survival is the measured cost
argument for re-asking **G2 alone at the consumer** instead (notes §3.16).

## `b_n02_*` — the evidence for adjudication (B), not eqpx members

`n02_select_merge_xor_noregion.c` (in the 43) keeps a 3-trip loop in its stage-1 module and has
**no loop at all** in the lowered one. These four are the trip-count sweep and the hand-unrolled
twin that show the collapse is PARITY-CORRECT and PRE-EXISTING, not a defect:

| program | K | `cq_template_xor_i32` in `@slice` |
|---|---|---|
| `b_n02_k2.c` | 2 | 0 |
| (`n02` itself) | 3 | 1 |
| `b_n02_k4.c` | 4 | 0 |
| `b_n02_k5.c` | 5 | 1 |
| `b_n02_unrolled.c` | hand-unrolled | trace `cmp` BYTE-IDENTICAL to `n02`'s |

i.e. the circuit realises `r ^ (K odd ? w : 0)`, which is the right value for an xor involution
at every K. The stage is **`unrollConstTripLoops`** (`ir-pass/src/LoopUnrollPrepass.cpp`, wired
at `CQLoweringPass.cpp:271`), confirmed by the lens's mutant M-F. See notes §3.16's
adjudication (B) for why it can never claim an eqpx-member loop.

## The 8 attack programs NOT copied here

They moved nothing and are recorded by name so a future reader knows the ground was covered:
`x05_two_regions`, `x06_arm_in_loop`, `x13_nested_loop`, `x07_switch_sparse`,
`y01_switch_sparse2`, `y02_switch_bare_out`, `y03_two_arms_chain` all DECLINE **identically on
both binaries** (value-arm swap-route / condition-predates-a-gate / X1 / QRAM in-bounds /
control-flow-under-quantum-control), and `y04_imm_from_qram` (a const-global QROM read as the
immediate) ACCEPTS on both at 15 lines, `imm=0`. The three `switch` shapes are the record that
**no 4.5 switch data-mux member could be produced from plain C** — the same result the
investigation reports; the fence is taint-based, so both producers are covered structurally
rather than by example.
