# CQ backend ABI: the logical circuit backend

Reference for the team that implements the runtime the lowered program calls. It lists every
`cqrt_*` and `cq_template_*` family with its contract. CONSTRUCTION_RULES.md (cited as CR) is
normative and wins over this file. Where this file goes past CR, the source is an example's
declarations, its `; C:`/`; IR:` comments, or its `.O1.ll`; those points are tagged *(corpus)*.
The questions this file first raised are resolved in CR (2026-10-27); §5 lists each with its ruling.

- **Ground truth.** Bennett.jl `824458d10e879c3fef673c231a02e5461dac667f` (CR §0) and BennettVM.jl
  `23d28e6471f9cf5d8a22177d08260ca86adfe841` (HEAD of 2026-09-27, cloned 2026-10-27). A citation
  `path:function` is relative to that repo's root. "BJ" means Bennett.jl and "BVM" means BennettVM.jl.
- **EXTEND** marks a family with no Bennett.jl implementation. The owner plans to extend Bennett.jl
  to it. The entry states the IEEE contract the extension must meet.
- **Counts** come from the commands shown, run from the `CQ_spec/` root on 2026-10-27. Examples 78,
  161 and 190 were being edited at the time, so nothing in this file relies on their text.

```sh
ls -d examples/*/ | wc -l                                                            # 192 examples
cat examples/*/*.lowered.ll | grep -ohE '@(cqrt_|cq_template_)[A-Za-z0-9_.]+' | sort -u | wc -l   # 529 symbols
cat examples/*/*.lowered.ll | grep -ohE '@cqrt_[A-Za-z0-9_.]+' | sort -u | wc -l     # 87 cqrt_*  (so 442 cq_template_*)
grep -ohE '^declare .*@(cqrt_|cq_template_)[A-Za-z0-9_.]+\(.*' examples/*/*.lowered.ll \
  | sed -E 's/ #[0-9]+//g' | sort -u | wc -l                                         # 534 declare lines (5 symbols declared two ways, §5 Q12)
# per-example symbol index used for every "examples" count below:
for f in examples/*/*.lowered.ll; do n=$(basename $(dirname $f)); n=${n%%_*}; \
  grep -v '^declare' $f | grep -ohE '@(cqrt_|cq_template_)[A-Za-z0-9_.]+' | sort -u | sed "s/^@/$n /"; done > sym_by_ex.txt
grep -E ' cqrt_qram_store' sym_by_ex.txt | cut -d' ' -f1 | sort -u | wc -l           # e.g. 16 (one family)
comm -23 <(grep -ohE '^declare i32 @cq_template_[A-Za-z0-9_]+' examples/*/*.lowered.ll | sed 's/.*@//' | sort -u) \
         <(grep -ohE '@cq_template_[A-Za-z0-9_]+_unc' examples/*/*.lowered.ll | sed 's/@//;s/_unc$//' | sort -u) | wc -l
                                                                                     # 48 forward templates whose _unc the corpus never calls
```

Every used symbol is declared and every declared symbol is used: `comm` of the two sets is empty.

---

## 0. Scope

**Execution model (CR §0).** The lowered program is an ordinary x86-64 host program. Running it
calls the backend, and each call appends gates to the circuit, returns a fresh handle, or returns a
measurement outcome. Classical values known only at run time, such as loop bounds, QROM tables
read from host memory, angles and pushed words, arrive as call arguments. The backend is therefore
a circuit builder driven by the host execution, not a translator of the IR. A call never returns
before its gates are appended in program order.

**Handles.** Every quantum object is an `i32` handle. There are three kinds:

| kind | made by | width | released by |
|---|---|---|---|
| rail | `cqrt_alloc_<W>`, every forward template, `cqrt_qram_load*`, `cqrt_tape_write_<W>*` | W qubits | `cqrt_free` (or never: kept, measured, tape) |
| QRAM bus | `cqrt_qram_alloc_<W>`, `cqrt_qram_realloc_<W>` | n cells × W qubits plus tape slots | `cqrt_qram_free` (or never) |
| tape | `cqrt_tape_alloc` | append-only list of entries | never |

- The backend records the width and kind of every handle. A template name gives the width of its
  result. An operand's width is the width implied by the name, except the **index operand** of
  `qrom_load`/`qram_*`, which is any rail at the C index expression's width (CR rule 20). The
  backend reads the index width from its own record.
- **Rail value encoding.** Integers are two's complement on W bits. `f16`/`f32`/`f64` are IEEE
  binary16/32/64 bit patterns. `f80` is the x87 80-bit extended pattern (explicit integer bit,
  CR rule 25). `i1` is one qubit. The qubit order inside a rail is internal to the backend, because
  only values cross the ABI (`alloc`, `measure`, literals). The quantum-angle ladder (§1.5) is the
  one place where bit weights matter.
- Widths in the corpus: `i1 i7 i8 i16 i32 i64 i80 i100 i128 f16 f32 f64 f80`. Any `N ≥ 1` is legal
  (CR §1.1), so implement templates generically in W.
- **Literal** means a classical value known at run time, not only a compile-time constant
  (`fshl_i32_qll(h, %2, 3)` in 134 passes a function argument). A literal has the LLVM operand
  type: `i1`, `iN`, `half`, `float`, `double`, `x86_fp80`.
- **Aliasing** *(corpus)*. One rail may fill several read-only operand slots of one call, as in
  `cq_template_fshr_i32(%5, %5, %6)` (112) and `cq_template_fadd_f16(%0, %0)` (111). The target of an
  in-place core gate (`not/and/or/xor_i1` `t`, `copy` `d`, `xorc` `h`, `ry/rz` target) never equals
  any other operand of that call.
- **Narrow scalar arguments and returns.** The corpus declares 5 symbols both with and without
  `signext`/`zeroext` (§5 Q12: allowed, CR §1.2). The backend must read only the low W bits of an `i1`/`i8`/`i16`
  argument. It must return `i1` zero-extended and `i8`/`i16` sign-extended. Both declarations then
  link correctly.

**Namespaces (CR §1.1).**

| prefix | who defines it | backend implements? |
|---|---|---|
| `cq_*`, `__cq_*` (`cq_theta_*`, `cq_measure_*`, `cq_phi`, `__cq_invert_begin/end`) | `CQ.h`, consumed by the compiler | **no**: never reaches the backend |
| `cqrt_*` | backend: core gates, QRAM, tape, abort, push/pop (§1) | **yes** |
| `cq_template_*` | backend: out-of-place reversible ops and their `_unc` twins (§2) | **yes** |
| `__cq_q_<fn>_<mask>…` | lowered code (clones, CR §1.4, rule 27) | **no** (§3) |

