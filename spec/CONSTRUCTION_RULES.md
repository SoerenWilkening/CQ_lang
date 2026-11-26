# CQ construction rules

This document and `examples/` are the specification of the CQ compiler. A compiler is correct when,
for every example, the circuit it emits from `name.c` compiled with `clang -O1` (x86-64) is
semantically equal to `name.lowered.ll` under §6. The lowered files are hand-written witnesses;
where one disagrees with this document, the document wins and the example is to be fixed (§7). An
example §7 lists as regeneration owed is not normative for the construction it names until regenerated.

## 0. Scope and fixed decisions

- **No declines.** Every C program lowers. There is no diagnostic path in the compiler.
  - A call to a bodiless function with a quantum argument or under a quantum predicate is an
    effect entry (rule 16). A call to a function a linked lowered library lists is its declared
    clone whatever the arguments (rule 27); one that nothing defines is an ordinary link error.
  - Cloning cannot arise: every copy the compiler emits is a basis copy (CNOT fan-out).
  - A loop or recursion whose exit depends on quantum data runs for a cutoff **K** (rule 14).
- **Ground truth** for the templates (§1.2) and the totalization of partial operations (§2) is
  Bennett.jl (revision `824458d10e879c3fef673c231a02e5461dac667f`). Where Bennett.jl has no
  implementation (f16/f32/f80 arithmetic, `frem`, directed rounding, `is_fpclass`) the contract in
  §2 applies. Memory, pointers, calls and loops are defined by this document alone.
- **No pointer is resolved at compile time.** No rule requires knowing what a pointer points into,
  which objects exist, or how large one is. A pointer is its x86-64 address, a classical value or
  a 64-bit rail (§1.1), and all memory is one bus indexed by that address (§1.3, rule 20).
- **Every body is lowered**; none is called unlowered. The lowering for all-classical arguments is
  the function's own symbol (§1.4). The only bodies never lifted are those rule 16 names and the
  bundle's host symbols `__cq_mem`, `__cq_alloc`, `__cq_clone_*` and `__cq_sig`: classical host C
  shipped with the runtime, one definition per process. A
  module with no `cq_*` call, no root list and no reference to a declared clone (rule 27) is not
  lowered at all: it passes through unchanged, and a call into it is a host call (rule 16).
- **Qubits are allocated lazily.** A rail is classical bits in the backend until a gate forces
  qubits. The lowered program never asks whether a rail is classical: no such symbol exists.
- **Garbage policy.** Garbage that compute–copy–uncompute can clean must be cleaned. A rail that
  cannot be returned to a known basis state (entangled by a measurement or by a non-diagonal gate
  on its source) stays allocated. `cqrt_free` accepts any rail in a *known classical basis state*;
  the backend resets it. What a bus store or a load copy keeps for the shot is rule 5 alone.
- **Measurement** is a backend concern. The spec never simulates outcomes. `cqrt_measure_<W>` is
  synchronous (mid-circuit measurement with classical feed-forward; no emit-only mode) and returns
  the real outcome; dominated uses of the measured SSA value denote that classical value.
- **Quantum rotation angle** is one primitive (`cqrt_ry_<W>_qangle[_controlled]`,
  `cqrt_rz_qangle[_controlled]`, §1.3); the precision **N** of its ladder is a backend flag only.
