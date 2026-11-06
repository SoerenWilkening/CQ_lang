Tooling for the CQ_spec corpus (NOT part of the spec; examples/ and CQ.h are the spec). Spec-authoring tooling: the compiler implementers do not run these checkers; they only match examples/ under §6.

cq_lowering_viewer.html  the viewer page (published at https://claude.ai/artifact/HvJcVoXE4zm6SJv7YFae6i);
                         it loads corpus.json = [{name,cname,irname,lowname,c,ir,low,trace}] built from examples/ + traces/
traces/NN_name.txt       reference trace per example; first line "# driver: calls", "# call: fn(args)" before each call
drivers.txt              (the one home of driver lines; there is no per-example drivers.d/) per example: "NN_name|prototypes|call;call[|extra]" used to build the trace driver; the optional
                         4th field is C run in main before the calls (e.g. defining the host array a pointer argument addresses); the optional 5th field
                         roots=f[,g] is the CR rule 27 root list the example links (161, 190; the 4th may be empty)
trace_stubs.c            stub runtime for symbols the trace stub runtime archives lack (push/pop, not/and/xor_i1, select_*, abort,
                         tape_fmt/_lit); with -DCQ_BUS the bus forms, always the effect entries and the injection bundle (MEMORY MODEL below)
trace_check.py           allocation check + uncompute pairing (every _unc matches an earlier forward call with the same
                         operands or a recomputed twin operand; no template result freed without its _unc or copy) + the bus checks of
                         CR rule 5 (MEMORY MODEL below); exit status 1 on an error
annotate_simple.py       generic "; C:" / "; IR:" annotator for straight-line examples
renumber_locals.py       local names in examples/*/*.lowered.ll are plain LLVM numbering (owner, 2026-10-22): arguments,
                         then unnamed blocks and non-void instructions in textual order, no named values or labels. A
                         "%1 / %q2 / %3" scheme is not expressible (a named value consumes no number). After editing or
                         adding a hand-written lowering run `renumber_locals.py examples/NN/x.lowered.ll`: it renumbers in
                         place, keeps every comment, and fails unless the function bodies are textually identical to
                         `llvm-as | opt -discard-value-names` (LLVM 19 accepts gaps in numbering, so parsing alone proves
                         nothing). `--check` only reports. The `; IR: %N` comments keep naming the .O1.ll values.

Regenerating a trace (RT = the trace stub runtime archives libcq_templates.a and libcq_runtime.a, built at
~/Desktop/Projects/CQ_lang/build/runtime; every cqrt_*/cq_template_* symbol prints one trace line and computes nothing;
LLVM = /usr/local/opt/llvm@19/bin):
  clang -w NN/x.lowered.ll drv.c trace_stubs.c RT/libcq_templates.a RT/libcq_runtime.a -o a.out && ./a.out
  (drv.c: prototypes from drivers.txt, puts("# call: ...") before each call; define static const double coef[4]={1,2,3,4}; static const int icoef[4]={1,2,3,4} when used)
  This recipe is for an example of the retired memory model. A bus example (its lowered module references @__cq_mem)
  needs -DCQ_BUS and a copy of libcq_runtime.a without the old cqrt_qram_* symbols: use make_trace.py (MEMORY MODEL below).
Rebuilding corpus.json: for each examples/NN_name/: name=NN_name, base=name.split('_',1)[1], files base.c / base.O1.ll / base.lowered.ll, trace traces/NN_name.txt.

make_trace.py [--out DIR] NN_name [...]   verify + link + run + trace_check for the named examples (writes
                              traces/NN_name.txt, or DIR/NN_name.txt); bus mode is chosen per example
build_corpus.py               rebuild corpus.json from examples/ + traces/
Examples 48-65 (2026-10-18) came from the coverage check against openlibm (all 178 non-complex TUs at -O1) and six
textbook algorithms.
K: every quantum-bounded rolled loop compares its trip counter against the literal 4; those lines carry the tag [K] in the
lowered files. K is a per-loop variable of the compiler (CONSTRUCTION_RULES.md §0, rule 14); the corpus fixes it at 4 so traces stay short.
libc_census.py <musl>         coverage of the C standard library's own code: compiles musl's std-lib TUs at -O1 and counts the
                              TUs whose every IR construct has an example (2026-10-20, musl b1efda5: 666/752 stock, 752/752 with --arch-cq = _tools/musl_arch_cq;
                              the rest is inline asm = syscall/TLS/x86 atomics/traps, the host boundary)
llvmlibc_census.py <llvm-project/libc>  the same measurement over LLVM libc's generic libm (clang++ -O1): 454/454 clean on
                              2026-10-20 (819e35c4), 43/52 C23 math names with a body; see LIBC_COVERAGE.md