**Link order.** For static archives, list a referencing archive before the archive it references:
`main.o  [lowered libraries (rule 27)]  libcq_templates.a  libcq_runtime.a`. The templates archive
comes before the core archive because template circuits are built from core primitives. This is the
order CQ_lang uses; CR does not state one.

**No build-flag marker.** A declared clone (CR rule 27) takes the loop cutoff K as a trailing
classical `i32`, so a lowered library works with any K the user chooses per function, and there is
nothing to mismatch at link time (161, 190). The angle precision N is the backend's own
configuration (§1.5); lowered code does not depend on it.

**Not implemented by the backend.**
- libm and libc functions (`sin`, `exp`, `memcmp`, `strlen`, …). The compiler lifts them from
  injected musl source (CR rule 18), or they are declared clones linked from a lowered library
  (rule 27). LLVM math intrinsics on quantum operands go the same way (rule 18). No `cqrt_sin`
  exists.
- Clones and their twins (§3). Function-pointer dispatch, slot arrays and fat-pointer arithmetic
  are ordinary lowered code.
- Retired spellings, which must not be provided (CR §1.3): `cqrt_x`, `cqrt_cnot`, `cqrt_toffoli`,
  `cqrt_phase_f64*`, `cqrt_measure_<W>_controlled`, `cqrt_rz_<W>`, `cqrt_ry_*_controlled_inv`,
  `cqrt_cswap`, every `*_inv` template, the controlled arithmetic grid.
- `cqrt_push`/`cqrt_pop` are classical host functions (a word stack), not circuit primitives. The
  runtime library still has to define them (§1.12).

**Global obligations.**
1. **Fresh results.** Every handle a call returns names a newly allocated object. A rail result
   starts in `|0⟩` and the call XORs the value into it. Handles are never reused while live.
2. **Garbage-free templates.** A template leaves every operand and every internal ancilla exactly
   as it found it. Its net map is `|args⟩|0⟩ → |args⟩|f(args)⟩` (Bennett compute–copy–uncompute,
   BJ `src/bennett_transform.jl:bennett_direct`).
3. **No inserted measurement.** The backend measures only at `cqrt_measure_<W>` and, at the end of
   the shot, the tape rails and abort flags (§1.11).
4. **Live outcomes.** `cqrt_measure_<W>` is synchronous: the backend runs the circuit up to the
   measurement (mid-circuit measurement, classical feed-forward) and returns this shot's real
   outcome, on which the host program branches. There is no emit-only mode (CR §0).
5. **Initialization.** `cqrt_*` calls can come from `@llvm.global_ctors` before `main` (160's
   global QRAM), so the backend initializes itself on first call.

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

### 1.2 `cqrt_free`
- **Sig.** `void @cqrt_free(i32 h)`.
- **Sem.** Resets rail h and releases it. Precondition: h is in a **known classical basis state** and
  not entangled. That holds for `|0⟩` after an `_unc` and for an unwritten seed (CR §0, rule 7).
  The reset is the backend's operation (a hardware reset). It must not disturb other rails.
- **Rails.** h is consumed. Never called on a measured rail, a tape rail, an abort flag, a QRAM bus
  or an escaped handle.
- **§2.** None. **Ref.** BJ `src/wire_allocator.jl:free!`. **Ex.** 03, 04, 07.

### 1.3 `cqrt_measure_<W>`
- **Sig.** `<T> @cqrt_measure_<W>(i32 h)` with `<T>` the C type (`i1`, `i8`, `i16`, `i32`, `i64`,
  `float`, `double`, `x86_fp80`).
- **Sem.** Projective measurement of all W qubits in the computational basis. Returns the outcome
  as a value of type `<T>`.
- **Rails.** h stays allocated and is never freed. Afterwards it holds the outcome, a known basis
  state. It may still be read as an operand or a control, but is never rotated again. The call is
  never conditioned (no `_controlled` form). Measuring the same rail again re-reads the outcome
  classically; the compiler emits a second call only to bring an outcome a callee measured into
  the caller (CR rule 2, 136), and the backend treats a `measure` of an already-measured rail as a
  re-read, never as a measurement event.
- **§2.** None. **Ref.** No reference implementation (Bennett.jl and BennettVM.jl are classical
  reversible). **Ex.** 01, 38, 155. In the corpus: 191 examples (all except 60).

### 1.4 `cqrt_ry_<W>[_controlled]`
- **Sig.** `void @cqrt_ry_<W>(i32 h, double θ)` and `void @cqrt_ry_<W>_controlled(i32 c, i32 h, double θ)`.
- **Sem.** Ry(θ) on **every** qubit of h (W qubits, fp rails included). `_controlled` applies each
  Ry under c = 1. Ry(θ) = exp(−iθY/2) = [[cos θ/2, −sin θ/2], [sin θ/2, cos θ/2]] (CR §1.3).
- **Rails.** h is modified in place and is frozen afterwards (never reverse-played, never freed;
  CR rule 10). c is unchanged. There is no `_unc`. `cq_invert` emits Ry(−θ) (rule 17).
- **§2.** A non-finite θ is the identity. **Ref.** No reference implementation. **Ex.** 01, 39,
  125 (`_controlled`). Corpus widths: f32 f64 f80 i1 i8 i16 i32 i64 (`_controlled`: i1, i32).

### 1.5 `cqrt_ry_<W>_qangle[_controlled]`: the N-bit angle ladder
- **Sig.** `void @cqrt_ry_<W>_qangle(i32 h, i32 A)`. The controlled form is
  `(i32 c, i32 h, i32 A)` (CR §1.3; no corpus use).
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
  **Ex.** 79, 132, 142. Corpus: `cqrt_ry_i32_qangle` only (5 examples).

### 1.6 `cqrt_rz_i1`
- **Sig.** `void @cqrt_rz_i1(i32 f, double θ)`.
- **Sem.** The phase gate P(θ) = diag(1, e^{iθ}) on flag f. It is not Rz: the two differ by a phase
  e^{iθ/2}, which is global only because the gate is never controlled. Implement exactly P.
- **Rails.** f is unchanged in value and gets a relative phase. There is no `_unc`; the adjoint is
  P(−θ).
- **§2.** A non-finite θ is the identity. **Ref.** No reference implementation. **Ex.** 03, 08, 41.
- **Fusion.** The bracket `and_i1(a, b, t) · rz_i1(t, θ) · and_i1(a, b, t)` (t |0⟩) equals CCP(θ) on a, b
  (CR §6). The backend may emit either form, whichever its gate set makes cheaper: the bracket costs
  one ancilla, two Toffolis and one arbitrary rotation, an ancilla-free CCP several. Never fuse it to a
  controlled Rz: Rz(θ) = e^{−iθ/2}·P(θ), and under a control that global factor becomes a relative
  phase (e.g. CRz(a→b) = CP(θ)·P(−θ/2) on a).
  The same holds for `xor_i1(a, t) · rz_i1(t, θ) · xor_i1(a, t)` = P(θ) on a. The corpus traces contain the
  and-bracket 67 times in 10 examples (08, 23, 60, 116, 117, 118, 137, 148, 154, 185).