- **Loop cutoff K** is per loop. The K of a loop in function `f`, first match wins: a per-loop
  annotation (no syntax yet; it will be a marker in the loop body, never a pragma); the
  per-function compiler flag; a `CQ_K(f, k)` line in the translation unit, which `CQ.h` defines
  as the `used` constant `__cq_k_<f>`; the global flag; the built-in default, **4** (the corpus
  value, lines tagged `[K]`). A lowered library ships a header of `CQ_K` lines with its defaults,
  included like `CQ.h`; its declared clones (rule 27) receive K as a classical run-time argument.
  A loop whose exit reads a value loaded from the bus is a K-loop like any other (rule 14).
  K is an unsigned 32-bit value greater than 0. K = 0 is not a K: nothing is defined for it.
  The function of a loop is the one that holds it in the `-O1` IR: a loop clang inlined into
  `g` resolves its K as a loop of `g` (K2 likewise).
  In a program of several translation units a `CQ_K(f, k)` line names the `f` of its own unit
  by C scope: the function that unit defines (a `static` one is that unit's alone), else the
  external function of that name. For an external `f` the line of the unit that defines it
  wins; where that unit has none, the largest k among the other units' lines. The per-function
  flag names every function of that C name. The binding is made per unit, before the units are
  linked into the module the pass lowers (K2 likewise).
- **Allocation bound K2.** An allocation whose size is a rail (`malloc`, `calloc`, `aligned_alloc`,
  `realloc`, a VLA) is made at **K2** bytes (rule 16), and a memory intrinsic whose length is a
  rail copies at most K2 bytes (rule 22). K2 resolves as K does, with `CQ_K2(f, k)`
  (the `used` constant `__cq_k2_<f>`) and the built-in default **4096** (the corpus value, lines
  tagged `[K2]`, never `[K]`). The overflow predicate
  `n > K2` is a kept output rail, as `a_K` is for a loop. The backend's K2 for a host input call
  whose length is a rail is a configuration value of its own, like N (BACKEND_ABI §1.11).
- **Target**: x86-64 only. **Optimization level**: `-O1` only. **No simulator**: §6 decides equivalence.
- **Retired** (the one list; none of these exists). Gates: every `cq_template_*_inv`, the
  controlled arithmetic grid, `cqrt_x`, `cqrt_cnot`, `cqrt_toffoli`, `cqrt_phase_f64[_controlled]`,
  `cqrt_measure_<W>_controlled`, `cqrt_rz_<W>`, `cqrt_ry_*_controlled_inv`, `cqrt_cswap`,
  `cqrt_tape_write_str_lit`, `cqrt_tape_str_begin/end`, the `ry_<W>_qangle(A, h)` argument
  order. Memory: per-object buses, `qram_alloc_<W>(n)` with n > 0 or
  W other than i8, `qram_alloc_host_<W>[_s]`, `@g.qram`, `qram_realloc[_unc]`, `qram_size`,
  `qram_free`, `qram_store*_unc`, the memory mirror, slot arrays, QROM (`cq_template_qrom_load[_s]`),
  fat pointers, object tables, assigned base addresses, range decoding, bound checks, cell counts,
  the `i32` `_hl` index. Clones: tag, idx, pointee and per-field digits, object-table and
  cell-count parameters, the pointer triple, per-signature variadic clones, `_inv<c>`, `_adj`,
  `_d<depth>`, a depth argument, storing clones and word counts, stored rails as extra results,
  snapshot twins.
- **The circuit is generated at run time.** The lowered program is an ordinary host program;
  executing it emits the gate sequence, parametrised by classical values known only at run time
  (loop bounds, host memory, host addresses, pushed words, classically computed angles). A backend
  is a circuit builder driven by the host execution, not a static translator of the lowered IR.

## 1. ABI

### 1.1 Handles and namespaces

Every quantum value is an `i32` **handle** to a rail whose logical width is the IR type's width
(`i1`, `i7`, `i8`, …, `i128`, `f16`, `bf16`, `f32`, `f64`, `f80`; any `N ≥ 1` is legal, `_BitInt`,
`__bf16` (bfloat16: 8 exponent bits, 7 fraction bits, same rounding and NaN rules as the IEEE
widths) and the x87 bit pattern included; `fp128` is unreachable from C on this target, rule 25). An aggregate or vector is a literal struct of handles
and classical values in field order. A pointer value is a classical `ptr`/`i64` or ONE handle to a
64-bit rail holding the x86-64 address. Narrow handle arguments carry the C ABI's `signext`/`zeroext`
only at externally visible signatures.

A handle is a classical run-time value of the lowered program (§0): the lowered code may compare
handles (`icmp eq i32`), branch on them and `select` over them (rule 9), a classical decision like
any other. A handle is never stored in program memory: memory holds bytes on the bus (§1.3), and
a handle that must outlive its SSA value goes to `cqrt_push`. **Handle 0 is reserved**: the
backend never allocates it, and it denotes "no rail" wherever a handle slot has no rail on the
path taken (rule 19's extra results).

Three symbol namespaces, never mixed. A program that itself spells a `cqrt_*` or `cq_template_*`
name gets what the link gives: the compiler has no diagnostic path (§0).

| prefix | meaning |
|---|---|
| `cq_*`, `__cq_*` | the user surface in `CQ.h` (`cq_theta_*`, `cq_measure_*`, `cq_phi`, `__cq_invert_begin/end`), the injection-bundle host symbols `__cq_mem`, `__cq_alloc`, `__cq_clone_*`, `__cq_sig` (§1.3), the clones `__cq_q_*` (§1.4) and the module-internal `__cq_register`, `__cq_act_*`, `__cq_k` (§1.3, §1.4) |
| `cqrt_*` | core gates and backend primitives (§1.3) |
| `cq_template_*` | generated out-of-place reversible operations, each with an `_unc` twin (§1.2) |

### 1.2 Template grammar

```
template := "cq_template_" op ["_" pred] "_" W ["_to_" W2] ["_" shape] ["_rm" | "_rmq"] ["_exc"] ["_unc"]
op       := add sub mul udiv sdiv urem srem and or xor shl lshr ashr
            fadd fsub fmul fdiv frem fneg icmp fcmp fcmps select
            zext sext trunc fpext fptrunc sitofp uitofp fptosi fptoui bitcast
            fma fshl fshr abs ctlz cttz ctpop bswap bitreverse smax smin umax umin uadd_sat usub_sat sadd_sat ssub_sat
            {u,s}{add,sub,mul}_overflow fabs copysign fmax fmin floor ceil trunc rint round sqrt
            is_fpclass
pred     := an icmp/fcmp predicate. A compare with the literal on the left is spelled by flipping
            the predicate; compares never take _lh.
W        := i<N> | f16 | bf16 | f32 | f64 | f80 ; casts spell <from>_to_<to>
shape    := one letter per DATA operand in signature order, h or q = handle, l = literal;
            omitted = all handles. Binary ops: _hl, or _lh for a non-commutative op only. A
            commutative op swaps its operands to _hl (§2's "IR operand order" is the template's
            order), except an fp op whose literal is a compile-time NaN constant, spelled _lh.
            _ll: a binary op whose only quantum operand is the _rmq mode. select: the two ARMS
            (hl, lh, ll); the condition is always a handle. Ternary: every mix of q and l, bare for
            qqq; fma's product operands are commutative, so lqq, lql are spelled qlq, qll unless
            the literal is a NaN; fshl and fshr keep every mixed shape.
_rm/_rmq := rounding mode appended as the LAST argument (i32 literal / handle), the x86-64 FE_*
            value: bits 10-11 select 0 nearest-even, 1 down, 2 up, 3 toward zero; other bits ignored.
_exc     := the same operands; the fresh i32 result rail holds the x86 exception bits the operation
            raises: INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32 (no DENORMAL);
            tininess after rounding, UNDERFLOW only together with INEXACT; a quiet NaN operand
            raises INVALID only in fcmps, conversions to integer and invalid arithmetic.
```
`trunc` with `_to_` is the integer cast, without it the fp rounding op. A rail may fill several
operand slots of one template (112 `fshr_i32(%5, %5, %6)`); the result rail is always fresh.
Runtime declarations may carry `signext`/`zeroext`; the backend reads only the low W bits of a
narrow operand either way. The forward form returns the fresh result handle, computed into a `|0⟩`
rail. The `_unc` form is `void`, takes `(out, <exactly the forward argument list, same literals>)`
and returns `out` to `|0⟩` by recomputation. Literals carry the LLVM operand type (`i1 true`,
`i128`, `double`). Every template is a total function of its operands (§2).

### 1.3 Core gates (`cqrt_*`)

Control flag is always argument 0 of a `_controlled` form, except in `qram_load`'s
`_controlled_unc`, which puts the result handle first: `(h, c, m, addr)`.

```
alloc_<W>(lit) -> h               fresh rail in basis state |lit>
free(h)                           reset; h must be in a known classical basis state
measure_<W>(h) -> value           projective measurement; h is never freed and holds the outcome afterwards, a known
                                  basis state that later operands, controls and gates act on (rule 2)
ry_<W>(h, θ)                      Ry(θ) = exp(−iθY/2) on every qubit of h; non-finite θ = identity
ry_<W>_controlled(c, h, θ)
ry_<W>_qangle(h, A)               Ry(val(A)) on h, val(A) the IEEE f64 the angle rail A holds, reduced exactly mod P
                                  (4π for Ry, 2π for a phase) and rounded to nearest-even onto the grid P·k/2^N;
                                  ladder bit i fires P·2^(i−N); non-finite = identity
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
add_<W>(s, d)                     d += s mod 2^W      (in place; s unchanged; s and d are different rails)
sub_<W>(s, d)                     d -= s mod 2^W      (the inverse of add_<W>; emitted only where an add_<W> is reversed)
addc_<W>(h, lit)                  h += lit mod 2^W    (in place; its inverse is addc_<W>(h, -lit))
qram_alloc_i8(0) -> m             the memory bus M, the only QRAM: 8-bit cells, 2^64 cells (n = 0), cell index = the
                                  x86-64 address; created once per process, reached only through __cq_mem(), never freed
qram_load_<W>[_hl][_controlled]([c,] m, addr) -> h
                                  fresh h ^= the S consecutive cells from addr, little-endian (the cells unchanged;
                                  _controlled under c = 0: nothing is touched and h stays |0>). _unc(h, [c,] m, addr)
                                  requires the cells to hold the value they had at the load
qram_store_<W>[_hl][_controlled]([c,] m, addr, v)
                                  each store owns a fresh tape slot t of S cells: t <-> cells (the displaced cells go
                                  out), then cells ^= v (a copy; v unchanged). v is always a handle; a classical value
                                  is first alloc_<W>(lit). _controlled: under c = 0 nothing is touched and t stays
                                  |0>. No _unc: a store is never popped and t is Kept (rule 5)
qram_swap_<W>[_hl][_controlled]([c,] m, addr, h)
                                  h <-> cells (for N not a multiple of 8 the low N bits of the S cells; their high
                                  bits stay); its own inverse, no tape slot, no _unc. _controlled: under c = 0
                                  nothing is touched. Its only use is the in-place form of rule 5, the only way a
                                  non-diagonal gate acts on a cell
                                  addr: the i32 handle of a 64-bit address rail (the QRAM query, decoded by the
                                  backend), or with _hl a classical i64 computed at run time. <W> is the width token
                                  of the access's LLVM type T (§1.2; a ptr is i64). S = DataLayout store-size(T) in
                                  cells: ceil(N/8) for iN, 2 for f16 and bf16, 4 for f32, 8 for f64, 10 for f80. An
                                  iN, N not a multiple of 8, is stored zero-extended and loaded from the low N bits.
                                  One call per access: a wide access is never spelled as byte accesses
tape_alloc() -> t
tape_fmt[_controlled]([c,] t, fmt)
tape_effect[_<W>]_controlled(c, t, name, n) [-> r]
                                  the effect entry of the host call `name` with the last n fields written to t; the _<W>
                                  form returns a fresh rail r of the callee's result type (below). A null `name`:
                                  the callee is the host address in the entry's first field (rule 19)
tape_write_<W>[_controlled]([c,] t, h) -> h', tape_write_<W>_lit(t, lit)
abort_i1(f)                       kept flag, measured at the end of the shot; a classical-valued 1 flag ends
                                  the shot at the call, which then does not return (rule 16)
invert_begin(), invert_end()      the adjoint region of rule 17; nested pairs nest; no gate of their own
push(w), pop() -> w               compiler-internal classical i32 word stack, not a circuit primitive (a wider value
                                  is i32 words, low word first); popped by rule 14's reverse loops and by a
                                  table clone's twin (§1.4)
```

**The memory bus.** All memory of the program is the one bus `M`; `m` above is always the value of
`i32 @__cq_mem()`. A cell is HOST or QUANTUM. Every cell starts HOST: its value is the host byte at
that address, read at each access. A store or swap whose address, control and resulting cell
content are classical-valued writes host memory and leaves the cells HOST; any other store or swap
makes every cell it can reach QUANTUM until a later such event makes it HOST again. Host code
(system calls, bodiless callees, startup data, initializers) therefore sees and is seen by the bus
with no seeding and no module constructor; at a QUANTUM cell it reads an unspecified byte, and a
byte it writes there is not seen by the bus. Out-of-domain addresses are totalized in §2; what is
un-copied, what is kept and the `_controlled` forms are rule 5.

The injection-bundle host symbols (classical host C shared by every module and library; no gate):

```
i32 @__cq_mem()                   the handle of M; the first call creates it with cqrt_qram_alloc_i8(i32 0)
[65 x i64] @__cq_sig              zero-initialised host array, one cell per signal number: the registered
                                  handler's address (rule 16)
ptr @__cq_alloc(i64 size, i64 align)
                                  size bytes of zeroed host memory at the given alignment, at an address that is
                                  never reused, with size as an i64 in the 8 host bytes before that address (rule
                                  16): every bus-resident alloca (a VLA included) and
                                  malloc/calloc/aligned_alloc/realloc block. Nothing frees it
void @__cq_clone_register(ptr fn, ptr sig, ptr clone, ptr ctl, ptr unc, ptr ctl_unc)
                                  module constructor: one row of the process-wide clone table per function whose
                                  address is taken or that is externally visible: fn = its host address, sig = its
                                  LLVM function type as a C string, then its all-ones table clone (§1.4) and that
                                  clone's _ctl, _unc and _ctl_unc. The function's own symbol is never a row
ptr @__cq_clone_resolve(ptr fn, i32 kind)
                                  the row's clone for host address fn (kind 0 forward, 1 _ctl, 2 _unc, 3 _ctl_unc);
                                  null when fn has no row (host code; rule 19)
i32 @__cq_clone_count(ptr sig), ptr @__cq_clone_at(ptr sig, i32 i)
                                  the n registered addresses of function type sig, i < n in registration order
                                  (the candidates of a function-pointer rail, rule 19)
```

The constructor is `internal void @__cq_register()` in `@llvm.global_ctors` at priority 65535. A
`sig` string is the private constant `@.cq.sig` (further function types `@.cq.sig.1`, `@.cq.sig.2`,
…): the LLVM 19 print of the function type with no attributes (`i32 (i32)`, `void (ptr, i64)`),
matched by its content, never by its address (each module has its own constants). A
module-internal `__cq_*` name that collides with a program symbol is renamed by the compiler.

Tape rails and abort flags are never freed, and all tape entries and abort flags form ONE event
sequence in call order. When the backend performs an entry (at its call, merged, or at the end of
the shot, where the tape rails that captured an output buffer's QUANTUM cells at the call are
measured) is BACKEND_ABI §1.11 alone; the compiler emits the same one call in every case and the
lowered program asks nothing. `tape_effect_<W>_controlled` returns the call's result in `r`.
`fmt`, `name` and the buffers of an entry are captured at the call (BACKEND_ABI §1.11). An
in-place target is never one of its own controls.

### 1.4 Clone naming

```
clone := "__cq_q_" fn "_" mask [ "_b" bound { "_" bound } ] [ "_rm" | "_rmq" ] [ "_t" ] [ "_ctl" ] [ "_pure" ] [ "_unc" ]
mask  := one digit per SCALAR formal of the function, LEFT TO RIGHT, after aggregate flattening,
         1 = quantum (a handle), 0 = classical (159 `shift_110`). A pointer is one scalar: 1 = a
         handle to a 64-bit address rail, 0 = the classical `ptr`; nothing about the pointee
         appears in a name or a parameter list. A variadic clone's formals are its fixed formals
         followed by ONE classical `ptr`, digit 0: the address of the block holding the variadic
         actuals (rule 16). A dead formal is passed as poison. A function with no scalar formal
         has the mask `v` (`__cq_q_get_v_unc`).
         The all-zero mask with no suffix is the function's OWN symbol with its C parameter list:
         the lowered body, reached by host code and all-classical calls. A variadic function's
         block form and the plain-`ptr` form of a function with a `byval` formal (rule 26) are
         always spelled by this grammar, all-zero mask included; their own symbol keeps the C
         signature for host callers.
_t     := a table clone (below).
_ctl   := the clone takes the block predicate as its FIRST parameter and applies it to everything
          that is not a template on SSA values: rotations, phases, bus accesses, tape and abort
          events, measurements (rule 19), the seed of a quantum-exit loop's chain (rule 14) and
          the calls of its `_ctl` callees. Templates and the
          copy-out run unguarded (rule 9): a result is not |0> where the predicate is 0, and the
          caller merges it by `select`.
_pure  := the clone without its phase effects (what the twins recompute through).
_bN..  := one upper bound per quantum integer argument whose range facts at the call site bound it
          (`memcmp(.., x & 3)` -> `_b3`); a clone's loop cutoffs use only these bounds and its own range
          facts (rule 14), never a bound of one particular call site that is not in its name.
_rm    := the clone of a body of `round.dynamic` ops with no strict op and no fenv call, reached
          from a caller that holds the fenv state with a mode other than the literal 0 (rule 23):
          it takes the mode as ONE classical `i32` after its formals (no mask digit), its
          `round.dynamic` ops are the `_rm` templates in that mode, and its calls of such bodies
          pass the mode on. No flags parameter, no `_exc`; results as the plain clone's.
_rmq   := the same clone when the mode is a rail: the trailing parameter is its handle, the ops
          are the `_rmq` templates and every result is a rail. A clone with 82's ABI (a strict op
          or a fenv call in its body: mode and flags as its last two parameters) keeps its plain
          name for a classical mode and takes `_rmq` when the mode is a handle.
          With `_rm` or `_rmq` the all-zero mask names a clone, not the own symbol
          (`__cq_q_nx_0_rmq(double x, i32 mode)`).
```
A clone name is read right to left: the suffix words, then the `_b` bounds, then the mask (`v` or
the rightmost token of binary digits), and `fn` is whatever remains. A name with bounds is internal
to its module, so the compiler never binds a clone by re-reading its name: the clone table is
keyed by the clone's fields, and two distinct clones whose names would coincide (a `fn` that
itself ends in `_<binary>_b<N>`) get distinct symbols.

Result: one `i32` handle per quantum scalar result regardless of width (a pointer result that is a
rail included), the C type for a classical result, a literal struct of scalar fields in field order
for several results (a nested aggregate is flattened: 166 returns `{ i32, i32, double }`). Twin:
`_unc(outs…, args…)`, `void`; a `_ctl` clone's is `_ctl_unc(pred, outs…, args…)`. A twin nobody
calls is not defined, a table clone's excepted (below). An internal function with no remaining use
is dropped. A clone called by name and a lowered own symbol keep the original's linkage, calling
convention and `unnamed_addr` (`internal fastcc` stays, and its calls stay `fastcc`); a clone whose
name has `_b` bounds is `internal` whatever the original (above). Every function, parameter and return attribute that states a memory, capture, nullness, range or purity
fact (`memory(...)`, `readnone`, `readonly`, `writeonly`, `nocapture`, `nonnull`, `dereferenceable`,
`noalias`, `nofree`, `nosync`, `willreturn`, `speculatable`, `range`) is dropped from the definition
of every clone and lowered own symbol and from every call of one; `noundef` stays, and a call of a host function or an intrinsic keeps its attributes as it stands (203). Attributes are not compared (§6).

**Recursion.** There is ONE clone per function, mask and kind, whatever the recursion depth, and
no depth is passed. A function that lies on a call cycle by name in its module, or has a table
clone (which anything may re-enter), has one module-internal classical counter of its live
`_ctl` activations: each of its `_ctl` clones and `_ctl_unc` twins reads it on entry (the
activation's depth `d`, rule 14), adds 1, and subtracts 1 at every return. The counter is
`@__cq_act_<fn> = internal global i32 0`, read and written by plain `load` and `store`; the cut
test is `icmp ult i32 d, K`. It is compiler state, not program memory: its accesses are no bus
accesses and no memory version changes (rule 5), and make no function one that writes memory.

**Received K.** No clone signature carries K except the table clone's. A module that defines a
table clone has one module-internal classical word `@__cq_k = internal global i32 -1` (all ones:
no cut). Each table clone, its `_ctl` form and their twins store their K actual in it on entry and
store the value they found there back at every return. A clone or own symbol that a table clone of
its module can reach by name and that holds a K cut (a quantum-exit loop, a quantum-depth
recursion) loads it once on entry: a value other than all ones is the K of that activation, in
place of its own, whether smaller or larger (rule 27: no K variant exists; rule 14: K is a
run-time value of the one rolled body). It is compiler state like `@__cq_act_<fn>`: plain `load` and `store`, no bus access,
no memory version change.

**Table clones.** A clone reached without its body in view (a row of the clone table, §1.3, or a
declared clone, rule 27) has an ABI that follows from the function's C signature and its mask
alone. Its name is `__cq_q_<fn>_<mask>_t` with no `_b` bounds. Which masks exist follows from the
C signature alone, so that a caller and a library built separately agree. Count the scalar formals
after aggregate flattening, the variadic block excepted (its digit is always 0):
- *Arrangements.* With at most 5 scalar formals every mask exists, the all-zero mask included
  (`_t` makes it a clone, not the own symbol): 2^n masks. A function with no scalar formal has
  the one mask `v`.
- *Class arrangements.* With more than 5, the scalar formals fall into three classes: pointers;
  integers (enums, `bool` and `char` included); floating point. A mask gives every formal of a
  class the same digit: one mask per set of the classes the signature has, the empty set and the
  full set included (at most 8).
- *The row.* The clone-table row of a function (rule 19) is its all-ones mask (a variadic
  function's block digit 0); every other table clone is reached by name only (rule 27).

A table clone takes each scalar formal as its mask says: a digit 1 as a handle (a pointer: a
handle to a 64-bit address rail), a digit 0 as the C-typed classical value (a pointer: the
classical `ptr`; a variadic function's block), then the cutoff K as a classical `i32` (rule 27).
It returns every scalar result as a handle (a classical result as a seed rail), whatever its
mask, and no extra result: it pushes the handles of the registers it minted (rule 19) on
`cqrt_push`. Its `_unc` twin always exists and pops those handles. For a
function rule 18 gives no twin it does nothing else, and every result stays allocated (KEPT);
otherwise it is rule 18's twin, frees the results it zeroes and leaves a FROZEN result (rule 19)
allocated. The caller frees no result of a table clone. A result that is rule 19's controlled-copy
rail (a `cq_measure` inside a `_ctl` clone) is returned as that rail, not copied and not pushed. In the clone without
a predicate a `cq_measure` of a formal measures a kept copy, `t = alloc_<W>(0); copy_<W>(h, t); measure_<W>(t)`:
`t` stays allocated and is not pushed, `h` is left to the caller, which has no record of the callee (rule 19) and
uncomputes and frees it as always; the outcome is classical and is returned as a seed rail like any classical
result (211).
`_t_ctl` and `_t_ctl_unc` take the predicate first; a table twin is `_unc([pred,] outs…, args…,
K)`, `args` exactly the forward's (classical ones as C values). Every table clone of a function
shares its `@__cq_act_<fn>` counter and the module's `@__cq_k`. A `_ctl` table clone whose body is only templates on SSA values computes unguarded and reads
its predicate only for the cut and for the seed of a loop chain. A call by name of a function whose body is in
the module is never a table clone: it is the rule-18 clone of its mask, all-ones included.

## 2. Totalization table

The classical reference evaluator (§6) and every backend use the same table. What LLVM 19's own
code generation fixes inline (a `cvtt`, `fist`, a shift, a double rounding through `float`,
`ExpandLargeFpConvert`) is the C program's semantics and is adopted for the VALUE where C leaves
the result to the implementation (rounding neighbour, out-of-range and NaN inputs). What a vendor
library computes (compiler-rt or libm: rounding mode and INEXACT for `sitofp`/`uitofp` from more
than 64 bits, `_exc` of `fptosi`/`fptoui` to more than 64 bits, INVALID for `frem` of 0 or ±Inf
and for `fmax`/`fmin` with a signalling NaN) is not fixed by the program: IEEE 754 at the
operation's width and the `_rm`/`_exc` contract of §1.2 are normative, and exception FLAGS follow
IEEE/x87 at that width wherever native raises none. A value C fixes exactly is never taken from a
miscompile: `uitofp` from more than 128 bits to f80 (LLVM 19's `ExpandLargeFpConvert` goes
negative when the top bit is set) is the non-negative value rounded to nearest even at f80's
64-bit significand (`_rm` when present), and the C oracle of §6 is overridden there as for the NaN
row. Every other `sitofp`/`uitofp` from more than 128 bits has `ExpandLargeFpConvert`'s value, its
exponent wrap for a magnitude beyond the format's range included (`i200 2^150` to f32 is
`0x8a800000`), in the plain and in the `_rm`/`_rmq` form alike: above 128 bits the mode is ignored
and the value is rounded to nearest even (no strict native code exists), and only the second step
to f16/bf16 rounds in the template's mode. This is a stated exception to the `_rm`/`_rmq` contract
of §1.2; the flags stay IEEE in the mode. IR that clang 19 emits and LLVM 19's parser rejects (`fpext`/`fptrunc` between `half` and
`bfloat`) is out of scope.

| operation | out-of-domain input | result |
|---|---|---|
| `udiv(a, 0)` | | `2^W − 1` |
| `urem(a, 0)` | | `a` |
| `sdiv(a, 0)` | | `−1` if `a ≥ 0`, else `+1` |
| `srem(a, 0)` | | `a` |
| `sdiv(INT_MIN, −1)` | | `INT_MIN` |
| `srem(INT_MIN, −1)` | | `0` |
| `shl/lshr/ashr(a, k)` | `k ≥ W` (literal or quantum amount) | amount taken mod W (a totalization of LLVM's poison; x86 masks 8- and 16-bit counts to 5 bits and is NOT the reference here) |
| `fshl/fshr` | | amount mod W |
| `fptosi/fptoui` from f16/f32/f64 | NaN, ±Inf, out of range | as x86-64 LLVM 19 `-O1` code (measured 2026-10-27; f16 via f32): let `c32(x)`/`c64(x)` be cvtt to i32/i64 with indefinite `INT_MIN` of that width. `fptosi` i8/i16 = trunc(c32), i32 = c32, i64 = c64; `fptoui` i8/i16 = trunc(c32), i32 = trunc(c64), i64 = `r1 \| (r2 & (r1 >>s 63))` with `r1 = c64(x)`, `r2 = c64(x − 2^63)`. E.g. NaN → s8 0, s32 `INT_MIN`, u32 0, u64 2^63; 300.0 → s8 44 |
| `fptosi/fptoui` from f80 | NaN, ±Inf, out of range | x87 `fistp` with indefinite `INT_MIN` of its width: s8 = trunc(fist16), s16 = fist16, s32 = fist32, s64 = fist64; u8 = trunc(fist16), u16 = trunc(fist32), u32 = trunc(fist64), u64 = `x < 2^63 ? fist64(x) : fist64(x − 2^63) ^ 2^63` (NaN → 0); other widths as LLVM 19 `-O1`: signed N ≤ 64 via the narrowest `fist` ≥ N, unsigned via the narrowest > N, 64 < N ≤ 128 the compiler-rt `__fixxfti`/`__fixunsxfti` value then trunc, N > 128 `ExpandLargeFpConvert` (|x| < 1 → 0; exponent ≥ N saturates to the signed N-bit extreme by sign, NaN included; else ±floor mod 2^N). Flags for N > 64: INVALID for NaN/Inf/out of range at the conversion width, else INEXACT (ruling 2026-10-27) |
| `fadd fsub fmul fdiv frem fma sqrt …` NaN result | | x86 SSE rule in IR operand order: the first NaN operand, quieted; an invalid operation (`frem` by 0 or of ±Inf included) gives the default NaN `0xFFF8000000000000` (f32 `0xFFC00000`, f16 `0xFE00`, bf16 `0xFFC0`, f80 the real indefinite `0xFFFF_C000000000000000`; the first-NaN rule holds for f80 too, although x87 natively returns the larger significand). Where native x86-64 `-O1` code leaves the choice to register allocation or to the libm vendor (two-NaN commutative `fadd`/`fmul`, `frem` and `fma` through libm), this row is normative, and the C oracle of §6 compares floating-point values NaN-insensitively (any NaN equals any NaN); the reference oracle compares bit patterns (ruling 2026-10-27) |
| `fmax(a, b)` / `fmin(a, b)` (`llvm.maxnum/minnum`) | | `isnan(a) ? b : isnan(b) ? a : (b > a ? b : a)`, min with `<`; equal values (±0) give `a`; two NaNs give `b` unchanged (x86-64 `-O1`, measured) |
| f80 non-canonical encodings | pseudo-NaN, pseudo-Inf, unnormal | invalid operand: result real indefinite `0xFFFF_C000000000000000`, INVALID; pseudo-denormals read as denormals (x87) |
| `fadd fsub fmul fdiv sqrt fma` | | IEEE, round to nearest even unless `_rm/_rmq` says otherwise |
| `llvm.fmuladd` | | unfused: `fmul` then `fadd`, each rounded (the x86-64 baseline has no FMA unit, so the classical program rounds twice); only `llvm.fma` is fused |
| `frem(x, y)` | | IEEE `fmod`: sign of `x`; `fmod(x, 0)` = NaN; `fmod(±Inf, y)` = NaN; `fmod(x, ±Inf)` = `x`; NaN propagates |
| `f16/f32/f80` arithmetic | | IEEE binary16 / binary32 / x87 extended, same rounding rule |
| `ctlz(0)`, `cttz(0)` | | `W` |
| `abs(INT_MIN)` | | `INT_MIN` |
| `rint`, `round`, `floor`, `ceil`, `trunc` | | IEEE; `rint` rounds in the current mode, ties to even in the default mode, and a `_rm`/`_rmq` template in the template's mode |
| bf16 conversions | | `fpext` bf16 → f32 is inline, a bare shift (an sNaN stays signalling). `fptrunc` f32 → bf16 and f64 → bf16 are compiler-rt calls (`__truncsfbf2`, `__truncdfbf2`), so IEEE is normative: one rounding to nearest even from the source width, a NaN becomes a quiet NaN carrying the high payload bits and never an Inf. `sitofp`/`uitofp` iN → bf16 is codegen's inline route iN → f32 (rounded) followed by that f32 → bf16 conversion (two roundings, visible for N > 24) (ruling 2026-10-27) |
| `is_fpclass` | | pure bit test; on f80 a pseudo-denormal is subnormal and a non-canonical encoding is a quiet NaN (native is inconsistent here; the table decides) |
| `ry`/`rz`/`phase` with a non-finite angle (literal or angle rail) | | identity |
| `qram_load` | a cell that is HOST and whose address is not readable host memory (address rail or `_hl` address; decided per cell) | that cell reads `0`; never a fault |
| `qram_store`, `qram_swap` | a HOST cell whose address is not writable host memory | the cell becomes QUANTUM (its displaced content is `0` when unreadable); never a fault |
| `qram_load`, `qram_store`, `qram_swap`, `_controlled` | control `0` | nothing is touched: no cell, no host byte; a load's `h` and a store's tape slot stay `|0⟩` |
| any bus access | address + S beyond 2^64 | the cell index wraps mod 2^64 |

## 3. Construction rules

Each rule names its witness examples. "Fresh" always means a `|0⟩` rail allocated for the result.

1. **Handle ABI.** Every quantum value is an `i32` handle (§1.1). Aggregates and vectors are
   tuples of handles and classical values. A pointer is never a tuple: it is one classical
   `ptr`/`i64` or one handle to a 64-bit rail holding the address. A template exists for every
   width on demand. — 01, 46, 64, 93, 103, 110, 111, 200.

2. **Source and sink.** `cq_theta_*(v, θ)` on a classical `v` mints `alloc_<W>(v)` then
   `ry_<W>(h, θ)`; on an existing handle it rotates that rail in place. On a loaded value
   (`cq_theta(p, θ)` is `load p`, rotate, `store p` in the -O1 code) it is rule 5's in-place
   form when the result is stored straight back through the same SSA pointer: the gate acts
   on the cell. `<W>` is the `cq_theta`'s own width, not the cell's access type (a `_Bool`
   cell is `qram_swap_i1`, `ry_i1`). A `cq_theta` on the value -O1 forwarded from a store to the
   cell it is stored back through (rule 5 *Readers*; a literal included) is that in-place form
   on the cell, never a mint. In every other case (the result is not stored, is stored
   through another pointer, or a memory version change lies between the load and the store)
   the rotation acts on the load copy, as the C program says: the copy is a FROZEN register
   from there on (never un-copied, rule 10) and a later store of it is an ordinary kept store
   (rule 5).
   `cq_measure_*` is `measure_<W>(h)`; the rail stays allocated; dominated uses of the measured
   SSA value denote the outcome; a re-measurement of the same rail is a classical re-read, and
   `cq_measure` of a value that never was a rail is that value: no gate. A
   measurement inside a quantum arm is never conditioned on quantum data: it is executed
   unconditionally at its program point, so the measured register is collapsed on every branch
   (a deviation from the C program that is the user's responsibility; the compiler may warn).
   Inside a `_ctl` clone the measurement is rule 19's controlled copy instead; inside a table clone without a
   predicate a measurement of a formal is of a kept copy (§1.4), so the caller's rail is never a measured rail. The arm flag is never measured. The outcome merges with the other incoming values by
   `select` under the flag, so the value the C program reads is tainted. Measurements of one
   rail in several quantum arms are one measurement. The arms of a classical branch (rule 8, a
   branch on a collapsed outcome included) are separate blocks: each `cq_measure` there is its
   own `measure_<W>` at its program point, and one path executes one of them.
   **Classical collapse.** A value computed only from measured rails and classical values is
   classical: its rail (a flag too) is uncomputed while its sources still hold the outcome
   (convention: right after the measurement), the value is recomputed classically from the
   outcomes, and a merge under such a flag is a classical `select`. A rail computed *before*
   the measurement of its only quantum source collapses too. A `cq_measure` of a collapsed
   value is a classical read. When the measurement happened inside a clone that returns only
   a function of the outcome, the caller re-reads the rail with `measure_<W>` at the collapse
   point (136). A collapsed rule-23 rail (flags or mode) is written back to the host
   environment there (`feraiseexcept(v)` / `fesetround(m)`) and is no output (65).
   **Collapse is static.** It applies to a value whose quantum sources are measured on EVERY
   path reaching it. A rail measured on some classical paths only is lowered as unmeasured
   after the join, and nothing is re-read. A clone that measures a rail on some of its
   classical paths returns the outcome there as a seed rail; its twin leaves that rail alone
   and the caller frees it after the twin (a table clone's results stay allocated, §1.4).
   Example owed (§8).
   — 01, 38, 42, 65, 128, 136, 140, 155, 195, 205, 207, 211; 120.

3. **Taint propagation.** Forward over SSA, and through calls per rule 18.
   - *Through memory.* Every load is a bus load and its result is a rail; the exception is a
     load of a host-resident object (rule 20), which is classical. Nothing is asked about what the cell holds: a
     classical value or a measured outcome that was stored and is loaded again is a rail.
     Over-taint is accepted (§0: such a rail costs no qubit).
   - *Pointers.* A pointer is tainted iff it is computed from a rail, and is then one 64-bit
     address rail (rule 21).
   - *Loops.* A value defined inside a quantum-exit loop (rule 14) and used after it is quantum,
     whatever it is inside the loop: it depends on which trip exited.

   The angle operand of a rotation is classical unless rule 15 applies. Casts, `freeze`,
   `insertvalue`/`extractvalue`/`shufflevector` on handles are representation changes and emit no
   gate for lane moves. — 17, 18, 26, 56, 103, 195, 203; 63.

4. **Opcode lowering, always out of place.** A tainted opcode becomes
   `cq_template_<op>[_<pred>]_<W>[_shape]` into a fresh rail (§1.2). A classical operand is a
   literal (`_hl`/`_lh`); a commutative op puts the handle first. `*.with.overflow` is two
   templates over the same operands; `cmpxchg` and `atomicrmw` are a bus load, the compare and
   `select` (or the operation's) templates, and a bus store (rules 20, 24), lowered by rule 5 as
   if written (an `add`, `sub` or `xor` is the in-place form, its result a plain load before the swap-out). There is no in-place
   template; in-place is reserved for rule 2 (rotation of an existing rail), rule 10 (controlled
   Ry), `xorc` on a basis-state seed, rule 5's in-place form on a memory cell and rule 6's
   in-place update (`add` and `xor` of a dead value, the core gates `add`, `addc`, `copy`, `xorc`). — 10, 11, 13,
   14, 56, 92, 112; 94, 130.

5. **Uncompute spine.** Every rail that is not a user register, a result, a tape/abort rail, an
   output or a rail kept below is uncomputed by its producer's `_unc(out, operands…)` and freed.
   Order: reverse dependency order (a rail is uncomputed before every rail its producer read,
   and an operand rail outlives every `_unc` that reads it); rails with no dependency between
   them uncompute in any order. Scheduling invariant: a garbage rail is uncomputed after its
   last consumer and before any non-diagonal gate on any of its sources. Convention for the
   examples (not a requirement): uncompute as early as the invariant allows.

   **Memory.** The bus `M` is ONE linear value (§1.3), and two bus accesses never commute for
   the compiler: no rule asks at compile time whether two addresses differ (the one run-time test of two
   classical addresses is the in-place form's *Readers* clause). A *memory version change* is a bus
   store, an in-place form, a plain store or memory intrinsic to a host-resident object (rule
   20), an observable `volatile` store (rule 24), an allocation (rule 16), an effect entry or a host call unless
   LLVM's memory attribute marks the callee as writing no memory (`memory(none)`, `memory(read)`,
   `memory(argmem: read)` and the like) (rule 16; a format entry is none), a call of a table
   clone (rules 19, 27), or a call of a function that *writes memory*: one whose body contains
   any of these (a static property, the least fixpoint over calls by name). Three sentences
   are the whole of memory uncomputation:
   1. *Load.* Every bus load is un-copied (`_unc`: the same load again, at the same address
      rail and control) after its value's last reader (the last consumer and, where that
      consumer is uncomputed, its `_unc`; rule 6's inverse included). A consumer that is never
      uncomputed (a measured, returned, kept or carried rail, a rule-6 image) has no `_unc` to
      wait for. Convention: right after the last reader, before a measurement of the consumer.
      The copy is freed only when that point precedes the next memory version change on every
      path; otherwise it is un-copied all the same and stays allocated (*overtaken*: `|0⟩`
      where the cell was not written in between, garbage where it was; no rule asks which).
      Exceptions, never un-copied and KEPT: a load copy that is itself measured (rule 2's
      measured rail), one that is the value rail of a kept store, and one a rotation acted on
      (rule 2's fallback). A load copy is never cleaned by rule 6.
   2. *In-place form* (below). It leaves nothing behind, and it is the only way a
      non-diagonal gate or a garbage-free update reaches a cell.
   3. *Store.* Every other bus store is KEPT for the shot: its tape slot stays allocated and
      nothing pops it, and in the function that makes the store so do its value rail (a seed
      included) and its control rail; a caller that passed either as an argument or a `_ctl`
      predicate treats it by its own rules. Its address rail follows its producer: a template
      result is uncomputed after the store, the result of a clone that has a twin is zeroed
      by that twin after the store (rule 18) and freed, a load copy is overtaken by the store
      (sentence 1: un-copied after it, not freed). A caller that passed the address rail to a storing callee treats
      it the same way after the call. One rail may be the value rail of several kept stores.

   Under a quantum predicate (an arm flag, a trip predicate of rule 14, a `_ctl` clone's
   predicate) every bus access is the `_controlled` form under that predicate; a load's `_unc`
   takes the same control at the value it had at the load (an access made inside an X bracket
   is un-copied inside the same bracket). No bus access is hoisted or speculated. Kept rails
   are which-path copies of what the program stored or loaded; the scheduling invariant and
   rule 6 are promised for SSA values and for the in-place form only. §6 lists kept store
   rails, kept load copies and tape slots as kept by this rule.

   **In-place form.** `y = load p; y_1 = g_1(y, …); …; y' = g_n(y_{n−1}, …); store y', p` on
   the same SSA pointer with no memory version change between the load and the store, where
   every step `g_i` is a `cq_theta` of the previous value (rules 2, 10) or a rule-6 bijection
   in it, is

         h = alloc_<W>(0); qram_swap_<W>(m, p, h)        ; h holds the cell, the cell |0>
         each step in order: the gate on h, or the update with rule 6's clean of the previous rail
         qram_swap_<W>(m, p, h or y'); free              ; the cell holds the result, the rail |0>

   with `_hl` swaps for a classical `p` and the plain form for an address rail. The form is
   emitted at the STORE's position and no bus access lies between its two swaps: a load a step
   reads (`*p += *q`) is a plain load at its own program point, before the swap-out. The
   address rail and the steps' other operands are uncomputed after the second swap when their
   producer is a template; one that is a bus load copy is overtaken by the form (a memory
   version change): sentence 1 un-copies it after the second swap and does not free it (`*p += *q`: the copy of `*q`; `**pp += 3`: that of `*pp`).
   - *Width casts.* `y = load T p; trunc T y to U` (`nuw`, or a range fact that the high bits
     are 0), the steps at `U`, `zext U to T; store T, p` is the form at width `U` (a `_Bool`
     cell: `qram_swap_i1`, `ry_i1`, `qram_swap_i1`); the high bits stay in the cells (§1.3).
     Every load of a `_Bool` cell read through a `trunc` to `i1` (or an `icmp ne 0` a `[0,2)` range
     fact makes equivalent) is ONE access at `i1` (`qram_load_i1`), never `qram_load_i8` and a trunc
     template; a `load i8 !range [0,2)` whose user is a `zext` is an `i8` load and the `zext`
     template (176, 178, 179, 185); `zext (icmp
     ne x, y)` of two such loads is the step `xor_i1`, so `*p ^= *q` on `_Bool` cells is the form at `i1`.
   - *Readers.* `y` may be the value -O1 forwarded from the preceding store to `p`: each store
     closes its own form, and the interval then runs from that store. Where `y` is the result
     of the preceding form it has no rail of its own: before a memory version change in the
     interval the lowered code takes a plain load of `p` as `y`'s copy, the steps act on that
     copy (rule 2) and the store is a kept store. No copy is taken, and the form stands, when
     the change is a bus store or in-place form at a classical address `q` (S_q cells), `p` is
     classical and a classical run-time branch finds the cells disjoint:
     `d = (q − p ≥ S_p && p − q ≥ S_q)`, the differences mod 2^64 and the compares unsigned,
     computed from the run-time addresses immediately before the change. The code branches on
     `d` twice and duplicates nothing: `br d` around the plain load of `p` (taken when d = 0),
     the change, emitted once, then `br d` at the store's position: d = 1 the form, d = 0 the
     steps on the copy and the kept store. The copy's handle reaches the second branch through
     a classical `phi` whose d = 1 incoming is `poison`; a later reader of `y'` reads a plain
     load taken after the swap-in when d = 1 and the copy rail when d = 0, joined by a
     classical `phi` of handles. With several changes in the interval `d` is the AND of their
     tests, computed before the first of them, where the one copy is taken; a change of any
     other kind, a change whose address is not computable at that point, or an address rail `p`, makes `d` the constant 0 (the copy, no branch). A classical address is computable at that point when it is a
     `getelementptr`/cast chain over values live there, wherever the IR places the chain: the
     compiler computes it there (164).
     Another reader of `y`, or of a step value before the first `cq_theta` step, reads a plain
     load taken before the swap-out (the bijections recomputed on that copy); every later reader
     of `y'` (no branch) ONE plain load taken right after the swap-in. A value at or
     after a `cq_theta` step that has another reader, other than its own store and the first
     step of the next form on the same SSA pointer (the forwarded `y` above), ends its form
     there: the reader reads a plain load taken after that swap-in, and the remaining steps
     are the next form.
   - *Under a quantum predicate* `c` the swaps are `_controlled` under `c`, each gate is its
     controlled form and each update the composite `c ? g(h, …) : h` (a rule-6 bijection), so
     `h` and `y'` are `|0⟩` again on the `c = 0` branch.

   An update of a cell that is not this shape is a plain load, the templates and a kept store;
   for `cq_theta` see rule 2. — 02, 04, 07, 20, 66, 118; 195, 198, 199, 202, 205, 206, 207.

6. **Bijective update of a dead value.** When `y' = f(y, …)` is a bijection in `y` for every value
   of the other operands and `y`'s old value is dead, the old rail is cleaned: compute
   `t = f⁻¹(y', …)` fresh, `copy_<W>(t, y_old)`, `_unc` of `t`, free `y_old`. When the old value is
   still needed to uncompute other rails, those are uncomputed first and then this rule applies (to
   the composite update, 127). The rule is not an optimisation and has no other trigger: it
   applies to a rotated user register (01, 38, 180) as to a template result (127). A seed (rule
   7) is freed directly instead.
   - *Dead* is asked at the CLEAN-UP POINT, not at the update instruction. The clean-up is placed
     after the old value's last reader in the function (every SSA use and every `_unc` that
     re-reads it) and before the first non-diagonal gate on the rail that holds its bijective
     image or on one of `f`'s other operands (convention: right after the update); it cleans
     the old rail from whatever bijective image is live there (`y'`, or a later image: the
     composite update). A later reader never keeps the old value, it only moves the clean-up.
     A chain of bijective updates is cleaned step by step, each old rail right after its own
     update. A call result that rule 18 keeps (no twin) is cleaned by this rule like any other
     rail: KEPT there only means that no twin is called. In a clone whose result is the
     bijective image, the image rail is returned directly (no copy-out), and a classical `phi`
     incoming that is a seed is freed by the same clean-up (204).
     The old value is kept only when no such point exists: it escapes (`ret`, a call argument
     the callee keeps), it is the value or control rail of a kept store (rule 5), it is
     measured (rule 2 instead), it is operand 1 of an update whose operands are both dead
     (`%sum = add %s, %t`, the IR operand order whatever the C source wrote: `%s` is cleaned
     against the sum, `%t` kept; below, 109), or a reader of it follows a non-diagonal gate on its image.
     A kept old value is a which-path record of the rail that replaced it: a later
     non-diagonal gate on `y'` or on an operand of `f` acts on a dephased register (162).
   - *In-place update (`add`, `xor`; owner 2026-11-25).* When `f` is the plain opcode `add` or
     `xor` (not `sub`, not a select or a composite update, not the rolled-loop case below; inside a
     `cq_invert` region rule 17 says which updates are gates, `sub` included, whatever reads the old
     value later), its other operand `o` is a literal or a rail other than `y`'s, and the clean-up point is right
     after the update (no reader of the old value follows the update instruction: no SSA use and
     no `_unc` that re-reads it), then wherever the sentences above would clean and free
     `y_old` there, the update and the clean-up together are ONE core gate on `y_old`'s rail:

         add y, o    add_<W>(o, y)      a literal o: addc_<W>(y, lit)
         xor y, o    copy_<W>(o, y)     a literal o: xorc_<W>(y, lit)

     and `y'` IS that rail from there on: no template, no fresh rail, no `t`, no `copy` onto the
     old rail, no free. The rail then lives as `y'` would have (kept, measured, returned, the
     old value of the next update in a chain, the step of rule 5's in-place form on the
     swapped-out rail `h`). *Garbage (owner 2026-11-26):* the same gate is emitted when `y` is a
     dead value that rule 5 would otherwise uncompute, a template result (the `mul` of 106, the
     `zext` of 72 and 90) or a clone result that has a twin (34, 67), under the same
     conditions: the gate goes on `y`'s rail, `y`'s own `_unc` or twin is NOT called (the rail
     holds `y'` from there on), and what `y` was computed from is undone where rule 5 places
     it (a load copy whose last reader was `y` is un-copied right after `y`, before the gate).
     When both operands are such values, operand 0 of the IR instruction is the rail updated
     and the other operand is uncomputed right after the gate (34, 72, 90). A template result
     beside a load copy that sentence 1 excepts stays as it was (198). Every case in which the old value is kept (escapes, a kept store's
     rail, measured, operand 1 of an update whose operands are both dead, a reader after a
     non-diagonal gate) and every case in which this rule does not free `y_old` itself (a
     seed, a rail the function does not own) is unchanged: the template into a fresh rail,
     as before. So is every update whose clean-up point is later than the update. Where the
     code is reversed (rule 17's region, a twin of rule 18, a reverse loop of rule 14) the
     inverse of `add_<W>(o, y)` is `sub_<W>(o, y)`, that of `addc_<W>(y, lit)` is
     `addc_<W>(y, -lit)`, and `copy` and `xorc` are their own. The gate is never
     `_controlled`: under a quantum predicate it is emitted exactly where the template it
     replaces was (a pure computation on a rail that is dead on every path), and an update
     merged with the old value by a `phi` is the composite case, not this one; inside a
     `cq_invert` region both are the select of an update with the predicate's flag (rule 17).
     *A select of an update (owner 2026-11-26):* outside a loop, `s = select c, f(y), y` (either
     arm order), `f` the plain `add` or `xor` of `y` and a literal or rail `o` that only `s` reads,
     is `s = y + select(c, o, 0)` (`^` for `xor`; the `0` in `y`'s arm's place): the select
     template on `o` (`_ll` for a literal), this clause's gate where its conditions hold, the
     select's `_unc`. So `if (x) a += 7;` lowers as `a += x ? 7 : 0;` does. A rolled loop's
     accumulator keeps its merge (rule 14), except a register's inside a `cq_invert` region
     (rule 17).
     §6: the old value and its image are ONE rail, so a gate before the update and a gate
     after it act on the same rail (38, 180); a lowering in the older form (two rails, the old
     one freed at `|0⟩`) is not this rule's.
   - *Bijections:* `add`, `sub`, `xor` with any other operand (classical or a rail), `sub 0, y`,
     `xor y, -1`, `mul` by an odd literal, `fshl`/`fshr` with `y` in both value slots, `bswap`,
     `bitreverse`, `fneg`; a select whose arms are such updates of `y` or `y` itself (125) and
     whose condition does not read `y`; a controlled swap (145). Not: a width change (casts are
     rule 3), `mul` by a classical parameter or by a rail (`c = 0` collapses it), shifts, FP
     arithmetic other than `fneg`; a select or loop update whose condition reads `y` (x = k and
     x = k + 1 both leave `x -= 1 under x > k` at k: 149's x, 54, 68, 139); a merge whose
     complement arm is a classical value rather than `y` itself (123: the old `y` is rule-5
     garbage, uncomputed as usual).
   - *In a rolled loop (rule 14):* a carried value whose trip update is such a bijection and whose
     trip predicate does not read it (a counter, an accumulator), and whose final value is live
     after the loop as something that is never uncomputed (measured, returned, stored, rotated,
     an operand of a kept rail, a measured one included; not a read by a phase's angle, whose
     rail is uncomputed after the phase), is cleaned in the body of the
     same trip, with the composite update's inverse (e.g. `a ? y' - 1 : y'`), after the arm's
     garbage whose `_unc` reads the old value. The cleaned rail is not pushed and the reverse
     loop never sees it; the final carried rail is the loop's result and is measured directly
     (no copy-out); trip 0's old rail is the incoming rail, whatever it is (a `|0⟩` rail, a
     seed, a rotated user register: 203), cleaned and freed by the same clean-up, a bus load copy
     excepted: rule 5 sentence 1 decides that one (un-copied after trip 0's update), and the
     register's handle is the carried rail from then on. Trip 0's own treatment runs under a
     classical branch on the trip index (the loop is not peeled). A carried value whose
     final rail nothing reads after the loop, or only rails that are themselves uncomputed read,
     is not cleaned per trip: its chain is garbage like any other, pushed per trip and undone by
     the reverse loop after its last reader (the straight-line rule: the clean-up point lies
     after the image is gone, so no clean-up exists; 95, 109). A loop-invariant rail read by such
     an update in every trip is cleaned from the last trip's image on the exit edge, and kept
     on a zero-trip path (75). 05, 09, 150 (the counter), 149 (s), 27 (acc).
   - *A memory cell.* `y = load p; y' = f(y, …); store y', p` (`g++`, `*p += x`, `s->n ^= k`) is
     rule 5's in-place form: the cell is the register, and no copy of the cell, tape slot
     or old value remains, at a classical address or an address rail alike (a load copy that
     supplied the address or an operand is un-copied after it and not freed, rule 5). Nothing else in memory
     is cleaned by this rule.
   - *Both operands dead* (`x + z`, two rails): when one is garbage that rule 5 uncomputes
     anyway (a template result, or a bus load copy that sentence 1 does not except), rule 6 cleans
     the other first (its inverse reads the garbage; 195). A load copy that sentence 1 excepts is
     kept, and rule 6 then cleans the other operand only if that is not itself rule-5 garbage;
     when both operands are garbage rule 6 has no trigger (198). When the garbage's
     `_unc` reads the other operand, the garbage is uncomputed first and rule 6 asks the
     composite update (127: `g = 2x`, `y' = g + x` is `y' = 3x`, so `x` is cleaned). When
     neither is such garbage, operand 0 of the IR instruction is cleaned against the result and
     operand 1 is kept.
   - *Dead on one classical path only* (a classical `select` or `phi` between `y'` and `y`:
     `c > 1 ? x + 7 : x`): the clean-up runs under a classical branch on that path's condition
     at the clean-up point; on the other path the old rail is the live value. Example owed (§8).

   — 01, 38, 125, 127, 144, 145, 180; 195, 198 (a cell), 203, 204.

7. **Seed rails.** A rail minted from a classical constant or parameter and never written is in a
   known basis state and is freed directly (§0), whatever its value (`alloc_i1(true)`). The seed a store of a classical value mints
   is that store's value rail and is kept with it (rule 5; a basis state costs no qubit).
   — 25, 57, 62; 28, 94, 95.

8. **Branch flags.** A tainted `br` condition becomes a flag rail: the compare template's result,
   or the bare `i1` rail. A conjunction of flags is `and_i1` into a fresh `|0⟩`; a disjunction
   `or_i1`; a flag used as data is the `cq_template_and_i1`/`or_i1` form. The false edge is an
   X bracket (`not_i1`) on the flag. A phase arm is `rz_i1(flag, θ)`. A mixed condition is first
   factored as `C && Q` on its Boolean function (not its syntax), where `C` is the conjunction
   of every classical term that is a conjunct of the whole condition and `Q` is the rest. `C`
   stays a classical branch around the quantum part (23 `cond_mixed`, 180). `Q` is one flag: a
   classical `i1` term inside it that cannot be factored out (`c || q`) becomes a seed rail
   (rule 7) and joins by `and_i1`/`or_i1`. A purely classical condition is always a classical
   branch, also inside a clone; a clone body is never flattened as a whole. The flag is
   uncomputed after its last controlled gate; a flag that controls a kept store is kept with
   it (rule 5). — 03, 08, 21, 23, 69, 137, 138, 146, 154; 59.

9. **Value arms.** Pure arm code (templates on SSA values) is hoisted and computed unguarded into
   fresh rails. A bus access is never hoisted: it stays in its arm as the `_controlled` form under
   the arm flag (rule 5), and a `_controlled` load's rail is `|0⟩` on the other branch. The merge
   (`phi` or `select`) is one `cq_template_select_<W>[_shape]` per distinct incoming, chained with
   the complement arm innermost, into a fresh rail; arm rails are then uncomputed. No other merge
   spelling. Nested value arms nest their selects; a conjunction flag is needed only where a
   phase gate, an in-place gate or a bus access (`_controlled` under it) sits in the inner arm;
   one that controls a kept store is kept with it (rules 5, 8). A `select` or `phi` whose condition (or choice
   of incoming edge) is purely classical is a classical `select`/`phi` over the handles, no
   gate (rule 8); each arm's rails are still computed and uncomputed, and the chosen handle is
   the merged value; a literal incoming of a classical `phi` over handles is a seed minted in
   a block on that incoming edge. — 04, 20, 21, 22, 24, 49, 123, 135, 143, 148, 158, 204.

10. **Controlled Ry and state prep.** A `phi` of `cq_theta(v, θ)` against `v` (or two thetas of one
    seed) is `ry_<W>_controlled(flag, rail)` on a rail seeded with `v`; `r = c;` before the prep
    adds `xorc_<W>_controlled`; a second prep of a rail nothing read in between undoes the first by
    its adjoint under the conjunction flag. When something did read the rail in between (a template,
    a flag, a store) or a rotation hit it, the second prep is a prep of a FRESH rail seeded
    with `v`, the register's handle moves to it, the old rail stays allocated as a frozen
    which-path record (rule 6's kept old value), and the arms merge by rule 9 over the two
    handles (example owed, §8). The rotated rail is frozen (never reverse-played). A flag that
    read the rotated register stays allocated.
    On a memory cell the controlled Ry is rule 5's in-place form with `ry_<W>_controlled(flag, h,
    θ)` on the swapped-out rail, and the cell is the register. `r = c;` before a prep of a cell
    is a kept store: its tape slot holds the displaced content, so whether anything read the
    cell in between is never asked. — 39, 66, 125, 133, 141; 120.

11. **Angle select is a quantum angle.** An angle that depends on quantum data in any way (a
    `select` or `phi` on a quantum flag, a `switch` over a quantum scrutinee, a value loaded from
    the bus, arithmetic on a register) is computed into an `f64` rail by ordinary templates and
    bus loads and consumed by rule 15's single primitive, never expanded into per-arm
    controlled rotations. A `cq_phi` whose angle -O1 merged into one `phi` over the edges of a
    quantum `switch` or diamond (22 `switch_phase`) is this case: the `phi` is the rule 9/13
    select chain of its incoming values, and the phase fires as `rz_qangle_controlled` under
    the shared block's predicate. — 22, 132, 141; 142.

12. **Phase deletion.** `cq_phi(θ)` is deleted only when no quantum predicate is in scope at any
    call depth. Inside a `_ctl` clone or a callee reached from a quantum arm it is
    `rz_i1(pred, θ)`. Under a purely classical condition at top level it is a global phase and is
    deleted. — 41, 146.

13. **switch.** One equality flag per reachable case on the scrutinee; a shared or fallthrough
    block gets `or_i1` of its edge flags; an `unreachable` default gets no flag, and then the last
    case needs none either: it is the complement of the others and becomes the innermost select
    arm; a reachable default is the complement of the case flags. Value arms merge per rule 9,
    phase arms per rule 8 (distinct `cq_phi` calls in their own blocks; one merged call with a
    `phi` angle is rule 11).
    A computed `goto` (`indirectbr`) is a `switch` over its destination list: the scrutinee is
    the ADDRESS itself (an integer like every pointer, rule 21; no index is recovered) and the
    flags are `icmp_eq_i64_hl(h, ptrtoint(blockaddress(@f, %bb)))`, a run-time constant. The
    default is `unreachable` (LangRef), so the last destination is the complement of the
    others. The lowered function keeps every destination block distinct (a stand-in with its
    own code is acceptable), and every `blockaddress` constant in the module denotes the
    lowered block. `callbr` (`asm goto`) is inline asm (rule 27). — 22, 49, 123, 131; 142;
    examples owed for a computed `goto` and a reachable default (§8).

14. **Loops.**
    - *Classical bound, quantum body*: the loop stays a classical loop. The bound is classical only
      when every value its exit test reads is; a bound loaded from the bus is a rail (rule 3) and
      the loop is the next case. Each trip computes next values into fresh rails and pushes every
      trip-local rail that rule 5 does not keep (and any classical per-trip value its `_unc`s
      need that is not expressible from the trip index) on `push`; after the result is copied
      out (`alloc` + `copy`) a reverse loop pops and uncomputes each trip. A rail rule 5 keeps
      that a reverse-loop `_unc` reads is reached by pushing its handle per trip (`cqrt_push`/
      `cqrt_pop`), never by recomputing it, and is neither uncomputed nor freed. Rule 5 decides each
      load as anywhere. — 25, 27, 57, 62, 131; 28, 187, 188.
    - *Quantum-dependent exit, cutoff K*: a loop whose exit test reads a rail, a value loaded from
      the bus included (the user raises K, §0). The loop is re-rolled so the pre-header guard is
      trip 0 of the latch test (equality by SCEV: the same expression over SCEV-equal
      operands, a load equal to a load of the same type at a SCEV-equal address when no
      memory version change lies between the guard and the loop header, 203); it runs exactly K trips (fewer only where a classical conjunct ends the chain, below) under the predicate
      chain `a_j = a_{j−1} & cond_j`, seeded `|1⟩` (or the arm flag when the loop sits in an
      arm, the predicate in a `_ctl` clone); every carried value advances by a `select` on `a_j`; the reverse loop pops K trips.
      A `cq_measure` in the body is one call in the rolled body and runs in every one of the K
      trips, unconditionally (rule 2), on that trip's carried rail; in a trip the C program does
      not reach, that rail holds the value its `select` kept. A `cq_measure` in an exit arm runs
      once, after the K trips, on the arm's value merged across the trips. A loop-carried value
      with a rail among its incoming values is a rail in every trip; the loop is never peeled.
      A use of that rail which the trip's own `cq_measure` of it dominates denotes the outcome
      (rule 2), in every trip. An exit test that reads only such outcomes and classical values is
      classical: the exit is rule 8's branch on it, made after that trip's measurement, and no
      cutoff applies to it. A loop all of whose exits are such is the classical loop of the first
      case (no K, no `a_K`): it runs the trips the outcomes give, one `measure_<W>` per executed
      trip, and inside a quantum arm measurement and branch are unconditional (rule 2). Beside
      a quantum exit it is a classical conjunct (below). A test that reads the carried rail
      before the trip's measurement, or another unmeasured rail, is quantum.
      The code after the loop runs once, after the K trips: its values are the `select` chain
      over the exit flags, and an exit block that makes a call or a bus store is never emitted
      per trip (an exit block that keeps nothing may be: 121).
      A classical conjunct `C` of the exit test (`while (c && q)`) is a classical branch AT EACH
      TEST (rule 8): where `C` is false the chain ends there, `a_j` is a `|0⟩` seed through a
      classical `phi` of handles and no later trip is emitted; where it is true
      `a_j = a_{j−1} & Q_j`. `do … while (c && q)` runs trip 0 whatever `c` is.
      Every bus access of trip j is the `_controlled` form under `a_j`, except one that the
      exit test of trip j reads: that one is under the predicate of reaching the test, and its `_unc`
      takes the same rail: `a_{j−1}` where the test of trip j gives `a_j` (the seed or the arm flag for trip 0,
      `a_{K−1}` for the test that gives `a_K`), `a_j` in the test-at-bottom form, where the test after body j
      gives `a_{j+1}`. None is made before the loop on the loop's behalf: a trip C would not run touches no cell and no host byte.
      An AFFINE INDUCTION is not carried: a value with a loop-invariant start and an
      unconditional classical step (SCEV `{start,+,step}`) has in trip j the value
      `start + j·step`, classical when the start is (a walked pointer's accesses are then
      `_hl`; the value is recomputed from the trip index in the forward and in the reverse
      loop, by arithmetic without `inbounds`/`nuw`/`nsw`, and never pushed) and otherwise one template from the invariant start rail and the literal
      `j·step`. Only its EXIT value is quantum: when the program reads it after the loop, a
      carried rail advancing by `select` on `a_j` is kept for that read alone (rule 6).
      **The overflow predicate is kept as an output rail**: `a_K` is the exit test evaluated
      after the K-th body (`a_{K−1} & cond_K`), so `a_K = 1` iff the loop would run another
      trip, and a loop that exits after exactly K trips reads 0. That test is made like every
      other: a load it reads is a bus load at trip K's address under `a_{K−1}`, un-copied at
      once, whatever object the address lies in (rule 21, §2). The cutoff is min(K, B), B an
      upper bound of the trip count from LLVM's range facts (`i < (x & 3)`: B = 3), taken
      only from the value ranges of the integers the exit test reads: an object's extent,
      `inbounds`, `dereferenceable` and the undefined behaviour of an access never bound a
      trip count (rule 21), so a scan over an array has no B (203). `a_K` is
      kept only when B > K or no bound is known. The kept rail is the chain's last predicate
      itself (09, 68, 150) or a `copy_i1` of it made after the loop, the last predicate then
      uncomputed by the reverse loop with the others; §6 does not tell the two apart. The K-th trip's own body predicate is not
      `a_K` and is uncomputed by the reverse loop like every earlier one; a predicate that
      controls a kept store, and every other trip rail rule 5 keeps, is not pushed but for its handle (first bullet). A test-at-bottom
      loop (`do … while`) runs trip 0 under the `|1⟩` seed and computes `a_{j+1}` after the
      body (150). A trip with two exit tests (a header test, the body, a latch test) chains a predicate
      per test, and `a_K` is the predicate of reaching the header after the K-th latch test; no
      header test of a (K+1)-th trip is made (189). Where -O1 tests at the loop header with no pre-header guard (09, 37, 54) the
      first header test is trip 0 of the chain, computed before the loop, and each of the K
      trips is body then test. Where the pre-header guard is not the latch test at trip 0 by
      SCEV (a pointer chase `while (n) { …; n = n->next; }`), the guard stays a classical
      branch (rule 8) or an arm flag that seeds the chain, the loop inside it is the
      test-at-bottom form, and a carried pointer with a classical start enters as the seed
      `alloc_i64(start)`. A loop seeded by an arm flag `F` tears `F` down by its compare's
      `_unc` after the chain, never as a seed (153). Nested K-loops keep one inner `a_K` per
      outer trip plus the outer one (68, 153). A carried value whose exit `phi` -O1 folded to
      a literal is copied out from the carried rail (149). — 05, 09, 37, 53, 54, 68, 149, 150,
      151, 152, 153, 169; 203 (an exit on a loaded value); 55, 87, 189.
    - *Classical bound with a quantum exit* (`for (i = 0; i < n; i++) if (q) break;`, a mixed exit
      `c_classical || q` whose classical test alone bounds the trip count; one whose classical
      conjunct gives no bound is the K-loop above): no cutoff applies. The loop is a classical loop over the classical bound,
      `q` feeds the predicate chain, and **every** predicate, the last included, is a function of
      the inputs and is uncomputed by the reverse loop (one that controls a kept store is kept,
      rule 5). The chain's `|1⟩` seed is minted after the classical zero-trip test, where a trip
      can run, never on the skip path (26). A bus load an exit test reads is under the predicate of
      reaching that test as in a K-loop (the predicate in scope for trip 0's), pushed with its trip's
      rails and un-copied by the reverse loop under the same rail (117). — 26, 139; 121, 130.
    - *Recursion with quantum depth* (a function re-entered under a quantum predicate,
      directly, through other functions or through a function-pointer rail): ONE clone per
      function, mask and kind. A `_ctl` clone that has a depth `d` (§1.4) counts it against
      the cutoff by a classical branch on entry: while `d` is below K the body runs; at the
      cutoff the clone returns at once, each of its results a `|0⟩` rail, and a
      `copy_i1` of its predicate into a fresh rail is the kept overflow predicate (an output
      rail, one per cut activation). Only `_ctl` activations count: the one that enters the
      recursion with no quantum predicate in scope does not, so up to K bodies run under a
      quantum predicate and the overflow predicate is the conjunction of K+1 arm predicates.
      The count is per function and the test is `d < K` for every function that has a counter,
      so a call chain that re-enters nothing is never cut (K > 0, §0); a recursion entered
      under a quantum predicate is cut at K whatever
      decides its depth (the user raises K). Every activation has its own rails by the host
      recursion and its own bus-resident locals by `__cq_alloc`. Clone and twin are rule 18's
      like any other; the twin makes the same cut, and its cut activation mints nothing and calls no gate; a table twin still
      frees the cut activation's `|0⟩` result rails (§1.4, 211). A forward clone that a twin calls to recompute is an activation like any other
      and keeps its overflow copy at the cut. — 205; 98.
    - `continue`, `return` inside a K-loop, nested K-loops: same chain, inner chain seeded by the
      outer trip predicate. — 149, 151, 153.
    - *No live exit*: a K-loop whose every exit edge leads only to a `noreturn` arm runs its K
      trips, each such edge rule 16's abort arm under that trip's exit flag; a loop with no
      exit edge at all runs K trips and then `abort_i1` on the `|1⟩` seed. Example owed (§8).
    - *Irreducible control flow* (a `goto` into a loop body, Duff's device) has no construction of
      its own: the compiler first makes every cycle a natural loop (LLVM's `fix-irreducible`) and
      applies the cases above to the result; the dispatch value is a carried value like any
      other. New example required (§8).

15. **Quantum angle.** An angle derived from a register is computed into an `f64` rail by ordinary
    templates and consumed by one primitive: `ry_<W>_qangle[_controlled]([c,] h, A)` for `cq_theta`,
    `rz_qangle[_controlled]([c,] A)` for `cq_phi`. The angle rail is uncomputed afterwards (a bus load copy by rule 5 sentence 1). The backend
    supplies the N-bit ladder. — 79, 143.

16. **Noreturn arms and host effects.** A callee with no body (after injection, and no declared
    clone of rule 27) is the host boundary. Its call is classified by the call site and by the
    callee's LLVM attributes. The only callees recognised by name and signature are ISO C and
    POSIX interfaces, and a body the bundle has for one of them is never lifted for the call:
    `malloc`, `calloc`, `aligned_alloc`, `realloc`, `free`; `memcpy`, `memmove` and `memset`,
    which are rule 22's construction; the *stream calls*: every
    `<stdio.h>` and `<wchar.h>` stream function, input and output alike, and the POSIX descriptor
    calls (`open`, `close`, `read`, `write`, `lseek`), except the string formatters `sprintf`,
    `snprintf`, `sscanf`, `swprintf`, `swscanf` and their `v` forms, which are injected and lifted
    (the bundle builds them over bundle-internal names for the formatting cores they call on their
    private `FILE`, `__cq_vfprintf`, `__cq_vfscanf`, `__cq_vfwprintf` and `__cq_vfwscanf`, and for
    every stream call those cores make on that `FILE`, lifted like any body, so no stream call by
    name remains in a lifted body; a function whose only `FILE` is one on its own stack, `strtod`,
    `strtol`, `wcstod`, `atof` and their families, keeps its body too, and the bundle has no body
    of any other public function that reads or writes a `FILE`, `exit` included); `signal`, `raise`; rule 23's
    fenv functions; rule 24's `setjmp`, `longjmp` and `pthread_*`. `stdin`, `stdout`, `stderr`
    and every `FILE` are the host C library's objects. What clang -O1 emits in place of a memory
    operation is that operation: `memset_pattern4/8/16` is a rule-22 fill whose source repeats, a
    fortified `__*_chk` call the plain function with the check dropped, and `__atomic_load`/`store`/
    `exchange`/`compare_exchange` rule-22 copies (a compare-exchange a byte compare and its two
    arms, rule 24).
    - *Ordinary host call*: every argument classical, no quantum predicate in scope, not a
      stream call with a pointer argument (the backend alone sees whether a buffer's cells are
      QUANTUM), and no tape or abort event can precede it: none from which the call is
      reachable in its function's CFG, no earlier call there of a function that contains one,
      itself or through its callees (an indirect callee and a declared clone count), and its
      function is not *called after an event*: one a call of which by name is so preceded in
      its caller, or whose caller is called after an event (the least fixpoint); a function
      whose address is taken or that is externally visible is, whenever the module contains
      an event; inside a table clone (`_t`, `_t_ctl`, their twins) every function is, always:
      its caller is not in view. The call is made as it stands and reads and writes host bytes, which the bus
      sees through the overlay (§1.3). At a QUANTUM cell the callee reads an unspecified byte
      and a byte it writes there is not seen by the bus (§1.3): a stated deviation and the
      user's responsibility; a library function avoids it by being injected (rule 18).
    - *Effect entry*: every other call that is in no class below, an unknown callee included
      (it is never dropped). It is ONE call sequence on the function's tape `t` (one
      `tape_alloc` at the entry of each function that records an entry; 47): the fields, then
      `tape_effect[_<W>]_controlled(c, t, name, n)`, n the number of fields. `c` is the predicate in scope or an
      `alloc_i1(true)` seed (rule 7: freed right after the effect call); the entry captures
      `c`, which is uncomputed afterwards like any flag. The `_<W>` form is used when the
      program reads the result, which is the rail it returns: KEPT, it has no `_unc` and is
      never freed. `name` is the callee's symbol name (its C identifier: a leading `\01` and
      the target's symbol prefix, `_` on Mach-O, removed) as `@.cq.effect.<name> = private
      unnamed_addr constant [<len+1> x i8] c"<name>\00", align 1`, one per host callee per
      module, after the module's own globals. The fields are the arguments in order: a
      classical one a `tape_write_<W>_lit`, a rail a `tape_write_<W>` field (`<W>` the width
      token of the argument's IR type at the call, §1.2), a pointer its address (`i64`), a
      vector its lanes. A buffer or
      string is never expanded into fields. When the backend performs the call, what a
      deferred result holds and how a buffer is read is BACKEND_ABI §1.11 alone; the lowered
      program asks nothing. `printf` is the format entry `tape_fmt[_controlled]([c,] t, fmt)`
      with its variadic arguments as fields by promoted IR type (47, 138).
      *Results.* No value the lowered program reads depends on whether the backend defers a
      call. For a C library function recognised by name above whose call is an effect entry
      and no input call, a result the program reads is never the entry's rail: it is the value
      musl's body returns when every host operation in it succeeds, computed by ordinary
      lowered code, and the effect goes to the tape with no result (nothing is emitted for an
      unread result, except for a format that may hold `%n`). `printf`, `fprintf`: the lifted
      `snprintf(0, 0, fmt, args…)` (rule 18); `vprintf`, `vfprintf`: the lifted
      `vsnprintf(0, 0, fmt, ap)`, with no copy of the `va_list` added; `wprintf`, `fwprintf`,
      `vwprintf`, `vfwprintf`: a bundle-internal count entry over the lifted wide core on a
      private `FILE` whose write discards and returns its length; `puts`, `fputs`: 0; `fputc`,
      `putc`, `putchar`: the argument as `unsigned char`; `fwrite`: `nmemb`, 0 where `size` is
      0; `write`: its length; `fputwc`, `putwc`, `putwchar`: the argument, or `WEOF` where the
      lifted `wctomb` fails; `fputws`: 0, or −1 where the lifted `wcsrtombs` reports an
      encoding error; `fflush`, `fclose`, `remove`, `rename`, `fsetpos`, `close`: 0; `fseek`,
      `fseeko`: 0, and −1 for a `whence` outside {0, 1, 2}; `setvbuf`: 0, and −1 for a type
      outside {0, 1, 2}; an `_unlocked` form as its locked one. A function not named here is
      decided the same way from musl's source. An `errno` store on the path to a computed
      failure value belongs to that value when it is a function of the arguments alone: it is
      made by ordinary lowered code under the same condition, through the module's accessor as
      for `signal` below (no accessor, no store): `EINVAL` (22) with the −1 of `fseek`,
      `fseeko` and `raise`; `setvbuf`'s −1 stores none. The `errno` a failed host operation
      would set is never produced. A failed host operation (a short or failed
      write, a missing file, an unseekable stream, the stream's error flag) is never produced:
      a stated deviation. Where musl's value is not a function of the arguments alone (`fopen`,
      `tmpfile`, `ftell`, `fileno`, `fwide`, `open`, `lseek`: host state), and for every callee
      that is no such library function, the result is the entry's rail, `|0⟩` when the backend
      defers the call (a stated deviation, §6; the compiler may warn). The result of an
      ordinary host call is the host's own, as is that of every call in a module left unchanged
      (§0). On a host whose C library is not musl the two classes differ where the libraries
      do (`printf("%p%n", NULL, &n)` gives 3 on macOS and 1 in musl; `puts` returns 10 and 0),
      and an entry's count is musl's while the bytes written are the host's: a stated
      deviation, absent on a musl host.
    - *Pure*: a callee LLVM marks `memory(none)` and `willreturn`. With classical arguments
      under a quantum predicate it is executed unguarded and its result merged like any
      classical arm value (rule 9).
    - `noreturn` (`abort`, `exit`, `_Exit`, `__builtin_trap`, `__assert_fail`, any
      `noreturn`-attributed function): under a quantum predicate, `abort_i1(pred)`; rails later
      modified in place are snapshotted under the predicate first. With a rail argument, or
      where a tape or abort event can precede it (the ordinary-host-call test above), and no
      quantum predicate it is the effect entry of its name under an `alloc_i1(true)` seed,
      then `abort_i1` of that seed, which ends the shot: the flag is classical-valued 1, so
      the call does not return (ABI §1.11) and the `unreachable` after it stays. Nothing of
      the continuation is built: on this run it is no part of the C program. Under a quantum
      predicate the `unreachable` after the `noreturn` call is a return of zero-valued results
      (`|0⟩` rails).
    - *Allocation* (`malloc`, `calloc`, `aligned_alloc`, `realloc`, any callee whose
      declaration carries `allockind`, a bus-resident `alloca` (rule 20), fixed or variable-length) is
      `__cq_alloc(size, align)` (§1.3; alignment 16 where the call names none): zeroed host
      memory at an address that is never reused, with the block's size as an `i64` in the 8
      bytes before it. It is classical host code, so under a quantum predicate it is executed
      unguarded and its address merged like any classical arm value (rule 9); in a loop every
      trip allocates. A size that is a rail `n` is allocated at **K2** bytes (§0), the header
      holds K2, and the overflow predicate `icmp_ugt_i64_hl(n, K2)` is kept as an output rail
      (omitted when range facts bound `n` by K2), computed immediately before the
      `__cq_alloc` call, so that it reads `n` at the value the call saw; a rail alignment is
      K2 rounded up to a power of two. `calloc(n, s)` is the size `n·s` as the EXACT product,
      never the wrapped one. With a rail operand the size is `umul.with.overflow`'s two
      templates (rule 4) and the kept predicate is `or_i1` of the overflow bit and
      `icmp_ugt_i64_hl(n·s, K2)`, both undone at once: it reads 1 wherever the exact product
      exceeds K2. With classical operands an overflowing product gives the null pointer and no
      `__cq_alloc` call (a classical test, as C's `calloc`). `realloc(p, n)` is,
      in this order: `q = __cq_alloc(n, 16)`; `s` = the `i64` bus load at `p − 8`
      (`qram_load_i64_hl(m, p − 8)` for a classical `p`; for an address rail at the rail
      `add_i64_hl(p, -8)`, uncomputed after the un-copy of `s`); the length rail
      `umin_i64[_hl](s, n)`; a rule-22 quantum-length copy from `p` to `q` with that length,
      its trip bound the new block's size (`n`, or K2) in place of min(K2, B), with no overflow predicate of its own (the
      length exceeds the bound only where the allocation's kept `n > K2` rail reads 1, §6); nothing for `p`. Allocating
      first lets `s` be un-copied before the copy's first store (rule 5). The size is always
      this bus load, a rail (rule 3), also for a classical `p` and `n`: never a host read. A block
      not made by `__cq_alloc` has no size header: `realloc` of it reads whatever word precedes it
      (a stated deviation).
    - *Deallocation*: `free` is nothing, under any predicate. `llvm.lifetime.*` and
      `llvm.stacksave`/`stackrestore` are dropped for bus-resident objects.
    - *Variadic calls.* The caller of a variadic clone (§1.4) stores every variadic argument
      into a `__cq_alloc` block in the SysV overflow-area layout (in order, 8-byte slots at
      the promoted type, 16-byte-aligned types in 16) and passes the block's address as the
      clone's last formal. In the clone `va_start(ap)` is the bus stores of `{gp_offset = 48,
      fp_offset = 176, overflow_arg_area = block, reg_save_area = 0}` into `ap`; `va_arg` and
      `va_end` are the -O1 code as it stands; `llvm.va_copy(d, s)` is `memcpy(d, s, 24)` (rule 22; 109). In the own symbol of a variadic
      function `va_start` stays the intrinsic: it fills `ap` with host bytes.
    - *Signal table.* The bundle has a host array `__cq_sig` of one `i64` per signal number.
      `signal(sig, h)` is the bus load of the cell `&__cq_sig[sig]` (its result; emitted
      also when unused, and then un-copied before the store) and a bus
      store of `h` there (controlled under a predicate in scope, at an address rail for a rail
      `sig`), after the host call when every argument is classical and no predicate is in
      scope: that host call is made as it stands whatever precedes it (the ordinary-host-call
      test is not asked for `signal`). With a rail argument or a predicate in scope there is
      no host call and no effect entry. A signal number is VALID when `1 ≤ sig ≤ 64` and `sig`
      is none of 9, 19, 32, 33, 34 (musl's `sigaction` and the kernel; the checker's reference
      uses this set, not its host's). For an invalid one `signal` returns `SIG_ERR` (−1 as an
      address) and neither loads nor stores: a classical test for a classical `sig` (the host
      call, where one is made, is still made and fails by itself); for a rail `sig` the flag
      `v` of that test by ordinary templates, the load and the store under `v` (ANDed with a
      predicate in scope), the result `select(v, loaded, −1)`, and a bus store of `EINVAL` (22) at
      `__errno_location()` under `¬v` (ANDed likewise), as a lifted musl body sets `errno`. The
      accessor is the one the module declares or defines for its own `errno` reads
      (`__errno_location`; `__error` in a Darwin-built module); a module with neither cannot
      read `errno`, and the store is omitted (host code that reads `errno` itself, `perror`,
      does not see `EINVAL`: a stated deviation). A call of the accessor returns an address
      and has no effect: it is made as it stands, unguarded, wherever a store needs the
      address; it is no effect entry and no event, and how often it is called is not compared
      (§6).
      `raise(sig)` loads that cell and calls through the
      loaded address rail by rule 19, as a call of function type `void (i32)` with `sig` as
      its one actual, except that the complement branch (no registered function: the default
      action or a host handler) is the effect entry `raise` with `sig` as its one field. A
      result of `raise` the program reads is the literal 0 under every candidate flag (rule 9)
      and under the complement musl's value, computed by ordinary lowered code: 0 for
      `0 ≤ sig ≤ 64`, −1 with `EINVAL` stored otherwise (*Results* above; the complement's entry has no result). No handler is tracked at compile time.
    - *Callback.* A library that calls back into the program (`qsort`, `bsearch`) must itself be
      lowered: injected (rule 18) or a lowered library (rule 27).

    — 45, 47, 138, 201, 208, 209, 210, 212, 213; 91, 99, 102, 108, 186.

17. **`cq_invert`.** The markers are the run-time primitives `invert_begin()` / `invert_end()`
    (§1.3): the code between them is lowered exactly as it would be anywhere else, except as this
    rule says, and the backend emits the gates recorded between the two calls reversed with each
    gate inverted. The code between them is what lies between the two calls in the IR the compiler
    receives; an instruction `-O1` moved across a marker is on the side where it lies (the compiler
    may warn). Allocations are not gates and stay where they are; a `free` inside the region is
    performed after the reversed list. The compiler places no uncompute of a rail allocated before
    the region inside it; an in-place gate on a register (below) is no uncompute. A measurement
    inside the region has no adjoint: it flushes the gates recorded before it forward, and only the
    gates recorded after the last measurement are reversed at the `end` (the compiler may warn). A
    bus store and an effect entry the backend performs at its call are flush points in the same way:
    performed in place and kept (rule 5), with only the gates after the last flush point reversed. A
    rail made in the region before a flush point and read after it is uncomputed before the flush
    point and made again after it from the rails live there, as across the `end` (below): its
    compute and its uncompute never straddle a flush point. A tape write is an XOR gate and an abort
    flag bookkeeping, inverted and kept like any other. Nested pairs nest; a `begin` and an `end`
    are events, so a path that returns inside a region, or a region a classical branch opens, needs
    no analysis. The asm fences in `CQ.h`'s macros are consumed.
    **Registers (owner 2026-11-26).** A *register* of the region is a rail live at its `begin` that
    holds a quantum value the region reads, whatever its role, and inside the region each in-place
    image of it; the SSA values bound to it are its chain. Inside the region an update `y' = f(y,
    o)` of a chain value `y` is ONE core gate on the register's rail when `f` is the plain `add`,
    `xor`, or `sub` with `y` as operand 0, or rule 6's select of such an update, `o` is a literal or
    a rail not computed from `y`'s chain, and `y`'s rail is one the function owns and no seed: rule
    6's in-place gate, `sub y, o` as `sub_<W>(o, y)` (a literal `addc_<W>(y, −lit)`). Rule 6's
    clean-up point is not asked: the gate is emitted whatever reads the old value later, and the
    image is the register from there on, never uncomputed inside the region. The backend replays the
    gate inverted (add by sub, sub by add, `addc` by `addc` of the negated literal, `copy` and
    `xorc` by themselves, BACKEND_ABI §1.13). Of several such updates of one old value, the last on
    each path is the gate; the others are values made in the region that read the rail before it. A
    reader of the old value after the gate (an SSA use, or an `_unc` that re-reads it) reads a copy,
    `copy_<W>(y, c)` on a fresh rail right before the gate; the copy is a rail made in the region
    and is cleaned inside it by rule 6 from the register's image after its last reader there (the
    composite against a later image). Where rule 6 finds no clean-up point for it, the copy is kept:
    it crosses the `end` and its gates are replayed as recorded, so its replayed readers read `|0⟩`
    until its own replay (the compiler may warn). Under a quantum predicate (a marker in an arm, or
    a quantum branch inside the region whose arm updates a register) the update is the select of an
    update with the predicate's flag, `y += f ? o : 0`, and the merge of `y'` with `y` at the join
    is the register's rail on both edges. In a rolled loop inside the region, a carried value whose
    entry incoming is a register, whose trip update is such an update and whose trip predicate and
    operand do not read it, is updated in place on the register's rail every trip (under a quantum
    trip predicate `a_j` as `y += a_j ? o : 0`): no carried rail, no per-trip clean-up, nothing
    pushed for it, and the repeat after the `end` (below) does not recompute it. A clone does not
    own its argument's rail, so a call never updates a register in place; a register passed by
    address is a bus cell, below. Classical code runs forward, no gate. An update that is none of
    these (`sub o, y`, `mul` by an odd literal, a select or loop update whose condition reads `y`)
    is a value made in the region, below. After the `end` every value of a register's chain (its
    value at the `begin` and each image) is the register's rail with whatever the replay left;
    nothing is recomputed for it. A register whose value at the `begin` was rule-5 garbage is not
    uncomputed after the region (its rail no longer holds that value): it is kept unless a rule that
    applies to its image after the `end` frees it. `rem -= x ? w : 0` repeated in a region after the
    same statements before it returns `rem` to its value before them, and the replayed rotations
    read the predicates of the forward statements: the region is the adjoint of its code as a
    circuit on the registers live at its `begin`. — 214.
    **Memory.** An in-place form inverts exactly (swap, gate, swap reversed is the form of the
    inverse gate), and a load un-copied inside the region reverses into itself. This holds whatever
    the cell holds (rule 3 asks nothing about it): after a region that holds `g++` on a bus cell and
    no later flush point, the cell reads `g − 1`. An overwriting store is a kept store, a flush
    point, and stays forward; an update of a host-resident object (rule 20) is classical code, no
    gate, and runs forward. A cell beside a register: 214.
    **A value made in the region and read after its `end`.** A rail made inside the region crosses
    the `end` only where a rule keeps it (a measured rail, a rotated register, a kept store's rail,
    a kept `a_K`, a kept copy of an old value). Every other one is uncomputed inside the region
    after its last reader there, and a reader after the `end` gets the value recomputed after the
    `end` from its pure cone, each value the cone reads bound as it is after the `end` (a register's
    chain value is the register, a register the region rotated is its rail as the replay left it),
    uncomputed after its last reader as anywhere else. No copy of it is kept across the `end` (§6
    item 1: a leak). What is recomputed is the value's pure cone, a loop in it included: the loop
    runs again after the `end` (forward, its values read in place, then its reverse loop), so its
    gates appear inside the region, replayed reversed, and once more after it. The repeat keeps no
    `a_K`: the in-region loop's is the kept rail. A register the region computes and then rotates is
    a kept rail whose gates are reversed as recorded: the rotation comes first, on the rail as
    allocated, and the template that computes the value (`o ^= f`, ABI §2) after it. `s = f(x);
    cq_theta(&s, θ)` in a region leaves `Ry(−θ)|0⟩` with `f(x)` XORed in on the rail of `s`, not
    `Ry(−θ)|f(x)⟩`: the adjoint of compute-then-rotate. The reference of §6 computes the same (the
    compiler may warn). A rotation, a measurement, a bus store and an effect entry are never
    repeated: a loop whose body holds one repeats only the instructions its read values and exit
    tests depend on, where those read nothing such an instruction produces (the other case and an
    example are owed, §8). A bus load is repeated like any pure instruction when no memory version
    change (rule 5) lies between the `begin` and the repeat: the cell then holds what the in-region
    load read. Where one does, the load reads what a store produced.
    **The reference of §6.** For one execution of the region (its part after the last flush point)
    let `F` be the map the C region computes on its registers and cells (a rotation the identity on
    basis states, each in-place form `y ← y op o`), and `s` their values where that part begins. The
    registers and cells after the `end` hold `F⁻¹(s)`, and the region's rotation list is the
    rotation list of the C region run from `F⁻¹(s)`, in reverse order with each angle negated: the
    state at the replay of a gate is the state the forward run from `F⁻¹(s)` has at that gate. A
    value read after the `end` is computed as above from `F⁻¹(s)`.
    **A marker under a quantum predicate.** `__cq_invert_begin/end` are `noduplicate`, so the only
    marker in an arm is one the C program wrote there. It is a host call, executed on every path at
    its position in the arm's lowered code, whose gates carry the arm flag.
    - *Match in the same arm:* nothing more is needed (the inverse of a controlled gate is the
      controlled inverse; the flag's compute and uncompute lie outside the region).
    - *Match outside the arm* (after the join, or before the branch): the code between the join and
      the match (the tail T) is lowered twice, under the arm flag `f` inside the bracket and under
      `not f` outside it, and the other arm's gates are placed outside the bracket. For a `begin` in
      arm A with its `end` after the join the order is `A1|f, B|not f, begin, A2|f, T|f, end, T|not
      f` (A1/A2 the arm before/after the marker, B the other arm); for an `end` in an arm whose
      `begin` is before the branch, `begin, prefix, B|not f, T|not f, A1|f, end, A2|f, T|f`. A
      register's update in T is `y += f ? o : 0` inside the bracket and `y += (not f) ? o : 0`
      outside it.
    - *A marker in EVERY arm matching one marker outside* is one event, emitted once at the join (an
      `end`) or at the branch (a `begin`), with every arm's controlled gates inside the region.
    - *Markers that do not pair on a path* are the C program's own error and are lowered as they
      stand.

    Examples owed (§8): a kept store and an in-place form inside a region; a rolled loop updating a
    register inside a region. — 44, 214; 61, 126.

18. **Function lifting.** Every function with a body is lowered (rule 19), once per taint mask of
    its scalar formals that a call uses (§1.4); the all-zero mask is the function itself. A
    pointer formal is one scalar, a classical address or an address rail: the clone reaches
    memory through the bus, and nothing about the pointee crosses the call.
    **Clone.** One form for every clone: it computes, **copies each result into a fresh
    rail**, uncomputes its SSA body by rule 5 and returns the copies (a one-template body may
    return its rail directly; a clone with no twin whose result is the KEPT result of a callee
    with no twin returns that rail directly, since a copy would leave it live beside the copy). What rule 5 keeps inside it (store rails, tape slots, kept load
    copies) simply stays.
    **Twin.** `_unc` recomputes the results (templates, bus loads, its callees' clones and
    twins), XORs each out with `copy_<W>` and uncomputes; the caller frees the result rails
    after it. It repeats no phase and no tape or abort event (it recomputes through `_pure`,
    §1.4) and makes no memory version change: a function that writes memory (rule 5), has a
    measurement whose outcome is tainted (under a quantum predicate, or rule 19's controlled
    copy) or reads the result rail of an effect entry has no twin (a classical-path measurement keeps it, rule 2; a table clone's measurement of a formal,
    itself or through a by-name callee given the copy, leaves it none and its results stay
    allocated, §1.4; any other table clone's twin is §1.4's), and its rail results are KEPT by the caller. The twin reads memory again, so the call of a clone that loads
    from the bus, itself or through a callee, is a load for rule 5: its twin runs after the
    results' last consumer and before the next memory version change after the call on every
    path, and where that change comes first the results are KEPT and no twin is called. When
    some results of one call are measured (or escape) and others are dead, the caller first
    copies each measured one into a fresh rail (`copy_<W>`), runs the twin on the clone's own
    result rails, frees them, and measures the copies: the twin always zeroes every result it
    returned, and no measured rail is ever gated (example owed, §8). A clone with no results has
    its twin right after the call; a twin (`_t_unc` included) never undoes a kept store and is no memory version change (190).
    **Library code** is injected source (musl, linked before lowering) and lifted like any
    callee. An LLVM math intrinsic on a quantum operand (`llvm.exp.f64`, `llvm.sin.f64`, …) is
    the call of the libm function of the same name (`llvm.<f>.f32` is `<f>f`, `llvm.<f>.f80`
    is `<f>l`), lifted from its body whenever the module has one after injection; a bodiless one is its
    declared clone on a root list (rule 27; 175, 184) and the host boundary otherwise (rule 16). On `half`/`bfloat` it binds to the
    `float` body around `fpext`/`fptrunc`, on a vector operand per lane (rule 25), and a
    constrained intrinsic is `llvm.<f>` under its exception behaviour (rule 23: ignore and
    maytrap bind to the plain body, strict to 82's ABI). The rule-23 flags rail is an argument
    like any other. A function the program defines shadows the injected body of the same name
    (169, 173). Every other body lifted is the pinned library source as the bundle builds it
    (clang 19.1.7 `-O1`, the pinned flags), pragmas included: musl's `ilogb` is a strictfp
    clone, lowered by rule 23. A reference that depicts another body pins nothing (169).
    Result taint is recorded per clone (an `i32` return is a handle or a classical int by that
    record, not by its type); a result computed from a bus load is a rail (rule 3), also in the
    all-zero mask. Recursion with classical depth is ordinary calls; with quantum depth it is
    rule 14. — 06, 07, 33, 34, 64, 82, 119, 136, 195, 200, 204; 36, 51, 95, 109.

19. **Indirect and opaque callees.**
    **Every body is lowered** (§0). The own symbol (§1.4) is what an all-classical call and
    host code reach, and a clone that would coincide with it is it (162). A body with no bus
    access, no `cq_*` call and no call (opcode-like, lifetime and debug intrinsics are not calls)
    is its own lowering. **The compiler never inlines**: a
    callee reached with a quantum argument is a rule-18 clone, whatever it returns and however
    it returns it (musl's `__rem_pio2(x, &y)` inside `sin`; 31, 163).
    **Results.** A function's own symbol that returns an unmeasured quantum value returns the
    handle (escaped, never freed): its parameter list keeps the C ABI, and its return type is
    the C return type when that is an integer of 32 bits or more (the handle zero-extended,
    162, 193) and `i32` otherwise (`_Bool`, `char`, `short`, every floating or pointer type;
    193). An aggregate return is the struct of §1.1 (rule 26). The results of a callee are
    recorded per callee: a result that is a register the callee minted, or that register's
    rule-6 image, is FROZEN, and the caller keeps it like its own registers (162). Every other
    result is zeroed by the twin, and so that the twin can, the clone returns the handle of
    each register it minted that is still allocated at its return as an extra `i32` result
    after the results, and the twin takes them there too, after the results and before the
    arguments (§1.4's `_unc(outs…, args…)`). The extra results are the union
    over the callee's return paths in mint-site order; on a classical path that did not mint
    one the callee returns handle 0 (§1.1), which the twin, replaying the same path, never
    reads. In a cycle of callees the records are the least fixpoint over the cycle.
    **Entry.** Host code that calls a function of the program (`main`, a callback, a signal
    handler) reaches its own symbol and reads a rail result as the handle, not the value.
    `main` is the exception: a `main` that returns a rail `r` makes the effect entry `exit`
    with `r` as its field under an `alloc_i1(true)` seed (rule 16) and then returns 0.
    **Function pointers.** A function pointer is the function's address (rule 21), a classical
    `ptr` or an address rail. Which functions it can denote is never analysed. Every module
    and lowered library registers the all-ones table clone (§1.4) of each of its address-taken and
    externally visible functions (`__cq_clone_register`, §1.3), and an indirect call is
    resolved from that table at run time. It is always a call of a table clone, with that
    ABI: the classical actuals are minted as seeds (rule 7), every result is a handle, and K
    is the K of the caller's enclosing function (§0). The caller has no record of the callee:
    the call is a memory version change (rule 5), and its twin is called exactly once, so
    that the handles the clone pushed are popped (§1.4): at its rule-18 position, or, where rule 18 would keep a result, right before
    that memory version change, after the result is copied into a fresh rail that is KEPT in
    its place.
    - *Classical pointer* `fp`: the callee is `__cq_clone_resolve(fp, kind)`. When that is null,
      `fp` is host code and the call is rule 16's host boundary with `fp` as the callee: the
      instruction as it stands, or an effect entry with a null `name` and the address as its
      first field (§1.3).
    - *Address rail* `r`: every registered function of the call's function type is a
      candidate. For `i < __cq_clone_count(sig)`, `a_i = __cq_clone_at(sig, i)`, the flag is
      `f_i = icmp_eq_i64_hl(r, a_i)` (rule 13's compare) and the `_ctl` clone of `a_i` (kind
      1) is called under `f_i` conjoined with the predicate in scope; the loop over the
      candidates is classical code. Under the complement of the flags `r` is host code: rule
      16's effect entry with a null `name` and `r` as its first field. The results merge by
      `select` under the flags (rule 9), each candidate's twin is its `_ctl_unc` (kind 3)
      under the same flag, and the flags are uncomputed after their last use. A candidate
      that calls through the same type again is recursion with quantum depth (rule 14).
      The loop carries two rails: the complement p (p_0 = the predicate in scope, or an
      `alloc_i1(true)` seed) and the merge out (out_0 = `alloc_<W>(0)`). Trip i: `f_i`; where
      a predicate P is in scope the candidate's control `and_i1(P, f_i, fresh)`, uncomputed
      after the twin; the `_ctl` call; the result copied into a fresh rail c_i that is KEPT
      (every candidate call is a memory version change); the twin; `p_{i+1} = p_i & NOT f_i`
      (`not_i1(f_i); and_i1(p_i, f_i, fresh); not_i1(f_i)`); `out_{i+1} = select_<W>(f_i,
      c_i, out_i)`; push p_i, out_i, c_i, f_i. After the loop the effect entry is made under
      p_n and the call's value is `select_<W>(p_n, r_e, out_n)`, copied out where it is
      measured or kept. The reverse loop pops each trip and uncomputes its select, its
      p_{i+1} and its flag (a_i again from `__cq_clone_at`); the seeds p_0 and out_0 are freed.
      The dispatch runs functions the program never called, so inside every `_ctl` clone
      (table or by name; a `_ctl` clone may be reached from the dispatch)
      `cq_measure(h)` measures a controlled copy, `t = alloc_<W>(0); copy_<W>_controlled(pred,
      h, t); measure_<W>(t)`: `t` is the measured rail, `h` is not collapsed where pred = 0,
      the outcome is tainted, and rule 2's classical collapse does not apply to `h` there. A `_t`
      clone measures a formal the same way without the predicate (`copy_<W>(h, t); measure_<W>(t)`,
      §1.4): the caller's rail is never the measured one, so rules 18 and 19 hold for it.

    **Under a quantum predicate** a callee becomes a `_ctl` clone iff its body, itself or through
    its callees, has anything but templates on SSA values: a rotation, a phase, a bus access,
    a tape or abort event, an indirect or bodiless call, a call cycle through itself, a
    quantum-exit loop whose `a_K` is kept (rule 14: the predicate seeds its chain, so `a_K` reads 0
    where the C program does not make the call; 169's `__cq_q_ilogb_1_ctl`). Otherwise it is called unguarded and
    its results merged like any classical arm value (rule 9), a call with no quantum argument
    included (musl's `__math_oflow(0)` in `exp`; a `volatile` access to a dead local inside it
    is nothing, rule 24; example owed, §8). A callee with no body follows rules 16 and 27.
    — 162, 193; 197, 200, 211, 212; 96, 97, 102, 117, 124.

20. **Memory.** All memory of the program is the one bus `M` (§1.3). Nothing is known about an
    address: not the object it lies in, its extent, or what its cells hold. Globals, `static` and
    thread-local objects, string literals, heap blocks and whatever the host mapped live at their
    host addresses, on the bus through the overlay: nothing is allocated or seeded for them, and
    no construction uses knowledge of an object. One classical fact is handed on, for the
    backend's resource bound only (BACKEND_ABI §1.10, Objects): a lowered module registers the
    extent of every global variable it defines or declares, `__cq_object(addr, size)` in a module
    constructor, and `__cq_alloc` registers every block it returns. No rule reads the registry
    and it changes no lowering. *Address literals:* a classical `i64` that enters an address
    computation as the value of a pointer P (the literal of an `_hl` add or sub, a `select`
    literal, a seed) is passed only where LLVM guarantees that P lies in its object or one past
    its end: P is a global, an argument, a load or call result or an `alloca`, or is reached from
    one by `inbounds` `getelementptr` only. Where P's chain has a `getelementptr` without
    `inbounds`, the literal is the pointer before it and the offset is added on the index side.
    An `inbounds` `getelementptr` is in bounds only index by index: the offsets after its first
    quantum index are added on the index side, never into the literal. Where a classical P whose
    chain has a `getelementptr` without `inbounds` is taken in by a `phi` or `select` (a select
    literal, a seed), its value is passed as it is and no object is known for the merged pointer.
    Where P is reached inside the function from an `inttoptr`, no object is known for it either: the
    address rail of an access through P is announced as such, `__cq_unbound(r)` once after the
    rail is formed and before the first access at it (BACKEND_ABI §1.10, No object). Every bus load
    of pointer type is followed by `__cq_pointer(h)` on its result, at an address rail and at a
    classical address alike (BACKEND_ABI §1.10, A pointer load). A value rail written by a
    bus store or swap at an address rail is announced as data, `__cq_data(v)` before the access,
    when the stored value is computed: its type is not a pointer and it is not a loaded value
    passed on unchanged (a `load` result, directly or through `phi`, `select` or `freeze`; a
    `ptrtoint` result is a pointer). The in-place form (rule 5) announces the rail it swaps
    back. Rule 22 copies announce nothing (BACKEND_ABI §1.10, Data). A classical address needs
    nothing.

    | access of type T | classical address `p` | address rail `r` |
    |---|---|---|
    | load | `h = qram_load_<W>_hl(m, p)` | `h = qram_load_<W>(m, r)` |
    | store of `v` | `qram_store_<W>_hl(m, p, v)` | `qram_store_<W>(m, r, v)` |
    | in-place form (rule 5) | `qram_swap_<W>_hl(m, p, h)` | `qram_swap_<W>(m, r, h)` |

    - **Every load is a bus load and its result is a rail; every store is a bus store** (the
      exceptions: a host-resident object, below, except as the source of a rule-22 copy into
      bus memory). `p` is the pointer's run-time `i64`,
      spelled `ptrtoint` of the pointer: the instruction for an instruction-valued pointer
      (for a pointer argument at any point that dominates its uses, the position not compared; 206 places it once at function entry, after `__cq_mem()`), the
      constant expression `ptrtoint (ptr @G to i64)` for a global, also inside an `_hl`
      literal of address arithmetic. `v` is a handle, a classical value first the seed
      `alloc_<W>(v)` (rule 7). The `_controlled` forms, what is un-copied and what is kept are
      rule 5. `m` is the value of `__cq_mem()`.
    - **Store size.** One call per access of S = store-size(T) cells (§1.3). A vector access is
      one access per lane, lane i at `address + i·S(lane)`; an aggregate access one per scalar
      field at its DataLayout offset. Alignment is not an operand. Union views, byte views,
      packed fields and bit-fields need no rule: each is an access of the type and at the
      address its instruction names.
    - **Host-resident objects.** An access whose pointer operand is, through `getelementptr`s
      with untainted indices only, a host-resident object stays the plain LLVM instruction and
      its load is classical, when no quantum predicate is in scope at the access (code C
      would not run reads no host byte). An object is host-resident iff it is
      (a) a global with `isConstant()`, whose access under a quantum predicate is the
      `_hl_controlled` bus access (HOST cells, §2); or
      (b) an `alloca` with an untainted size whose every transitive user, through such
      `getelementptr`s, is: a load with no quantum predicate in scope; a store THROUGH it of an untainted value with no quantum predicate in scope; a lifetime or
      debug intrinsic; an `icmp`; or a memory intrinsic with an untainted length and no quantum
      predicate in scope that writes it (`memset` of an untainted byte, a copy from a
      host-resident source) or reads it into a host-resident destination.
      Any other user makes the `alloca` bus-resident. The test is local to one lowered function
      body (asked per clone) and is one monotone fixpoint with taint (rule 3): every `alloca`
      starts host-resident, a failing user demotes it, its loads become rails, and the test
      repeats. Rules 23 and 24 each add one case. The bytes of a host-resident object are on
      the bus all the same: an access that reaches them any other way reads HOST cells.
    - **Address arithmetic.** A `getelementptr` with a tainted base or index is 64-bit template
      arithmetic into an address rail: each tainted index brought to `i64` (`sext_<W>_to_i64`
      where -O1 wrote no cast), scaled by `mul_i64_hl(·, size)` (or `shl_i64_hl`; §6 compares
      semantics; no scale at size 1) and added by `add_i64[_hl]`, per `getelementptr`
      instruction: two that share an index rail each emit their own scale and add. The untainted part (a classical base's run-time
      address, offsets, untainted indices) is one classical `i64`, the `_hl` literal. With
      nothing tainted the `getelementptr` stays. The address rail is rule-5 garbage: a load's
      address rail always outlives the load's `_unc`; for an access with no `_unc` (a load copy
      rule 5 excepts, a store, the second swap of an in-place form) the access is its last
      reader and the rail is uncomputed right after it. No index is narrowed, bounded or
      checked.
    - **Allocation.** A bus-resident `alloca` is `__cq_alloc(size, align)` at its program point
      (rule 16) and no `alloca` remains for it: one zeroed block per activation. A
      host-resident `alloca` stays, with its lifetime markers. Those of a bus-resident object
      are dropped (rule 16), so a block-scoped bus-resident object is one block whose cells
      carry over from trip to trip, and the end of its lifetime undoes nothing.

    — 195, 196, 197, 199, 203, 204; 29, 30, 50, 58, 67, 71, 74, 75, 76, 77, 78, 160, 168.

21. **Pointers.** A pointer is an integer, its x86-64 address: a classical `ptr`/`i64`, or ONE
    handle to a 64-bit rail iff it is computed from a rail (rule 3: loaded from the bus, merged
    under a quantum flag, or derived from either). Nothing else belongs to a pointer: no object,
    base, extent or origin. `inbounds`, `nonnull`, `dereferenceable`, `align`, `noalias` and
    TBAA are never consulted.
    - *Dereference.* One bus access at the address (rule 20), with no guard and no bounds
      check; an address that is not memory is totalized by §2.
    - *Arithmetic.* `getelementptr` is rule 20's. `ptrtoint` and `inttoptr` are identities at 64
      bits (to or from another width the `trunc`/`zext` template), so pointer difference,
      tagging, `llvm.ptrmask` and alignment tests are rule 4's integer templates.
    - *Compare.* The integer compare of the addresses, `icmp_<pred>_i64[_hl]`; `null` is the
      literal 0.
    - *Merge.* A pointer `select` or `phi` under a quantum flag is `select_i64[_hl|_lh|_ll]`
      (rule 9), a classical pointer entering as its `i64` literal; under a classical condition
      it is the classical `select`/`phi`, over handles when an incoming is a rail (a classical
      incoming is then a seed, rule 7).
    - *Nested pointers.* A pointer in memory is an `i64` cell value: stored as its address,
      loaded as the `qram_load_i64` rail, which is the address of the next access, to any depth.
    - *Calls.* A pointer argument or result is one scalar: one mask digit, one `ptr` or one
      handle (§1.4). Function pointers and block addresses are addresses too (rules 19, 13); a
      pointer handed to host code is its address.

    Pointer values are compared only relationally (§6).
    — 198, 200, 208; 84, 85, 86, 88, 89, 105, 107, 129, 167, 189.

22. **Memory intrinsics.** `llvm.memcpy`, `llvm.memmove` and `llvm.memset` (`.inline` forms
    included), and a call by name of `memcpy`, `memmove` or `memset` (rule 16; the call's result
    is its destination pointer, and no body of that name is lifted for it, the program's own
    included: reserved identifiers, C17 §7.1.3), are byte accesses on
    the bus, `qram_load_i8` and `qram_store_i8`: `_hl` at a
    classical address, at the fresh rail `add_i64_hl(r, j)` for byte j of an address rail `r`
    (j = 0 included), uncomputed and freed right after its access in the same trip. A copy
    LOADS ALL its source bytes and then STORES ALL of them: it has no direction and is exact
    for any overlap. Its load loop pushes each trip's byte rail on `cqrt_push` (for a quantum
    length the trip's predicate first, then the byte rail) and its store loop pops them, so
    it stores bytes n−1 down to 0. This hand-over and the `c_i` of rule 19's dispatch loop are, like rule 14's,
    pushes of a kept rail's handle only; a copy has no reverse loop, and the byte order inside either
    loop is not compared (§6). `memset` is ONE loop of byte stores of one `i8` value rail
    (the seed `alloc_i8(v)` for a classical byte). An intrinsic is never widened into word
    accesses and is always emitted: whether the destination is fresh `__cq_alloc` memory or
    already holds the value is never asked (§0).
    - *Classical length* n (a constant or a run-time value): host loops of n trips. A
      constant n is never unrolled: every length is the one rolled construction.
    - *Quantum length* (a rail n): the same loops as rule-14 K-loops. Trip j runs under ONE
      predicate per byte, `p_j = icmp_ugt_i64_hl(n, j)`, computed in the load loop and kept
      as that byte's store control (rule 5); the chain is the `p_j` themselves. The cutoff is
      min(K2, B), K2 that of the enclosing function (§0) and B the bound of n from range
      facts; `n > K2` is the kept overflow predicate when B > K2 or no bound is known. A
      predicate `c` in scope is conjoined with `p_j`. The length rail (and what produced it)
      has its last consumer in the load loop and is uncomputed between the two loops (for a `memset`, whose one loop computes `p_j`, right after that loop).
    - Each byte store is a kept store (rule 5): its tape slot stays, and so does its value
      rail, the load copy of that byte (never un-copied, never freed; a `memset`'s one seed
      rail likewise).
    - *Host-resident destination* (rule 20): the intrinsic stays the instruction.
    - *Any other destination*: nothing is asked about the source. Every source byte is
      `qram_load_i8[_hl]`, whatever the source pointer is (a constant global is read as HOST cells, the
      copies classical-valued; an `alloca` that is such a source is bus-resident by rule 20 (b)).

    A struct assignment, a `byval` copy (rule 26) and `realloc`'s copy are this copy; padding
    bytes are bytes. Every other string and memory function (`memcmp`, `memchr`, `strlen`,
    `strcmp`, `mempcpy`, `bcopy`, `bzero`, …) is a library call, lifted by rule 18.
    — 196, 200 (a `memset`), 201, 208 (a rail length); 202, 72, 73, 90, 190.

23. **Floating-point environment.** The C17 §7.6 functions (`fegetround`, `fesetround`,
    `feclearexcept`, `feraiseexcept`, `fetestexcept`, `fegetexceptflag`, `fesetexceptflag`,
    `fegetenv`, `fesetenv`, `feholdexcept`, `feupdateenv`) are recognised by name and signature
    (rule 16; reserved identifiers, C17 §7.1.3). Under `FENV_ACCESS` the mode and flags split
    into a host part (real calls) and a quantum part (rail); constrained ops take `_rm`/`_rmq`
    and emit a second `_exc` template; fenv calls on quantum state are rail operations; a clone
    that does constrained FP work takes the caller's mode and flags rail and returns the new
    flags rail beside its result (82); the final flags rail is an output, and so is the final
    mode where it is a rail at the entry's return (the environment the C program leaves: it is
    kept, never uncomputed, and reads what `fegetround()` returns there), unless rule 2
    collapsed it into a host write-back (65).
    Three exception behaviours. `fpexcept.strict` (`FENV_ACCESS ON`) is the model above.
    `fpexcept.ignore` and `fpexcept.maytrap` (clang's `-frounding-math` without the pragma: every
    TU of musl's libm) raise nothing observable: no `_exc`, no flags rail. Their `round.dynamic`
    mode is the mode at the root of the call chain, the default (C17 §7.6.1) unless an ancestor
    holds the fenv state. So in a chain whose root has no fenv access every such op is the plain
    template and the clone has no mode and no flags parameter (169's `__cq_q_scalbn_10(x, n)`,
    175's `__cq_q_exp_1(x)`). A body that contains a strict op or a fenv call, itself or through
    a callee, takes 82's ABI; a caller without the fenv state passes the mode literal 0 and an
    empty flags rail, and the returned flags rail is never read: twin, free, never kept (169's
    `__divdc3` calling `__cq_q_logb_1(x, 0, flags)`). A body of `round.dynamic` ops reached from
    a caller that holds the fenv state with a mode other than the literal 0 (a non-default
    literal, a run-time classical mode, a rail: a `fesetround` under a quantum predicate makes
    the mode `select(pred, new, old)`) takes that mode as its one trailing parameter and its
    ops become `_rm`/`_rmq`; it is a distinct clone, `__cq_q_<fn>_<mask>_rm` for a classical
    mode and `_rmq` for a mode rail (§1.4), also when every data argument is classical: the
    call is then never the in-place own symbol, and an `_rmq` clone's result is a rail.
    Example owed (§8).
    Once the environment has a quantum part, every callee whose body (itself or through a callee)
    reads or writes the environment is reached with the flags rail and the mode as arguments,
    whatever its data arguments: those two digits of its mask are 1. `feenableexcept` and
    `fedisableexcept` are not C17 and have no musl body: rule 27.
    **Environment objects.** A `fenv_t` or `fexcept_t` object is memory like any other (rule 20),
    and a host fenv call reads and writes its host bytes. At a QUANTUM cell of the object rule
    16's deviation holds as for any host call (the call reads an unspecified byte, and a byte it
    writes there is not seen by the bus; these functions are never injected), and such an input
    is not compared (§6). One confined shape keeps the quantum
    part out of memory: an `alloca` whose every user is a recognised fenv call taking the `alloca`
    itself (lifetime and debug intrinsics aside) is host-resident, and its quantum part (the
    flags rail, the mode when it is a rail) is carried per object as SSA values, saved by the
    saving call and reinstated by the restoring one (82). Every other such object holds the
    whole environment in its own bytes:
    - a restoring call whose argument is a constant, a `constant` global or a constant pointer
      expression (musl's `FE_DFL_ENV`) is the host call as it stands and empties the quantum
      part: an empty flags rail and the mode literal 0 (100);
    - after a saving call (`fegetenv`, `feholdexcept`, `fegetexceptflag`) the quantum part is
      merged into the object's exception-flag and rounding-mode fields: a bus load, the `or` or
      `select` template, a bus store;
    - a restoring call (`fesetenv`, `feupdateenv`, `fesetexceptflag`) loads those two fields
      from the bus as the new flags rail and mode, then makes the host call on a `__cq_alloc`
      copy of the object (rule 22) in which both fields are stored as 0.

    The field offsets are the target libc's, fixed with the example (§8, owed).
    — 65, 80, 81, 82, 100.

24. **Threads, atomics, volatile, setjmp.** Single-thread collapse: an atomic access is the
    ordinary access (`load atomic`/`store atomic` are rule 20's, `cmpxchg` and `atomicrmw` rule
    4's), fences are nothing, `pthread_create(t, attr, f, p)` is the call `f(p)` (rule 19
    when `f` is a pointer) and `pthread_join(t, r)` is nothing, except that when some `pthread_join` of the
    module has a second operand other than the null constant, every `pthread_create` stores `f`'s result in
    `*t` (converted to the `pthread_t` type) and every such join stores its `pthread_t` operand through `r`
    (the sequential schedule's result, as a `void *`); each of these calls returns 0 and the mutex calls
    (`pthread_mutex_lock`, `_trylock`, `_timedlock`, `_unlock` and musl's internal names
    `__pthread_mutex_*` of the same functions, which a lifted `mtx_*` body calls) are
    no-ops that return 0 (no operand of these calls is a user for rule 20 (b); the two stores just named are
    ordinary stores of rule 20, and a constant start routine is not
    address-taken by that use), and a thread-local object is the one thread's
    object at its address (`llvm.threadlocal.address` is that address).
    `volatile` is read off the access and its pointer operand:
    - *Unobservable.* The pointer operand is, through `getelementptr`s with untainted indices,
      an `alloca` or an internal global whose every use (for the global, in the module) is,
      through such `getelementptr`s, a load or a store through it, lifetime and debug intrinsics aside. The qualifier is dropped
      and the access is rule 20's. Such a global that no instruction stores to is
      host-resident like a constant (48).
    - *Observable.* Every other `volatile` access is rule 20's bus access like any load or
      store (the `_hl` form at a classical address, the `_controlled` store under a quantum
      predicate); the overlay (§1.3) makes it the host access on a HOST cell and the cell's
      value on a QUANTUM one. A load at a classical address under a quantum predicate is the
      `_hl` load unguarded, its value merged (rule 19). No tape entry is made. Stated
      deviation: the load's `_unc` reads the address a second time.

    `setjmp` and `longjmp` are host calls as they stand, and a `longjmp` under a quantum
    predicate is rule 16's `noreturn` arm. One pairing is made, by operand and never by what a
    pointer might reach: when exactly one `setjmp` in the module has an internal global `G` as
    its operand and every other use of `G` in the module is the operand of a `longjmp`, each
    such `longjmp` is an escaped-flag result merged at that `setjmp`'s diamond, and no host
    call is made for either (101). — 48, 101; 32, 94, 106.

25. **Widths and ABI extras.** `i128`, `_BitInt`, `_Float16`, `x86_fp80` are width variants;
    `<2 x T>` is a pair of lanes, in memory one access per lane (rule 20); `signext`/`zeroext`
    are ABI notes. IR the pinned pipeline (§0) cannot emit (`fp128`, scalable or pointer
    vectors, `invoke`/`landingpad`/`resume`, `inalloca`, `va_arg` instructions, a non-x86-64
    `va_start`) is not an input: meeting it is an internal error that names §0, never a stop.
    — 19, 93, 103, 110, 111; 63.

26. **Aggregates and complex.** An SSA aggregate is one rail per quantum scalar field, classical
    fields stay classical; the mask is applied field-wise; `extractvalue`/`insertvalue` on handles
    are classical. An aggregate in memory is bus memory at its address like any object (rule
    20), and nothing about its type crosses a call.
    - `sret`: the parameter is a pointer formal like any other (one mask digit); the callee
      stores the result through it and the caller loads it. The attribute stays, an ABI note.
      A field an entry stored as a rail is a QUANTUM cell, unspecified to host code (§1.3).
    - `byval`: the caller makes the copy, `q = __cq_alloc(size, align)` and a bus copy of `size`
      bytes (rule 22), and passes `q` as a plain pointer: a lowered call carries no `byval`,
      and the callee is reached by the plain-`ptr` form of §1.4. Its own symbol keeps the C
      signature for host callers. The copy is made right before the call, after its other
      arguments and every earlier access of the source; under a quantum predicate its bus accesses are `_controlled` under it, like the call.

    `_Complex` arithmetic follows clang's Annex G IR: the inlined fast path lowers by rule 4, the
    `__mul*c3`/`__div*c3` fallback is injected and cloned by rule 18, and its `fcmp uno` branches
    are quantum control by rule 8. — 64, 69, 103, 159, 165, 166, 169; 70, 78, 107, 122, 163,
    164.

27. **Callees without a body: declared clones.** The compiler knows no library by name (rule
    16's ISO C interfaces excepted). Which bodiless functions are lowered code is a build
    input: the root lists of the lowered libraries the program links (shipped with their
    headers, §0; another translation unit of the program is such a library). A bodiless callee
    on no list is the host boundary (rule 16). A call from lowered code to a listed function is
    a call of its declared clone when an actual is a rail (any scalar leaf of a fixed actual or,
    for a variadic callee, any variadic actual) or when a cell can be QUANTUM (§1.3) at the call:
    its inputs then arrive through memory. Otherwise (every actual classical and no cell can be
    QUANTUM) the call is classical: it is the call of the function's own C symbol as it stands,
    resolved at link time by the original library, and rule 16's like a call of an unlisted
    function (an ordinary host call, or under a quantum predicate an effect entry; its result
    classical where it is an ordinary host call). A cell can be QUANTUM at the call when the
    module's code reached from a function's own symbol or a `-cq-roots` clone (not from a table
    clone) has a store, swap, atomic or memory intrinsic whose value, address or length is a
    rail or that a quantum predicate controls, a `realloc`, a block or `byval` copy holding a
    rail, a rail saved into a fenv object, a call through a pointer, or a declared clone's call
    with a rail actual, anywhere, before the call or not (no flow is analysed, and nothing is
    known about which object an address lies in, rule 20); and always inside a table clone and
    in a function a table clone reaches by name (its caller is not in view). The compiler emits
    only declarations of the clone and its twin, the link supplies the definitions, and a
    missing one is an ordinary undefined-symbol error (no fallback to the original function).
    Injected source has a body and is rule 18's. The declared clone is a table clone of §1.4,
    so that name and call follow from the callee's C signature and the call's arrangement alone:
    - *Call.* `__cq_q_<fn>_<mask>_t(actuals…, K)`. Among the masks §1.4 gives the signature,
      the call takes the one with the fewest quantum digits that has a 1 at every scalar actual
      that is a rail: with at most 5 scalar formals the call's own arrangement, otherwise the
      union of the classes that hold a rail; every actual classical, the all-zero mask. A
      variadic call whose fixed actuals are all classical but a variadic actual is a rail takes
      the all-ones mask (no mask covers its block otherwise). A classical actual at a digit 1 is
      a seed (rule 7; a classical pointer `alloc_i64` of its address), at a digit 0 its C value;
      a rail is never passed at a digit 0. A variadic callee's further actuals go into rule
      16's block, passed as the classical `ptr` at the last digit 0. K is the callee's K
      resolved as in §0 (for an indirect call see rule 19). Every result is a handle. The call
      is a memory version change; its twin `_unc(outs…, args…)` is called, and frees the
      results, as rule 19 says for a table clone. Under a quantum predicate the call is
      `_t_ctl(pred, …)` of the same mask and the results merge by `select`. Default C calling
      convention, not `fastcc`.
    - *Cutoff.* Inside the clone and its callees every quantum-exit loop runs min(K, B) trips
      and quantum-depth recursion is cut at K (rule 14); no K variant of a library exists. A
      callee reached by name receives K through `@__cq_k` (§1.4), one reached through the table
      as its K actual. Rule 6's per-trip clean holds in a loop the received K can cut as in
      any other: the cut is a classical exit of the chain (rule 14).
    - *The table.* The all-ones clone is the row a function pointer reaches (rule 19), keyed by
      the original library's address of the function; a module that takes the address of a
      listed function references that clone, so the link includes the library's row. A
      declared clone handed a function pointer calls back through the table.
    - *Inline asm.* An `asm` statement with a quantum operand is a callee without a body, named
      `__cq_q_asm_<h>_<1…1>_t`: `<h>` is the first 16 lowercase hex digits of the SHA-256 of
      the asm string as LLVM spells it (`$N` operands), a single NUL byte and the constraint
      string; the mask is over its operands in order. With only classical operands and no
      quantum predicate in scope it stays the asm (host bytes, §1.3); with a quantum operand,
      no outputs and a quantum predicate it is a rule-16 effect entry named by the asm string.
    - *Library build.* The same compiler run over the library source with a list of roots (C
      names; the masks follow from §1.4, nobody lists them): each root's table clones, one per
      mask §1.4 gives its signature, with their `_ctl` forms and twins, are exported; the
      all-ones one is registered (rule 19); calls inside the library are rule 18's and pass the
      received K down. The lowered library defines no C symbol: a root's own body is internal
      to it, a global of the library source is only declared, and the original library, linked
      beside it, provides every C function and object (rule 20: one object at one host
      address). So a program's classical call of a root, a host call or effect entry resolved
      by name, and the address of a root all reach the original library's. A library that exports only the all-ones mask
      does not serve a program built under this rule: its calls name masks the library does
      not define (an ordinary link error), and the library is rebuilt. Root lists and
      recommended K values are build inputs (a corpus example's list is the `roots=` field of
      its `_tools/drivers.txt` line: 161, a rail and a classical actual, `_10_t`; 190, every
      actual classical with rails stored in memory, `_00_t`).

    — 161, 190; a callback through the table and an inline asm owed (§8).

## 4. Metadata and non-normative artefacts

Metadata in a lowered file (`!cq.branchphase` and any other) is non-normative. `_tools/` (traces,
drivers, viewer, checkers) built and verified this suite and is no part of the compiler's
acceptance: a compiler is accepted by matching the examples under §6, nothing else. Comments in
lowered files explain; they never add requirements.

## 5. Conventions for the corpus

- Uncompute as early as rule 5 allows; flags computed just before first use and uncomputed right
  after their last controlled gate.
- Local names are plain LLVM numbering (`_tools/renumber_locals.py`). `m = __cq_mem()` is called
  once, at function entry, in every function that accesses the bus.
- Every example header states: the construction rules it witnesses, the registers and memory
  cells whose final value is checked, which rails are expected clean, which rails and tape slots
  are kept and by which rule, and the rotation list (§6). A bus store's tape slot has no handle
  in the lowered program: the header names it by its store (the line or IR value).
- An example omits the clone-table row, the table clone, `_t_ctl` and their twins of an externally
  visible function whose address it never takes: only rows of address-taken functions are shown
  (96, 97, 211, 212), and an example with an address-rail call has no other externally visible function of
  that call's function type. The compiler emits them for every such function (§1.3, rule 19); nobody calls them in the example, they emit no gate, and §6 does not compare them.

## 6. Semantic acceptance

The emitted circuit belongs to the class *basis permutations interleaved with rotations whose
angle is classical (or an angle rail) and whose control is a basis predicate*. Two circuits of
that class are equal iff:

1. **Permutation part.** Run as a classical reversible program on basis inputs (each `cq_theta`
   input replaced by a chosen bit pattern, templates evaluated by §2), the named output registers
   equal the C program evaluated classically on the same inputs under §2, and every rail the
   example declares clean is `0`. A named output that lives in memory is read from the bus at
   exit, at the address the C object has in that run. A rail still allocated at exit is a frozen
   register (rule 10), a measured value, an effect entry's result rail, or a kept rail a rule names (5, 6, 14, 16, 17, 18, 19, 23; the
   overflow predicates `a_K` and `n > K2`, and a register or an old value's copy a `cq_invert`
   region keeps, among them); any other live rail is a leak and FAILS,
   with or without a reference: a user program under the checker has no clean-list, so every
   rail it does not name is clean. A live rail in a known classical basis state on every input
   (a seed never rotated, a rail only ever written with classically known values) is no leak,
   whatever role it carries: an `a_K` kept where B ≤ K always reads 0 and is not judged by
   rule 14's keep condition. Rule 5 keeps, for the shot: a store's tape slot and, as far as
   the storing function owns them, its value rail (a seed included) and control rail; a load copy that a memory version change
   overtook before its `_unc` (un-copied, not freed), and a result of a clone that loads that one overtook before its twin. An in-place form keeps
   nothing.
2. **Rotation list.** The sequence of `(gate, target register, angle or angle-rail expression,
   control predicate as a Boolean function of the inputs)` is equal up to rail renaming and
   reordering of: gates with disjoint support; any two phases (diagonal gates commute whatever
   their supports); an Ry with any gate that neither acts on the Ry's target rail nor is
   non-diagonal on one of its control rails (so a phase whose predicate does not read the Ry's
   target commutes with a controlled Ry: 125 and 133 are equal). An Ry is ordered against
   every other gate it overlaps. A phase P(θ) on a flag rail is the phase e^{iθ·f} on every
   basis branch, f the flag's Boolean function of the inputs; which rail carries it is
   irrelevant. So `and_i1(a, b, t) · rz_i1(t, θ) · and_i1(a, b, t)` with t |0⟩ equals the
   doubly-controlled phase CCP(θ) on a, b (never a controlled Rz, which differs by a relative
   phase). Phases are compared as a TOTAL, never one gate at a time: within a set of phases
   movable to a common position, the two sides are equal iff Σ θ_k·f_k(inputs) agrees on every
   basis input (mod 2π). So one phase on a disjunction of pairwise-disjoint predicates equals
   the per-edge phases of the same angle (117: one `rz_i1` on the block predicate or one per
   exit edge; both are rule-8 constructions).

A phase whose control predicate (every enclosing arm predicate included) is constant over the quantum
inputs once the classical arguments and the outcomes of the measurements executed before it are fixed,
and whose angle is classical, is a global phase: whether either side emits it is not compared (rules 2
and 12 compose to this; it never applies to an Ry, nor to a phase with an angle rail).

The classical reference of item 1 runs every quantum-exit loop and quantum-depth recursion with the
same cutoff as the circuit: a loop is stopped after K trips (the exit test after the K-th body gives
`a_K`). On an input where the C program would run more than K trips `a_K` must read 1, and
the rotation list and the event sequence (tape entries, abort flags, an early end of the C program)
are compared through trip K; on an input with at
most K trips `a_K` must read 0 and everything is compared. Likewise the kept rail `n > K2` of a
rail-sized allocation must read `n > K2` on every input (for `calloc` on the exact product, rule 16).
**Horizon.** On an input where a kept overflow predicate (`a_K`, `n > K2`, a recursion cut) reads 1,
or an abort flag under a quantum predicate reads 1, nothing after that point is compared:
outputs, rotations, events and measurements alike.
**Measurements** are identified by call site. Before the horizon, an execution of a measurement
site on an input where the C program does not reach it is accepted iff every condition by which
the C run left the path to the site is quantum under rule 2's static collapse (a quantum arm, a
trip behind a quantum exit or break, a `_ctl` predicate); where one of them is classical, an
argument or a statically collapsed outcome, it is a failure. An accepted extra execution is no
event of that input, and its measured rail is a kept rail. It is permitted, not required: a
lowering that leaves it out and agrees on everything compared is equal under §6 (rule 14 fixes
the form the compiler emits). Trip j's copy of a body `cq_measure`
measures trip j's carried rail (rule 14). A function with no body (rules 16, 27) is
modelled on both sides by one deterministic stand-in of the name and argument bits; the model is the
checker's, not the spec's. The stand-in of a declared clone (rule 27) must have an effect that occurs
exactly when the clone runs, so that a call made without its predicate is seen: a phase of an angle
fixed per name serves (the plain clone emits it, the `_ctl` form where its predicate reads 1, a
`cq_invert` region replays it negated). A call of the `errno` accessor (rule 16) is no host effect on
either side: its count and order are not compared, what is stored and read through it is.
For a C library call whose result rule 16 computes in the circuit the
reference takes the result from the same musl source and performs only the host operation; the
host library's own return value is not the reference (`puts` returns 10 on macOS and 0 in musl).
For an ordinary host call (rule 16), and for every call of a module the pass leaves unchanged, the
reference is the host's own call and its own result, with no substitution. Which of the two a call
is, is rule 16's static classification, fixed at compile time; applying it is no model of the
backend's deferral.
Standard input is one finite stream with state, the same bytes on both sides (the checker's
default, or the `stdin="…"` field of the example's line in `drivers.txt`): an input call
consumes what the C program consumes on that basis input (a call whose predicate reads 0 consumes
nothing, a rail length consumes for its value there), and the consumption across branches of
BACKEND_ABI §1.11 is not modelled. An input on which the C program is undefined (206's call that violates
`restrict`) is compared against the reference only.

An indeterminate value the C program reads is what its cell holds on the bus: 0 for a cell never
written since its `__cq_alloc` (`malloc`, an uninitialized bus-resident local, the grown part of a
`realloc` block), and for a block-scoped object re-entered by a loop the value the trip before
left there (rule 20: one block). The classical reference models both. An
uninitialized cell of a host-resident `alloca` (host stack memory) is not compared.

Pointer values (`ptrtoint`, printed addresses) are compared only relationally (equality and
order): host addresses differ per run. Byte identity of traces is never required. The tape is
compared per input as the sequence of its entries in order (name or format, fields, predicate);
the result rail of an entry the backend deferred (rule 16 *Results*: a callee that is no C library
function, or one whose result is host state) is a stated deviation, and that rail alone is not
compared against the C program.
Two kinds of input are not compared and are not a PASS: one on which the program reads such a
deferred result rail, and one on which a bodiless callee receives a pointer into an object that
holds a QUANTUM cell at the call (rule 16; reach through a global or a stored pointer is not
detected, and the report says so). Such an input is still run, and every check of this section
that reads the lowered run alone (the leak rule, the frees, the uncomputation) is judged on it: a
violation there is a FAIL. The measurement rule above is judged against the C run's path, which is
no reference on such an input, and is not judged there. A run is judged on the inputs it compared and
states the number it did not compare with the reason; a run that compared no input and shows no
such violation is PASS (STRUCTURE ONLY): counted apart from PASS, never as one.

The circuit compared is the one the backend builds from the lowered program's execution (§0): the
gates between `invert_begin()` and `invert_end()` enter it reversed and inverted (rule 17), so the
rotation list of a `cq_invert` example is read through that reversal, never from the IR's order.

A checker that samples inputs reports its coverage and never narrows the claim. A coverage target
of its own making (a loop trip class, a branch) whose cheapest reaching input exceeds the checker's
stated cost budget is reported as UNCOVERED, with that input and its cost: never compared, never a
failure of the compiler, never dead, never a PASS, and never removed by changing the example or the
budget (117: the inner k-loop's zero-trip exit is reached only at t = 32, after 2^31 − 1 trips).
Only a target proved dead from range facts is dead. The budget is the checker's, not the spec's.

## 7. Examples normalised under these rules (done 2026-10-26)

Every example not listed below conforms.

101 conforms to rule 24 as it stands.

## 8. Examples written 2026-10-26 (144–180)

144–194 each state their outcome per §5; the rules cite them as witnesses.

Owed, no source yet. Each fixes the construction its rule names:
- rule 2: a measurement under a classical branch inside a callee, the result read and rotated afterwards. Rule 6:
  an old value dead on one classical path only. Rule 10: a second `cq_theta` prep after a reader of the first.
- rule 13: a `switch` with a reachable default; a computed `goto` over a `blockaddress` table read at a quantum
  index, one whose address is a loop-carried `phi` chosen under a quantum flag, one stored and reloaded.
- rule 14: an irreducible loop (`goto` into a loop body with a quantum exit); a K-loop whose only exit aborts and
  a `for (;;)` with a quantum body; a pointer-chase K-loop.
- rule 16: `printf` whose count the program reads, and `%s` of a pointer rail; an output call of a buffer that holds QUANTUM cells (with 99); a variadic call's block (with
  95); `main` returning a loaded value and `exit` of one (rule 19).
- rule 17: a K-loop with a clone call inside a region; a K-loop inside a region whose exit value is read
  after the `end` through a computation, and one whose read value depends on a rotation, measurement or store
  of its body (construction owed too); `cq_invert_begin()` inside a quantum arm with its `end`
  after the join, a pair inside one arm, an `end` in each arm closing one `begin`; a kept store and an in-place
  form inside a region; a rolled loop updating a register inside a region.
- rule 18: a static callee under `#pragma STDC FENV_ACCESS ON` measured from a plain caller (the mode literal 0,
  the empty flags rail, the copy-out of the measured result before the twin).
- rule 19: a host call with classical arguments and no gate under a quantum predicate; an in-place callee minting
  a register on one classical path only (handle 0); a `select` of two function pointers under a quantum flag; a
  function with no formals under a quantum predicate (mask `v`).
- rule 23: a `FENV_ACCESS ON` caller with `fesetround(FE_UPWARD)` calling a `round.dynamic` body (the `_rm`
  clone), and one with the `fesetround` under a quantum predicate and classical data arguments (the `_rmq` clone);
  a `fenv_t` reached through a pointer (fixes the field offsets).
- rule 14: a classical branch with an effect inside a K-loop body; `while (c && q)` with a classical `c`; a
  `cq_measure` in a K-loop body and in its exit arm; a loop that measures its carried rail and
  exits on the outcome, inside a quantum arm. Rule 6: a bijective accumulator read only by a flag.
- rule 16: `calloc` with two rail operands whose product overflows; `signal` and `raise` with an invalid
  number; `fseek`, `fclose` and `remove` whose result is read behind a quantum field; `abort` under a quantum
  predicate followed by a classical `exit`; a classical `exit` behind a deferred entry with code
  after it (the shot ends at the seed's `abort_i1`). §1.4, rule 27: a table clone calling a
  by-name callee that holds a K-loop (`@__cq_k`). Rule 22: a by-name `memcpy` from a freestanding body.
- rule 24: `pthread_join(t, &r)` whose result is read (106 joins with a null result only).
- rule 24: an observable `volatile` access at an address rail. Rule 26: a `byval`
  copy (with 164). Rule 27: a callback through a declared clone and the table; an `asm` with a quantum operand.

Written 2026-11-05 (flat memory), 195–213: each states its outcome per §5 and has a trace; the rules cite
them as witnesses. Bus accesses at classical addresses and address rails, store size, pointers in cells:
195–199 (rules 3, 5, 6, 20, 21). A pointer as one scalar, a clone that stores, one block per activation:
200, 204 (§1.4, rules 18, 20). Allocation: 201, 208, 213 (rule 16, K2). Kept and un-copied load copies: 202.
A host-resident `alloca` beside an escaped one, a scan K-loop: 203. One clone per quantum-depth recursion:
205 (rule 14). `cq_theta` on a cell twice and on a load copy: 206, 207 (rules 2, 5). Host and input calls
behind a deferred output: 209, 210 (BACKEND_ABI §1.11). A function-pointer rail: 211. The signal table: 212.

Written 2026-11-26: 214 invert_inplace_register (rule 17 registers, owner 2026-11-26): a knapsack PREP and
its adjoint in a region; an old value read after its in-place update in the region (the copy); a bus cell and
a register updated in place in one region.

Out of scope by §0: an `-O0`+mem2reg or `-O2` variant of any example.
