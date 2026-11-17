# CQ backend ABI: the logical circuit backend

Reference for the team that implements the runtime the lowered program calls: every `cqrt_*` and
`cq_template_*` family with its contract and with how it is built. CONSTRUCTION_RULES.md (CR) is
normative and wins over this file. A point taken from an example and not from CR is tagged
*(corpus)*. §5 lists the questions this file raised, each with its ruling. §6 says which parts of
CR this file follows.

- **Ground truth.** Bennett.jl `824458d10e879c3fef673c231a02e5461dac667f` (CR §0) and BennettVM.jl
  `23d28e6471f9cf5d8a22177d08260ca86adfe841`, for the reversible circuits of the core XOR gates
  (§1.1–§1.9), the templates (§2) and their totalization only. Memory, pointers, calls and loops
  are CR's own design and have no reference implementation. A citation `path:function` is
  relative to that repo's root and names source read at that revision; "BJ" is Bennett.jl, "BVM"
  BennettVM.jl. Bennett.jl is a reference to read, never a dependency: the backend implements
  its own circuits, and Bennett.jl has none at f16, bf16, f32 and f80.
- **Ref.** names the reference circuit or semantics. **Impl.** says how the function is built
  under the gate-set rule (§0, obligation 8): the BJ circuit it follows, a composition that is
  spelled out, or "not a gate" with what the runtime does instead. Where BJ's result differs from the contract,
  the Impl. line says what is adapted.
- **EXTEND** marks a family with no Bennett.jl implementation. The entry states the IEEE contract
  an extension must meet; §2.11 gives the route to its circuit.
- **Counts** come from the commands shown, run from the `CQ_spec/` root over all 213 examples.
  The 565 symbols are instances of 24 of the 25 core operations and 58 of the 66 template
  operations (§4): the backend is those 91 operations, generic in width.

```sh
ls -d examples/*/ | wc -l                                                            # 213 examples
cat examples/*/*.lowered.ll | grep -ohE '@(cqrt_|cq_template_)[A-Za-z0-9_.]+' | sort -u | wc -l   # 565 symbols
cat examples/*/*.lowered.ll | grep -ohE '@cqrt_[A-Za-z0-9_.]+' | sort -u | wc -l     # 128 cqrt_*  (so 437 cq_template_*)
# per-example symbol index used for every "examples" count below:
for f in examples/*/*.lowered.ll; do n=$(basename $(dirname $f)); n=${n%%_*}; \
  grep -v '^declare' $f | grep -ohE '@(cqrt_|cq_template_)[A-Za-z0-9_.]+' | sort -u | sed "s/^@/$n /"; done > sym_by_ex.txt
grep -E ' cqrt_push' sym_by_ex.txt | cut -d' ' -f1 | sort -u | wc -l                 # e.g. 53 (one family)
comm -23 <(grep -ohE '^declare i32 @cq_template_[A-Za-z0-9_]+' examples/*/*.lowered.ll | sed 's/.*@//' | sort -u) \
         <(grep -ohE '@cq_template_[A-Za-z0-9_]+_unc' examples/*/*.lowered.ll | sed 's/@//;s/_unc$//' | sort -u) | wc -l   # 49
```

Every used symbol is declared and every declared symbol is used (`comm` of the two sets is empty).

---

## 0. Scope

**Execution model (CR §0).** The lowered program is an ordinary x86-64 host program. Running it
calls the backend, and each call appends gates to the circuit, returns a fresh handle, or returns a
measurement outcome. Classical values known only at run time (loop bounds, addresses, angles)
arrive as call arguments. The backend is a circuit builder driven by the host execution, not a
translator of the IR. A call never returns before its gates are appended in program order.

**Handles.** Every quantum object is an `i32` handle. There are three kinds:

| kind | made by | width | released by |
|---|---|---|---|
| rail | `cqrt_alloc_<W>`, every forward template, `cqrt_qram_load*`, `cqrt_tape_write_<W>*`, `cqrt_tape_effect_<W>_controlled` | W qubits | `cqrt_free` (or never: kept, measured, tape, effect result) |
| memory bus | `cqrt_qram_alloc_i8(i32 0)`, once per process (§1.10) | 2^64 cells × 8 qubits plus tape slots | never |
| tape | `cqrt_tape_alloc` | append-only list of entries | never |

- **Handle 0 is reserved.** No allocation ever returns it; it denotes "no rail" in a handle
  position that has none on the path taken (CR §1.1). A handle is a classical value of the host
  program, which may compare, branch on, select, pass and push handles (§1.12). A cell of the
  bus holds data, never a handle.
- The backend records the width and kind of every handle. A template name gives the width of its
  result and of its operands. The **address operand** of a bus access is a 64-bit rail, or an
  `i64` literal in the `_hl` forms (§1.10).
- **Classical-valued.** A rail or a bus cell is *classical-valued* while it holds one basis value
  that the backend knows, with no superposition and no entanglement. The backend allocates qubits
  lazily: a classical-valued rail is classical bits, and qubits exist only from the first gate
  that forces them. The backend tracks this at least through `cqrt_alloc`, every core gate
  other than an Ry (§1.4, §1.5: their definition governs), template and bus access whose operands, controls and cells are all classical-valued (the
  result is classical-valued), and `cqrt_measure_<W>` (the rail is classical-valued afterwards).
  The overlay (§1.10) and the tape (§1.11) are defined by it.
- **Rail value encoding.** Integers are two's complement on W bits. `f16`/`f32`/`f64` are IEEE
  binary16/32/64 bit patterns. `bf16` is the bfloat16 pattern (8 exponent bits, 7 fraction bits,
  CR §1.1). `f80` is the x87 80-bit extended pattern (explicit integer bit, CR rule 25). `i1` is one qubit. The qubit order inside a rail is internal to the backend, because
  only values cross the ABI (`alloc`, `measure`, literals). The quantum-angle ladder (§1.5) is the
  one place where bit weights matter.
- Widths in the corpus: `i1 i7 i8 i16 i32 i64 i100 i128 f16 f32 f64 f80`. Any `N ≥ 1` is legal
  (CR §1.1), so implement templates generically in W.
- **Literal** means a classical value known at run time, not only a compile-time constant
  (`fshl_i32_qll(h, %2, 3)` in 134 passes a function argument). A literal has the LLVM operand
  type: `i1`, `iN`, `half`, `float`, `double`, `x86_fp80`.
- **Aliasing** *(corpus)*. One rail may fill several read-only operand slots of one call, as in
  `cq_template_fshr_i32(%5, %5, %6)` (112) and `cq_template_fadd_f16(%0, %0)` (111). The target of an
  in-place core gate (`not/and/or/xor_i1` `t`, `copy` `d`, `xorc` `h`, `ry/rz` target) never equals
  any other operand of that call.
- **Narrow scalar arguments and returns.** The corpus declares 6 symbols both with and without
  `signext`/`zeroext` (allowed, CR §1.2). The backend reads only the low W bits of an
  `i1`/`i8`/`i16` argument and returns `i1` zero-extended and `i8`/`i16` sign-extended.

**Namespaces (CR §1.1).**

| prefix | who defines it | backend implements? |
|---|---|---|
| `cq_*`, `__cq_*` (`cq_theta_*`, `cq_measure_*`, `cq_phi`, `__cq_invert_begin/end`) | `CQ.h`, consumed by the compiler | **no**: never reaches the backend |
| `cqrt_*` | backend: core gates, memory bus, tape, abort, push/pop (§1) | **yes** |
| `cq_template_*` | backend: out-of-place reversible ops and their `_unc` twins (§2) | **yes** |
| `__cq_q_<fn>_<mask>…` | lowered code (clones, CR §1.4, rule 27) | **no** (§3) |
| `__cq_mem`, `__cq_alloc`, `__cq_clone_*`, `__cq_sig` | the injection bundle: classical host C, one definition shared by every module and lowered library (§1.10, §1.14) | **no** |
| `__cq_register`, `__cq_act_<fn>`, `__cq_k`, `@.cq.sig[.<n>]`, `@.cq.effect.<name>` | lowered code, module-internal (CR §1.3, §1.4, rule 16) | **no** |

**Link order.** A referencing archive comes before the archive it references:
`main.o  [lowered libraries (rule 27)]  libcq_templates.a  libcq_runtime.a` (template circuits
are built from core primitives).

**No build-flag marker.** A declared clone (CR rule 27) takes the loop cutoff K as a trailing
classical `i32`, so nothing can mismatch at link time. The angle precision N (§1.5) and the
input-length bound K2 (§1.11; default 4096 bytes) are the backend's own configuration. The
compiler's allocation bound K2 (CR §0) reaches `__cq_alloc` as a classical size and does not
cross this ABI.

**Not implemented by the backend.**
- libm and libc functions and LLVM math intrinsics on quantum operands: lifted from injected
  source (CR rule 18) or linked as declared clones (rule 27). No `cqrt_sin` exists.
- Clones and their twins (§3), function-pointer dispatch (§1.14) and address arithmetic (a
  pointer is a 64-bit integer; `getelementptr` is `sext`/`zext`, `mul`/`shl`, `add` templates).
- Allocation: the bundle allocator `__cq_alloc` (§1.10). The backend never allocates or releases
  program memory.
- **Retired**, must not be provided (CR §0): `cqrt_x`, `cqrt_cnot`, `cqrt_toffoli`,
  `cqrt_phase_f64*`, `cqrt_measure_<W>_controlled`, `cqrt_rz_<W>`, `cqrt_ry_*_controlled_inv`,
  `cqrt_cswap`, `cqrt_tape_write_str_lit`, `cqrt_tape_str_begin/end`, every `*_inv` template,
  the controlled arithmetic grid, `cqrt_qram_alloc_host_<W>[_s]`, `cqrt_qram_realloc_<W>[_unc]`, `cqrt_qram_size`,
  `cqrt_qram_free`, `cqrt_qram_store_<W>*_unc`, `cq_template_qrom_load_<W>[_s]`, the `i32`-index
  `_hl` bus forms, and `cqrt_qram_alloc_<W>` for any bus other than the one of §1.10.
- `cqrt_push`/`cqrt_pop` are classical host functions the runtime library defines (§1.12), not
  circuit primitives.

**Global obligations.**
1. **Fresh results.** Every handle a call returns names a newly allocated object. A rail result
   starts in `|0⟩` and the call XORs the value into it. Handles are never reused while live.
2. **Garbage-free templates.** A template leaves every operand and every internal ancilla exactly
   as it found it. Its net map is `|args⟩|0⟩ → |args⟩|f(args)⟩` (Bennett compute–copy–uncompute,
   BJ `src/bennett_transform.jl:_bennett_default`; `bennett_direct` there is the forward-only
   path for a gate list that already cleans up after itself).
3. **No inserted measurement.** The backend measures only at `cqrt_measure_<W>` and, at the end of
   the shot, the tape rails (captured output buffers among them) and abort flags (§1.11).
4. **Live outcomes.** `cqrt_measure_<W>` is synchronous: the backend runs the circuit up to the
   measurement (mid-circuit measurement, classical feed-forward) and returns this shot's real
   outcome, on which the host program branches. There is no emit-only mode (CR §0).
5. **Initialization.** `cqrt_*` calls can come from `@llvm.global_ctors` before `main`, in any
   order, so the backend initializes itself on first call.
6. **Lazy qubits, no query.** The lowered program never asks whether a rail or a cell is
   classical-valued: no symbol reports it, and the lowered code is the same for classical and
   quantum data.
7. **No fault.** No bus access faults or reads host memory that is not readable (§1.10).
8. **Gate set.** Every gate the backend appends is X, CX or CCX, with three exceptions:
   (a) the rotations: `cqrt_ry_*`, `cqrt_rz_i1`, `cqrt_rz_qangle` and their `_controlled` and
   `_qangle` forms. Only the Ry and P gates themselves are meant: the reduction of an angle
   rail (§1.5) is X/CX/CCX;
   (b) measurement (`cqrt_measure_<W>`, the end of the shot in §1.11) and the reset inside
   `cqrt_free`;
   (c) bookkeeping, which emits no gate: `push`/`pop`, `invert_begin`/`end`, tape and abort
   records, the host-boundary logic, the HOST/QUANTUM overlay, handle management.
   An X/CX/CCX circuit returns every ancilla it takes to `|0⟩` before the call returns.
   Bennett.jl emits exactly such gate lists (BJ `src/gates.jl:NOTGate`/`CNOTGate`/`ToffoliGate`,
   all ancillae back at 0) and is the reference for the reversible circuits.

**Building the circuits** (how an Impl. line is read). x_i is bit i of rail x.
- *BJ gate emitters* (`lower_add!`, `lower_mux!`, …) append NOT/CNOT/Toffoli gates on wire
  vectors and are generic in W. They take their result wires and their ancillae from a
  `WireAllocator` and leave the ancillae dirty. The backend wraps one as: the emitter's gates,
  CX of its result into the result rail, the same gates in reverse order ("wrapped" below; BJ
  `src/bennett_transform.jl:_bennett_default`). An emitter that only XORs into its result
  wires and takes no ancilla is emitted straight onto the result rail.
- *BJ soft kernels* (`soft_fadd`, `_soft_udiv_compile`, …) are branchless integer programs on
  bit patterns: shifts, adds, compares and selects, no data-dependent branch. The circuit of a
  kernel is each of its operations as the integer circuit of §2.2–§2.5 on ancilla rails, the
  whole wrapped ("compiled" below). The kernel is the specification of the circuit; the backend
  builds it at the widths it needs. BJ's own compiler (`src/Bennett.jl:reversible_compile`)
  does the same for its 64-bit kernels and may be used to generate or cross-check a gate list.
