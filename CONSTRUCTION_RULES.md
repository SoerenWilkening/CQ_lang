# CQ construction rules

This document and `examples/` are the specification of the CQ compiler. A compiler is correct when,
for every example, the circuit it emits from `name.c` compiled with `clang -O1` (x86-64) is
semantically equal to `name.lowered.ll` under §6. The lowered files are hand-written witnesses of
these rules; where a lowered file and this document disagree, the document wins and the example is
to be fixed (§7 lists the known cases).

Owner rulings of 2026-10-26 are folded in. Nothing here refers to any earlier implementation.

## 0. Scope and fixed decisions

- **No declines.** Every C program lowers. There is no diagnostic path in the compiler.
  - A quantum call to a function with no body becomes a call to a declared clone (rule 27). If
    nothing linked defines it, the program fails with an ordinary undefined-symbol link error.
  - Cloning cannot arise: every copy the compiler emits is a basis copy (CNOT fan-out).
  - A loop or recursion whose exit depends on quantum data runs for a cutoff **K** (rule 14).
- **Ground truth** for reversible construction is Bennett.jl
  (revision `824458d10e879c3fef673c231a02e5461dac667f`), including its totalization of partial
  operations (§2). Where Bennett.jl has no implementation (f16/f32/f80 arithmetic, `frem`,
  directed rounding, `is_fpclass`) the contract in §2 applies.
- **Garbage policy.** Garbage that compute–copy–uncompute can clean must be cleaned. A rail that
  cannot be returned to a known basis state (entangled by a measurement or by a non-diagonal gate
  on its source) stays allocated. `cqrt_free` accepts any rail in a *known classical basis state*;
  the backend resets it.
- **Measurement** is a backend concern. The spec never simulates outcomes; `cqrt_measure_<W>`
  returns the outcome, and dominated uses of the measured SSA value denote that classical value.
  The call is synchronous: the backend runs the circuit up to the measurement (mid-circuit
  measurement with classical feed-forward) and returns the real outcome. There is no emit-only mode.
- **Quantum rotation angle** is one primitive (`cqrt_ry_<W>_qangle[_controlled]`, `cqrt_rz_qangle[_controlled]`);
  the angle precision **N** (bits of the fixed-point ladder) is a toolchain flag consumed by the
  backend only. The lowered code does not depend on N (§1.3).
- **Loop cutoff K** is per loop. The K of a loop in function `f`, first match wins: a per-loop
  annotation; the per-function compiler flag (e.g. `fmod=2046,sin=53`); a `CQ_K(f, k)` line in the
  translation unit, which `CQ.h` defines as the `used` constant `__cq_k_<f>` the compiler reads; the
  global flag; the built-in default. A lowered library ships a header of `CQ_K` lines with its
  recommended per-function defaults (a build output, e.g. from trip counts measured by running the
  classical functions), included like `CQ.h`. A declared clone (rule 27) receives its K as a
  classical run-time argument, so one lowered library serves every choice of K. The corpus fixes
  K = 4 (lines tagged `[K]`). **The built-in default is 4** (the corpus value; a real program sets
  its K by flag or `CQ_K`). The per-loop annotation has no syntax yet (`CQ.h` defines none); until
  it does the chain is flag → `CQ_K` → global flag → default, and when it is added it will be a
  marker in the loop body, never a pragma (2026-10-27).
- **Target**: x86-64 only. **Optimization level**: `-O1` only.
- **Retired**: the whole `cq_template_*_inv` family and the controlled arithmetic grid. The
  template surface is forward + `_unc` (§1.2); the core keeps the few controlled gates in §1.3.
- **No simulator.** Equivalence is decided by §6.
- **The circuit is generated at run time.** The lowered program is an ordinary host program;
  executing it emits the gate sequence. Classical values known only at run time (loop bounds,
  QROM tables, host addresses, pushed per-trip values, classically computed angles) parametrise
  the circuit. A backend is therefore a circuit builder driven by the host execution, not a
  static translator of the lowered IR.

## 1. ABI

### 1.1 Handles and namespaces

Every quantum value is an `i32` **handle** to a rail whose logical width is the IR type's width
(`i1`, `i7`, `i8`, …, `i128`, `f16`, `bf16`, `f32`, `f64`, `f80`; any `N ≥ 1` is legal, `_BitInt`,
`__bf16` (bfloat16: 8 exponent bits, 7 fraction bits, same rounding and NaN rules as the IEEE
widths) and the x87 bit pattern included; `fp128` is unreachable from C on this target, rule 25). An aggregate, vector or fat pointer is a literal struct of handles
and classical values in field order. Narrow handle arguments carry the C ABI's `signext`/`zeroext`
only at externally visible signatures.

Three symbol namespaces, never mixed:

| prefix | meaning |
|---|---|
| `cq_*`, `__cq_*` | the user surface in `CQ.h` (`cq_theta_*`, `cq_measure_*`, `cq_phi`, `__cq_invert_begin/end`) |
| `cqrt_*` | core gates and backend primitives (§1.3) |
| `cq_template_*` | generated out-of-place reversible operations, each with an `_unc` twin (§1.2) |

### 1.2 Template grammar

```
template := "cq_template_" op ["_" pred] "_" W ["_to_" W2] ["_" shape] ["_rm" | "_rmq"] ["_exc"] ["_unc"]
op       := add sub mul udiv sdiv urem srem and or xor shl lshr ashr
            fadd fsub fmul fdiv frem fneg icmp fcmp fcmps select
            zext sext trunc fpext fptrunc sitofp uitofp fptosi fptoui bitcast
            fma fshl fshr abs ctlz cttz ctpop bswap smax smin umax umin uadd_sat usub_sat
            {u,s}{add,sub,mul}_overflow fabs copysign fmax fmin floor ceil trunc rint round sqrt
            is_fpclass qrom_load qrom_load_s
pred     := an icmp/fcmp predicate. A compare with the literal on the left is spelled by flipping
            the predicate; compares never take _lh.
W        := i<N> | f16 | bf16 | f32 | f64 | f80 ; casts spell <from>_to_<to>
shape    := one letter per DATA operand in signature order, h or q = handle, l = literal;
            omitted = all handles. Binary ops: _hl, or _lh for a non-commutative op only
            (a commutative op swaps its operands to _hl; for an fp op only when the literal is not
            a NaN, else it is spelled _lh). _ll: a binary op whose only quantum operand is the
            _rmq mode. select: the two ARMS (hl, lh, ll);
            the condition is always a handle. Ternary: every mix of q and l over the three operands,
            bare for qqq; for fma the product operands are commutative and lqq, lql are spelled qlq, qll
            unless the literal is a NaN, which keeps its position (as for binary ops); fshl and fshr are
            not commutative and keep every mixed shape (lqq, lql, llq included).
_rm/_rmq := rounding mode appended as the LAST argument (i32 literal / handle), the x86-64 FE_*
            value: bits 10-11 select 0 nearest-even, 1 down, 2 up, 3 toward zero; other bits ignored.
_exc     := the same operands; the fresh i32 result rail holds the x86 exception bits the operation
            raises: INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32 (no DENORMAL);
            tininess after rounding, UNDERFLOW only together with INEXACT; a quiet NaN operand
            raises INVALID only in fcmps, conversions to integer and invalid arithmetic.
qrom     := qrom_load_<W>(ptr base, i64 n, idx) reads element idx of n little-endian elements of
            the type's ALLOC size (f80: 16 bytes); qrom_load_<W>_s(ptr base, i64 n, i64 stride, idx)
            uses a stride in bytes (an array-of-struct field, 78).
```
`trunc` with `_to_` is the integer cast, without it the fp rounding op. A rail may fill several
operand slots of one template (112 `fshr_i32(%5, %5, %6)`); the result rail is always fresh.
Runtime declarations may carry `signext`/`zeroext`; the backend reads only the low W bits of a
narrow operand either way.