replay/                       state-vector replayers for the algorithm examples 113-118: replay a trace exactly and
                              compare with the analytic state or distribution. 2026-10-22: 113 -> |D^4_2> exact; 116 -> Shor m uniform
                              on {0,2,4,6}, y on {1,4,7,13}; 118 -> |+>^4 -> |0000> p = 1. 2026-10-26, runtime-sized rewrites (sizes and
                              problem data are function inputs): 114 dicke_n(4,2),(5,2),(5,3) -> uniform |D^n_k>; 115 4-ring p=2 and 5-path
                              p=1 vs exact QAOA, max dp 1.1e-16; 117 (3,4,{3,5}) P(round(M~)=2)=0.6885, (3,3,{1}) 0.9816; 176 P(target) =
                              sin^2((2r+1)theta); 177 constant -> 0, balanced -> nonzero, p=1; 178 reads s, p=1; 179 y.s=0 uniform;
                              180 teleport 0 on all four branches; 185 c = kv*2^(t-nk). Not part of the spec.
Examples 132-141 (2026-10-25) cover construction shapes that had no example yet: angle select (132), state-prep
seed/incoming mismatch and overwrite (133), i128 compare/merge and the quantum-classical-literal funnel shift (134), switch
and classical-condition select inside a lifted callee (135), a measuring callee (136), depth-3 nest and a 9-leaf condition
tree (137), fp/compound/nested tape entries (138), a quantum break inside nested loops (139), two measuring return arms
(140), a compare read as both condition and data (141). fp128 has no example: clang 19 rejects __float128/_Float128 on
Darwin x86-64, so the shape is unreachable from C here.
Example 142 widens 132's two-arm angle select to the multi-way case: a select of selects, a switch over a quantum
scrutinee and a constant table read at a quantum index. Each is a QUANTUM ANGLE (rule 11): the angle is computed into
an f64 rail (select_f64 chain, a bus load of the table cell) and consumed by ONE cqrt_ry_<W>_qangle(h, A); the compiler
never expands it into per-arm controlled rotations. 
Example 143 (2026-10-25): a lifted call's quantum int result (conditional values, merged in the clone) as (a) the register
of a second cq_theta: a plain Ry on the result rail; (b) the ANGLE of cq_theta and (c) the angle of cq_phi: the angle is
computed into an f64 register by ordinary templates, then ONE primitive reads it (cqrt_ry_<W>_qangle(h, A),
cqrt_rz_qangle(A), cqrt_rz_qangle_controlled(flag, A); stubs in trace_stubs.c) and the backend supplies the decoded
bit-controlled ladder (rule 15). 79 has the same shape (a fixed-point ladder spelled in the IR would be inexact).
MEMORY MODEL (owner rulings 2026-11-05; CONSTRUCTION_RULES.md §1.3 and rules 20-22 are normative): ONE bus M holds all
memory of the program: 8-bit cells, 2^64 cells, cell index = the x86-64 address. It is created once as
cqrt_qram_alloc_i8(0) (n = 0: 2^64 cells) and reached through the injection-bundle getter i32 @__cq_mem(). A cell is HOST
or QUANTUM. Every cell starts HOST: its value is the host byte at that address, read at each access. A store whose value,
address and control are all classical-valued writes the host byte and the cell stays HOST; any other store makes the cell
QUANTUM. A load at an address that is neither readable host memory nor a QUANTUM cell reads 0 and never faults. Every
access is ONE call; it touches store-size(T) consecutive cells from the address, little-endian, and <W> is the ACCESS
width (i8, i16, i32, i64, i128, f32, f64, f80 = 10 cells, ptr = i64). The contract fixes the unitary; the circuit behind
a call is the backend's. m is the bus handle, addr a classical i64 address (_hl = classical ADDRESS in this family), A a
64-bit address rail:
  cqrt_qram_load_<W>_hl(m, addr) -> h      fresh rail h ^= cells (cells preserved). _unc(h, m, addr) un-copies, at the
  cqrt_qram_load_<W>(m, A) -> h            memory version the load read. _unc(h, m, A).
  cqrt_qram_store_<W>_hl(m, addr, v)       the displaced cells go to a fresh tape slot, then cells ^= v. v is ALWAYS a
  cqrt_qram_store_<W>(m, A, v)             handle: a classical value is first cqrt_alloc_<W>(lit). No _unc: a store is
                                           never popped; its slot, its value rail and its control rail are KEPT (rule 5).
  ..._controlled(c, ...)                   all four, control rail first; under c = 0 nothing is touched. The load's twin
                                           is _controlled_unc(h, c, m, addr|A). Every access under a quantum predicate
                                           (arm flag, K-loop trip predicate) is the _controlled form.
  cqrt_qram_swap_<W>[_hl][_controlled]([c,] m, addr|A, h)   h <-> cells; self-inverse, no tape slot, no _unc.