- *The result rail in any state.* A template and a core XOR gate are `o ^= f(args)` whatever o
  holds, not only for o = `|0⟩`: `cq_invert` replays them on a rail a rotation has acted on
  (§1.13, CR rule 17). Both constructions above give that map. A circuit that overwrites a copy
  of an operand in place (BJ `src/adder.jl:lower_add_cuccaro!`) may serve inside the computed
  part, never as the write to o.
- *A literal operand* (`_hl`, `_lh`, `_ll`, an `l` of a ternary shape; `xorc`, `alloc`) is a
  call argument, known when the gates are appended. Either an ancilla register is set to it by X
  on its 1-bits (BJ `src/lowering/operand.jl:resolve!`, widths up to 64 there), used as the
  handle operand and cleared by the same X gates, or the constant is folded into the gate list:
  a CX from a known bit is X or nothing, a CCX with one known control is CX or nothing. Both
  are the same unitary.
- *`_unc`* is the gate list of its forward form (the same XOR map).
- *`_controlled`* exists for core gates only, never for a template. Each gate takes the
  control: X → CX, CX → CCX, CCX → three CCX over one ancilla that returns to 0 (BJ
  `src/controlled.jl:controlled`, `promote_gate!`).
- *Classical-valued operands* (above) need no gate: the backend computes the value on bits.

---

## 1. Core gates (`cqrt_*`)

`<W>` is the width token. `_controlled` takes the control flag (an `i1` rail) as **argument 0**.
`_unc` of an in-place core gate takes the same arguments (CR §1.3). ⟦h⟧ is the basis value of rail
h. "Unchanged" means the rail is not touched. "Ex" lists 2–3 witness examples.

### 1.1 `cqrt_alloc_<W>`
- **Sig.** `i32 @cqrt_alloc_<W>(<T> lit)`, where `<T>` is `iN`/`half`/`float`/`double`/`x86_fp80`.
- **Sem.** Allocates a fresh W-qubit rail in the basis state `|lit⟩` (`lit` mod 2^W, or the fp bit
  pattern) and returns its handle.
- **Rails.** Fresh. A seed that is never written is freed directly (CR rule 7).
- **§2.** None. **Ref.** BJ `src/wire_allocator.jl:allocate!` (zero wires; a nonzero seed is X on its
  1-bits). **Ex.** 01, 13, 111.
- **Impl.** Handle management (c). The fresh rail is classical-valued and holds `lit` as bits;
  no gate is appended. When a later gate forces qubits they start in `|0⟩` and get X on the
  1-bits of the value.

### 1.2 `cqrt_free`
- **Sig.** `void @cqrt_free(i32 h)`.
- **Sem.** Resets rail h and releases it. Precondition: h is in a **known classical basis state** and
  not entangled. That holds for `|0⟩` after an `_unc` and for an unwritten seed (CR §0, rule 7).
  The reset is the backend's operation (a hardware reset). It must not disturb other rails.
- **Rails.** h is consumed. Never called on a measured rail, a tape rail, an abort flag, the memory
  bus or an escaped handle. A classical-valued rail (§0) is in a known basis state whatever value
  it holds.
- **§2.** None. **Ref.** BJ `src/wire_allocator.jl:free!`. **Ex.** 03, 04, 07.
- **Impl.** Not a gate (b, c): the reset of the rail's qubits, where it has any, and the release
  of the handle. BJ's `free!` puts zero wires back in the pool for reuse; the backend may reuse
  reset qubits the same way.

### 1.3 `cqrt_measure_<W>`
- **Sig.** `<T> @cqrt_measure_<W>(i32 h)` with `<T>` the C type (`i1`, `i8`, `i16`, `i32`, `i64`,
  `float`, `double`, `x86_fp80`).
- **Sem.** Projective measurement of all W qubits in the computational basis. Returns the outcome
  as a value of type `<T>`.
- **Rails.** h stays allocated and is never freed. Afterwards it holds the outcome, a known basis
  state, and may still be read as an operand or a control; a later gate on it acts on that
  state (CR rule 2). The call is never conditioned (no `_controlled` form). A `measure` of an
  already-measured rail is a classical re-read, never a measurement event (CR rule 2, 136).
- **§2.** None. **Ref.** No reference implementation (Bennett.jl and BennettVM.jl are classical
  reversible). **Ex.** 01, 38, 155. In the corpus: 212 examples (all except 60).
- **Impl.** Not a gate (b): the measurement of the rail's qubits, run at the call (obligation
  4). A classical-valued rail has no qubits: its bits are returned.

### 1.4 `cqrt_ry_<W>[_controlled]`
- **Sig.** `void @cqrt_ry_<W>(i32 h, double θ)` and `void @cqrt_ry_<W>_controlled(i32 c, i32 h, double θ)`.
- **Sem.** Ry(θ) on **every** qubit of h (W qubits, fp rails included). `_controlled` applies each
  Ry under c = 1. Ry(θ) = exp(−iθY/2) = [[cos θ/2, −sin θ/2], [sin θ/2, cos θ/2]] (CR §1.3).
- **Rails.** h is modified in place and is frozen afterwards (never reverse-played, never freed;
  CR rule 10). c is unchanged. There is no `_unc`. `cq_invert` emits Ry(−θ) (rule 17).
- **§2.** A non-finite θ is the identity. **Ref.** No reference implementation. **Ex.** 01, 39,
  125 (`_controlled`). Corpus widths: f32 f64 f80 i1 i8 i16 i32 i64 (`_controlled`: i1, i32).
- **Impl.** Rotation (a): W single-qubit Ry(θ) gates, for `_controlled` each controlled by c. No
  X/CX/CCX and no ancilla. A non-finite θ appends nothing. A classical-valued h gets its qubits
  here.

### 1.5 `cqrt_ry_<W>_qangle[_controlled]`: the N-bit angle ladder
- **Sig.** `void @cqrt_ry_<W>_qangle(i32 h, i32 A)`. The controlled form is
  `(i32 c, i32 h, i32 A)` (CR §1.3; 126).
- **Sem.** Ry(val(A)) on every qubit of h on each basis branch of A. A is an **`f64` rail**: the
  program's IEEE double, bit-exact (79, 143). val(A) is that double.
  `Σ_a α_a|a⟩_A ⊗ |ψ⟩_h ↦ Σ_a α_a|a⟩_A ⊗ Ry(val(a))^{⊗W}|ψ⟩_h`. The backend builds the circuit
  (CR §1.3): reduce val(A) exactly mod P (P = 4π for Ry, 2π for a phase), round it to nearest-even
  onto the grid P·k/2^N, k ∈ [0, 2^N), and fire one controlled Ry per ladder bit i with angle
  P·2^(i−N). Rotations about one axis add, so each branch gets Ry(val) up to that rounding, exact
  when val lies on the grid. N is the backend's configuration; the IR never spells the ladder.
