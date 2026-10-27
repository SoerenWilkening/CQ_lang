Tooling for the CQ_spec corpus (NOT part of the spec; examples/ and CQ.h are the spec). Spec-authoring tooling: the compiler implementers do not run these checkers; they only match examples/ under §6.

cq_lowering_viewer.html  the viewer page (published at https://claude.ai/artifact/HvJcVoXE4zm6SJv7YFae6i);
                         it loads corpus.json = [{name,cname,irname,lowname,c,ir,low,trace}] built from examples/ + traces/
traces/NN_name.txt       reference trace per example; first line "# driver: calls", "# call: fn(args)" before each call
drivers.txt              per example: "NN_name|prototypes|call;call[|extra]" used to build the trace driver; the optional
                         4th field is C run in main before the calls (e.g. allocating a register array for a bool* arg)
trace_stubs.c            stub runtime for symbols the trace stub runtime archives lack (push/pop, not/and/xor_i1, select_*, qrom, abort, tape_fmt/_lit)
trace_check.py           allocation check + uncompute pairing (every _unc matches an earlier forward call with the same
                         operands or a recomputed twin operand; no template result freed without its _unc or copy)
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
Rebuilding corpus.json: for each examples/NN_name/: name=NN_name, base=name.split('_',1)[1], files base.c / base.O1.ll / base.lowered.ll, trace traces/NN_name.txt.

make_trace.py NN_name [...]   verify + link + run + trace_check for the named examples (writes traces/NN_name.txt)
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
an f64 rail (select_f64 chain, qrom_load_f64) and consumed by ONE cqrt_ry_<W>_qangle(h, A); the compiler never expands
it into per-arm controlled rotations.
Example 143 (2026-10-25): a lifted call's quantum int result (conditional values, merged in the clone) as (a) the register
of a second cq_theta: a plain Ry on the result rail; (b) the ANGLE of cq_theta and (c) the angle of cq_phi: the angle is
computed into an f64 register by ordinary templates, then ONE primitive reads it (cqrt_ry_<W>_qangle(h, A),
cqrt_rz_qangle(A), cqrt_rz_qangle_controlled(flag, A); stubs in trace_stubs.c) and the backend supplies the decoded
bit-controlled ladder (rule 15). 79 has the same shape (a fixed-point ladder spelled in the IR would be inexact).
QRAM MODEL (owner rulings 2026-10-25 and 2026-10-27; CONSTRUCTION_RULES.md rules 20-22 and §1.3 are normative): an
object is a QRAM iff some access to it has a QUANTUM OFFSET (a quantum-index store, or a quantum-index load while it may
hold a handle); holding quantum values alone never makes a QRAM (that is a slot array of handles); a quantum-index read of
classical-only memory is a QROM. Every access to a QRAM is ONE call; the per-cell flag+select ladder (and the "slot array of handles") is the BACKEND's circuit
(fan-out per cell as in Bennett.jl memory.jl, bucket brigade, select-swap: the contract fixes the unitary, a permutation of
the cells, never the circuit). Reads of CONSTANT data at a quantum index keep the one-call QROM (cq_template_qrom_load).
The ABI is the QRAM contract of CONSTRUCTION_RULES.md §1.3 (the handle forms link from the trace stub runtime archive
libcq_runtime.a; the controlled loads, the controlled fixed-index store and cqrt_qram_free are stubs in trace_stubs.c):
  cqrt_qram_alloc_<W>(n) -> a<N>          at the alloca / malloc site: n cells of width W, all |0>. Prints a<N>: an array
                                           bus, not a rail. A nonzero initializer is one store_hl per cell (below).
  cqrt_qram_store_<W>(a, idx, val)         cell[idx] <- val. idx is the logical-i32 index RAIL (cell index: -O1's zext to
                                           i64 and the gep scaling are NOT emitted). val is ALWAYS a handle: a classical
                                           value is materialised once by cqrt_alloc_<W>(lit) (a known basis state, shared by
                                           every store that reads it, freed after its last store is popped). The backend
                                           keeps the displaced cell on its own tape.
  cqrt_qram_store_<W>_unc(a, idx, val)     pops that tape (same args, no out). LIFO per array: pop in reverse store order.
  cqrt_qram_store_<W>_hl(a, j, val)        classical index j (_hl = classical INDEX in this family): the initializer of a
                                           cell, or a fixed-index write of a quantum value into a quantum array. _unc same.
  cqrt_qram_store_<W>_controlled(g, a, idx, val) / _hl_controlled(g, a, j, val)   under a flag g (block predicate, object
                                           guard B & tag == o of a fat pointer, loop trip predicate). _unc same args.
  cqrt_qram_load_<W>(a, idx) -> h          fresh rail h ^= cell[idx] (cell preserved). _unc(h, a, idx) un-copies.
  cqrt_qram_load_<W>_hl(a, j) -> h         fixed-index read of a quantum array. _unc(h, a, j).
  cqrt_qram_load_<W>_controlled(g, a, idx) -> h   h ^= g ? cell[idx] : 0. _unc(h, g, a, idx). Multi-origin fat-pointer
                                           loads: one controlled load per object, xor-merged (guards are disjoint); _hl_controlled too.
  cqrt_qram_free(a)                        after every store was popped (all cells |0>; R5).
Reference conversions: 30 (write + fixed reads), 84 (fat pointer, two objects, controlled stores, initializer). A quantum
fat pointer's idx is the CELL index of the object; a provenance with mixed cell widths carries a byte offset and rescales
(lshr) at the access. QRAM witnesses after the 2026-10-27 audit: 30, 55, 72, 73 (b), 77, 84, 87,
88 (tab, a, b), 91 (heap_quantum_size), 160, 168; QROM through a quantum pointer: 85, 88 (s), 89, 105, 107, 167; slot arrays
with per-cell select: 90, 91 (heap_in_loop), 129. By contrast a QUANTUM
ANGLE (79, 132, 141, 142, 143, 185) is one backend primitive for exactness reasons (rule 15).
seq_locals.py FILE.ll    makes a hand-written file's local numbering sequential per function (LLVM refuses gaps) before
                         renumber_locals.py; keeps comments.
sample_check.py [NN_name | NN_name:mutant.lowered.ll ...]   §6.1 basis-input SAMPLE check (not a simulator, not exhaustive):
                         runs lowered.ll against a computing runtime (generated IR stubs -> sample_rt.c -> a Python rail
                         evaluator, templates per §2) and base.O1.ll with cq_theta/cq_measure = identity, on ~7 fixed seed
                         values; compares outputs, measured values, fired Ry/phase angles; _unc residue and dirty frees FAIL.
                         KDIFF = differs only where the K = 4 cutoff may bind; f80 and fenv (_rm/_exc) examples are SKIPPED.