### 1.7 `cqrt_rz_qangle[_controlled]`
- **Sig.** `void @cqrt_rz_qangle(i32 A)` and `void @cqrt_rz_qangle_controlled(i32 c, i32 A)`.
- **Sem.** `|a⟩_A ↦ e^{i·val(a)}|a⟩_A`, a diagonal on A's basis. `_controlled` applies the phase only
  on the c = 1 branch (`|c,a⟩ ↦ e^{i·c·val(a)}|c,a⟩`). The phase is relative. A's uncompute kicks it
  back onto the sources (79, 143). It uses the same ladder as §1.5 with P = 2π.
- **Rails.** A and c are unchanged in value.
- **§2.** A non-finite val is the identity. **Ref.** No reference implementation. **Ex.** 79, 132,
  185 (`_controlled`: 79, 185).

### 1.8 `i1` logic: `cqrt_not_i1`, `cqrt_and_i1`, `cqrt_or_i1`, `cqrt_xor_i1`
| sig | semantics | ex |
|---|---|---|
| `void @cqrt_not_i1(i32 h)` | X: h ^= 1 | 21, 26, 39 (32 examples) |
| `void @cqrt_and_i1(i32 a, i32 b, i32 t)` | Toffoli: t ^= a ∧ b | 05, 08, 23 (44) |
| `void @cqrt_or_i1(i32 a, i32 b, i32 t)` | t ^= a ∨ b | 23, 49, 69 (16) |
| `void @cqrt_xor_i1(i32 a, i32 t)` | CNOT: t ^= a | 68 (1) |

- **Rails.** a and b are unchanged. t (h) is modified in place. Each gate is an involution, so the
  `_unc` is the same call. A flag conjunction targets a fresh `|0⟩` rail (CR rule 8).
- **§2.** None.
- **Ref.** BJ `src/gates.jl:NOTGate`/`CNOTGate`/`ToffoliGate`. The OR is
  `src/lowering/phi.jl:_or_wire!` (CNOT, CNOT, Toffoli). These core gates differ from the templates
  `cq_template_and_i1`/`or_i1`/`xor_i1`, which write a fresh rail (§2.3).

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
- **Ex.** copy 05, 07, 120 (76 examples; widths f16 f32 f64 f80 i1 i7 i8 i32 i64; `_controlled`
  i32: 45 only). xorc: `cqrt_xorc_i32_controlled` in 133 only. The uncontrolled `xorc` is not in
  the corpus.

### 1.10 QRAM: `cqrt_qram_alloc/realloc/store/load/free`
An object is a QRAM iff some access to it has a quantum offset (CR rule 20). Every access is ONE
call. The address-decoding circuit belongs to the backend: bucket brigade, select-swap, fan-out per
cell. The contract fixes the unitary, never the circuit, and the IR never has per-cell code.
`idx` is a quantum index rail of any width; `j` is a classical `i32` cell index (the `_hl` form, no
decoding, O(W) gates, constant depth). `v` is always a rail handle. A classical stored value is
first materialized by `cqrt_alloc_<W>` *(corpus, README)*.

| sig (corpus types) | semantics |
|---|---|
| `i32 @cqrt_qram_alloc_<W>(i32 n)` | n cells of W qubits, all `\|0⟩`; returns bus `a`. n is classical (a quantum size is allocated at its upper bound). |
| `i32 @cqrt_qram_realloc_<W>(i32 a, i32 n)` → `a'` | Same object, **logical** size n. No gate, and no cell moves. Shrinking hides cells ≥ n: they stay physically allocated and are out of range by §2. Growing maps the new indices to **fresh** `\|0⟩` cells, never to hidden ones. `a'` replaces `a` for every later access. |
| `void @cqrt_qram_realloc_<W>_unc(i32 a', i32 n_old)` | Restores the old size. Precondition: every store made through `a'` was popped. Afterwards `a` is the bus again (91, 186). |
| `void @cqrt_qram_store_<W>[_hl][_controlled]([c,] a, idx\|j, v)` | Takes a fresh W-qubit tape slot t, swaps t ↔ cell[idx] (the displaced cell goes out), then cell[idx] ^= v. v is unchanged. `_controlled`: under c = 0 nothing happens and t stays `\|0⟩`. |
| `void @cqrt_qram_store_<W>[_hl][_controlled]_unc(same args)` | cell[idx] ^= v, then t ↔ cell[idx]. t is `\|0⟩` again and is released. **Precondition:** v, idx and c hold their forward values. |
| `i32 @cqrt_qram_load_<W>[_hl]([c,] a, idx\|j)` → h | Fresh h ^= cell[idx]. The cell is unchanged. `_controlled` (CR §1.3, no corpus use): h ^= c ? cell[idx] : 0 *(README)*. |
| `void @cqrt_qram_load_<W>[_hl]_unc(i32 h, [c,] a, idx\|j)` | h ^= cell[idx], so h = `\|0⟩`. Requires the cell to hold the value it had at the load. The caller then frees h. |
| `void @cqrt_qram_free(i32 a)` | Releases the object after every store was popped (all cells and slots `\|0⟩`). |

- **Ordering.** Pops are LIFO only among stores that may touch the same cell. Stores to provably
  different cells commute, and `_hl` accesses to different cells commute. An unpopped store keeps
  its tape slot allocated (a kept item). A store whose v was later rotated or measured is never
  popped, and its object stays allocated (CR §0). A global QRAM is allocated once in a module
  constructor and is never popped or freed (160). A `_unc` pops the most recent unpopped slot with
  identical `(a, idx|j, v[, c])` (CR §1.3).
- **§2.** For an index ≥ n, read UNSIGNED at the index rail's width (a `_hl` literal likewise), a
  load returns 0 and reads no cell, and a store is a no-op whose slot stays `|0⟩`. A pop is
  evaluated at the logical size its forward store saw.
- **Controlled load.** `h ^= (c ? cell[idx] : 0)`; `_unc(h, c, a, idx | j)`.
- **Ref.** BJ `src/lowering/memory.jl:lower_store!` and `_lower_store_via_shadow!`;
  `src/shadow_memory.jl:emit_shadow_store!`, `emit_shadow_load!`, `emit_shadow_store_guarded!`
  (the `_controlled` store); `src/softmem.jl:soft_mux_store_*`/`soft_mux_load_*` (quantum-index
  mux). BVM `src/ir/memory_floor.jl:MemoryStore`/`MemoryLoad` (the store saves the displaced cell
  to history: the tape slot); `src/ir/memory_instructions.jl:MemorySwap` (the slot exchange);
  `src/ir/intrinsics.jl:IntrinsicMalloc`/`IntrinsicFree`. For realloc, BVM
  `src/ir/intrinsics.jl:IntrinsicRealloc` implements a *different* model (malloc + copy, old region
  leaked). CQ's logical resize has no reference implementation.