- **Rails.** A is read only and unchanged (then uncomputed by its producer's `_unc`). h is rotated
  in place and frozen.
- **§2.** A non-finite val(A) is the identity on that branch. **Ref.** No reference implementation.
  **Ex.** 79, 132, 142. Corpus: `cqrt_ry_i32_qangle` (79, 132, 141, 142, 143), `cqrt_ry_i1_qangle`
  (58, 59, 115, 120, 185), `cqrt_ry_i8_qangle` (121), `cqrt_ry_i32_qangle_controlled` (126).
- **Impl.** Two parts; only the second is a rotation.
  - *Reduction (X/CX/CCX, no reference circuit).* A fresh N-qubit register K ^= k(a), where
    k(a) = round(val(a)·2^N / P) mod 2^N for a finite val(a) and 0 for a non-finite one (exponent
    field all ones). A is unchanged and every ancilla returns to `|0⟩`.
    *Fixed:* k as a function of the 64 bits of A. The product with 2^N/P is the real-number
    product, taken mod 2^N (two's complement for a negative val: k(−x) = −k(x) mod 2^N), then
    rounded to nearest. P is irrational, so val·2^N/P is never half an integer for a finite
    val ≠ 0: the tie rule never fires, and k(±0) = 0.
    *Left to the backend:* N and the circuit. One construction from BJ parts: split A into
    sign s, exponent e and the 53-bit significand m by CX (the implicit bit is [e ≠ 0]; a
    subnormal has the exponent of e = 1); the bits of 2^N/P that can reach K at exponent e are
    a window of one classical constant, the binary expansion of 1/π, selected by e (a table
    lookup on e, BJ `src/qrom.jl:emit_qrom!`, 64 data bits per call there, or a barrel shift,
    BJ `src/lowering/arith.jl:lower_var_shl!`); m times the window by BJ
    `src/multiplier.jl:lower_mul_wide!`; the N bits above the binary point plus the bit below
    it, added in as the rounding (BJ `src/adder.jl:lower_add!`); negation under s (BJ
    `src/lowering/aggregate.jl:_cond_negate_inplace!`); 0 under e = 0x7FF. The whole is wrapped
    (§0) with K as the result rail.
    *Exact means exact:* k is the correctly rounded value for every one of the 2^64 inputs, so
    the circuit is a function of N alone and two backends with the same N agree. The window is
    cut to a finite width; the guard width that keeps the cut from ever changing k is found
    once per N at design time, by the worst-case search used for argument reduction (for each
    exponent, the significand that brings val·2^N/P closest to half an integer). No tolerance
    is granted.
  - *Rotations (a).* For each ladder bit i < N and each qubit q of h: Ry(P·2^(i−N)) on q,
    controlled by K_i. `_controlled`: t ^= c ∧ K_i by CCX on a fresh ancilla, the controlled Ry
    from t, the same CCX again. Then the reduction once more, which returns K to `|0⟩`, and K is
    released.
  - A classical-valued A needs no reduction circuit: the backend computes k on the host and
    appends Ry(P·k/2^N).

### 1.6 `cqrt_rz_i1`
- **Sig.** `void @cqrt_rz_i1(i32 f, double θ)`.
- **Sem.** The phase gate P(θ) = diag(1, e^{iθ}) on flag f. It is not Rz: the two differ by a phase
  e^{iθ/2}, which is global only because the gate is never controlled. Implement exactly P.
- **Rails.** f is unchanged in value and gets a relative phase. There is no `_unc`; the adjoint is
  P(−θ).
- **§2.** A non-finite θ is the identity. **Ref.** No reference implementation. **Ex.** 03, 08, 41.
- **Impl.** Rotation (a): one P(θ) on f, nothing for a non-finite θ. No X/CX/CCX.
- **Fusion.** The bracket `and_i1(a, b, t) · rz_i1(t, θ) · and_i1(a, b, t)` (t |0⟩) equals CCP(θ)
  on a, b (CR §6), and `xor_i1(a, t) · rz_i1(t, θ) · xor_i1(a, t)` equals P(θ) on a. The backend
  appends the calls as they come (CCX, P, CCX: obligation 8); a synthesis stage after it may
  fuse either bracket. Never fuse to a controlled Rz: Rz(θ) = e^{−iθ/2}·P(θ), and under a
  control that global factor becomes a relative phase. The and-bracket occurs in 11 examples
  (08, 23, 60, 116, 117, 118, 137, 148, 152, 154, 185).

### 1.7 `cqrt_rz_qangle[_controlled]`
- **Sig.** `void @cqrt_rz_qangle(i32 A)` and `void @cqrt_rz_qangle_controlled(i32 c, i32 A)`.
- **Sem.** `|a⟩_A ↦ e^{i·val(a)}|a⟩_A`, a diagonal on A's basis. `_controlled` applies the phase only
  on the c = 1 branch (`|c,a⟩ ↦ e^{i·c·val(a)}|c,a⟩`). The phase is relative. A's uncompute kicks it
  back onto the sources (79, 143). It uses the same ladder as §1.5 with P = 2π.
- **Rails.** A and c are unchanged in value.
- **§2.** A non-finite val is the identity. **Ref.** No reference implementation. **Ex.** 79, 132,
  143 (`_controlled`: 22, 79, 115, 185).
- **Impl.** The reduction of §1.5 with P = 2π into K (X/CX/CCX), then for each ladder bit i < N
  the rotation (a) P(2π·2^(i−N)) on K_i itself, then the reduction again and K released.
  `_controlled`: t ^= c ∧ K_i by CCX, P on t, the same CCX again (the bracket of §1.6). The
  phases on K's bits multiply to e^{2πi·k/2^N} on each branch.

### 1.8 `i1` logic: `cqrt_not_i1`, `cqrt_and_i1`, `cqrt_or_i1`, `cqrt_xor_i1`
| sig | semantics | ex |
|---|---|---|
| `void @cqrt_not_i1(i32 h)` | X: h ^= 1 | 21, 26, 39 (45 examples) |
| `void @cqrt_and_i1(i32 a, i32 b, i32 t)` | Toffoli: t ^= a ∧ b | 05, 08, 23 (53) |
| `void @cqrt_or_i1(i32 a, i32 b, i32 t)` | t ^= a ∨ b | 23, 49, 69 (18) |
| `void @cqrt_xor_i1(i32 a, i32 t)` | CNOT: t ^= a | 68 (1) |

- **Rails.** a and b are unchanged. t (h) is modified in place. Each gate is an involution, so the
  `_unc` is the same call. A flag conjunction targets a fresh `|0⟩` rail (CR rule 8).
- **§2.** None.
- **Ref.** BJ `src/gates.jl:NOTGate`/`CNOTGate`/`ToffoliGate`. The OR is
  `src/lowering/phi.jl:_or_wire!` (CNOT, CNOT, Toffoli). These core gates differ from the templates
  `cq_template_and_i1`/`or_i1`/`xor_i1`, which write a fresh rail (§2.3).
- **Impl.** `not_i1`: X(h). `and_i1`: CCX(a, b, t). `or_i1`: CX(a, t), CX(b, t), CCX(a, b, t).
  `xor_i1`: CX(a, t). No ancilla.

### 1.9 `cqrt_copy_<W>[_controlled]`, `cqrt_xorc_<W>[_controlled]`
- **Sig.** `void @cqrt_copy_<W>(i32 s, i32 d)` and `void @cqrt_copy_<W>_controlled(i32 c, i32 s, i32 d)`;
  `void @cqrt_xorc_<W>(i32 h, <T> lit)` and `void @cqrt_xorc_<W>_controlled(i32 c, i32 h, <T> lit)`.
- **Sem.** copy: d ^= s, a W-bit CNOT fan-out. d need not be `|0⟩`. xorc: h ^= lit (X on the 1-bits
  of lit). `_controlled`: only on the c = 1 branch.
- **Rails.** s and c are unchanged, and d (h) is modified. Each is an involution (`_unc` = same
  call). Uses: copy-out of a result into a fresh `alloc` rail (CR rules 14, 18), rule-6 cleanup
  `copy(t, y_old)`, and xorc on a basis seed before a controlled prep (rule 10).
- **§2.** None.
- **Ref.** BJ `src/bennett_transform.jl:_emit_copy_gates!` and `src/fast_copy.jl:emit_fast_copy!`;
  controlled forms per `src/controlled.jl:controlled` (adds a control to every gate).
- **Impl.** `copy`: CX(s_i, d_i) on each of the W bits. `copy_controlled`: CCX(c, s_i, d_i).
  `xorc`: X(h_i) at the 1-bits of lit. `xorc_controlled`: CX(c, h_i) at the 1-bits of lit. No
  ancilla.
- **Ex.** copy 05, 07, 13 (108 examples; widths f16 f32 f64 f80 i1 i7 i8 i16 i32 i64;
  `_controlled` i32: 45, 211). xorc: `cqrt_xorc_i32_controlled` in 133 only. The uncontrolled
  `xorc` is not in the corpus.

### 1.10 Memory bus: `cqrt_qram_alloc_i8`, `cqrt_qram_load/store/swap`
All memory of the program is ONE bus `m` (CR rule 20): 2^64 cells of 8 qubits, and the cell index
is the x86-64 address. Every access is ONE call. The address-decoding circuit (bucket brigade,
select-swap, fan-out per cell) belongs to the backend: the contract fixes the unitary, never the
circuit.

- **Creation.** Once per process, as `cqrt_qram_alloc_i8(i32 0)` (n = 0 denotes 2^64 cells), by
  the first call of the injection-bundle getter `i32 @__cq_mem()`, through which every module
  and lowered library reaches the same handle. No other bus is requested; the bus is never freed.
- **Access width.** `<W>` is the width token of the accessed LLVM type T. One access touches
  exactly DataLayout store-size(T) consecutive cells from the address, little-endian, addresses
  taken mod 2^64: `i8` 1, `i16` 2, `i32` 4, `i64` 8, `i128` 16, `f16` and `bf16` 2, `f32` 4, `f64`
  8, `f80` 10 (the x87 pattern; bytes 10–15 of its slot are not touched). A pointer is accessed
  as `i64`. A width N that is not a multiple of 8 (`i1`, `i7`, `i100`) occupies ⌈N/8⌉ cells: a
  store writes the value zero-extended, a load reads the low N bits, and a swap exchanges h with
  the low N bits and leaves the high bits where they are. Below, "the cells" are the cells of
  one access, read as one W-bit value.
- **Address.** `addr` is a 64-bit rail in the plain forms (the QRAM query) and a classical `i64`
  in the `_hl` forms (direct access: no decoding, O(W) gates, constant depth).
- **Value.** `v` and `h` are rails of width W. A classical stored value is first materialized by
  `cqrt_alloc_<W>`.

| sig | semantics |
|---|---|
| `i32 @cqrt_qram_alloc_i8(i32 n)` → m | n = 0 only: the bus. Every cell starts HOST (overlay, below). |
| `i32 @cqrt_qram_load_<W>_hl(i32 m, i64 addr)` → h, `i32 @cqrt_qram_load_<W>(i32 m, i32 addr)` → h | Fresh h ^= the cells. The cells and `addr` are unchanged. |
| `i32 @cqrt_qram_load_<W>[_hl]_controlled(i32 c, i32 m, addr)` → h | Fresh h ^= c ? the cells : 0. Under c = 0 no cell is touched and no host byte is read. |
| `void @cqrt_qram_load_<W>[_hl][_controlled]_unc(i32 h, [i32 c,] i32 m, addr)` | h ^= the cells. **Precondition:** `addr` and c hold their forward values. Where the cells hold the value they had at the load, h = `\|0⟩` and the caller frees h; otherwise h stays allocated (CR rule 5). |
| `void @cqrt_qram_store_<W>[_hl][_controlled]([i32 c,] i32 m, addr, i32 v)` | Takes a fresh tape slot t as wide as the cells, swaps t ↔ the cells (the displaced content goes out), then the cells ^= v. v is unchanged. `_controlled`: under c = 0 nothing is touched and t stays `\|0⟩`. A store has no `_unc`: t is allocated at every call and never released. |
| `void @cqrt_qram_swap_<W>[_hl][_controlled]([i32 c,] i32 m, addr, i32 h)` | h ↔ the cells. No tape slot. Self-inverse: the undo is the same call. `_controlled`: under c = 0 nothing is touched. |

- **Overlay.** A cell is HOST or QUANTUM. Every cell starts HOST: its value is the host byte at
  that address, read at each access and never snapshotted. A store or swap whose address and
  control (if any) are classical-valued (§0) and that leaves classical-valued content in the cells
  writes those bytes to host memory, and the cells are HOST; the content it displaces goes to the
  tape slot or to h as always. Any other store or swap makes every cell it can reach QUANTUM:
  the backend holds the content, and the host byte at that address is unspecified until a later
  event makes the cell HOST again. Host code (system calls, bodiless callees, startup data,
  initializers, `argv`) therefore sees and is seen by the bus with no seeding call and no module
  constructor. A byte host code writes at a QUANTUM cell is not seen by the bus. A write the
  backend itself makes for an effect entry (§1.11) is a bus store.
- **No fault.** A load, or the displaced read of a store or swap, at an address that is not
  readable host memory and not a QUANTUM cell reads 0 and never faults. A classical-valued store
  to an address that is not writable host memory makes the cell QUANTUM and writes no host byte.
  For an address rail that is not classical-valued, the set R of addresses it *can reach* is the
  set the backend bounds the rail's value to. R contains every value the rail has an amplitude
  on; any such R gives the same unitary (a flag of an address outside the support never
  fires), so a circuit builder, which cannot know the support, takes the bound it can prove. The
  backend reads and overlays exactly the cells of R. A looser R costs qubits and turns more HOST
  cells QUANTUM; how tight it is is the backend's resource question, like N and K.
- **Undo (CR rule 5).** The lowered code undoes a bus event in two cases only, and the backend
  relies on nothing else:
  1. *A load copy* is un-copied (`_unc`) after the last consumer of the loaded value and every
     `_unc` that re-reads it, and freed only when that point precedes the next memory version
     change (CR rule 5) on every path; otherwise it stays allocated. A load copy that is measured,
     is the value rail of a kept store or was rotated is never un-copied and stays allocated.
  2. *The in-place form*: `h = cqrt_alloc_<W>(0)`, `swap(m, p, h)` (h holds the content, the
     cells 0), a gate or a rule-6 bijective update on h giving `y'`, `swap(m, p, y')`, then
     `cqrt_free` of the rail the cells' 0 went to. `addr` holds the same value at both swaps and
     no bus access lies between them. Nothing remains. It is the only way a non-diagonal gate
     reaches a cell (a `_Bool` cell: `swap_i1`, `cqrt_ry_i1`, `swap_i1`).

  Every other store is kept for the shot: its tape slot is never released (v and c: CR rule 5).
- **Under a quantum predicate** (an arm flag, a K-loop trip predicate) every bus access is the
  `_controlled` form, and no bus access is hoisted or speculated (CR rule 9).
- **Classical-valued `_unc`.** The load `_unc` precondition protects quantum state. When the
  cells, h and `addr` are classical-valued the `_unc` is a classical XOR of host bytes: if host
  code changed the cells in between, h ends in a non-zero basis value, and its release is still
  legal (§1.2).
- **Allocation.** The bus has no allocation call. A bus-resident object gets its address from
  the bundle allocator `ptr @__cq_alloc(i64 size, i64 align)` (classical host C): zeroed host
  memory at an address that is never reused, so a never-written cell reads 0 (CR §6), with
  `size` written as an `i64` in the 8 host bytes before the returned address (HOST cells). No
  size is known at compile time: `realloc` reads the old size with a bus load at `p − 8` (CR
  rule 16). `free` emits nothing, and no memory is ever released. A size that is a rail is
  allocated at the bound **K2** bytes (CR §0), and its header holds K2.
- **Impl.** `qram_alloc_i8`: not a gate (c): the bus object and its overlay. The accesses, with
  cell bits written cell_i:
  - *Classical address (`_hl`): no decoding.* A HOST cell is classical bits and takes no gate
    as long as what meets it is classical-valued; when a store or swap makes it QUANTUM
    (Overlay, above) it gets qubits in its byte's value (X on the 1-bits).
    load: CX(cell_i, h_i); from a HOST cell, X(h_i) at the 1-bits of its byte.
    `load_controlled`: CCX(c, cell_i, h_i); from a HOST cell, CX(c, h_i) at the 1-bits.
    swap: per bit CX(h_i, cell_i), CX(cell_i, h_i), CX(h_i, cell_i), or a relabeling of the
    qubits, which appends nothing. `swap_controlled`: per bit CX(cell_i, h_i), CCX(c, h_i,
    cell_i), CX(cell_i, h_i).
    store: that swap between the fresh slot t and the cells, then CX(v_i, cell_i).
    `store_controlled`: the controlled swap, then CCX(c, v_i, cell_i).
    The load `_unc` is the load's gates.
  - *Address rail: X/CX/CCX the backend builds; no reference circuit for the access.* With R the
    set of addresses the address rail can reach:
    (1) *decoding:* for each a ∈ R a flag f_a = [⟦addr⟧ = a], ANDed with c in a `_controlled`
    form, on an ancilla, computed from the 64 address qubits;
    (2) *the per-cell operation:* for each a ∈ R and each of the S cells a + j mod 2^64, the
    `_hl_controlled` access above with f_a as its control, on byte j of h (of t and v for a
    store);
    (3) *uncompute:* the decoding reversed, so that `addr`, c and every ancilla are as before.
    *Fixed:* the unitary Σ_a |a⟩⟨a| ⊗ U_a, U_a being the `_hl` access at a; `addr`, c and v
    unchanged; every ancilla `|0⟩` at return; the little-endian byte order and the wrap mod
    2^64; under c = 0 no cell touched and no host byte read; the overlay state afterwards.
    *Left to the backend:* the decoder, how tight R is (No fault, above), the order of the cells, whether
    flags are shared between the S bytes of one access. One decoder is unary iteration, BJ
    `src/qrom.jl:_qrom_tree!`: one CCX and two CX per tree node give the two child flags from the
    parent flag and one address bit, and the same three gates take them back; a bucket brigade
    or a select-swap network is as good. A load whose reachable cells are all HOST is a table
    lookup of the host bytes read at the access: BJ `src/qrom.jl:emit_qrom!` where R is a
    power-of-two block indexed by the low address bits (its table length is a power of two,
    its data at most 64 bits wide).
- **§2.** A load of unreadable host memory reads 0 (above). Nothing else is partial.
- **Ref.** None for the bus (CR's design); the decoder and the HOST-cell lookup as cited under
  Impl. **Ex.** 195 (`_hl` store and load, the in-place swap pair), 196
  (quantum-address store and load), 198 (a pointer cell), 199 (byte and word views of the same
  cells), 201, 208, 213 (`__cq_alloc`, `realloc`, K2), 202 (a load copy un-copied at once, a
  kept load copy, a kept store), 203 (a host-resident object next to bus loads), 204
  (addresses never reused), 205–207 (`swap_i1`, the in-place form, a rotated load copy). 30,
  84, 160. In the corpus: 91 examples (load 89, store 76, swap 32); widths load f64 f80 i1 i8
  i32 i64, store f64 f80 i8 i16 i32 i64, swap i1 i8 i32 i64.

### 1.11 Tape and abort: `cqrt_tape_*`, `cqrt_abort_i1`
The deferred-measurement model (CR §1.3, rule 16). Tape rails and abort flags are never freed.
All tape entries and abort flags form ONE event sequence in call order. The compiler emits the
same one effect call for every host call that is not an ordinary host call (CR rule 16),
whatever the callee, and asks nothing afterwards; this section alone says what the
backend does with it. An effect entry is complete at its `cqrt_tape_effect*` call, which follows
its fields; a format entry when the fields its format string consumes are written.

- **Resolved.** An event is *resolved* when it is complete, its predicate and all its fields
  are classical-valued (§0; an abort flag: the flag is), every cell of a buffer the backend
  knows the call reads is HOST, and every earlier event is resolved with no abort flag among
  them reading 1. The backend performs a resolved entry at once when
  its predicate is 1 and skips it when 0: a format entry is `printf` on `fmt` and its fields in
  order, an effect entry the host call `name` with its fields as the arguments (a null `name`:
  the call of the host address in the first field, with the remaining fields). The backend
  performs every entry with the host C library the lowered program is linked against, never
  with a lowered symbol; that library made every `FILE` the program holds. Memory the host
  call reads or writes is host memory, which the bus sees through the overlay (§1.10); a write the
  backend itself makes for an effect entry is a bus store (§1.10).
- **The host-boundary table.** An effect entry. The first and the last two rows apply when
  every earlier event is resolved; the five INPUT rows apply at the call whatever precedes
  (input is never held behind a deferred output; only the order of outputs is kept):

  | case | backend |
  |---|---|
  | resolved (above) | the host call at once, its result returned in the rail r |
  | INPUT call, its predicate and every field classical-valued | the host call at once, whatever precedes, its result returned in r (predicate 0: skipped, r `\|0⟩`) |
  | INPUT call, the buffer ADDRESS is a quantum rail | one host call into a temporary classical buffer, then a quantum-address bus store of those bytes |
  | INPUT call, the LENGTH is a quantum rail n | one host call at the backend's bound K2 (§0) into a temporary classical buffer; for each value v the rail n can take, the bytes the same host call with length v would have stored from that input (`fgets`: the first min(v − 1, len) bytes then a NUL for v ≥ 1, nothing for v = 0; `read`/`fread`: byte j for j < min(v, got)) are bus-stored under n = v. The input consumed is that of the K2 call on every branch (a stated deviation from the C program, like the predicate row) |
  | INPUT call under a quantum predicate | performed unconditionally, its result and its bytes merged under the predicate; the input is consumed on every branch (a stated deviation from the C program, like the measurement in an arm of CR rule 2) |
  | INPUT call, its `FILE`, descriptor or other identifying argument is a quantum rail id | never deferred: for each value v the rail can take that names a stream open at the call, one host call on v into a temporary classical buffer, its bytes bus-stored and its result merged under id = v; a value that names no open stream stores nothing. The input is consumed on every such stream (a stated deviation, like the predicate row) |
  | OUTPUT call with a quantum field or predicate, or one that reads a QUANTUM cell | deferred to the end of the shot |
  | a call that is no INPUT call whose file number, path or other identifying argument is truly quantum | deferred to the end of the shot |

  The backend knows by `name` which arguments of a host call are its buffer, its length and its
  identifying arguments, and whether it is an input call. Every other callee is an OUTPUT call:
  the stdio and POSIX writers (`printf`, `fprintf`, `puts`, `fputs`, `putchar`, `putc`, `fputc`,
  `fwrite`, `write`), a callee the backend does not know, and a null `name`. For a C library
  call whose result CR rule 16 computes in the circuit the compiler emits the bare entry (no
  r): no value the lowered program reads depends on whether the backend defers a call.

  The table the backend holds. An INPUT call is one that reads a stream or descriptor, or reads
  or changes its input state; every other callee is an OUTPUT call. The arguments of the C
  signature are the fields, in order. A string is NUL-terminated and captured as the Capture
  clause below says. The identifier matters for an INPUT call only: any other call with a
  quantum field is deferred, whichever field it is. An `_unlocked` form is its locked one.

  | callee | class | buffer or string | length | identifier |
  |---|---|---|---|---|
  | `fgets(s, n, f)`, `fgetws(s, n, f)` | INPUT (210) | s, written | n characters (`fgetws`: of 4 bytes) | f |
  | `fread(p, size, nmemb, f)` | INPUT | p, written | size·nmemb | f |
  | `read(fd, p, n)`, `pread(fd, p, n, off)` | INPUT | p, written | n | fd |
  | `gets(s)` | INPUT | s, written, at most K2 bytes | | stdin |
  | `fgetc(f)`, `getc(f)`, `getchar()`, `fgetwc(f)`, `getwc(f)`, `getwchar()`, `getw(f)`, `ungetc(c, f)`, `ungetwc(c, f)`, `feof(f)`, `ferror(f)`, `clearerr(f)` | INPUT | none | | f |
  | `scanf(fmt, …)`, `fscanf(f, fmt, …)`, `vscanf(fmt, ap)`, `vfscanf(f, fmt, ap)`, and the wide `wscanf`, `fwscanf`, `vwscanf`, `vfwscanf` | INPUT | fmt: a string (wide in the `w` forms), read; each pointer the format consumes: written with what its conversion stores | | f |
  | `getline(lp, np, f)`, `getdelim(lp, np, d, f)`, `fgetln(f, np)` | INPUT | the pointer cell `*lp`, the size cell `*np` and the line they name: written | | f |
  | `printf(fmt, …)` | OUTPUT, the format entry (47, 138, 209) | fmt and each `%s` argument: strings (`%ls`: wide) | | |
  | `fprintf(f, fmt, …)`, `vprintf(fmt, ap)`, `vfprintf(f, fmt, ap)` | OUTPUT | fmt and each `%s` argument: strings; the arguments of a `v` form through its `va_list` | | |
  | `wprintf`, `fwprintf`, `vwprintf`, `vfwprintf` | OUTPUT | as the row above with a wide fmt | | |
  | `puts(s)`, `fputs(s, f)`, `perror(s)`; `fputws(s, f)` | OUTPUT (99) | s: a string; `fputws`: a wide string | | |
  | `putchar(c)`, `putc(c, f)`, `fputc(c, f)`, `putwchar(c)`, `putwc(c, f)`, `fputwc(c, f)` | OUTPUT (209) | none | | |
  | `fwrite(p, size, nmemb, f)` | OUTPUT (99) | p, read | size·nmemb | |
  | `write(fd, p, n)` | OUTPUT | p, read | n | |
  | `fflush(f)`, `fclose(f)`, `ftell(f)`, `fileno(f)`, `fwide(f, m)`, `fseek(f, off, w)`, `fseeko(f, off, w)`, `close(fd)`, `lseek(fd, off, w)`, `tmpfile()` | OUTPUT | none | | |
  | `remove(path)`, `unlink(path)`, `rename(old, new)`, `fopen(path, mode)`, `open(path, flags, …)` | OUTPUT (102) | each pointer argument: a string | | |
  | `fsetpos(f, pos)` | OUTPUT | pos: an `fpos_t`, read | `sizeof` in the host library | |
  | `setvbuf(f, buf, mode, size)` | OUTPUT | none: buf is not read at the call; the host library keeps and later writes it as host memory (§1.10 Overlay) | | |
  | `raise(sig)` | OUTPUT (102, 212) | none | | |
  | `abort()`, `exit(code)`, `_Exit(code)`, any other `noreturn` callee | OUTPUT, followed by `abort_i1` (CR rule 16) | none known | | |
  | `__assert_fail(expr, file, line, func)` | OUTPUT, `noreturn` | expr, file, func: strings | | |
  | `__builtin_trap` (`llvm.trap` in the IR; the entry carries the C name) | OUTPUT, `noreturn`; no host symbol of that name: the backend performs a trap | none | | |
  | the fenv calls of CR rule 23 | OUTPUT | the `fenv_t` or `fexcept_t` object: read by `fesetenv`, `feupdateenv`, `fesetexceptflag`, written by `fegetenv`, `feholdexcept`, `fegetexceptflag` | `sizeof` in the host library | |
  | a null `name` | OUTPUT; the callee is the host address in the first field (96, 97, 211) | none known | | |
  | any other name | OUTPUT | none known | | |

  Never an effect entry, so never seen by the backend under these names: `malloc`, `calloc`,
  `aligned_alloc`, `realloc` (`__cq_alloc`, §1.10), `free` (nothing), `memcpy`, `memmove`,
  `memset` (bus accesses, CR rule 22), `signal` (the signal table, CR rule 16), `setjmp` and
  `longjmp` (host calls as they stand, CR rule 24: they must run in the caller's frame; under a
  quantum predicate a `longjmp` is `abort_i1` alone), the `pthread_*` calls (CR rule 24), the
  string formatters `sprintf`, `snprintf`, `sscanf` and their kin (lifted, CR rule 16), and the
  `errno` accessor.
- **Deferred.** A deferred event is one of the last two rows, an unresolved format entry or
  abort flag, or any event that is not an INPUT call behind one; its r is `|0⟩`. At the end of
  the shot (process exit: return from `main`, `exit`, or an `atexit` handler the backend registers on its first call; a
  classical `_Exit` loses the tape as it loses unflushed stdio) the backend measures the
  deferred events and performs, in sequence order, every entry whose predicate read 1 and that
  no earlier abort flag reading 1 precedes.
- **Capture.** A buffer or string a deferred entry reads is captured when the entry is
  complete, never at the end of the shot, under the entry's predicate c, over the extent the backend knows by `name` (a classical length; an OUTPUT buffer's rail
  length n at the bound K2, byte j under `j < n`; a NUL-terminated string up to its first HOST
  0 byte or K2 bytes, a wide string in 4-byte units up to its first zero unit; a `va_list`: its
  24 bytes and through them the slots the format's conversions take, as `va_arg` reads them,
  CR rule 16 *Variadic calls*): a HOST cell as its byte, a QUANTUM cell XOR-copied under c into a fresh tape
  rail (as `cqrt_tape_write_i8_controlled`; a cell at an address rail by the `_controlled`
  load), measured at the end of the shot; under c = 0 no cell is read and the rail stays `|0⟩`. The
  performed call receives the captured bytes of a string followed by a 0 and reads them up to the
  first 0 among them, a measured cell's outcome included; a string of K2 or more bytes is cut at K2
  (a stated deviation). `fmt` and `name` are copied
  at the call. The predicate c of an entry (`cqrt_tape_fmt_controlled`,
  `cqrt_tape_effect[_<W>]_controlled`) is captured at that call too: a classical-valued c as
  its bit, any other c XOR-copied into a fresh tape rail of the event, never freed, and that
  rail is what the end of the shot measures. After the call the compiler treats c by its own
  rules (it may flip, uncompute and free it; 47, 138, 211).

| sig | semantics |
|---|---|
| `i32 @cqrt_tape_alloc()` → t | A new empty tape. In the corpus each function that records entries allocates its own (47). |
| `void @cqrt_tape_fmt(i32 t, ptr fmt)` and `void @cqrt_tape_fmt_controlled(i32 c, i32 t, ptr fmt)` | Opens a `printf` entry with host format string `fmt` and predicate c (1 if uncontrolled). The entry is always appended, so the tape length is classical. |
| `void @cqrt_tape_effect_controlled(i32 c, i32 t, ptr name, i32 n)` and `i32 @cqrt_tape_effect_<W>_controlled(i32 c, i32 t, ptr name, i32 n)` → r | The effect entry of the host call `name` (`raise`, `remove`, `read`, …; a host string) under predicate c. Its arguments are the last n fields written to t before the call; fields of a preceding format entry beyond those its format string uses are ignored. `<W>` is the width token of the callee's result type (a pointer: `i64`); the bare form is emitted when the callee has no result or the program does not read it (CR rule 16). r is a fresh rail: the call's result when the entry is performed at this call, `\|0⟩` when it is skipped or deferred. No uncontrolled form exists: the compiler passes a `cqrt_alloc_i1(true)` seed (CR rule 16). |
| `i32 @cqrt_tape_write_<W>(i32 t, i32 h)` → h′ and `i32 @cqrt_tape_write_<W>_controlled(i32 c, i32 t, i32 h)` → h′ | Appends a field. h′ is a fresh write-only tape rail with h′ ^= h (`_controlled`: h′ ^= c ? h : 0). h is unchanged. h′ stays entangled with h and is never freed or uncomputed *(corpus, 47; sample_check)*. |
| `void @cqrt_tape_write_<W>_lit(i32 t, <T> lit)` | Appends a classical field. |
| `void @cqrt_abort_i1(i32 f)` | Marks f as an abort flag: kept, and an event of the sequence. f = 1 means this branch aborted at this program point. The host program keeps running; rails later modified in place were snapshotted by the compiler (rule 16). When f is classical-valued 1 (§0; always so for a fresh `alloc_i1(true)` seed) every branch aborted here and the call does not return: the shot ends at this point as at process exit (Deferred, above), the backend measuring the deferred events and performing the tape in order, the `noreturn` entry before the flag among it; the backend then ends the process if no performed entry did (CR rule 16, `noreturn`). |

- **Impl.** Not gates (b, c), except the copies named here. `tape_alloc`, `tape_fmt`,
  `tape_write_<W>_lit`, `tape_effect` and `abort_i1` append a record to the event sequence; the
  host call, its time and its result are the host-boundary logic above; the end of the shot is
  a measurement.
  - `tape_write_<W>`: a fresh rail h′ and CX(h_i, h′_i); `_controlled`: CCX(c, h_i, h′_i). A
    classical-valued h is recorded as bits.
  - A captured predicate that is not classical-valued: CX(c, a fresh tape rail). A captured
    QUANTUM cell: the `_controlled` load of §1.10 into a fresh tape rail.
  - An INPUT row that merges under a predicate, under n = v or under id = v: the flag
    [rail = v] is the circuit of `cq_template_icmp_eq_<W>_hl` (§2.4), ANDed with the predicate
    by CCX; each byte is a `_controlled` bus store (§1.10) of a classical-valued byte under
    that flag; a result is XORed into r by CX from the flag at its 1-bits; the flag is then
    uncomputed.
- **§2.** None. **Ref.** No reference implementation.
- **Ex.** 47, 138 (fmt, write widths i32, f64, `_controlled`, `_lit`), 67; abort 45, 108.
  Effect entries: 99 (`fwrite`, `fputs`), 102 (`remove`, `raise`), 209, 210 (behind a deferred
  output, the INPUT rows), 212 (`raise`), 96, 97, 211 (`cqrt_tape_effect_i32_controlled`, a
  null `name`).

### 1.12 `cqrt_push`, `cqrt_pop`
- **Sig.** `void @cqrt_push(i32 w)` and `i32 @cqrt_pop()`.
- **Sem.** A classical LIFO word stack, one per process. The calls emit no gates. The words are
  `i32`; a wider classical value is pushed as `i32` words, low word first, and popped in reverse
  (an `i64` address is two words). Three users:
  - A rule-22 copy pushes each byte's predicate and load copy in its load loop and pops them
    in its store loop.
  - A bounded loop pushes each trip's rail handles and per-trip classical values, and its
    reverse loop pops them (CR rule 14).
  - A table clone pushes the handles of the registers it minted, and its `_unc` twin pops
    them (CR §1.4).
- **Balance** is the lowered code's obligation (CR rule 14, §1.4); the backend checks nothing,
  and words nobody pops stay on the stack.
- **Rails.** None (w can be a handle, kept as a plain integer).
- **§2.** None. **Ref.** None (a host word stack). **Ex.** 05, 25, 62 (53 examples).
- **Impl.** Not a gate (c): a host array of `i32` words.

### 1.13 `cqrt_invert_begin`, `cqrt_invert_end`
- **Sig.** `void @cqrt_invert_begin()`, `void @cqrt_invert_end()`.
- **Sem.** CR rule 17 (`cq_invert`). `begin` opens a region; `end` closes the innermost open region
  and the backend then emits the gates recorded between the two calls REVERSED, each replaced by its
  inverse (an Ry or P by the same gate with the negated angle; a self-inverse gate, i.e. every
  template, every `_unc`, every core XOR gate, by itself). Allocations are not gates and keep their
  place (the rail exists from its `alloc`); a `free` recorded inside the region is performed after
  the reversed list. A measurement, a bus store or an effect entry performed at its call inside the region has
  no inverse: it flushes the gates recorded before it forward (it needs them) and is
  performed in place, the store's slot kept (§1.10); only the gates recorded after the last such event are reversed at `end`. A
  bus load and a bus swap are self-inverse gates; a tape write is an XOR gate and an abort flag
  is bookkeeping. Regions nest; `begin`/`end` are events of the host execution, so a region may
  be opened or closed under classical control, in a loop, or across a function return. A marker
  the program writes inside a quantum arm is a host call executed on every path, and the region
  then holds the arm's controlled gates, whose inverses are the controlled inverses (CR rule
  17).
- **Rails.** None of its own. **§2.** None. **Ref.** BJ `src/bennett_transform.jl:_bennett_default`
  (its uncompute is the forward gate list appended in reverse order, each NOT/CNOT/Toffoli
  being its own inverse; BJ has no rotations and no separate adjoint function). **Ex.** 44, 61,
  126.
- **Impl.** Not a gate (c): the backend holds the gates of an open region back and appends them
  at `end` in reverse order, an Ry or P with its angle negated, every X, CX and CCX as it is.
  Nothing is added to the gate list.

### 1.14 The clone table: `__cq_clone_register`, `__cq_clone_resolve`, `__cq_clone_count`, `__cq_clone_at`
Injection-bundle code, listed here because lowered code calls it; the backend does not implement
it.
- **Sig.** `void @__cq_clone_register(ptr fn, ptr sig, ptr clone, ptr ctl, ptr unc, ptr ctl_unc)`,
  `ptr @__cq_clone_resolve(ptr fn, i32 kind)`, `i32 @__cq_clone_count(ptr sig)`,
  `ptr @__cq_clone_at(ptr sig, i32 i)`.
- **Sem.** CR §1.3, rules 19 and 27: every call through a function pointer. ONE table per
  process, into which every module and lowered library registers; classical host code, no
  gates. The compiler knows no candidate set of a pointer: the table supplies it at run time.
  - `register`: a module constructor adds one row per function whose address is taken or that is
    externally visible: `fn` its host address, `sig` its LLVM function type as a C string, then
    its table clone (§3), that clone's `_ctl`, its `_unc` and its `_ctl_unc`.
  - `resolve`: the row's clone for the function at `fn` (`kind` 0 forward, 1 `_ctl`, 2 `_unc`,
    3 `_ctl_unc`), or null when `fn` has no row (host code).
  - `count`, `at`: the n registered addresses of function type `sig`, `i` < n in registration
    order. A `sig` is matched by the content of its string, never by its address: every module
    has its own private `@.cq.sig` constants.