A pointer value is a classical ptr/i64 or ONE handle to a 64-bit rail. The address arithmetic of a getelementptr with a
quantum operand IS emitted (sext/zext of the index, mul/shl by the element size, add: existing templates);
ptrtoint/inttoptr are identities. Bus-resident objects are allocated by the bundle's ptr @__cq_alloc(i64 size, i64 align)
(zeroed, an address never reused); free is nothing.
Retired: per-object buses, cqrt_qram_alloc_host[_s], @g.qram, cqrt_qram_realloc[_unc], cqrt_qram_size, cqrt_qram_free,
slot arrays, store _unc (the store pop), QROM (cq_template_qrom_load[_s]), fat pointers, object tables, range decoding, bound checks, cell counts.
Witnesses: 195-213 and the examples regenerated 2026-11-05.
TRACING A BUS EXAMPLE (2026-11-05). Write examples/NN_name/{base.c, base.O1.ll, base.lowered.ll}, add the line
"NN_name|prototypes|call;call[|extra]" to drivers.txt (or drivers.d/NN_name.txt), then `python3 _tools/make_trace.py
NN_name`. An example whose lowered module references @__cq_mem is a BUS example: make_trace.py compiles trace_stubs.c
with -DCQ_BUS and links a private copy of libcq_runtime.a (llvm-objcopy --redefine-syms, in /tmp/cq_spec_trace_NN_name)
whose retired cqrt_qram_* symbols are renamed to cqrt_retired_qram_*, so a retired symbol (a store _unc, an i32-index
form, alloc_host, realloc, qram_free, qrom_load) is LINK FAILED. Every other example links as before; all 194 traces
were reproduced byte for byte by the old and the new tooling. A trace_check error fails make_trace.py for a bus example.
  trace lines   the bus prints m<N> (created once per process, in the first call's section); a classical address is
                printed in full and rewritten to P<n>[+off] per "# call:" section; an address rail is h<N>. __cq_alloc
                prints the comment line "# __cq_alloc(size, align) -> P<n>". The other bundle symbols (__cq_mem,
                __cq_sig, __cq_clone_register/resolve/count/at: weak definitions in trace_stubs.c, real host C) print
                nothing. Widths stubbed: i1 i7 i8 i16 i32 i64 i80 i100 i128 f16 bf16 f32 f64 f80, load/store/swap,
                plain/_hl, with and without _controlled, the load _unc twins. cqrt_tape_effect_<W>_controlled -> r.
  trace_check   bus lines are those with the handle m<N>: a store _unc is an error; a free or an _unc of a store's
                value or control rail is an error (the trace has no function boundaries, so a caller freeing a rail
                it passed to a storing clone is reported too: read by hand); a load _unc after a store, swap, effect
                entry, __cq_alloc or table-clone call is legal, but freeing that load copy afterwards is an error; swaps pair up (same symbol, bus, address, control,
                one section, no bus access between) and the second swap's rail is freed. Not checked: the X bracket of
                a controlled access, the Readers clause, host calls and plain stores as memory version changes
                (they leave no trace line), value equality.
TOOL STATUS: sample_check.py and sample_rt.c are RETIRED for bus examples (owner, 2026-11-05). They model the old
per-object memory and are kept only for examples with no memory access. Bus examples are checked here by the trace path
above; their semantic check is the implementing compiler's own evaluator (CQ_lang2 checker), which reports a reference
that disagrees with its C program as a spec issue.
A QUANTUM ANGLE (79, 132, 141, 143; 142, 185) is one backend primitive for exactness reasons (rule 15).
seq_locals.py FILE.ll    makes a hand-written file's local numbering sequential per function (LLVM refuses gaps) before
                         renumber_locals.py; keeps comments.
sample_check.py [NN_name | NN_name:mutant.lowered.ll ...]   §6.1 basis-input SAMPLE check (not a simulator, not exhaustive):
                         runs lowered.ll against a computing runtime (generated IR stubs -> sample_rt.c -> a Python rail
                         evaluator, templates per §2) and base.O1.ll with cq_theta/cq_measure = identity, on ~7 fixed seed
                         values; compares outputs, measured values, fired Ry/phase angles; _unc residue and dirty frees FAIL.
                         Memory left in host objects is not compared, and a flat-bus example cannot be verified yet
                         (MEMORY MODEL above, TOOL STATUS).
                         KDIFF = differs only where the K = 4 cutoff may bind; f80 and fenv (_rm/_exc) examples are SKIPPED.
                         A reference whose C program measures a value rule 2 made classical declares the count in its
                         header (`; Classical reads (rule 2): N`, 65); those C-side measurements have no lowered gate.