- **Ex.** 30, 84, 91 (alloc/store/load 16 examples; free 15; realloc 91, 186, 192; widths i8, i32;
  `_controlled` stores 55, 84, 88, 192).

### 1.11 Tape and abort: `cqrt_tape_*`, `cqrt_abort_i1`
This is the deferred-measurement model (CR §1.3, rule 16). Tape rails and abort flags are never
freed. All tape entries and abort flags form ONE event sequence in call order. At the end of the
shot (process exit: return from `main`, `exit`, or an `atexit` handler the backend registers on its
first call; a classical `_Exit` loses the tape as it loses unflushed stdio) the backend measures
them and performs, in sequence order, every entry whose predicate read 1 and that no earlier abort
flag reading 1 precedes: a format entry is printed with `printf` on `fmt` and its measured fields in
order, an effect entry performs the host call with its recorded arguments. Strings are copied at
call time.

| sig | semantics |
|---|---|
| `i32 @cqrt_tape_alloc()` → t | A new empty tape. In the corpus each function that records entries allocates its own (47). |
| `void @cqrt_tape_fmt(i32 t, ptr fmt)` and `void @cqrt_tape_fmt_controlled(i32 c, i32 t, ptr fmt)` | Opens a `printf` entry with host format string `fmt` and predicate c (1 if uncontrolled). The entry is always appended, so the tape length is classical. |
| `void @cqrt_tape_effect_controlled(i32 c, i32 t, ptr name)` | Opens an effect entry: a host call `name` (`raise`, `remove`, …) recorded under c and never executed by the program. No uncontrolled form exists, since an unconditional effect is the real host call. |
| `i32 @cqrt_tape_write_<W>(i32 t, i32 h)` → h′ and `i32 @cqrt_tape_write_<W>_controlled(i32 c, i32 t, i32 h)` → h′ | Appends a field. h′ is a fresh write-only tape rail with h′ ^= h (`_controlled`: h′ ^= c ? h : 0). h is unchanged. h′ stays entangled with h and is never freed or uncomputed *(corpus, 47; sample_check)*. |
| `void @cqrt_tape_write_<W>_lit(i32 t, <T> lit)` | Appends a classical field. |
| `void @cqrt_tape_write_str_lit(i32 t, ptr s)` | Appends a classical string field. |
| `void @cqrt_abort_i1(i32 f)` | Marks f as an abort flag: kept, and measured at the end of the shot. f = 1 means this branch aborted at this program point. The host program keeps running; rails later modified in place were snapshotted by the compiler (rule 16). |

- **§2.** None. **Ref.** No reference implementation for tapes. For abort, BVM
  `src/ir/unreachable_halt.jl:UnreachableHalt` is the closest mechanism (a halt state, classical).
- **Ex.** 47, 102, 138 (tape_alloc 5 examples; fmt 47, 67, 99, 138; effect 102; write widths i8,
  i32, f64, `_controlled` 47, 138, `_lit` 47, 99, 102; abort 45, 102, 108).

### 1.12 `cqrt_push`, `cqrt_pop`
- **Sig.** `void @cqrt_push(i32 w)` and `i32 @cqrt_pop()`.
- **Sem.** A classical LIFO word stack. A bounded loop pushes each trip's rail handles and per-trip
  classical values, and the reverse loop pops them (CR rule 14). The calls emit no gates.
- **Rails.** None (w can be a handle, kept as a plain integer).
- **§2.** None. **Ref.** BVM `src/history/delta.jl:DeltaEntry` and `src/history/Replay.jl:unrun!` (a
  history tape replayed LIFO). **Ex.** 05, 25, 62 (39 examples). The words are `i32`; the compiler
  pushes a wider classical value as `i32` words, low word first (CR §1.3).

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
| `_unc` coverage | The backend provides `_unc` for **every** forward template. The corpus never calls the `_unc` of 48 of its forward templates (results kept or measured), which does not make them optional. |
| W | The operand width. A cast spells `<from>_to_<to>`. The result width is W, except compares, `*_overflow` and `is_fpclass` (`i1`), casts (W2) and `_exc` (`i32`). |
| shape | One letter per **data** operand in signature order: `h`/`q` is a handle and `l` a literal. Omitted means all handles. Binary ops use `_hl`, or `_lh` for a non-commutative op only (a commutative op is swapped to `_hl`; an fp op only when the literal is not a NaN, CR §1.2). Compares never take `_lh`; the predicate is flipped instead. `select` letters cover the two **arms**, and the condition is always a handle. Ternary ops (`fma`, `fshl`, `fshr`) use `qqq` (bare), `qql`, `qlq`, `qll`, `llq`. The corpus also has `_ll` on a binary op (`fadd_f64_ll_rmq`, §5 Q6). |
| literal | Typed as the LLVM operand: `i1 true`, `i128`, `double`, `x86_fp80`, `half`. A narrow literal is read as its low W bits. |
| `_rm` / `_rmq` | Rounding mode as the **last** argument: `_rm` an `i32` literal, `_rmq` an `i32` rail. Encoding *(corpus, 80 header)*: x86-64 `FE_*` values, `FE_TONEAREST 0`, `FE_DOWNWARD 1024`, `FE_UPWARD 2048`, `FE_TOWARDZERO 3072` (§5 Q7). |
| `_exc` | Same operands and mode. The fresh `i32` result rail holds the operation's IEEE exception bits *(corpus, 81 header)*: `INVALID 1`, `DIVBYZERO 4`, `OVERFLOW 8`, `UNDERFLOW 16`, `INEXACT 32` (§5 Q8). |

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
**corpus widths**, **reference**, **ex**.