- **Use.** A call through a classical function pointer resolves `(fp, kind)`; a null result is a
  call of host code (an ordinary call, or an effect entry with a null `name`, §1.11). A call
  through a function-pointer rail calls every registered function of the call's function type:
  for each `fn = at(sig, i)`, the `_ctl` clone under `cq_template_icmp_eq_i64_hl(rail, fn)`,
  and under the complement of those flags the effect entry with a null `name`.
- **Rails.** None. **§2.** None. **Ref.** None (a symbol table). **Ex.** 211, 212.
- **Impl.** Not a gate (c), and not the backend's: classical host C of the injection bundle.

---

## 2. Templates (`cq_template_*`)

### 2.1 Grammar and conventions (CR §1.2)
```
cq_template_<op>[_<pred>]_<W>[_to_<W2>][_<shape>][_rm|_rmq][_exc][_unc]
```
| element | rule |
|---|---|
| forward | `i32 @cq_template_X(args…)`. Takes a fresh `\|0⟩` result rail o, sets o ^= f(args), returns o. Every operand is unchanged and no ancilla is left dirty. |
| `_unc` | `void @cq_template_X_unc(i32 o, args…)`, with exactly the forward argument list and the same literals. o ^= f(args). Precondition: every handle in `args` holds its forward value and o holds f(args). Postcondition: o = `\|0⟩`. The caller then calls `cqrt_free(o)`; `_unc` never frees. Forward and `_unc` are the same XOR map, and implementations may share it. |
| `_unc` coverage | The backend provides `_unc` for **every** forward template. The corpus never calls the `_unc` of 49 of its forward templates (results kept or measured), which does not make them optional. |
| W | The operand width. A cast spells `<from>_to_<to>`. The result width is W, except compares, `*_overflow` and `is_fpclass` (`i1`), casts (W2) and `_exc` (`i32`). |
| shape | One letter per **data** operand in signature order: `h`/`q` is a handle and `l` a literal. Omitted means all handles. Binary ops use `_hl`, or `_lh` for a non-commutative op only (a commutative op is swapped to `_hl`; an fp op only when the literal is not a NaN, CR §1.2). Compares never take `_lh`; the predicate is flipped instead. `select` letters cover the two **arms**, and the condition is always a handle. Ternary ops (`fma`, `fshl`, `fshr`) take every mix of `q` and `l`, bare for `qqq`; `fma`'s product operands are commutative, so `lqq` and `lql` are spelled `qlq` and `qll` unless the literal is a NaN; `fshl` and `fshr` keep every mixed shape. `_ll` is a binary op whose only quantum operand is the `_rmq` mode (`fadd_f64_ll_rmq`). |
| literal | Typed as the LLVM operand: `i1 true`, `i128`, `double`, `x86_fp80`, `half`. A narrow literal is read as its low W bits. |
| `_rm` / `_rmq` | Rounding mode as the **last** argument: `_rm` an `i32` literal, `_rmq` an `i32` rail. It is the x86-64 `FE_*` value: bits 10–11 select 0 nearest-even, 1 down, 2 up, 3 toward zero (`FE_TONEAREST 0`, `FE_DOWNWARD 1024`, `FE_UPWARD 2048`, `FE_TOWARDZERO 3072`); the other bits are ignored (CR §1.2). |
| `_exc` | Same operands and mode. The fresh `i32` result rail holds the x86 exception bits the operation raises: `INVALID 1`, `DIVBYZERO 4`, `OVERFLOW 8`, `UNDERFLOW 16`, `INEXACT 32` (no DENORMAL); tininess after rounding, UNDERFLOW only together with INEXACT; a quiet NaN operand raises INVALID only in `fcmps`, conversions to integer and invalid arithmetic (CR §1.2). |
| Impl. | Every template is built as §0 "Building the circuits" says; the Impl. list under each table names the BJ circuit or spells the composition. A template never takes `_controlled`. |