Forward form: returns the fresh result handle, computed into a `|0⟩` rail.
`_unc` form: `void`, arguments `(out, <exactly the forward argument list, same literals>)`;
returns `out` to `|0⟩` by recomputation. Literals carry the LLVM operand type (`i1 true`,
`i128`, `double`). Every template is a total function of its operands (§2).

### 1.3 Core gates (`cqrt_*`)

Control flag is always argument 0 of a `_controlled` form. `_unc` of an in-place core gate takes
the same arguments.

```
alloc_<W>(lit) -> h               fresh rail in basis state |lit>
free(h)                           reset; h must be in a known classical basis state
measure_<W>(h) -> value           projective measurement; h is never freed; afterwards it holds the outcome (a known basis
                                  state) and may still be read as an operand or control, never rotated again
ry_<W>(h, θ)                      Ry(θ) = exp(−iθY/2) on every qubit of h; non-finite θ = identity
ry_<W>_controlled(c, h, θ)
ry_<W>_qangle(h, A)               Ry(val(A)) on h, val(A) the IEEE f64 the angle rail A holds. The backend
                                  reduces val(A) exactly mod P (4π for Ry, 2π for a phase), rounds it to
                                  nearest-even onto the grid P·k/2^N, and ladder bit i fires P·2^(i−N);
                                  non-finite = identity
ry_<W>_qangle_controlled(c, h, A)
rz_i1(f, θ)                       the phase gate P(θ) = diag(1, e^{iθ}) on the flag f (the name says rz; it is P)
rz_qangle(A)                      the phase e^{i val(A)} on each basis branch of A (rz_i1's P(θ) with a quantum θ)
rz_qangle_controlled(c, A)        the same phase on the c = 1 branch only
not_i1(h)                         X
and_i1(a, b, t)                   t ^= a & b          (Toffoli)
or_i1(a, b, t)                    t ^= a | b
xor_i1(a, t)                      t ^= a              (CNOT)
copy_<W>(s, d)                    d ^= s              (unconditional XOR, an involution; d need not be |0>)
copy_<W>_controlled(c, s, d)
xorc_<W>(h, lit), xorc_<W>_controlled(c, h, lit)
qram_alloc_<W>(n) -> a            n cells, all |0>; n classical (a quantum size allocates at its upper bound)
qram_realloc_<W>(a, n) -> a'      the same object with LOGICAL size n (a quantum n: its upper bound): no gate, no cell
                                  moves; shrinking hides the cells >= n (still physically allocated, out of range by
                                  §2); growing maps the new logical indices to FRESH |0> cells, never to cells a shrink
                                  hid (C's grown part is indeterminate = 0, §6). The hidden cells stay allocated until
                                  the _unc chain re-exposes them for their pops, or the object is kept (§0). a' replaces a for every later access.
                                  _unc(a', n_old) restores the old size, after every store made through a' was popped;
                                  a pop is evaluated at the logical size its forward store saw
qram_store_<W>[_hl][_controlled]([c,] a, idx | j, v)
                                  each store owns a fresh W-qubit tape slot t: t <-> cell[idx] (swap the displaced cell
                                  out), then cell[idx] ^= v (a copy; v unchanged). _controlled: under c = 0 nothing
                                  happens and t stays |0>. _unc (same arguments): cell[idx] ^= v, t <-> cell[idx], t is
                                  |0> again and released. PRECONDITION of the pop: v, idx and c hold their forward
                                  values (a store whose value rail is later rotated or measured cannot be popped: the
                                  object stays allocated, §0). Pops are ordered last-in-first-out only among stores that
                                  may touch the same cell; stores to provably different cells commute. Unpopped
                                  stores keep their tape slots allocated (a Kept item). A `_unc` pops the most
                                  recent unpopped slot whose (a, idx | j, v[, c]) are the same rails/literals
qram_load_<W>[_hl][_controlled]([c,] a, idx | j) -> h        h ^= (c ? cell[idx] : 0) (fresh h; cell unchanged); _unc(h, [c,] a,
                                  idx | j) requires the cell to hold the value it had at the load
qram_free(a)                      after every store was popped
                                  idx = quantum index rail: the QRAM query (address decoding is the backend's
                                  circuit, never per-cell code in the IR); _hl j = direct cell access: no address
                                  decoding, O(W) gates, constant depth; _hl accesses to different cells commute
tape_alloc() -> t
tape_fmt[_controlled]([c,] t, fmt), tape_effect_controlled(c, t, name)
tape_write_<W>[_controlled]([c,] t, h) -> h', tape_write_<W>_lit(t, lit), tape_write_str_lit(t, s)
abort_i1(f)                       kept flag, measured at the end of the shot
push(w), pop() -> w               compiler-internal classical i32 word stack; not a circuit primitive; a wider
                                  classical value is pushed as i32 words, low word first, popped in reverse
```

Retired spellings: `cqrt_x`, `cqrt_cnot`, `cqrt_toffoli` (use `not_i1`, `xor_i1`, `and_i1`), `cqrt_phase_f64[_controlled]`
(use `rz_qangle[_controlled]`), `cqrt_measure_<W>_controlled` (a measurement is never conditioned), `ry_<W>_qangle(A, h)` argument order (now `(h, A)`),
`cqrt_rz_<W>`, `cqrt_ry_*_controlled_inv`, `cqrt_cswap`, every `*_inv` template.

The tape and the abort flag follow the deferred-measurement model: tape rails and abort flags are
never freed. All tape entries and abort flags form ONE event sequence in call order. At the end
of the shot (process exit: return from `main`, `exit`, or an `atexit` handler the backend registers;
a classical `_Exit` loses the tape as it loses unflushed stdio) the backend measures them and
performs, in sequence order, each entry whose predicate read 1 and that no earlier abort flag
reading 1 precedes: a format entry prints, an effect entry performs the host call with the recorded
arguments. Strings are copied at call time. An in-place target is never one of its own controls.

### 1.4 Clone naming