### 2.2 Integer arithmetic
| op | semantics (unsigned ⟦·⟧ mod 2^W unless s-) | widths | reference | ex |
|---|---|---|---|---|
| `add` | a + b | i7 i8 i16 i32 i64 i100 i128 | BJ `src/adder.jl:lower_add!` (`lower_add_cuccaro!`, `src/qcla.jl:lower_add_qcla!`) | 01, 02, 93 |
| `sub` | a − b | i8 i32 i64 | BJ `src/adder.jl:lower_sub!` | 10, 22, 156 |
| `mul` | a · b mod 2^W | i32 i64 i100 i128 | BJ `src/multiplier.jl:lower_mul!` | 04, 06, 93 |
| `udiv` | ⌊a/b⌋; **b = 0 → 2^W − 1** | i32 i128 | BJ `src/divider.jl:_soft_udiv_compile` (same b = 0 result) | 11, 37, 93 |
| `urem` | a mod b; **b = 0 → a** | i32 | BJ `src/divider.jl:_soft_urem_compile` | 11, 62, 74 |
| `sdiv` | signed, truncating; **b = 0 → −1 if a ≥ 0 else +1**; **INT_MIN/−1 → INT_MIN** | i32 | BJ `src/lowering/aggregate.jl:lower_divrem!` | 11, 156 |
| `srem` | sign of a; **b = 0 → a**; **INT_MIN rem −1 → 0** | i32 | BJ `src/lowering/aggregate.jl:lower_divrem!` | 11, 156 |