Shape → operand mapping, as declared in the corpus:

| spelling | signature | meaning |
|---|---|---|
| `sub_i32` | `(i32 a, i32 b)` | o = a − b |
| `sub_i32_hl` | `(i32 a, i32 lit)` | o = a − lit |
| `sub_i32_lh` | `(i32 lit, i32 b)` | o = lit − b (the literal comes first; both are `i32`) |
| `shl_i64_lh` | `(i64 lit, i32 k)` | o = lit << (⟦k⟧ mod 64) |
| `select_i8_lh` | `(i32 c, i8 lit, i32 b)` | o = ⟦c⟧ ? lit : ⟦b⟧ |
| `fshl_i32_qll` | `(i32 a, i32 b, i32 k)` | o = fshl(⟦a⟧, b, k) |
| `copysign_f64_lh` | `(double mag, i32 s)` | o = copysign(mag, ⟦s⟧) |
| `fadd_f64_hl_rm_exc` | `(i32 a, double lit, i32 mode)` | exception bits of a + lit under mode |
| `fadd_f64_ll_rmq` | `(double x, double y, i32 m)` | o = x + y rounded under the quantum mode m (80, 100) |

Below, "BJ" names the Bennett.jl circuit. Columns: **ops**, **semantics with §2 totalization**,
**corpus widths**, **reference**, **ex**. "Wrapped" and "compiled" are the two constructions of
§0.

### 2.2 Integer arithmetic
| op | semantics (unsigned ⟦·⟧ mod 2^W unless s-) | widths | reference | ex |
|---|---|---|---|---|
| `add` | a + b | i7 i8 i16 i32 i64 i100 i128 | BJ `src/adder.jl:lower_add!` (`lower_add_cuccaro!`, `src/qcla.jl:lower_add_qcla!`) | 01, 02, 110 |
| `sub` | a − b | i8 i16 i32 i64 | BJ `src/adder.jl:lower_sub!` | 10, 22, 156 |
| `mul` | a · b mod 2^W | i32 i64 i100 i128 | BJ `src/multiplier.jl:lower_mul!` | 04, 06, 93 |
| `udiv` | ⌊a/b⌋; **b = 0 → 2^W − 1** | i32 i128 | BJ `src/divider.jl:_soft_udiv_compile` (same b = 0 result; a 64-bit kernel) | 11, 37, 93 |
| `urem` | a mod b; **b = 0 → a** | i32 | BJ `src/divider.jl:_soft_urem_compile` | 11, 62, 74 |
| `sdiv` | signed, truncating; **b = 0 → −1 if a ≥ 0 else +1**; **INT_MIN/−1 → INT_MIN** | i32 | BJ `src/lowering/aggregate.jl:lower_divrem!` | 11, 156 |
| `srem` | sign of a; **b = 0 → a**; **INT_MIN rem −1 → 0** | i32 | BJ `src/lowering/aggregate.jl:lower_divrem!` | 11, 156 |

**Impl.**
- `add`, `sub`, `mul`: the BJ emitter, wrapped (§0). `lower_add!` is a ripple adder: per bit three
  CX and two CCX, W carry ancillae. `lower_sub!` is a + ¬b + 1 on a complemented copy of b.
  `lower_mul!` is `src/multiplier.jl:lower_mul_wide!` at result width W: W rows of CCX partial
  products, each added by `lower_add!`. `_hl`, `_lh`: the literal operand of §0.
- `udiv`, `urem`, W ≤ 64: BJ `lower_divrem!`: both operands zero-extended to 64 bits by CX, the
  kernel (64 restoring trips of shift, compare, subtract and select, compiled by
  `reversible_compile`), the low W bits copied out. The b = 0 rows are the kernel's own values
  (2^64 − 1 truncates to 2^W − 1; the remainder is a).
- `sdiv`, `srem`, W ≤ 64: BJ `lower_divrem!`: sign-extend, negate each operand under its sign bit
  (`src/lowering/aggregate.jl:_cond_negate_inplace!`), the unsigned kernel, then negate the result
  under sign(a) ⊕ sign(b) (`sdiv`) or sign(a) (`srem`). Every CR §2 row is what this circuit
  gives: b = 0 yields all ones, sign-fixed to −1 or +1 (`srem`: a); INT_MIN/−1 wraps to INT_MIN
  with remainder 0.
- W > 64 (`udiv_i128_lh`): the kernels are `UInt64` only. **EXTEND**, §2.11.

### 2.3 Bitwise and shifts
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `and` `or` `xor` | bitwise; the `i1` forms are the data templates of flags (CR rule 8) | and: i1 i8 i16 i32 i64; or: i32 i64 i128; xor: i1 i8 i32 i64 | BJ `src/lowering/arith.jl:lower_and!`/`lower_or!`/`lower_xor!` | 10, 12, 77 |
| `shl` `lshr` `ashr` | shift by **⟦k⟧ mod W**, literal or quantum amount (CR §2: a totalization of LLVM's poison; x86's masking of 8- and 16-bit counts is not the reference) | shl: i8 i16 i32 i64; lshr: i32 i64 i100 i128; ashr: i32 i64 | BJ `src/lowering/arith.jl:lower_var_shl!`/`lower_var_lshr!`/`lower_var_ashr!`; constant amount: `lower_shl!`/`lower_lshr!`/`lower_ashr!` | 10, 18, 53 |
| `fshl` `fshr` | LLVM funnel shifts, **amount mod W**: fshl = high W bits of (a∥b) << k; fshr = low W bits of (a∥b) >> k | i32 (fshl: bare, `qql`, `qll`; fshr: bare, `qql`) | BJ `src/extract/instructions.jl:_handle_intrinsic` (`llvm.fshl.`/`llvm.fshr.` expansion) | 56, 112, 134 |