```
clone := "__cq_q_" fn "_" mask [ "_b" bound { "_" bound } ] [ "_ctl" ] [ "_pure" ] [ "_adj" ] [ "_d" depth ] [ "_unc" ]
mask  := one digit per FIELD of the clone's formal list, LEFT TO RIGHT, 1 = quantum, 0 = classical.
         A scalar parameter is one field; an aggregate or pointer-to-slot parameter contributes
         one digit per field it carries (159 `shift_110`, 163 `mk_00010`, 129 `bump_1011`); a
         field's digit is 1 iff the cell holds a handle AT THE CALL (a cell the callee makes
         quantum is 0 and is a slot result); a pointer passed as a fat-pointer triple
         `(object, tag, idx)` contributes a tag digit and an idx digit (the object none), followed by
         one digit per pointee cell the callee accesses (1 iff it holds a handle at the call;
         107 `bump_0011`; QRAM cells get no digits: a QRAM object is quantum by definition, 191
         `addto_0001`); a pointer to a runtime-length register (`bool x[n]`)
         is one digit, 1 iff any cell holds a handle (117 `grover_1000_ctl`); a
         variadic clone is specialised per call-site arity and a dead formal is passed as poison.
         The compiler-added object-table parameter of a fat pointer gets no digit.
_ctl   := the clone takes the block predicate as its FIRST parameter and controls every gate.
_pure  := the clone without its phase effects (what the twins recompute through).
_adj   := the adjoint of a void in-place clone (rule 17).
_dK    := recursion depth clone (rule 14).
_bN..  := one upper bound per quantum integer argument whose range facts at the call site bound it
          (`memcmp(.., x & 3)` -> `_b3`); a clone's loop cutoffs use only these bounds and its own range
          facts (rule 14), never a bound of one particular call site that is not in its name.
```
Reading a clone name is right to left: the suffix words, then the `_b` bounds, then the mask (the
rightmost token of binary digits), and `fn` is whatever remains; that reading is normative. A name
with bounds is internal to its module (rule 27 clones carry none), so the compiler never binds a
clone by re-reading its name: the clone table is keyed by the clone's fields, and a function is
created with a uniquifying constructor so that two distinct clones whose names would coincide (a
`fn` that itself ends in `_<binary>_b<N>`) get distinct symbols (ruling 2026-10-27).

Result: one `i32` handle per quantum scalar result regardless of width, the C type for a classical
result, a literal struct of scalar fields in field order for several results (a nested aggregate is
flattened: 166 returns `{ i32, i32, double }`). Twin:
`_unc(outs…, args…, old slot handles in slot order)`, `void`. A twin nobody calls is not defined.
The original (unlifted) body is kept only while a classical call site still uses it; a callee whose
every call was retargeted is dropped.

## 2. Totalization table

The classical reference evaluator (§6) and every backend use the same table.

| operation | out-of-domain input | result |
|---|---|---|
| `udiv(a, 0)` | | `2^W − 1` |
| `urem(a, 0)` | | `a` |
| `sdiv(a, 0)` | | `−1` if `a ≥ 0`, else `+1` |
| `srem(a, 0)` | | `a` |
| `sdiv(INT_MIN, −1)` | | `INT_MIN` |
| `srem(INT_MIN, −1)` | | `0` |
| `shl/lshr/ashr(a, k)` | `k ≥ W` (literal or quantum amount) | amount taken mod W (x86 semantics) |
| `fshl/fshr` | | amount mod W |
| `fptosi/fptoui` from f16/f32/f64 | NaN, ±Inf, out of range | as x86-64 LLVM 19 `-O1` code (measured 2026-10-27; f16 via f32): let `c32(x)`/`c64(x)` be cvtt to i32/i64 with indefinite `INT_MIN` of that width. `fptosi` i8/i16 = trunc(c32), i32 = c32, i64 = c64; `fptoui` i8/i16 = trunc(c32), i32 = trunc(c64), i64 = `r1 \| (r2 & (r1 >>s 63))` with `r1 = c64(x)`, `r2 = c64(x − 2^63)`. E.g. NaN → s8 0, s32 `INT_MIN`, u32 0, u64 2^63; 300.0 → s8 44 |
| `fptosi/fptoui` from f80 | NaN, ±Inf, out of range | x87 `fistp` with indefinite `INT_MIN` of its width: s8 = trunc(fist16), s16 = fist16, s32 = fist32, s64 = fist64; u8/u16 = trunc(fist32), u32 = trunc(fist64), u64 = `x < 2^63 ? fist64(x) : fist64(x − 2^63) ^ 2^63` (NaN → 0) |
| `fadd fsub fmul fdiv frem fma sqrt …` NaN result | | x86 SSE rule in IR operand order: the first NaN operand, quieted; an invalid operation (`frem` by 0 or of ±Inf included) gives the default NaN `0xFFF8000000000000` (f32 `0xFFC00000`, f16 `0xFE00`). Where native x86-64 `-O1` code leaves the choice to register allocation or to the libm vendor (two-NaN commutative `fadd`/`fmul`, `frem` and `fma` through libm), this row is normative, and the C oracle of §6 compares floating-point values NaN-insensitively (any NaN equals any NaN); the reference oracle compares bit patterns (ruling 2026-10-27) |
| `fmax(a, b)` / `fmin(a, b)` (`llvm.maxnum/minnum`) | | `isnan(a) ? b : isnan(b) ? a : (b > a ? b : a)`, min with `<`; equal values (±0) give `a`; two NaNs give `b` unchanged (x86-64 `-O1`, measured) |
| f80 non-canonical encodings | pseudo-NaN, pseudo-Inf, unnormal | invalid operand: result real indefinite `0xFFFF_C000000000000000`, INVALID; pseudo-denormals read as denormals (x87) |
| `fadd fsub fmul fdiv sqrt fma` | | IEEE, round to nearest even unless `_rm/_rmq` says otherwise |
| `llvm.fmuladd` | | unfused: `fmul` then `fadd`, each rounded (the x86-64 baseline has no FMA unit, so the classical program rounds twice); only `llvm.fma` is fused |
| `frem(x, y)` | | IEEE `fmod`: sign of `x`; `fmod(x, 0)` = NaN; `fmod(±Inf, y)` = NaN; `fmod(x, ±Inf)` = `x`; NaN propagates |
| `f16/f32/f80` arithmetic | | IEEE binary16 / binary32 / x87 extended, same rounding rule |
| `ctlz(0)`, `cttz(0)` | | `W` |
| `abs(INT_MIN)` | | `INT_MIN` |
| `rint`, `round`, `floor`, `ceil`, `trunc` | | IEEE; `rint` ties to even |
| `is_fpclass` | | pure bit test |
| `ry`/`rz`/`phase` with a non-finite angle (literal or angle rail) | | identity |
| `qrom_load`, `qram_load` | index `≥ n` (UNSIGNED reading of the index rail at its width; a `_hl` literal likewise) | `0`; no cell is read |
| `qram_store` | index `≥ n` (unsigned reading, as above) | no-op (its tape slot stays `|0⟩`) |

## 3. Construction rules

Each rule names its witness examples. "Fresh" always means a `|0⟩` rail allocated for the result.

1. **Handle ABI.** Every quantum value is an `i32` handle (§1.1). Aggregates, vectors and fat
   pointers are tuples of handles and classical values; a template exists for every width on
   demand. — 01, 46, 64, 93, 103, 110, 111.