### 2.3 Bitwise and shifts
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `and` `or` `xor` | bitwise; the `i1` forms are the data templates of flags (CR rule 8) | and: i1 i8 i16 i32 i64 i80; or: i32 i64 i80 i128; xor: i1 i8 i32 i64 | BJ `src/lowering/arith.jl:lower_and!`/`lower_or!`/`lower_xor!` | 10, 12, 77 |
| `shl` `lshr` `ashr` | shift by **⟦k⟧ mod W** for any amount ≥ W, literal or quantum (x86) | shl: i8 i16 i32 i64 i80; lshr: i32 i64 i80 i100 i128; ashr: i32 i64 | BJ `src/lowering/arith.jl:lower_var_shl!`/`lower_var_lshr!`/`lower_var_ashr!` (mod W for raw LLVM input); constant: `lower_shl!` etc. (BJ returns 0 at k = W; §2's mod W overrides) | 10, 18, 53 |
| `fshl` `fshr` | LLVM funnel shifts, **amount mod W**: fshl = high W bits of (a∥b) << k; fshr = low W bits of (a∥b) >> k | i32 (`qql`, `qll`, bare) | BJ `src/extract/instructions.jl:_handle_intrinsic` (`llvm.fshl.`/`llvm.fshr.` expansion) | 56, 112, 134 |

### 2.4 Compare
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `icmp_<pred>` | `i1` result; pred ∈ eq ne ugt uge ult ule sgt sge slt sle | i1 i8 i32 i64 i128 (used: eq ne sgt slt ugt ult) | BJ `src/lowering/arith.jl:lower_icmp!` (`lower_eq!`, `lower_ult!`, `lower_slt!`) | 03, 04, 134 |
| `fcmp_<pred>` | `i1` result; LLVM fcmp, o = ordered and u = unordered or | f32 f64 f80 (used: oeq ogt olt one ord ueq uge ult une uno) | f64: BJ `src/softfloat/fcmp.jl:soft_fcmp_olt` etc. (ogt/uge by operand swap). f32: exact via `src/softfloat/fpconv.jl:soft_fpext` + the f64 compare. f80: **EXTEND** (IEEE 754 compare of x87 extended values, NaN unordered) | 15, 48, 69 |
| `fcmps_<pred>` | the signaling compare; value as `fcmp`. Used only as `_exc`: INVALID (1) iff either operand is NaN | f64 | **EXTEND** (exception bits) | 81, 100 |

### 2.5 Select
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `select` | `(i32 c, arm1, arm2)`: **o = ⟦c⟧ = 1 ? arm1 : arm2** (LLVM operand order; 04: `select_i32(f, then, else)`). Shapes `hl`, `lh`, `ll` give the arms; c is an `i1` rail. | i8 i32 i64 i128 f32 f64 f80 | BJ `src/lowering/arith.jl:lower_select!`/`lower_mux!`; BVM `src/ir/select_instruction.jl:SelectInstruction` | 04, 09, 101 |

### 2.6 Casts
| op | semantics | corpus pairs | reference | ex |
|---|---|---|---|---|
| `zext` `sext` `trunc` (int) | as LLVM | zext i1/i8/i16→i32, i8/i32→i64, i32→i80, i64→i100/i128; sext i7/i8→i32, i32→i64; trunc i32→i8/i16, i64→i7/i32, i80→i16, i100/i128→i64 | BJ `src/lowering/arith.jl:lower_cast!` | 17, 18, 46 |
| `bitcast` | bit pattern copied (o ^= a) | f64↔i64, f80↔i80 | BJ `src/extract/instructions.jl` (bitcast is wire aliasing) | 18, 50, 63 |
| `fpext` | exact widening | f16→f32, f32→f64, f64→f80 | f32→f64: BJ `src/softfloat/fpconv.jl:soft_fpext`. f16→f32 and f64→f80: **EXTEND** (exact; NaN stays quiet NaN with the payload left-aligned, as x86) | 17, 111, 172 |
| `fptrunc` | IEEE RNE narrowing, overflow → ±Inf | f32→f16, f64→f32 | f64→f32: BJ `src/softfloat/fpconv.jl:soft_fptrunc`. f32→f16: **EXTEND** (binary16 RNE, subnormals, overflow to Inf) | 17, 111, 183 |
| `sitofp` `uitofp` | correctly rounded (RNE) | sitofp i32→f64; uitofp i1→f32/f64/f80, i8/i32→f64 | →f64: BJ `src/softfloat/sitofp.jl:soft_sitofp`/`soft_uitofp`. →f32/f80: **EXTEND** (RNE to binary32 / x87 64-bit significand) | 17, 69, 157 |
| `fptosi` `fptoui` | truncate toward 0; NaN, ±Inf, out of range: **the x86-64 LLVM 19 `-O1` result** (CR §2): with c32/c64 = cvtt to i32/i64 (indefinite = INT_MIN of that width), s8/s16 = trunc(c32), s32 = c32, s64 = c64, u8/u16 = trunc(c32), u32 = trunc(c64), u64 = `r1 \| (r2 & (r1 >>s 63))`, r1 = c64(x), r2 = c64(x − 2^63); f80 via x87 `fist` (CR §2 row) | f64→i32 | BJ `src/softfloat/fptosi.jl:soft_fptosi`, `src/softfloat/fptoui.jl:soft_fptoui` (x86-exact for f64→i32/u32; other widths **EXTEND** to the CR §2 table) | 17, 56, 169 |

### 2.7 Overflow, saturating, min/max, abs
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `{u,s}{add,sub,mul}_overflow` | **`i1` overflow flag only** (element 1 of `*.with.overflow`). Element 0 is the ordinary `add`/`sub`/`mul` template over the same operands (CR rule 4). u: unsigned carry/borrow/product > 2^W−1; s: signed result out of range | uadd i32, sadd i32, usub i64, umul i32 (ssub and smul not in the corpus) | sadd, uadd, smul, umul: BJ `src/extract/instructions.jl:_handle_intrinsic` + `_fuse_overflow_extractvalue`. usub (= a <ᵤ b): `src/lowering/arith.jl:lower_ult!`. ssub: no reference implementation | 92, 112 |
| `uadd_sat` `usub_sat` | min(a + b, 2^W − 1); max(a − b, 0) | i32 | no reference implementation in BJ (`_WIDTH_DEPENDENT_INTRINSICS` lists them, but there is no expansion); build from add/sub + compare + select | 92, 109 |
| `sadd_sat` `ssub_sat` | signed a + b / a − b clamped to [−2^(W−1), 2^(W−1) − 1] (`llvm.sadd.sat`/`llvm.ssub.sat`; total, no CR §2 row). Overflow iff sign(a) = sign(b) ≠ sign(a + b) (sub: sign(a) ≠ sign(b) and sign(a − b) ≠ sign(a)); the clamp is sign(a) in the top bit and its complement below | i32 (ssub not in the corpus) | none in BJ; build from add/sub + a three-sign overflow flag + select, O(W) Toffolis, as the unsigned pair | 194 |
| `smax` `smin` `umax` `umin` | as LLVM | i32 | BJ `src/extract/instructions.jl:_handle_intrinsic` (compare + select) | 26, 56, 187 |
| `abs` | \|a\|; **abs(INT_MIN) = INT_MIN** | i32 | BJ `src/extract/instructions.jl:_handle_intrinsic` | 56 |

### 2.8 Bit counting
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `ctlz` `cttz` | the result has width W; **ctlz(0) = cttz(0) = W** | ctlz i32, cttz i64 | BJ `src/extract/instructions.jl:_handle_intrinsic` | 56, 108 |
| `ctpop` | popcount, width W | i32 | same | 56, 178 |
| `bswap` | byte reversal (W a multiple of 16) | i32 | same | 109 |

### 2.9 Floating-point arithmetic
All results are IEEE, round to nearest even unless `_rm`/`_rmq` is present. Operands and results are
bit patterns. `llvm.fmuladd` reaches the backend as `fmul` then `fadd` (unfused, CR §2). Only
`llvm.fma` uses `fma`. A NaN result follows x86 SSE in IR operand order: the first NaN operand, quieted; an invalid operation gives `0xFFF8000000000000` (f32 `0xFFC00000`) (CR §2).

| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `fadd` `fsub` `fmul` `fdiv` | IEEE basic ops | f16 (fadd), f32, f64, f80; `_rm`/`_rmq`/`_exc` only f64 | f64: BJ `src/softfloat/fadd.jl:soft_fadd`, `fsub.jl:soft_fsub`, `fmul.jl:soft_fmul`, `fdiv.jl:soft_fdiv` (x86-exact: `INDEF` 0xFFF8… for invalid). f16/f32/f80 and any `_rm`/`_rmq`/`_exc`: **EXTEND** (IEEE 754 binary16/32 RNE with subnormals; x87 extended with 64-bit significand and PC = extended; directed modes RD/RU/RZ per the mode operand; `_exc` sets the bits of §2.1 with x86 rules: tininess after rounding, UNDERFLOW only together with INEXACT when masked) | 13, 14, 80 |
| `fneg` | sign-bit flip (no rounding) | f32 f64 f80 | f64: BJ `src/softfloat/fneg.jl:soft_fneg`; the others are the same bit flip at bit W−1 (bit 79 for f80) | 13, 69 |
| `sqrt` | IEEE sqrt; negative → NaN | f64 | BJ `src/softfloat/fsqrt.jl:soft_fsqrt` | 16, 172, 183 |
| `fma` | fused, one rounding (`llvm.fma` only) | none in corpus | f64: BJ `src/softfloat/fma.jl:soft_fma`; others **EXTEND** (one rounding; f32 cannot be emulated by f64 double rounding) | none |
| `frem` | IEEE `fmod` (exact): sign of x; fmod(x, 0) = NaN; fmod(±Inf, y) = NaN; fmod(x, ±Inf) = x; NaN propagates | f32 (bare), f64 (`hl`, `lh`), f80 (`hl`) | **EXTEND** (no reference implementation in BJ) | 83 |

### 2.10 Floating-point misc
| op | semantics | widths | reference | ex |
|---|---|---|---|---|
| `fabs` | clear the sign bit | f32 f64 f80 | BJ `src/extract/instructions.jl:_handle_intrinsic` (`llvm.fabs.`, a mask); width-generic | 16, 69, 104 |
| `copysign` | magnitude of arg 0, sign of arg 1 (non-commutative: `hl`, `lh`) | f32 f64 f80 | BJ same (`llvm.copysign.`); width-generic | 16, 69, 169 |
| `fmax` `fmin` | `fmax(a, b) = isnan(a) ? b : isnan(b) ? a : (b > a ? b : a)`, `fmin` with `<`: equal values (±0) give a, two NaNs give b unchanged (x86-64 `-O1`, CR §2) | fmax f64 (fmin not in the corpus) | f64: BJ `src/softfloat/fmin.jl:soft_fmax`/`soft_fmin`, adapted: BJ returns +0/−0 for ±0 where x86 returns a | 16, 169 |
| `floor` `ceil` `trunc` `rint` `round` | IEEE roundToIntegral: floor and ceil toward −∞ and +∞; trunc toward 0; **rint ties to even** (CR §2; the dynamic mode is ignored); round = C `round`, ties away from zero | floor, trunc, rint f64 (ceil and round not in the corpus) | f64: BJ `src/softfloat/fround.jl:soft_floor`/`soft_ceil`/`soft_trunc`/`soft_round` (RNE)/`soft_round_away` | 16 |
| `is_fpclass` | `(i32 h, i32 mask)` → `i1` = 1 iff h's class bit is set in mask. LLVM bit order: 0 sNaN, 1 qNaN, 2 −Inf, 3 −normal, 4 −subnormal, 5 −0, 6 +0, 7 +subnormal, 8 +normal, 9 +Inf (104: 264 = isnormal). A pure bit test that raises no exception | f64 `_hl` | **EXTEND** (no reference implementation) | 104 |

`trunc_f64` (rounding) and `trunc_<from>_to_<to>` (integer cast) share the op name. They are told
apart only by the `_to_`.

### 2.11 QROM: `qrom_load[_s]`
| sig | semantics |
|---|---|
| `i32 @cq_template_qrom_load_<W>(ptr table, i64 n, i32 idx)` | o ^= T[⟦idx⟧], where T[i] is the W-bit little-endian element at host address `table + i·size`, size = the type's alloc size (W/8; f80: 16). n is the element count. idx is a quantum index rail of any width (often i32, i8 in 76). |
| `i32 @cq_template_qrom_load_<W>_s(ptr base, i64 n, i64 stride, i32 idx)` | Strided: T[i] is at `base + i·stride` (stride in **bytes**). `base` is already offset to the field (struct-of-arrays column). CR §1.2; 78. |
| `_unc(o, same args)` | o ^= T[⟦idx⟧] with **the same table values** as the forward call, never a re-read of host memory (CR rule 20). The backend snapshots T at the forward call, keyed by o. |

- **Element types** in the corpus: `i32` and `f64` (`_s`: `i32`, `f64`). Classical memory only.
  T is the object's contents **at the load**, and n is the object's cell count, or the index's
  upper bound from range facts, or 2^W of the index (76: 256).
- **§2.** For an index ≥ n (unsigned reading of the index rail), the result is 0 and no element
  is read, so host memory past the object is never touched.
- **Ref.** BJ `src/qrom.jl:emit_qrom!` (Babbush–Gidney unary iteration). BJ requires a power-of-two L and an
  index of exactly log₂ L wires, so pad T with zeros to 2^⌈log₂ n⌉ entries and gate the result to
  0 for index values outside [0, n).
- **Ex.** 29, 50, 184 (17 examples). `_s`: 78.

---

## 3. Clones (not backend primitives)

A clone `__cq_q_<fn>_<mask>[_b…][_ctl][_pure][_adj][_dK][_unc]` (CR §1.4) is ordinary lowered code
that calls the primitives above. The backend links clones and never implements them.
Rule 27 (2026-10-27) is the only part that touches the link step:
- A quantum call to a function with **no body** in the module becomes a call to the declared clone
  that §1.4 names, without `_b` bounds. A pointer argument contributes tag and idx digits plus ONE
  digit for its pointee object. The compiler emits only declarations, and a lowered library
  supplies the definitions. A missing definition is an ordinary undefined-symbol link error, with no
  fallback.
- Every result is an `i32` handle and the `_unc` twin always exists. A classical result comes back
  as a seed rail. Under a quantum predicate the caller always calls `<clone>_ctl(pred, …)` and
  merges by `select`.
- The clone and its twin take K as the last forward argument (the twin's snapshot pointers follow).
- A lowered library is the same compiler run over library source with a list of root clone names.
  It exports each root's `_ctl` and its twins. Witnesses: 161 (`__cq_q_ext_fn_10`),
  190 `escape` (`__cq_q_ext_sink_0010`, snapshot twin).

---

## 4. Coverage table

"Ex" is the number of examples that call the family (from `sym_by_ex.txt`, §header). The status
column says where the reversible circuit comes from.

| family | ex | corpus widths / variants | status |
|---|---|---|---|
| `cqrt_alloc_<W>` | 192 | i1 i7 i8 i16 i32 i64 f16 f32 f64 f80 | BJ |
| `cqrt_free` | 175 | – | BJ |
| `cqrt_measure_<W>` | 191 | i1 i8 i16 i32 i64 f32 f64 f80 | none (measurement) |
| `cqrt_ry_<W>[_controlled]` | 192 | f32 f64 f80 i1 i8 i16 i32 i64; ctl i1 i32 (16) | none (rotation) |
| `cqrt_ry_<W>_qangle[_controlled]` | 5 | i32; `_controlled` unused | none; ladder per CR §1.3 |
| `cqrt_rz_i1` | 33 | i1 | none (phase) |
| `cqrt_rz_qangle[_controlled]` | 4 | ctl: 2 | none; ladder per CR §1.3 |
| `cqrt_not_i1` / `and_i1` / `or_i1` / `xor_i1` | 32 / 44 / 16 / 1 | i1 | BJ |
| `cqrt_copy_<W>[_controlled]` | 76 | f16 f32 f64 f80 i1 i7 i8 i32 i64; ctl i32 (1) | BJ |
| `cqrt_xorc_<W>[_controlled]` | 1 | ctl i32 only | BJ (X gates) |
| `cqrt_qram_alloc` / `realloc` / `store` / `load` / `free` | 16 / 3 / 16 / 16 / 15 | i8 i32; `hl`, ctl, `hl_ctl`; load ctl unused | BJ + BVM; realloc: none |
| `cqrt_tape_*` | 5 | i8 i32 f64; ctl; `_lit`; `str_lit` | none |
| `cqrt_abort_i1` | 3 | i1 | none (BVM halt is classical) |
| `cqrt_push` / `pop` | 39 / 39 | i32 | BVM (history tape) |
| `add` `sub` `mul` | 96 / 30 / 51 | see §2.2 | BJ |
| `udiv` `urem` `sdiv` `srem` | 5 / 7 / 2 / 2 | i32 i128 | BJ |
| `and` `or` `xor` | 54 / 24 / 14 | i1–i128 | BJ |
| `shl` `lshr` `ashr` | 29 / 29 / 9 | i8–i128 | BJ |
| `fshl` `fshr` | 2 / 1 | i32 | BJ |
| `icmp` | 106 | i1 i8 i32 i64 i128 | BJ |
| `fcmp` | 17 | f32 f64 f80 | BJ f64, f32 via exact fpext; f80 EXTEND |
| `fcmps` (`_exc`) | 2 | f64 | EXTEND |
| `select` | 82 | i8 i32 i64 i128 f32 f64 f80 | BJ |
| `zext` `sext` `trunc`(int) `bitcast` | 33 / 6 / 18 / 9 | see §2.6 | BJ |
| `fpext` `fptrunc` | 5 / 4 | f16↔f32, f32↔f64, f64→f80 | BJ f32↔f64; f16, f80 EXTEND |
| `sitofp` `uitofp` | 6 / 9 | →f32 f64 f80 | BJ →f64; →f32, →f80 EXTEND |
| `fptosi` `fptoui` | 2 / 1 | f64→i32 | BJ (f64→i32/u32); other widths EXTEND |
| `*_overflow` | 2 | uadd sadd umul i32, usub i64 | BJ (sadd uadd smul umul; usub via ult); ssub none |
| `uadd_sat` `usub_sat` | 1 / 1 | i32 | none (composite) |
| `sadd_sat` `ssub_sat` | 1 / 0 | i32 | none (composite) |
| `smax` `smin` `umax` `umin` `abs` | 3 / 3 / 2 / 1 / 1 | i32 | BJ |
| `ctlz` `cttz` `ctpop` `bswap` | 1 / 1 / 2 / 1 | i32 i64 | BJ |
| `fadd` `fsub` `fmul` `fdiv` | 29 / 16 / 32 / 11 | f16 f32 f64 f80 | BJ f64; f16 f32 f80 EXTEND |
| `_rm` `_rmq` `_exc` forms | 4 (80 81 82 100) | f64 | EXTEND |
| `fneg` `fabs` `copysign` | 10 / 13 / 10 | f32 f64 f80 | BJ (sign-bit ops, width-generic) |
| `sqrt` | 3 | f64 | BJ |
| `fma` | 0 | – | BJ f64 |
| `frem` | 1 | f32 f64 f80 | EXTEND |
| `fmax` / `fmin` | 2 / 0 | f64 | BJ |
| `floor` `trunc`(fp) `rint` / `ceil` `round` | 1 / 1 / 1 / 0 / 0 | f64 | BJ |
| `is_fpclass` | 1 | f64 | EXTEND |
| `qrom_load` / `qrom_load_s` | 17 / 1 | i32 f64 | BJ |

Grammar ops never used by the corpus (unverified by any witness): `fma`, `fmin`, `ceil`, `round`,
`ssub_overflow`, `smul_overflow`, and the shapes `qlq`/`llq`; core `cqrt_xorc_<W>` (uncontrolled),
`cqrt_qram_load_*_controlled` and `cqrt_ry_<W>_qangle_controlled`.

**Basis-sample checker cross-check** (`_tools/sample_check.py`, tooling, not spec). The figure
supplied with this task is 162 examples. A re-run on 2026-10-27 (`cd _tools && python3
sample_check.py -j 8 | tail -1`) printed `# PASS 163  FAIL 4  KDIFF 10  SKIPPED 15`. Each of the 4
FAILs (76, 105, 107, 192) is a sample where the native C reference reads past an object or reads an
indeterminate value (UB). §2 totalizes those reads to 0, or, for 76's n = 256 QROM, reads different
host bytes. None of the 4 is a template-semantics disagreement. Of the 15 SKIPs, 7 have f80 rails,
4 fenv templates, 3 a link failure on declared clones (161, 175, 190), and 60 has
none of these (its reference does not link `cqrt_alloc_i1`).

The checker's evaluator `tmpl()` is a concrete reading of §2. It agrees with §2.2–§2.11 on div/rem
by 0 and INT_MIN/−1, shifts and funnel shifts mod W, ctlz/cttz(0) = W, abs(INT_MIN), select arm order, fptosi/fptoui and fmax/fmin per CR §2 (updated 2026-10-27, matches native x86), `round` ties away, `rint` ties even, `is_fpclass` bit
order, `*_overflow` as an `i1` flag, the unsigned index reading, and QRAM controlled load
`c ? cell : 0`. Disagreements and gaps:
1. **QROM `_unc` re-reads host memory** (`s.mem(...)` inside `template()` at `_unc` time). CR rule 20
   says the `_unc` uses the forward values. The two diverge if the table changes between load and
   uncompute.
2. (resolved) `fmax`/`fmin` and `fptosi`/`fptoui` now follow the CR §2 rows, which are the x86 results.
3. (resolved) see 2.
4. **`cqrt_free`** accepts only 0 or an untouched seed. §0 allows any known basis state, so the
   checker is stricter.
5. **`is_fpclass`** maps every NaN to qNaN (bit 1). An sNaN input would be misclassified.
6. **Not modelled** (the example is SKIPPED): f80 rails (`x86_fp80` anywhere in the declarations),
   and `_rm`/`_rmq`/`_exc` (fenv). These are **unverified** by the checker: every f80 template,
   `alloc/measure/copy_f80`, `fadd/fdiv/fmul_f64_*_rm*`, `fcmps_*_exc`.

---

## 5. Resolved questions (rulings in CR, 2026-10-27)

Each first draft of this file listed these as open. All follow from the fixed goal (the C program's
x86-64 LLVM 19 `-O1` semantics, Bennett.jl as circuit ground truth, no declines, measurement as a
backend concern) and are now normative in CR.

| # | question | ruling | CR |
|---|---|---|---|
| Q1 | measurement in a circuit-building backend | synchronous live measurement with feed-forward; no emit-only mode | §0 |
| Q2 | angle ladder | reduce mod P (4π Ry, 2π phase), round to nearest-even on P·k/2^N, bit i fires P·2^(i−N); N is backend-only | §0, §1.3; 79 fixed |
| Q3 | rotation conventions | Ry(θ) = exp(−iθY/2); `rz_i1` is P(θ), name kept | §1.3 |
| Q4 | ABI marker | superseded: no marker; declared clones take K as a trailing run-time argument, chosen per function by the user | §0, rule 27; 161, 190 |
| Q5 | index signedness | unsigned reading at the rail width (in-bounds C indices are never negative relative to the object) | §2; 184 comment fixed |
| Q6 | `_ll` on binary ops | allowed when the only quantum operand is the `_rmq` mode | §1.2 |
| Q7 | rounding-mode encoding | x86 `FE_*`: bits 10–11 (0 RNE, 1 down, 2 up, 3 zero), other bits ignored | §1.2 |
| Q8 | `_exc` encoding | `i32` rail: INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32; tininess after rounding; UNDERFLOW only with INEXACT | §1.2 |
| Q9 | NaN payloads vs commutative swap | x86 SSE rule in IR operand order (measured); fp ops swap to `_hl` only for a non-NaN literal, else `_lh` | §1.2, §2 |
| Q10 | fmax/fmin | x86-64 `-O1` result (measured): equal → first operand, both NaN → second | §2 |
| Q11 | fptoui/fptosi out of range | x86-64 LLVM 19 `-O1` codegen table (measured); f80 via x87 `fist` | §2 |
| Q12 | extension attributes | allowed on runtime declarations; backend reads low W bits | §1.2 |
| Q13 | which store a pop undoes | most recent unpopped slot with identical `(a, idx\|j, v[, c])` | §1.3 |
| Q14 | `qrom_load_s` | `qrom_load_<W>_s(base, n, stride_bytes, idx)`; unstrided stride = alloc size (f80 16) | §1.2 |
| Q15 | `trunc` collision | `_to_` decides | §1.2 |
| Q16 | tape semantics | one event sequence; perform entries with predicate 1 not preceded by an abort reading 1; strings copied at call time | §1.3 |
| Q17 | push word width | `i32` words, a wider value split low word first | §1.3 |
| Q18 | unwitnessed core forms | semantics stated (controlled load `h ^= c ? cell : 0`, `_unc(h, c, a, idx)`); no new example needed | §1.3 |
| Q19 | end of shot | process exit (`main` return, `exit`, backend `atexit`); `_Exit` loses the tape | §1.3 |
| Q20 | f80 non-canonical | x87: invalid operand → real indefinite, INVALID; pseudo-denormal = denormal | §2 |
| Q21 | operand aliasing | a rail may fill several read operands; an in-place target is never one of its own controls | §1.2, §1.3 |