**Impl.**
- `and`: CCX(a_i, b_i, o_i). `or`: CX(a_i, o_i), CX(b_i, o_i), CCX(a_i, b_i, o_i). `xor`:
  CX(a_i, o_i), CX(b_i, o_i). Straight onto o, no ancilla. `_hl`: `and` is CX(a_i, o_i) at the
  1-bits of the literal; `or` is X(o_i) at its 1-bits and CX(a_i, o_i) at its 0-bits; `xor` is
  CX(a_i, o_i) everywhere and X(o_i) at its 1-bits.
- Shift by a literal (`_hl`): k = lit mod W on the host, then CX wiring only (BJ `lower_shl!`,
  `lower_lshr!`, `lower_ashr!`): shl o_(i+k) ^= a_i; lshr o_i ^= a_(i+k); ashr as lshr plus the
  sign bit a_(W−1) into the top k bits. BJ takes k ∈ [0, W] and at k = W gives 0 (ashr: the
  sign in every bit): here k = W has become 0, a copy.
- Shift by a rail: BJ `lower_var_*!`, a barrel shifter of ⌈log2 W⌉ `lower_mux!` stages over the
  low ⌈log2 W⌉ bits of the amount, wrapped. That is mod W only when W is a power of two. At any
  other W (i7, i100) it must be adapted: at W = 100 BJ's `lower_var_shl!` gives 0 for an amount
  of 100…127 and the unshifted value for 128 (`lower_var_ashr!` fills with the sign instead). Reduce first: r = k mod W (`urem` by the literal W),
  shift by r, uncompute r. `_lh`: the shifted value is the literal operand.
- `fshl`, `fshr`: BJ's expansion: k = s mod W; k = 0 gives a (fshl) or b (fshr); otherwise
  (a << k) | (b >> (W − k)), for fshr (a << (W − k)) | (b >> k). With a literal amount this is
  CX wiring (the two parts fill disjoint bits of o). With a rail amount it is the shifts above,
  `or`, `icmp_eq` against 0 and `select`; BJ builds it for W a power of two and rejects any
  other W: reduce the amount as for a shift.

### 2.4 Compare
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `icmp_<pred>` | `i1` result; pred ∈ eq ne ugt uge ult ule sgt sge slt sle | i8 i32 i64 i128 (used: eq ne sgt slt ugt ult) | BJ `src/lowering/arith.jl:lower_icmp!` (`lower_eq!`, `lower_ult!`, `lower_slt!`) | 03, 04, 134 |
| `fcmp_<pred>` | `i1` result; LLVM fcmp, o = ordered and u = unordered or | f32 f64 f80 (used: oeq ogt olt one ord ueq uge ult une uno) | f64: BJ `src/softfloat/fcmp.jl:soft_fcmp_olt`, `soft_fcmp_oeq`, `soft_fcmp_ole`, `soft_fcmp_une`, `soft_fcmp_ord`, `soft_fcmp_uno`, `soft_fcmp_one`, `soft_fcmp_ueq`, `soft_fcmp_ult`, `soft_fcmp_ule`. f16, bf16, f32, f80: **EXTEND** (IEEE 754 compare, NaN unordered; f80 on x87 extended values) | 15, 48, 69 |
| `fcmps_<pred>` | the signaling compare; value as `fcmp`. Used only as `_exc`: INVALID (1) iff either operand is NaN | f64 | **EXTEND** (exception bits) | 81, 100 |

**Impl.**
- `icmp`: BJ `lower_icmp!`, wrapped. eq: `lower_eq!` (the bitwise XOR of the operands, an OR
  chain over it, a final X); ne: eq and one more X. ult: `lower_ult!` (the carry chain of
  a + ¬b + 1; the result is the complemented carry-out); ugt: ult with the operands swapped; ule,
  uge: their complements. slt: `lower_slt!` (both sign bits flipped, then ult); sgt, sle, sge
  likewise. `_hl`: the literal operand of §0.
- `fcmp` f64: the kernel of the predicate, compiled; bit 0 of its value is XORed into o. ogt,
  oge, ugt, uge are olt, ole, ult, ule with the operands swapped (BJ
  `src/extract/instructions.jl`, the fcmp dispatch). f32: `fpext` both operands to f64 (exact,
  §2.6), the f64 kernel, uncompute. f16, bf16, f80: §2.11.
- `fcmps`: its value is `fcmp`'s. The `_exc` word: §2.11.

### 2.5 Select
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `select` | `(i32 c, arm1, arm2)`: **o = ⟦c⟧ = 1 ? arm1 : arm2** (LLVM operand order; 04: `select_i32(f, then, else)`). Shapes `hl`, `lh`, `ll` give the arms; c is an `i1` rail. | i8 i32 i64 i128 f32 f64 f80 | BJ `src/lowering/arith.jl:lower_select!`/`lower_mux!`; BVM `src/ir/select_instruction.jl:SelectInstruction` (semantics) | 04, 09, 101 |

**Impl.** BJ `lower_mux!` (r ^= arm2; diff = arm1 ⊕ arm2; CCX(c, diff_i, r_i)), wrapped. The same
map with no ancilla, per bit: CX(arm2_i, o_i), CCX(c, arm1_i, o_i), CCX(c, arm2_i, o_i). `_hl`
(arm2 literal): X(o_i) and CX(c, o_i) at the 1-bits of the literal, CCX(c, arm1_i, o_i). `_lh`
(arm1 literal): CX(arm2_i, o_i), CCX(c, arm2_i, o_i), CX(c, o_i) at the 1-bits of the literal.
`_ll`: X(o_i) at the 1-bits of lit2, CX(c, o_i) at the 1-bits of lit1 ⊕ lit2. An fp width is its
bit pattern.

### 2.6 Casts
| op | semantics | corpus pairs | reference | ex |
|---|---|---|---|---|
| `zext` `sext` `trunc` (int) | as LLVM | zext i1→i8/i32, i8→i32/i64, i16→i32, i32→i64, i64→i100/i128; sext i7/i8→i32, i32→i64; trunc i32→i8/i16, i64→i7/i32, i100/i128→i64 | BJ `src/lowering/arith.jl:lower_cast!` | 17, 18, 46 |
| `bitcast` | bit pattern copied (o ^= a) | f64↔i64 | BJ `src/extract/instructions.jl` (the bitcast arm: a same-width `IRCast`) | 18, 50, 51 |
| `fpext` | exact widening; a NaN is quieted, its payload left-aligned (x86). bf16→f32 is a bare 16-bit shift, an sNaN stays signalling (CR §2) | f16→f32, f32→f64, f64→f80 | f32→f64: BJ `src/softfloat/fpconv.jl:soft_fpext`. Every other pair: **EXTEND** | 17, 111, 172 |
| `fptrunc` | IEEE RNE narrowing, overflow → ±Inf. To bf16: one rounding from the source width, a NaN becomes a quiet NaN carrying the high payload bits (CR §2) | f32→f16, f64→f32 | f64→f32: BJ `src/softfloat/fpconv.jl:soft_fptrunc`. Every other pair: **EXTEND** (RNE at the target, subnormals, overflow to Inf) | 17, 111, 183 |
| `sitofp` `uitofp` | correctly rounded (RNE). From more than 64 bits and to bf16 the CR §2 rows hold: above 128 bits `ExpandLargeFpConvert`'s value, except `uitofp` to f80, which is the non-negative value rounded to nearest even at the 64-bit significand; to bf16 through f32, two roundings | sitofp i32→f64; uitofp i1→f32/f64/f80, i8/i32→f64 | to f64 from at most 64 bits: BJ `src/softfloat/sitofp.jl:soft_sitofp`/`soft_uitofp`. Every other pair: **EXTEND** (RNE at the target's significand) | 17, 69, 157 |
| `fptosi` `fptoui` | truncate toward 0; NaN, ±Inf, out of range: **the x86-64 LLVM 19 `-O1` result** (CR §2): with c32/c64 = cvtt to i32/i64 (indefinite = INT_MIN of that width), s8/s16 = trunc(c32), s32 = c32, s64 = c64, u8/u16 = trunc(c32), u32 = trunc(c64), u64 = `r1 \| (r2 & (r1 >>s 63))`, r1 = c64(x), r2 = c64(x − 2^63); f16 via f32; f80 via x87 `fist` and wider targets by the CR §2 row | f64→i32 | from f64: BJ `src/softfloat/fptosi.jl:soft_fptosi` (= c64), `src/softfloat/fptoui.jl:soft_fptoui` (= the u64 formula), adapted below. From f80, and to more than 64 bits: **EXTEND** | 17, 56, 169 |

**Impl.**
- `zext`, `sext`, `trunc`: CX wiring straight onto o (BJ `lower_cast!`): zext CX(a_i, o_i); sext
  also CX(a_(W−1), o_j) for every higher bit j; trunc the low W2 bits. `bitcast`: W CX.
- `fpext` f32→f64, `fptrunc` f64→f32: the kernels (`UInt32` → `UInt64` and back), compiled.
- `sitofp`, `uitofp` to f64: the source sign-extended (`sitofp`) or zero-extended (`uitofp`) to
  64 bits by CX, then `soft_sitofp`; a 64-bit `uitofp` source takes `soft_uitofp` (BJ
  `src/extract/instructions.jl`, the sitofp/uitofp dispatch).
- `fptosi`, `fptoui` from f64. `soft_fptosi` is c64 and `soft_fptoui` is the u64 formula, exactly.
  BJ narrows by truncating that 64-bit value, which is not the CR table: `soft_fptosi(3e9)` has
  the low word 0xB2D05E00 where c32 is 0x80000000, and `soft_fptoui(2^63 + 2^11)` has the low
  word 0x800 where trunc(c64) is 0. Build instead: s64 = `soft_fptosi`; u64 = `soft_fptoui`;
  u32 = the low 32 bits of `soft_fptosi`; c32 = `soft_fptosi` with its invalid test moved to a
  biased exponent ≥ 1054 (|x| ≥ 2^31) and the indefinite 0x80000000, low 32 bits; s32 = c32; s8,
  s16, u8, u16 = the low bits of c32. From f16 and f32: `fpext` first.

### 2.7 Overflow, saturating, min/max, abs
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `{u,s}{add,sub,mul}_overflow` | **`i1` overflow flag only** (element 1 of `*.with.overflow`). Element 0 is the ordinary `add`/`sub`/`mul` template over the same operands (CR rule 4). u: unsigned carry/borrow/product > 2^W−1; s: signed result out of range | uadd i32 (`hl`), sadd i32, usub i64, umul i32 (`hl`) (ssub and smul not in the corpus) | one literal operand, sadd, uadd, smul, umul, W ≤ 64: BJ `src/extract/instructions.jl:_fuse_overflow_extractvalue` with `_ovf_admissible_range`. usub (= a <ᵤ b): `src/lowering/arith.jl:lower_ult!`. Two rails, and ssub: none (BJ fails loudly on two dynamic operands) | 92, 112 |
| `uadd_sat` `usub_sat` | min(a + b, 2^W − 1); max(a − b, 0) | i32 (`hl`) | none in BJ (`_WIDTH_DEPENDENT_INTRINSICS` lists them, but there is no expansion) | 92, 109 |
| `sadd_sat` `ssub_sat` | signed a + b / a − b clamped to [−2^(W−1), 2^(W−1) − 1] (`llvm.sadd.sat`/`llvm.ssub.sat`; total, no CR §2 row). Overflow iff sign(a) = sign(b) ≠ sign(a + b) (sub: sign(a) ≠ sign(b) and sign(a − b) ≠ sign(a)); the clamp is sign(a) in the top bit and its complement below | i32 (ssub not in the corpus) | none in BJ | 194 |
| `smax` `smin` `umax` `umin` | as LLVM | smax, smin i32 (`hl`); umax i32; umin i32 (`hl`), i64 | BJ `src/extract/instructions.jl:_handle_intrinsic` (compare + select) | 26, 56, 109 |
| `abs` | \|a\|; **abs(INT_MIN) = INT_MIN** | i32 | BJ `src/extract/instructions.jl:_handle_intrinsic` | 56 |

**Impl.** Compositions of §2.2–§2.5 on ancilla rails, each undone after the write to o.
- `uadd_overflow`: s = a + b; o ^= [s <ᵤ a] (`lower_ult!`). `usub_overflow`: o ^= [a <ᵤ b].
- `sadd_overflow`: s = a + b; t1 = sign(a) ⊕ sign(s) and t2 = sign(b) ⊕ sign(s) by CX on two
  ancillae; CCX(t1, t2, o). `ssub_overflow`: d = a − b; t1 = sign(a) ⊕ sign(b), t2 = sign(a) ⊕
  sign(d); CCX(t1, t2, o).
- `umul_overflow`: the 2W-bit product (BJ `src/multiplier.jl:lower_mul_wide!` at result width
  2W); o ^= the OR of its high W bits (the OR chain of `lower_eq!`). `smul_overflow`: both
  operands sign-extended to 2W bits, `lower_mul!` at 2W; o ^= the OR over i ≥ W of p_i ⊕ p_(W−1).
- With one literal operand BJ gives the same flag as an interval test on the rail, `x < L or
  x > U` with L and U computed from the literal (`_ovf_admissible_range`; sadd, uadd, smul,
  umul): two `icmp_hl` and an OR. It is an alternative for the `_hl` shapes, not a requirement.