2. **Source and sink.** `cq_theta_*(v, θ)` on a classical `v` mints `alloc_<W>(v)` then
   `ry_<W>(h, θ)`; on an existing handle it rotates that rail in place. `cq_measure_*` is
   `measure_<W>(h)`; the rail stays allocated; dominated uses of the measured SSA value denote the
   outcome; a re-measurement of the same rail is a classical re-read. A measurement inside a
   quantum arm is never conditioned on quantum data: it is executed unconditionally at its
   program point, so the measured register is collapsed on every branch (a deviation from the C
   program that is the user's responsibility; the compiler may warn, it never declines). The arm
   flag is never measured. The outcome merges with the other incoming values by `select` under the
   flag, so the value the C program reads is tainted (§0). Measurements of one rail in several
   arms are one measurement (the later ones are classical re-reads). **Classical collapse:** a
   value computed only from measured rails and classical values is classical: its rail (a flag
   too) is uncomputed while its sources still hold the outcome, and the value is recomputed by
   ordinary classical instructions from the outcomes; a merge under such a flag is a classical
   `select`. — 01, 38, 42, 120, 128, 136, 140, 155.

3. **Taint propagation.** Forward over SSA. Through memory per rule 20, through calls per rule 18,
   through pointers per rule 21. The angle operand of a rotation is classical unless rule 15
   applies. Casts, `freeze`, `insertvalue`/`extractvalue`/`shufflevector` on handles are
   representation changes and emit no gate for lane moves. — 17, 18, 26, 56, 63, 103.

4. **Opcode lowering, always out of place.** A tainted opcode becomes
   `cq_template_<op>[_<pred>]_<W>[_shape]` into a fresh rail (§1.2). A classical operand is a
   literal (`_hl`/`_lh`); a commutative op puts the handle first. `*.with.overflow` and `cmpxchg`
   are two templates over the same operands. There is no in-place template; in-place is reserved
   for rule 2 (rotation of an existing rail), rule 9 (controlled Ry) and `xorc` on a basis-state
   seed. — 10, 11, 13, 14, 56, 92, 94, 112, 130.

5. **Uncompute spine.** Every rail that is not a user register, a result, a tape/abort rail or an
   output is uncomputed by its producer's `_unc(out, operands…)` and freed. Order: reverse
   dependency order (a rail is uncomputed before every rail its producer read, and an operand rail
   outlives every `_unc` that reads it); rails with no dependency between them uncompute in any
   order (they commute). Scheduling invariant: a garbage rail is uncomputed after its last
   consumer and before any non-diagonal gate on any of its sources. Convention for the examples
   (not a requirement): uncompute as early as the invariant allows. — 02, 04, 07, 20, 66, 118.

6. **Bijective update of a dead value.** When `y' = f(y, …)` is a bijection in `y` for the other
   operands and `y`'s old value is dead, the old rail is cleaned: compute `t = f⁻¹(y', …)` fresh,
   `copy_<W>(t, y_old)`, `_unc` of `t`, free `y_old`. When the old value is still needed to
   uncompute other rails, those are uncomputed first and then this rule applies. — 125, 127
   (to be rewritten as the two witnesses).

7. **Seed rails.** A rail minted from a classical constant or parameter and never written is in a
   known basis state and is freed directly (§0 free policy). — 25, 28, 57, 62, 94, 95.

8. **Branch flags.** A tainted `br` condition becomes a flag rail: the compare template's result,
   or the bare `i1` rail. A conjunction of flags is `and_i1` into a fresh `|0⟩`; a disjunction
   `or_i1`; a flag used as data is the `cq_template_and_i1`/`or_i1` form. The false edge is an
   X bracket (`not_i1`) on the flag. A phase arm is `rz_i1(flag, θ)`. A mixed condition is first
   factored as `C && Q` on its Boolean function (not its syntax: -O1 may spell `c && q` as two
   branches or as one `and i1`), where `C` is the conjunction of every classical term that is a
   conjunct of the whole condition and `Q` is the rest. `C` stays a classical branch around the
   quantum part (23 `cond_mixed`, 180). `Q` is one flag: a classical `i1` term inside it that cannot
   be factored out (`c || q`, Annex G's `isnan` tests) becomes a seed rail (rule 7) and joins by
   `and_i1`/`or_i1` (ruling 2026-10-27).
   A purely classical condition is always a classical branch, also inside a clone; a clone body is
   never flattened as a whole. The flag is uncomputed after its last controlled gate. — 03, 08,
   21, 23, 59, 69, 137, 138, 146, 154.

9. **Value arms.** Pure arm code is hoisted and computed unguarded into fresh rails; the merge
   (`phi` or `select`) is one `cq_template_select_<W>[_shape]` per distinct incoming, chained with
   the complement arm innermost, into a fresh rail; arm rails are then uncomputed. No other merge
   spelling. Nested value arms nest their selects; a conjunction flag is needed only where a
   phase or in-place gate sits in the inner arm, never for a pure select. — 04, 20, 21, 22, 24,
   49, 123, 135, 143, 148, 158.

10. **Controlled Ry and state prep.** A `phi` of `cq_theta(v, θ)` against `v` (or two thetas of one
    seed) is `ry_<W>_controlled(flag, rail)` on a rail seeded with `v`; `r = c;` before the prep
    adds `xorc_<W>_controlled`; a second prep of a rail nothing read in between undoes the first by
    its adjoint under the conjunction flag. The rotated rail is frozen (never reverse-played). A
    flag that read the rotated register stays allocated. — 39, 66, 120, 125, 133, 141.

11. **Angle select is a quantum angle.** An angle that depends on quantum data in any way (a
    `select` or `phi` on a quantum flag, a `switch` over a quantum scrutinee, a table read at a
    quantum index, arithmetic on a register) is computed into an `f64` rail by ordinary templates
    (`select_f64[_ll|_hl|_lh]`, `qrom_load_f64`, arithmetic) and consumed by rule 15's single
    primitive. The compiler never expands it into per-arm controlled rotations; the ladder is the
    backend's. — 132, 141, 142.

12. **Phase deletion.** `cq_phi(θ)` is deleted only when no quantum predicate is in scope at any
    call depth. Inside a `_ctl` clone or a callee reached from a quantum arm it is
    `rz_i1(pred, θ)`. Under a purely classical condition at top level it is a global phase and is
    deleted. — 41; new example required (§8, item 3).

13. **switch.** One equality flag per reachable case on the scrutinee; a shared or fallthrough
    block gets `or_i1` of its edge flags; an `unreachable` default gets no flag, and then the last
    case needs none either: it is the complement of the others and becomes the innermost select
    arm; a reachable default is the complement of the case flags. Value arms merge per rule 9, phase arms per
    rule 8. — 22, 49, 123, 131, 142; new example for a reachable default (§8).

14. **Loops.**
    - *Classical bound, quantum body*: the loop stays a classical loop. Each trip computes next
      values into fresh rails and pushes every trip-local rail (and any classical per-trip value
      not expressible from the trip index) on `push`; after the result is copied out
      (`alloc` + `copy`) a reverse loop pops and uncomputes each trip. An array (slot cells or
      QRAM) the loop writes and the program reads afterwards is not copied out: the reads use it in
      place, and the reverse loop runs after those readers are uncomputed, restoring each trip's old
      slot handles or popping its stores (187, 188). — 25, 27, 28, 57, 62, 131, 187, 188.
    - *Quantum-dependent exit, cutoff K*: the loop is re-rolled so the pre-header guard is trip 0
      of the latch test (equality by SCEV); it runs exactly K trips under the predicate chain
      `a_j = a_{j−1} & cond_j`, seeded `|1⟩` (or the arm flag when the loop sits in an arm); every
      carried value advances by a `select` on `a_j`; the mirror pops K trips. **The overflow
      predicate is kept as an output rail**: `a_K` denotes the result of the exit test evaluated
      after the K-th body (`a_{K−1} & cond_K` for the test that would admit a (K+1)-th trip), so
      `a_K = 1` iff the loop would run another trip (non-convergence is observable, and a loop that
      exits after exactly K trips reads 0). The cutoff of a loop is min(K, B) where B is an upper bound
      of its trip count from LLVM's range facts (`i < (x & 3)`: B = 3); `a_K` is kept only when B > K
      or no bound is known (91). The K-th trip's own body predicate is not `a_K`; it is
      uncomputed by the mirror like every earlier one. A test-at-bottom loop (`do … while`) runs
      trip 0 under the `|1⟩` seed and computes `a_{j+1}` after the body (150).
      Where -O1 tests at the loop header with no pre-header guard (09, 37, 54, 189) a trip is test then
      body, and the last chained predicate already is the test admitting trip K+1: it is `a_K`. A loop
      seeded by an arm flag `F` tears `F` down by its compare's `_unc` after the chain, never as a
      seed (153). Nested K-loops keep one inner `a_K` per outer trip plus the outer one (68, 153). A
      carried value whose exit `phi` -O1 folded to a literal is copied out from the carried rail
      (149). — 05, 09, 37, 53, 54, 55, 68, 87, 149, 150, 151, 152, 153, 169, 189.
    - *Classical bound with a quantum exit* (`for (i = 0; i < n; i++) if (q) break;`, a mixed exit
      `c_classical || q`): no cutoff applies. The loop is a classical loop over the classical bound,
      `q` feeds the predicate chain, and **every** predicate, the last included, is a function of
      the inputs and is uncomputed by the mirror. Nothing is kept. — 26, 121, 130, 139.
    - *Recursion with quantum depth*: one clone per level `_d1.._dK`; the call at level K is
      replaced by a `|0⟩` rail; the depth cutoff is min(K, B) like a loop's, and the kept overflow
      predicate is "the cut level would recurse once more" (0 on every branch when B ≤ K). — 98.
    - `continue`, `return` inside a K-loop, nested K-loops: same chain, inner chain seeded by the
      outer trip predicate. New examples required (§8).
    - *Irreducible control flow* (a `goto` into a loop body, Duff's device) has no construction of
      its own: the compiler first makes every cycle a natural loop (LLVM's `fix-irreducible`, a
      semantics-preserving CFG rewrite that adds a dispatch header and one carried state value) and
      applies the cases above to the result; the dispatch value is a carried value like any other.
      §6 compares semantics, never CFG shape. New example required (§8, 2026-10-27).

15. **Quantum angle.** An angle derived from a register is computed into an `f64` rail by ordinary
    templates and consumed by one primitive: `ry_<W>_qangle[_controlled]([c,] h, A)` for `cq_theta`,
    `rz_qangle[_controlled]([c,] A)` for `cq_phi`. The angle rail is uncomputed afterwards. The backend
    supplies the N-bit ladder. — 79, 143.

16. **Noreturn arms and host effects.** Calls the compiler does not lift are classified:
    - pure classical call (no side effect, no quantum argument): ordinary call;
    - side-effecting host call under a quantum predicate (`printf`, `puts`, `fprintf`, `write`,
      `remove`, `raise`, `signal`, …): a tape entry with the predicate; never executed;
    - `noreturn` (`abort`, `exit`, `_Exit`, `__builtin_trap`, `__assert_fail`, any
      `noreturn`-attributed function): `abort_i1(pred)`; rails later modified in place are
      snapshotted under the predicate first;
    - allocation (`malloc`, `calloc`, `aligned_alloc`): `qram_alloc` (a quantum size at its upper
      bound) when the block is a QRAM (rule 20), else a host call; `realloc` of a QRAM is
      `qram_realloc` (one object across the call, 91), of a slot block a host `realloc`;
    - deallocation is a lifetime end, not an effect: `free(p)` of a quantum block under a
      classical predicate uncomputes every cell that can be proven clean (pop the stores, last-in-first-out among those that may touch the same cell, un-copy loads) and then `qram_free`s the block; entangled cells stay allocated
      (§0). `free(p)` under a quantum predicate emits nothing (a reset cannot be conditioned on
      quantum data): the block lives to the end of the enclosing scope, where the classical rule
      applies. `free` of a classical block is an ordinary call.
    Recognition is by the callee's attributes and semantics, never only by name. — 45, 47, 99,
    102, 108, 138; 91 (conditional `free` emits nothing, `realloc`); 186 (unconditional and
    classically guarded `free` of a QRAM with `qram_realloc`, and a block left allocated because a
    cell is entangled).

17. **`cq_invert`.** The bracketed region's gate list is emitted reversed with each gate inverted:
    angles negated, compute/uncompute pairs reverse into themselves (flags are recomputed inside
    the adjoint), loop trips in reverse order, clones as `_adj`. The markers and the asm fences
    are consumed. — 44, 61, 126.

18. **Function lifting.** A callee reached with a quantum argument is cloned per taint mask
    (§1.4). The clone computes, **copies each result into a fresh rail**, uncomputes its body and
    returns the copies (a one-template body may return its rail directly). Its `_unc` twin
    recomputes, XORs each result out with `copy_<W>`, uncomputes, and the caller frees the result
    rails after the twin. Rule 6 clean-up of caller cells a clone overwrote happens in the CALLER
    after the call (the caller knows the old handles and whether they are dead; a clone is shared by
    every call site with its mask). A callee that measures returns a classical value and has no twin. A
    callee that stores into a caller's QRAM returns each stored value rail as an extra `i32`
    result (the pop needs it, §1.3); the caller pops that store at the object's lifetime end and
    then calls the twin, which takes those rails first (191).
    Library code is injected source (musl, linked before lowering) and lifted like any callee; an
    LLVM math intrinsic on a quantum operand (`llvm.exp.f64`, `llvm.sin.f64`, `llvm.pow.f64`, …)
    is the call of the libm function of the same name and is lifted the same way (175, 184).
    A library may instead be lowered once and linked (rule 27).
    Result taint is recorded per clone (an `i32` return is a handle or a classical int by that
    record, not by its type). Recursion with classical depth is ordinary calls. — 06, 07, 33, 34,
    36, 51, 64, 82, 95, 109, 119, 136.

19. **Indirect and opaque callees.** An external function that returns an unmeasured quantum
    value keeps its C signature and returns the handle (escaped, never freed); an in-module caller
    of such a function inlines it (162). A call through a classical function pointer dispatches over
    the static callee set; a function pointer loaded at a quantum index is a QROM of callee tags
    with every candidate clone called unguarded and merged by `select`; a callee under a quantum
    predicate becomes a `_ctl` clone iff its body has a non-pure gate (rotation, phase, slot or
    QRAM store, tape), otherwise it is called unguarded and merged. A callee with no body follows
    rule 27. — 96, 97, 102, 117, 124.

20. **Memory classification.** Each memory object (an `alloca`, global or heap block as -O1
    leaves it; SROA has already split structs; an array of structs is one object per scalar field
    column, all indexed by the same index rail, field-wise as in rule 26 (168); nothing is split further)
    is classified once, over all of its accesses in the whole program after lifting (rule 18):
    loads, stores and memory intrinsics, direct or through a pointer. Every access has an
    **offset** (cell index into the object), classical or quantum (tainted).

    | access | classical offset | quantum offset |
    |---|---|---|
    | load, the object holds only classical values | classical load | **QROM** (host reads the table) |
    | load, the object may hold a handle | slot load (the handle, no gate) | **QRAM load** |
    | store | slot store: the rail replaces the cell; under a quantum predicate `select` into a fresh rail (rule 9) | **QRAM store** |
    | memory intrinsic with a quantum length | per-cell guarded update (rule 22) | as a quantum-offset store |

    - An object is a **QRAM** iff some access to it is a QRAM access (quantum-offset store, or
      quantum-offset load while it may hold a handle). It is a QRAM for its whole lifetime: every
      other access to it is the classical-index (`_hl`) form of the QRAM call. One call per access
      (§1.3); the backend chooses the circuit (never linear per-cell code in the IR); stores are
      popped last-in-first-out among stores that may touch the same cell (§1.3).
    - Otherwise an object that may hold a handle is a **slot array**: a classical array of handles,
      4-byte cells; -O1's byte-offset GEPs are divided by the element size and re-emitted. A
      runtime-sized object (`bool q[n]`, `malloc(n)`) is a slot array of runtime length (one
      `alloca i32, n` or heap block of handle cells). A VLA's lifetime ends at its scope's end
    (`llvm.stackrestore` or the function return); its clean-up runs there (192). An object that never holds a handle is
      ordinary classical memory, read at a quantum offset as a **QROM**:
      `cq_template_qrom_load_<W>[_s]` over its contents AT THE LOAD (the backend embeds those
      values; the `_unc` uses the same values, never a re-read); length = the object's cell count
      when known, otherwise the index's upper bound from LLVM's range facts (`2^W` fallback), strided and flattened forms for struct arrays and 2-D arrays (30, 50; a 2-D
      QRAM flattens `r·cols + c` the same way, 191).
    - Holding quantum values never makes an object a QRAM; only a quantum offset does.
    - A slot cell is homogeneous: if it holds a handle on any path it holds a handle on every path,
      and a classical store into it materialises the value as a seed rail `alloc_<W>(v)` (rule 7)
      (102, 106, 129).
    - **Index operand** of a QROM or QRAM access: the logical index rail at the width of the C
      index expression. The `zext` to `i64` and the GEP scaling are address arithmetic and are
      never emitted.
    - `extern` globals are outputs and never freed; TLS and `static` locals are slots. A global
      QRAM is allocated once by a module constructor, its stores are never popped (its state is the
      program's visible result) and it is never freed (160).
    - A slot record for an `sret`/`byval` aggregate keeps classical fields as classical cells and
      quantum fields as handle cells (163, 164).
    — 29, 30, 31, 32, 48, 50, 58, 63, 67, 71, 72, 74, 75, 76, 77, 78, 108, 114, 120, 160, 168.

21. **Quantum pointers.** A pointer depending on quantum data is a fat pointer `(tag, idx)` over a
    per-function object table; `idx` is always a **cell index** of the object; byte arithmetic
    (`ptrtoint`, `char *` casts) converts at the access by the element size. A dereference is one
    access per object in the provenance, guarded by `tag == o` (guards disjoint): a load is the
    pure access executed unguarded (an out-of-range index reads 0 by §2; a slot or host load checks
    the index against the object's cell count from the object table and reads 0 beyond it, never
    host memory past the object) and merged by `select` on
    the guards; a store is the `_controlled` form under its guard (QRAM) or a guarded `select`
    (slot). Its offset is `idx`: a quantum `idx` makes it a quantum-offset access of
    each such object (rule 20: QRAM, or QROM for classical memory); a classical `idx` with a
    quantum `tag` is a guarded classical-offset access (slot load / `select` store; a classical
    load of classical memory). A pointer
    LOADED through a fat pointer is itself a fat pointer: the per-object guarded loads yield the
    stored pointers, each mapped to `(tag, idx)` by its provenance, merged by `select` (189).
    Pointer compares compare addresses: the object table maps each tag to the object's classical
    base address, and a compare is over `base[tag] + size·idx` (`base[tag]` is a `select` chain on the flags `tag == o`, complement innermost, like any
    multi-way merge, rule 9);
    when every object in both provenances is a distinct allocation of this function it reduces to
    comparing tags, then indices (parameters and globals may alias: they always use addresses).
    A host object's base is its real host address. A QRAM object has no host block: its base is
    its address in the QRAM address space, a unique constant the compiler assigns from a reserved
    range of x86-64 NON-CANONICAL addresses (base `0x4000_0000_0000_0000 + 0x1000·n` for object
    n; no host pointer can take such a value), aligned, `size` bytes per cell, so equality is exact, order is
    exact within an object and consistent across objects; `inttoptr` of an integer derived from
    `ptrtoint(p)` keeps `p`'s provenance (LLVM's rule): tag = p's tag, `idx = (addr − base[tag]) /
    size`, one-past-the-end included; only an integer of unknown origin is decoded by range tests
    over the candidate objects (`base ≤ addr ≤ base + size·n`, one-past included); a pointer crossing a
    clone boundary is passed as `(object, tag, i32 idx)`: `object` is the host pointer of a host
    object or the bus handle `a` of a QRAM object, and the caller's object table (bases, cell counts
    and handles) whenever the provenance has several objects or the callee needs a base (compare,
    `ptrtoint` whose base does not cancel); `tag` is a classical constant when the provenance is
    one object; when the callee loads through the pointer, the object's cell count follows the triple
    as a compiler-added `i32` (no mask digit, 190). A slot or host load beyond the cell count reads
    0 as a shared `|0⟩` seed rail (rule 7). A pointer decoded from a loaded host address carries its
    decoded `idx`; when that `idx` is the same classical value in every merged arm (a node pointer
    always points at cell 0), it is that classical value and the access stays a classical-offset
    access (189). — 84, 85, 86, 88, 89, 105, 107, 129.

22. **Memory intrinsics.** `memset`/`memcpy`/`memmove` work per **cell** of the destination (the
    element type the object is accessed as; for a `char` array a cell is a byte). A classical
    length is one ordinary update per cell (slot: the source handle or a shared basis-state seed;
    QRAM: one `_hl` store per cell). A quantum length `n` (bytes) guards cell `j` of size `s` by
    `n ≥ s(j+1)`; a cell the copy can cover only partly (`sj < n < s(j+1)`) is a byte-masked merge
    of old and new value under `n > sj`. Slot array: the guarded cell is `select(guard, new, old)`
    into a fresh rail; QRAM: `store_hl_controlled(guard, …)`. Only cells some execution of the C
    program can touch are emitted: cell `j` exists iff `sj <` the upper bound of the length (LLVM
    range facts / known bits; per object of a quantum source pointer, the bound of the length on
    the paths that select that object). A classical source byte is a host load and is never
    speculated past that bound. `memcmp`, `strlen`, `strcmp` and the other non-intrinsic
    string/memory functions are library calls: injected musl source lifted by rule 18 (190; 121 writes the same loops in user code).
    — 72, 73, 90.

23. **Floating-point environment.** Under `FENV_ACCESS` the mode and flags split into a host part
    (real calls) and a quantum part (rail); constrained ops take `_rm`/`_rmq` and emit a second
    `_exc` template; fenv calls on quantum state are rail operations; the final flags rail is an
    output. — 65, 80, 81, 82, 100.

24. **Threads, atomics, volatile, setjmp.** Single-thread collapse: atomics are plain ops, fences
    nothing, `pthread_create` a direct call of the clone, mutexes no-ops; an unobservable
    `volatile` access is classical; `longjmp` under a quantum predicate is an escaped-flag result
    merged at the `setjmp` diamond. — 32, 48, 94, 101, 106.

25. **Widths and ABI extras.** `i128`, `_BitInt`, `_Float16`, `x86_fp80` are width variants;
    `<2 x T>` is a pair of lanes; `signext`/`zeroext` are ABI notes. `fp128` is unreachable from C
    on this target. — 19, 63, 93, 103, 110, 111.

26. **Aggregates and complex.** One rail per quantum scalar field, classical fields stay classical;
    the mask is applied field-wise; `extractvalue`/`insertvalue` on handles are classical. `sret`
    and `byval` are slot parameters (rule 20). `_Complex` arithmetic follows clang's Annex G IR:
    the inlined fast path lowers by rule 4, the `__mul*c3`/`__div*c3` fallback is injected and
    cloned by rule 18, and its `fcmp uno` branches are quantum control by rule 8. — 64, 69, 70,
    78, 103, 107, 122; new examples required (§8).

27. **Callees without a body: declared clones.** The compiler knows no library by name. Every
    quantum call to a function with no body in the module (after injection, and except the calls
    rule 16, rule 22 and the intrinsic routes classify) is a call to the clone that §1.4 names, and
    the compiler only emits declarations of that clone and of the twins it calls. Whatever is linked
    supplies the definitions. A missing one is an ordinary undefined-symbol link error, and there is
    no fallback to the original function. A call with no quantum argument stays the ordinary call.
    Injected source has a body, so it is lifted by rule 18 with full knowledge of that body. This
    rule only fixes the ABI for the case where the body is absent, so that the name and the call
    follow from the call site alone:
    - *Name.* The mask is formed as in §1.4 with no `_b` bounds. A pointer argument contributes
      its tag and idx digits and ONE digit for its pointee object, 1 iff any cell holds a handle
      at the call (as for a runtime-length register).
    - *Results.* Every result is a handle (an `i32` per scalar), and the `_unc` twin always exists.
      A clone whose value is classical (e.g. measured) returns it as a seed rail, and its twin
      leaves that rail alone (a known basis state, freed by the caller).
    - *Under a quantum predicate.* The call is always `<clone>_ctl(pred, …)` and the caller merges
      its results by `select`. A pure clone's `_ctl` may ignore `pred`.
    - *Pointers.* A pointer crosses as the rule-21 triple `(object, tag, idx)` followed by the
      object-table cell count (as in 190's memcmp clone). The clone may overwrite cells of a pointee
      object marked 1 with handles it minted. Before the call, the caller copies that object's
      cells (handle numbers, a classical copy) into a snapshot of the same size. The twin takes
      `(outs…, args…, snapshot pointer per marked object)`: it uncomputes what the clone wrote and
      restores every cell from the snapshot. The caller uncomputes its own rails through its own
      SSA values as usual and calls the twin after the last read of the result or of a cell
      the clone may have written. The clone leaves no garbage of its own (rule 18).
    - *Cutoff.* The clone takes one more classical `i32` argument, K, after all others. The twin
      takes the same forward arguments, K included, before any snapshot pointers. Every
      quantum-exit loop and quantum-depth recursion inside the clone and its callees runs for
      min(K, B) trips, where B is the loop's own bound (rule 14). The caller passes the callee's K
      resolved as in §0 (flag, `CQ_K` header, default). A loop-free clone ignores it.
      Since K is not baked in, no K variant of a library exists and none can mismatch.
    - *Linkage.* Declared clones and their twins use the default C calling convention (not
      `fastcc`), since they cross translation units.
    - *Inline asm.* An `asm` statement with a quantum operand is a callee without a body: its
      clone is named `__cq_q_asm_<h>_<mask>` where `<h>` is the first 16 lowercase hex digits of
      the SHA-256 of the asm string as LLVM spells it (`$N` operands), a single NUL byte, and the
      constraint string, with the mask over its operands in order; the
      call, results, `_ctl` form, twin and K follow this rule. An asm with only classical operands
      stays the asm (the host boundary). An asm with a quantum operand and no outputs under a
      quantum predicate is a rule-16 tape effect with the asm string as its name (2026-10-27).
    - *Library build.* A lowered library is the same compiler run over the library source, given a
      list of root clone names. Each root is lowered as if a call site with that name existed and is
      exported under this ABI, together with its `_ctl` form and its twins. Calls inside the library
      have bodies and follow rule 18, passing the K they received down. The classical bodies stay
      and serve classical callers. The root list, and any per-function K the library build
      recommends (e.g. measured by running the classical functions), are build inputs and outputs,
      not part of this spec.
    — 161, 190.

## 4. Metadata and non-normative artefacts

`!cq.branchphase` and any other metadata in a lowered file is non-normative. `_tools/` (traces,
drivers, viewer, checkers) is tooling, not spec. The checkers (`sample_check.py`, `trace_check.py`, `make_trace.py`, `replay/`)
built and verified this suite; they are not part of the compiler's acceptance. A compiler is
accepted by matching the examples under §6, nothing else. Comments in lowered files explain; they never add
requirements beyond this document.

## 5. Conventions for the corpus

- Uncompute as early as rule 5 allows; flags computed just before first use and uncomputed right
  after their last controlled gate.
- Local names are plain LLVM numbering (`_tools/renumber_locals.py`).
- Every example header states: the construction rules it witnesses, the registers whose final
  value is checked, which rails are expected clean, and the rotation list (§6).

## 6. Semantic acceptance

The emitted circuit belongs to the class *basis permutations interleaved with rotations whose
angle is classical (or an angle rail) and whose control is a basis predicate*. Two circuits of
that class are equal iff:

1. **Permutation part.** Run as a classical reversible program on basis inputs (each `cq_theta`
   input replaced by a chosen bit pattern, templates evaluated by §2), the named output registers
   equal the C program evaluated classically on the same inputs under §2, and every rail the
   example declares clean is `0`.
2. **Rotation list.** The sequence of `(gate, target register, angle or angle-rail expression,
   control predicate as a Boolean function of the inputs)` is equal up to reordering of gates
   with disjoint support and up to rail renaming. A phase P(θ) on a flag rail is the phase
   e^{iθ·f} on every basis branch, where f is the flag's Boolean function of the inputs; which rail
   carries it is irrelevant. So `and_i1(a, b, t) · rz_i1(t, θ) · and_i1(a, b, t)` with t |0⟩ equals the
   doubly-controlled phase CCP(θ) on a, b (never a controlled Rz, which differs by a relative phase).

A phase whose control predicate is constant over the quantum inputs once the classical arguments are
fixed, and whose angle is classical, is a global phase: whether either side emits it is not compared
(this is what rule 12's deletion relies on; it never applies to an Ry, nor to a phase with an angle rail).

An indeterminate value the C program reads (a cell never written: `malloc`, `realloc` growth,
an uninitialized local) is taken as 0 by the classical reference, the value the circuit's fresh
`|0⟩` cell holds; no code is emitted for it.

Pointer values (`ptrtoint`, printed addresses) are compared only relationally (equality and
order), never as absolute numbers: host addresses differ per run and QRAM bases are assigned.

Byte identity of traces is never required.

## 7. Examples normalised under these rules (done 2026-10-26)

| rule | examples that currently deviate | change |
|---|---|---|
| §1.4 mask order | 06, 07, 09, 24, 31, 33, 34, 35, 36, 37, 64, 143; `_ctl` after the mask in 102, 117, 124 | rename clones left-to-right |
| §1.4 dead originals | 06, 07 (kept the unlifted body with no classical caller) | dropped |
| §1.4 slot twins | 107, 108, 122, 31, 52, 106 (129 since 2026-10-27: no twin, rule 6 in the caller) | twin takes `(outs…, args…, old handles)` |
| 18 copy-out | 36, 51, 82, 95, 109 | copy result to a fresh rail |
| 9 merge spelling | 143, 121 | `cq_template_select_<W>` |
| 4 out-of-place | 113, 114 (in-place `xor_i1` on user registers), 107, 91 (xor-merge), 121 (`xorc_i8` on a `|0⟩`) | fresh-rail templates |
| 8 i1 gates | 69, 84, 90 (`and_i1` template as flag; 12 and 86 use the conjunction as data and keep the template), 23/49/54/123 (OR by CNOT+Toffoli), 118 (`select_i1_lh` as OR) | `and_i1`/`or_i1` for flags |
| §1.3 spellings | 143 (`cqrt_x`) | `not_i1` |
| 7 seed frees | 05, 09, 26, 37, 54, 131, 139 (redundant reset before free) | free directly |
| 20 index operand | 29, 30 (read), 74, 76, 78, 97, 120 (50 has no zext: -O1 folded it) | logical index rail, drop the `zext` |
| 14 output `a_K` | 05, 09, 26, 37, 53, 54, 55, 68, 87, 139 (57 has a classical bound and no chain) | keep the last predicate as an output |
| 16 lifetime | 91 (`free` under a quantum predicate emits nothing; the block is uncomputed and freed at scope end where provable) | ruling 2026-10-26 |
| 6 bijective cleanup | 125, 127 (also applied in 113, 114 to the superseded CNOT targets) | rewrite as the two witnesses |
| 12 | 41 | header: deletion is scope-dependent |
| 3 lane gate | 103 (dead `fadd_f32` on an unread lane) | remove |
| 27 declared clones (2026-10-27) | 161 (`ext_fn` called with the raw handle), 190 `escape` (`ext_sink` gets slot memory of handles) | done 2026-10-27: `__cq_q_ext_fn_10`, `__cq_q_ext_sink_0010` (snapshot twin), trailing K argument |

## 8. Examples written 2026-10-26 (144–180)

Each states its outcome per §5. The sketches that produced them:

1. 144 `value_arm_then_rotate` — `cq_theta(&y,ty); if (x>k) y += 1; cq_theta(&y,t);` (rule 6).
2. 145 `swap_test` — quantum-controlled swap of two quantum registers, then un-rotate the control (rule 6).
3. 146 `callee_phase_under_control` — `static void g(double p){ cq_phi(p); } if (x>k) g(p);` and the classically-conditioned twin (rule 12).
4. 147 `switch_sparse_default`, 148 — `case 1/5/9/default` on a runtime scrutinee; `nested_switch` (rule 13).
5. 149 `continue_quantum`, 150 `do_while_quantum`, 151 `return_in_kloop`, 152 `phase_in_kloop`, 153 `nested_kloops_in_arm` (rule 14).
6. 154 `short_circuit_call_rhs` — `if (x>k && f(x,c)==m)` with `f` noinline (rule 8).
7. 155 `measure_in_arm` — `if (x>k) m = cq_measure(y);` (rule 2).
8. 156 `qq_width_matrix`, 157 — sub/shl/ashr/sdiv/srem/udiv/fadd/fdiv/and with both operands quantum at i8, i16, i32, i64, f32; `uitofp_q`; quantum shift amount at i64 (rule 4).
9. 158 `value_arm_depth3`, 159 `struct_byvalue_quantum`, 160 `global_qram` (rules 9, 26, 20).
10. 161 `opaque_callee` — an external declaration called with a quantum argument (rule 27 since 2026-10-27).
11. 162 `quantum_return_entry` — an entry function returning an unmeasured quantum value (§1.1).
12. 163–168 aggregates: `sret` return > 16 B, `byval` > 16 B, `{int,int}` coerced to `i64`, `{i64,i32}`, nested struct return, struct with a quantum pointer field, struct in a quantum-indexed array written and read (rule 26).
13. 169–174 complex: `__divdc3`, `__muldc3` both-quantum, imaginary-only-quantum variants of every existing complex example, `cabs`, `conj`, `__mulsc3`/`__divsc3`, `long double` mul/div (rule 26).
14. 175 `libm_quantum` — `exp`, `sin`, `log`, `pow`, `atan2` on a quantum `double` (rule 18 with injected libm source). The call sites and clone signatures are the witness; 184 shows one lifted body in full.
15. 176–180 algorithms: `grover_search`, `deutsch_jozsa`, `bernstein_vazirani`, `simon`, `teleport`.

Added 2026-10-26 (181–185): 181/182 imaginary-only-quantum complex at float and long double width
(`__mulsc3`/`__mulxc3` lifted with mask 1100: Annex G's `im * 0 + re` taints the real part too), 183
`cabs` through the `complex.h` entry point (clang inlines musl's `cabs` and `hypot`, so the bodies
lower straight-line in the entries), 184 musl `atan` on a quantum double with the whole body shown
(`atanhi[id]`/`atanlo[id]` at a quantum `id` are QROM loads), 185 QPE with a quantum angle register
(`cqrt_rz_qangle_controlled` per counting qubit; replay: every basis `k` reads `kv·2^(t−nk)` with p = 1 when `t ≥ nk`). The algorithm examples
114, 115, 117, 176–179, 185 take their sizes and problem data as function inputs; 113, 116, 118 stay fixed-size on purpose.

Added 2026-10-27: 186 `free_qram` (QRAM lifetime end at `free`, `qram_realloc`, entangled block kept).

To write (2026-10-27): an irreducible loop (`goto` into a loop body with a quantum exit) under rule 14's
`fix-irreducible` bullet; a `switch` with a reachable default (rule 13); an inline `asm` with a quantum
operand, as a declared clone (rule 27).

Out of scope by §0: an `-O0`+mem2reg or `-O2` variant of any example.