- `uadd_sat`: s and the `uadd_overflow` flag v; o_i = s_i ∨ v: CX(s_i, o_i), CX(v, o_i),
  CCX(s_i, v, o_i). `usub_sat`: d = a − b and v = [a <ᵤ b]; CX(d_i, o_i), CCX(v, d_i, o_i).
- `sadd_sat`, `ssub_sat`: s (or d), the signed overflow flag v as above, and the clamp register
  (top bit sign(a), every lower bit its complement, by CX and X); o = `select`(v, clamp, s).
- `smax`, `smin`, `umax`, `umin`: BJ: `icmp` sge / sle / uge / ule of (a, b), then
  `select`(flag, a, b).
- `abs`: BJ: n = 0 − a, f = [a ≥ₛ 0], `select`(f, a, n). INT_MIN stays INT_MIN.

### 2.8 Bit counting
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `ctlz` `cttz` | the result has width W; **ctlz(0) = cttz(0) = W** | ctlz i32 i64, cttz i64 | BJ `src/extract/instructions.jl:_handle_intrinsic` | 56, 108 |
| `ctpop` | popcount, width W | i32 | same | 56, 178 |
| `bswap` | byte reversal (W a multiple of 16) | i32 | same | 109 |
| `bitreverse` | bit i of a at bit W − 1 − i | none in the corpus | same | none |

**Impl.**
- `ctlz`: BJ: start from the literal W; for bit i from 0 up to W − 1 a `select` on a_i replaces
  the running value by the literal W − 1 − i, so the highest set bit wins and 0 gives W. `cttz`:
  the same from the top bit down, with the literal i. Wrapped.
- `ctpop`: BJ: the W bits summed by W − 1 `add`s at width W. Wrapped.
- `bswap`, `bitreverse`: BJ expands them into shifts, masks and ORs; what results is CX wiring
  only. bswap: o_(8j+r) ^= a_(8(n−1−j)+r) for the n = W/8 bytes; bitreverse: o_i ^= a_(W−1−i).

### 2.9 Floating-point arithmetic
All results are IEEE, round to nearest even unless `_rm`/`_rmq` is present. Operands and results are
bit patterns. `llvm.fmuladd` reaches the backend as `fmul` then `fadd` (unfused, CR §2). Only
`llvm.fma` uses `fma`. A NaN result follows x86 SSE in IR operand order: the first NaN operand, quieted; an invalid operation gives `0xFFF8000000000000` (f32 `0xFFC00000`, f16 `0xFE00`, bf16 `0xFFC0`, f80 the real indefinite `0xFFFF_C000000000000000`) (CR §2).
An f80 operand in a non-canonical encoding (pseudo-NaN, pseudo-Inf, unnormal) is an invalid
operand: it reads as the real indefinite, a NaN, so an fp result is the real indefinite and a
compare (`fcmp`, `fcmps`) is unordered, each with INVALID in its `_exc` word, as x87 does; a
pseudo-denormal reads as a denormal (CR §2).

| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `fadd` `fsub` `fmul` `fdiv` | IEEE basic ops | fadd f16 f32 f64 f80; fsub, fmul, fdiv f32 f64 f80; `_rm`/`_rmq`/`_exc` only f64 (fadd, fmul, fdiv) | f64: BJ `src/softfloat/fadd.jl:soft_fadd`, `fsub.jl:soft_fsub`, `fmul.jl:soft_fmul`, `fdiv.jl:soft_fdiv` (x86-exact: `INDEF` 0xFFF8… for invalid). f16/bf16/f32/f80 and any `_rm`/`_rmq`/`_exc`: **EXTEND** (IEEE 754 binary16/32 RNE with subnormals; x87 extended with 64-bit significand and PC = extended; directed modes RD/RU/RZ per the mode operand; `_exc` sets the bits of §2.1) | 13, 14, 80 |
| `fneg` | sign-bit flip (no rounding) | f32 f64 f80 | BJ `src/softfloat/fneg.jl:soft_fneg` (f64; the same XOR at bit W−1 at any width) | 13, 69 |
| `sqrt` | IEEE sqrt; negative → NaN | f64 | BJ `src/softfloat/fsqrt.jl:soft_fsqrt`; other widths **EXTEND** | 16, 172, 183 |
| `fma` | fused, one rounding (`llvm.fma` only) | none in corpus | f64: BJ `src/softfloat/fma.jl:soft_fma`; others **EXTEND** (one rounding; f32 cannot be emulated by f64 double rounding) | none |
| `frem` | IEEE `fmod` (exact): sign of x; fmod(x, 0) = NaN; fmod(±Inf, y) = NaN; fmod(x, ±Inf) = x; NaN propagates | f32 (bare), f64 (`hl`, `lh`), f80 (`hl`) | **EXTEND** (no reference implementation in BJ) | 83 |

**Impl.**
- `fadd`, `fsub`, `fmul`, `fdiv`, `sqrt`, `fma` at f64: the kernel, compiled by
  `reversible_compile` (`soft_fadd`: 62,800 gates, 12,488 of them CCX, at BJ's default options).
  `soft_fsub` is `soft_fadd` with the sign of b flipped unless b is a NaN. The NaN row above is
  the kernels' own (`src/softfloat/softfloat_common.jl:_sf_propagate_nan2`, `_sf_propagate_nan3`
  for `fma`). `_hl`, `_lh`: the literal operand of §0.
- `fneg`, any width: CX(a_i, o_i) on every bit and X on the sign bit of o (bit W − 1; f80:
  bit 79). No kernel.
- Every other width, `_rm`, `_rmq`, `_exc`, `frem`: §2.11.

### 2.10 Floating-point misc
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `fabs` | clear the sign bit | f32 f64 f80 | BJ `src/extract/instructions.jl:_handle_intrinsic` (`llvm.fabs.`, an AND with a 64-bit mask: W ≤ 64) | 16, 69, 104 |
| `copysign` | magnitude of arg 0, sign of arg 1 (non-commutative: `hl`, `lh`) | f32 f64 f80 | BJ same (`llvm.copysign.`; W ≤ 64) | 16, 69, 169 |
| `fmax` `fmin` | `fmax(a, b) = isnan(a) ? b : isnan(b) ? a : (b > a ? b : a)`, `fmin` with `<`: equal values (±0) give a, two NaNs give b unchanged (x86-64 `-O1`, CR §2) | fmax f64 (`hl`, bare) (fmin not in the corpus) | f64: BJ `src/softfloat/fmin.jl:soft_fmax`/`soft_fmin`, adapted below; other widths **EXTEND** | 16, 169 |
| `floor` `ceil` `trunc` `rint` `round` | IEEE roundToIntegral: floor and ceil toward −∞ and +∞; trunc toward 0; **rint in the current mode**: ties to even in the plain template, the template's mode with `_rm`/`_rmq` (CR §2); round = C `round`, ties away from zero | floor, trunc, rint f64 (ceil and round not in the corpus) | f64: BJ `src/softfloat/fround.jl:soft_floor`/`soft_ceil`/`soft_trunc`/`soft_round` (RNE)/`soft_round_away`; other widths **EXTEND** | 16 |
| `is_fpclass` | `(i32 h, i32 mask)` → `i1` = 1 iff h's class bit is set in mask. LLVM bit order: 0 sNaN, 1 qNaN, 2 −Inf, 3 −normal, 4 −subnormal, 5 −0, 6 +0, 7 +subnormal, 8 +normal, 9 +Inf (104: 264 = isnormal). A pure bit test that raises no exception; on f80 a pseudo-denormal is subnormal and a non-canonical encoding is a quiet NaN (CR §2) | f64 `_hl` | **EXTEND** (no reference implementation) | 104 |

**Impl.**
- `fabs`, any width: CX(a_i, o_i) for i < W − 1; the sign bit of o stays 0. `copysign`:
  CX(a_i, o_i) for i < W − 1 and CX(b_(W−1), o_(W−1)); `_hl` (literal sign): X(o_(W−1)) when
  the literal's sign bit is set; `_lh` (literal magnitude): X(o_i) at the 1-bits of the literal
  below the sign bit, CX(b_(W−1), o_(W−1)). BJ's expansions are the same wiring for W ≤ 64.
- `fmax`, `fmin` at f64: the kernel, adapted. BJ breaks the ±0 tie by sign (`soft_fmax(−0, +0)`
  is +0, `soft_fmin(+0, −0)` is −0) where the contract returns a. Drop the kernel's `both_zero`
  arm: `fmax` picks b iff `soft_fcmp_olt(a, b)`, `fmin` picks b iff `soft_fcmp_olt(b, a)`. Its
  NaN arms are the contract's (a NaN: b; b NaN: a; both: b).
- `floor`, `ceil`, `trunc`, `rint`, `round` at f64: the kernels, compiled: `soft_floor`,
  `soft_ceil`, `soft_trunc`, `soft_round` (plain `rint`), `soft_round_away` (`round`). `rint`
  with a mode: the kernel the mode names, `soft_round`, `soft_floor`, `soft_ceil` or `soft_trunc`
  for 0, 1, 2, 3; `_rmq`: all four values and a `select` on bits 10–11 of the mode rail, or one
  kernel with a mode operand (§2.11).
- `is_fpclass`: §2.11.

### 2.11 EXTEND: the kernels the backend writes
An EXTEND family gets its circuit the way the f64 families do: a branchless integer kernel on
bit patterns, built from the integer circuits of §2.2–§2.5 (§0). Bennett.jl has no kernel for
these families; the backend writes each one, with BJ's f64 kernel as the model for the
algorithm. The last column records a cross-check, not a dependency: scratch kernels of each
kind were given to BJ's compiler at the pinned revision (Julia 1.12.1 with LLVM.jl 9.13.2; with
LLVM.jl 10.4.3 the package fails to load on a missing `LLVM.NewPMPassBuilder`) and the
X/CX/CCX circuits it produced were simulated against a host reference on sampled inputs. That
shows such a kernel yields a clean circuit at these widths and what it costs. It does not show
a production kernel correct: each kernel owes its own test against its CR §2 rows.

| family | kernel to write | modelled on | cross-check with BJ's compiler |
|---|---|---|---|
| `fadd` `fsub` `fmul` `fdiv` `sqrt` `fma`, the rounding ops, `fmax`/`fmin`, `fcmp` at f16, bf16, f32 | the f64 body on `UInt16`/`UInt32` with the format's field widths (fraction 10, 7, 23 bits; exponent 5, 8, 8) | BJ `soft_fadd`, `soft_fmul`, `soft_fdiv`, `soft_fsqrt`, `soft_fma`, `soft_floor`…, and the shared steps `src/softfloat/softfloat_common.jl:_sf_normalize_clz`, `_sf_handle_subnormal`, `_sf_round_and_pack` | an f32 and an f16 add compiled (47,978 and 42,868 gates) and agreed with native `Float32` and `Float16` addition on 600 samples each. `Float32` and `Float16` arguments are rejected, so the functions take the unsigned integer. BJ's own f32 route (`fpext`, the f64 kernel, `fptrunc`) rounds twice and BJ does not call it bit-exact (`src/softfloat/fpconv.jl`, header) |
| every f80 op | functions on the pair (significand `UInt64`, sign and exponent `UInt16`) with a tuple result; wider intermediates as (hi, lo) `UInt64` pairs. The explicit integer bit and the non-canonical encodings (§2.9) have no f64 counterpart | the same kernels with BJ `src/softfloat/softfloat_common.jl:_add128`, `_sub128`, `_shiftRightJam128`, `_sf_widemul_u64_to_128` (the `soft_fma` helpers) for the 64-bit steps | the plumbing only: a `(UInt64, UInt16)` operand pair, a tuple result, a 64×64→128 product and a 128-bit align-and-add through the helpers all compiled. A `UInt128` argument is rejected, and a `UInt128` intermediate failed on an `i128` constant. No f80 kernel was written |
| `_rm`, `_rmq` | the kernel with the mode as an operand (bits 10–11): the rounding decision, the overflow result (±Inf or the largest finite) and the sign of an exact zero sum depend on it. `_rm` is the same circuit with a literal mode | BJ `_sf_round_and_pack`, `_sf_handle_subnormal` | an f64 add with a mode operand compiled (57,866 gates) and agreed with a BigFloat reference in all four modes on 400 samples |
| `_exc` | a second function over the same operands and mode that returns the `i32` flag word | the same kernel | compiled for that add (48,192 gates); INEXACT and OVERFLOW agreed on 400 samples. INVALID, DIVBYZERO and UNDERFLOW were not checked |
| `frem` | signs and specials by the §2.9 row, then a fixed-trip restoring loop on the significands, one trip per unit of exponent difference: 277 trips at f32, 2,098 at f64, 32,829 at f80 | BJ `src/divider.jl:_soft_urem_compile` | an f32 `frem` compiled with `max_loop_iterations = 300`: 4,283,637 gates, 1,073,504 of them CCX; its circuit agreed with `rem(::Float32, ::Float32)` on 300 samples. f64 and f80 were not tried; the gate count grows with the trip count |
| `is_fpclass` | the ten class bits from the fields, ANDed with the mask, OR-reduced | the field tests of BJ `src/softfloat/fcmp.jl:_either_nan` | f64 with a rail mask compiled (4,602 gates), 300 samples. With the literal mask of `_hl` only the classes it names are tested |
| `fcmps` `_exc` | INVALID iff an operand is a NaN | BJ `src/softfloat/fcmp.jl:soft_fcmp_uno` | f64 compiled (1,702 gates) |
| `fpext`, `fptrunc` at f16, bf16, f80 | the conversions with the other field widths | BJ `soft_fpext`, `soft_fptrunc` | not tried |
| `sitofp`, `uitofp` to f16, bf16, f32, f80, and from more than 64 bits | `soft_sitofp` with the target's fields; a wide source as (hi, lo) pairs; the CR §2 rows above 64 and 128 bits | BJ `soft_sitofp`, `soft_uitofp` | not tried |
| `fptosi`, `fptoui` from f80, and to more than 64 bits | the x87 `fist` rows of CR §2 | BJ `soft_fptosi`, `soft_fptoui` | not tried |
| `udiv` `urem` `sdiv` `srem` above 64 bits | the restoring loop with W trips on (hi, lo) pairs | BJ `_soft_udiv_compile`, `_soft_urem_compile` | a 128-bit `udiv` on pairs compiled with `max_loop_iterations = 130` (2,139,127 gates) and agreed with `UInt128` division, b = 0 included, on 30 samples |
| a shift or funnel shift by a rail at a W that is no power of two | `urem` of the amount by the literal W, then the BJ barrel shifter | BJ `lower_var_shl!` | the deviation was measured at W = 100 (§2.3); the adapted circuit was not built |

The BJ gate emitters need no such function at any width: `lower_add!`, `lower_sub!`, `lower_mul!`
and `lower_ult!` were run at W = 100 and 128 against big-integer arithmetic (20 samples each).

---

## 3. Clones (not backend primitives)

A clone `__cq_q_<fn>_<mask>[_b…][_t][_ctl][_pure][_unc]` (CR §1.4) is ordinary lowered code that
calls the primitives above. The backend links clones and never implements them.

- **Every body is lowered.** The mask has one digit per scalar formal after aggregate flattening
  (1 = a handle). A pointer is one scalar: a classical `ptr` or one handle to a 64-bit address
  rail. The all-zero mask is the function's own symbol with its C parameter list and C return
  ABI, so its host address stays callable by host code. The bus is ambient (`__cq_mem`), never
  a parameter.
- **One clone per function, mask and kind**, and one form (CR rule 18): compute, copy the
  results out, uncompute the SSA body; the twin `_unc(outs…, args…)` recomputes. Bus stores and
  kept load copies made inside stay (§1.10). A function that writes memory, measures or reads an effect entry's result
  rail has no twin (CR rule 18). No depth is passed: a re-entered `_ctl` clone counts its live activations
  in a module-internal global and is cut at K by a classical branch on entry (CR §1.4, rule 14).
- **Table clone `_t`.** The form reached without the body in view: a row of the clone table
  (§1.14) or a declared clone (rule 27). All-ones mask, no `_b` bounds, C calling convention.
  Every result is an `i32` handle, a classical result a seed rail; the twin always exists,
  pops the minted-register handles its clone pushed, for a no-twin function does nothing
  else (results KEPT), otherwise frees the results it zeroes and the
  caller frees none (CR §1.4). The clone and its twin take K as the last argument: a call by
  name passes the callee's K, a call through a pointer the K of the caller's function. Under a quantum predicate the caller calls `<clone>_ctl(pred, …)` and
  merges by `select`. A call by name of a function whose body is in the module never reaches
  the table clone: it is the rule-18 clone of its mask.

Rule 27 is the only part that touches the link step:
- A call from lowered code to a function with **no body** in the module that is on a lowered
  library's root list is a call of its table clone, whatever its arguments. A call to an
  unlisted one is an effect entry (§1.11) or an ordinary host call, as CR rule 16 says. The compiler emits only declarations; a missing definition
  is an ordinary undefined-symbol link error.
- A lowered library is the same compiler run over library source with a list of root names. It
  exports each root's table clone, `_ctl` and twins, and registers them (§1.14). A library that
  calls back into the program (`qsort`, `bsearch`) must itself be lowered. Witnesses: 161
  (`__cq_q_ext_fn_11_t` with the classical c as a seed, and K), 200 (a pointer as one scalar), 190.

---

## 4. Coverage table

**The operations.** The backend is 25 core operations and 66 template operations; the 565
corpus symbols are their expansions by width, shape and suffix. `<W>` is `i<N>` for any N ≥ 1,
`f16`, `bf16`, `f32`, `f64` or `f80`.

| core operation (`cqrt_…`) | expands as | § |
|---|---|---|
| `alloc`, `measure` | `_<W>` | 1.1, 1.3 |
| `free` | none | 1.2 |
| `ry` | `_<W>[_qangle][_controlled]` | 1.4, 1.5 |
| `rz_i1`; `rz_qangle` | none; `[_controlled]` | 1.6, 1.7 |
| `not_i1`, `and_i1`, `or_i1`, `xor_i1` | none | 1.8 |
| `copy`, `xorc` | `_<W>[_controlled]` | 1.9 |
| `qram_alloc` | `_i8` | 1.10 |
| `qram_load` | `_<W>[_hl][_controlled][_unc]` | 1.10 |
| `qram_store`, `qram_swap` | `_<W>[_hl][_controlled]` | 1.10 |
| `tape_alloc`; `tape_fmt` | none; `[_controlled]` | 1.11 |
| `tape_effect` | `[_<W>]_controlled` | 1.11 |
| `tape_write` | `_<W>[_controlled]`, `_<W>_lit` | 1.11 |
| `abort_i1` | none | 1.11 |
| `push`, `pop` | none | 1.12 |
| `invert_begin`, `invert_end` | none | 1.13 |

The 66 template operations, each expanded by the grammar of §2.1
(`cq_template_<op>[_<pred>]_<W>[_to_<W2>][_<shape>][_rm|_rmq][_exc][_unc]`):
- integer arithmetic (7): `add sub mul udiv sdiv urem srem`;
- bitwise and shifts (8): `and or xor shl lshr ashr fshl fshr`;
- compare and select (4): `icmp fcmp fcmps select`;
- casts (10): `zext sext trunc fpext fptrunc sitofp uitofp fptosi fptoui bitcast`;
- overflow, saturating, min/max, abs (15): `uadd_overflow usub_overflow umul_overflow
  sadd_overflow ssub_overflow smul_overflow uadd_sat usub_sat sadd_sat ssub_sat smax smin umax
  umin abs`;
- bit counting (5): `ctlz cttz ctpop bswap bitreverse`;
- floating-point arithmetic (8): `fadd fsub fmul fdiv frem fneg sqrt fma`;
- floating-point misc (9, `trunc` being the cast's token again): `fabs copysign fmax fmin floor
  ceil trunc rint round is_fpclass`.

The corpus declares 24 of the core operations (`qram_alloc_i8` is called by the bundle's
`__cq_mem` only) and 58 of the template operations.

**Examples per family** (from `sym_by_ex.txt`, header). Widths and the source of each reversible
circuit are in §1 and §2.

- **Core.** `alloc` 212, `free` 203, `measure` 212, `ry` 211 (`_controlled` 16), `ry_qangle` 12
  (`_controlled` 1), `rz_i1` 33, `rz_qangle` 6 (`_controlled` 4), `not_i1` 45, `and_i1` 53,
  `or_i1` 18, `xor_i1` 1, `copy` 108 (`_controlled` 2), `xorc` 1, `qram_load` 89, `qram_store`
  76, `qram_swap` 32 (any bus access 91; at an address rail 44; `_controlled` 35), `tape_*` 11
  (`tape_fmt` 5, `tape_effect` 8), `abort_i1` 2, `invert_begin`/`end` 3, `push`/`pop` 53.
- **Integer.** `add` 124, `sub` 62, `mul` 82, `udiv` 5, `urem` 7, `sdiv` 2, `srem` 2, `and` 66,
  `or` 26, `xor` 15, `shl` 29, `lshr` 30, `ashr` 9, `fshl` 3, `fshr` 1, `icmp` 117, `select` 88,
  `zext` 64, `sext` 8, `trunc` 15, `bitcast` 9, `*_overflow` 2, `uadd_sat` 1, `usub_sat` 1,
  `sadd_sat` 1, `ssub_sat` 0, `smax` 4, `smin` 3, `umax` 2, `umin` 6, `abs` 1, `ctlz` 2,
  `cttz` 1, `ctpop` 2, `bswap` 1, `bitreverse` 0.
- **Floating point.** `fcmp` 18, `fcmps` 2, `fpext` 5, `fptrunc` 4, `sitofp` 7, `uitofp` 10,
  `fptosi` 3, `fptoui` 1, `fadd` 30, `fsub` 17, `fmul` 34, `fdiv` 12, the `_rm`/`_rmq`/`_exc`
  forms 4 (80, 81, 82, 100), `fneg` 12, `fabs` 14, `copysign` 11, `sqrt` 3, `fma` 0, `frem` 1,
  `fmax` 2, `fmin` 0, `floor` 1, `trunc` 1, `rint` 1, `ceil` 0, `round` 0, `is_fpclass` 1.
- **EXTEND** (no Bennett.jl circuit; route in §2.11): every fp op at f16, bf16, f32 or f80 other
  than `fneg`, `fabs`, `copysign`, `select`, `bitcast`, `fcmp` at f32, `fpext` f32→f64 and
  `fptrunc` f64→f32;
  every `_rm`/`_rmq`/`_exc` form; `fcmps`; `frem`; `is_fpclass`; `sitofp`/`uitofp` to a width
  other than f64 or from more than 64 bits; `fptosi`/`fptoui` from f80 or to more than 64 bits;
  the four divisions above 64 bits; a shift or funnel shift by a rail at a W that is no power
  of two.
- **Adapted** (a BJ circuit whose result differs from the contract): `fptosi`/`fptoui` to less
  than 64 bits (§2.6), `fmax`/`fmin` on ±0 (§2.10), a shift by a literal k ≥ W (§2.3).
- **Composed, no BJ circuit**: the six `*_overflow` flags on two rails, the four `*_sat`
  (§2.7); every bus access at an address rail (§1.10); the reduction of an angle rail (§1.5).

Without any witness: `fma`, `fmin`, `ceil`, `round`, `bitreverse`, `ssub_overflow`,
`smul_overflow`, `ssub_sat`, every `bf16` form, the ternary shapes with a literal in the first
or second slot (`qlq`, `lqq`, `lql`, `llq`), `cqrt_xorc_<W>` (uncontrolled), `cqrt_qram_swap` at
an address rail under a control, `cqrt_tape_effect_<W>_controlled` at a width other than i32.

**Basis-sample checker** (`_tools/sample_check.py`, tooling, not spec). Its evaluator agrees
with §2.2–§2.10 on every totalization. It differs or is silent on:
1. `cqrt_free`: it accepts only 0 or an untouched seed; §1.2 allows any known basis state.
2. `is_fpclass`: it maps every NaN to qNaN (bit 1).
3. Not modelled, so unverified: f80 rails, `_rm`/`_rmq`/`_exc`, the memory bus as §1.10 states
   it, and tape entries performed at their call (§1.11).

---

## 5. Resolved questions

Every question this file raised is ruled in CR; the contract is stated once, at the place named.
Q1: §0 obligation 4. Q2, Q3: §1.4–§1.7. Q4, Q12, Q21: §0. Q5, Q14, Q18, Q22–Q24: §1.10. Q6–Q9,
Q15: §2.1, §2.9. Q10: §2.10. Q11: §2.6. Q13: withdrawn, no store is popped (§1.10). Q16, Q19:
§1.11. Q17: §1.12. Q20: CR §2.

Decided in this file, where CR leaves the matter to the backend or its text already settles it:
Q25 (the cells an address rail can reach: the bound the backend can prove, any superset of the
support): §1.10. Q26 ("reduced exactly mod P" is exact for every f64, no tolerance): §1.5. Q27
(which callees are INPUT calls, and their buffers): §1.11. Q28 (wide strings, `va_list`
blocks, host-library objects, `setvbuf`): §1.11. Q29 (`__builtin_trap`; `setjmp`/`longjmp` are
never entries): §1.11. Q30 (an f80 compare of a non-canonical operand is unordered): §2.9. Q31
(the backend appends brackets as called; fusion is a later stage's): §1.6.

---

## 6. Keeping this file in step with CR

CR is normative; this file restates the part of it a backend implements. On a CR change, these
parts of CR can alter a contract stated here, and the sections named are re-read against them:
- any `cqrt_*` or `cq_template_*` name, signature or grammar element (CR §1.2, §1.3, the
  retired list of CR §0): §0, §1, §2.1, §4;
- the totalization table (CR §2), every row of which is the value some template or bus access
  returns: §1.10, §2.2–§2.11;
- rule 5 (what is un-copied and what is kept, the `_controlled` bus forms, the in-place form):
  §1.10;
- rule 16 (effect entries, the callees recognised by name, their results, allocation, K2):
  §1.11 and its callee table, §0;
- rule 17 (`cq_invert`: what is reversed, the flush points): §1.13 and the result-rail clause
  of §0;
- rules 20 to 22 (the bus, access widths and address forms, pointers as integers, the byte
  accesses of the memory intrinsics and their use of `push`/`pop`): §1.10, §1.12.

The other rules decide which calls the lowered program makes, not what a call does.

**Conformance.** The test of a backend is the corpus run against it. Each example's lowered
program, linked against the backend and executed on basis inputs (every `cq_theta` input
replaced by a chosen bit pattern), must give the named outputs, the clean rails and the kept
rails that CR §6 item 1 asks for, with the rotation list of item 2 read off the gates the
backend appended. This file adds no acceptance criterion. When `examples/` changes, the counts
of the header and of §4 are recomputed with the header's commands.
