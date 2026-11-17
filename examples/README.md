# Examples: quantum algorithms in plain C

Two textbook algorithms written against `CQ.h` (`spec/CQ.h`), with the problem size as an
ordinary run-time argument.

| Program | Function | What it does |
|---|---|---|
| `grover/grover.c` | `int grover(int n, unsigned marked)`, `1 <= n <= 16` | Grover search for one marked element among `2^n`: preparation `A = Ry(pi/2)^n`, then `floor(pi/4 sqrt(2^n))` iterations of `A R0 A^dag O` (phase oracle `O`, reflection `R0` about `|0>`, `A^dag` by `cq_invert`), then measures the register. Returns `marked` with probability 0.945 (n = 3), 0.961 (n = 4), 0.999 (n = 5). |
| `dicke/dicke.c` | `int dicke(int n, int k)`, `1 <= n <= 31`, `0 <= k <= n` | Prepares the Dicke state `D(n, k)` by the Baertschi–Eidenbenz split-and-cyclic-shift construction (CNOTs and controlled Ry with classical angles), then measures it. Returns a uniformly random `n`-bit string of weight `k`. |

Each file also defines fixed-size entry points with no arguments (`grover_3`, `grover_4`,
`dicke_3_1`, `dicke_3_2`, `dicke_4_1`, `dicke_4_2`) for checking.

## The idioms

- `cq_theta(&q, a)` is Ry(a) on `q` in place and makes `q` quantum. `if (c) cq_theta(&q, a)` is a
  controlled Ry, and `if (c && d) ...` a doubly controlled one.
- `t ^= c` on two `bool` qubits is a CNOT.
- `if (pred(x)) cq_phi(M_PI)` is a phase oracle: a phase pi on every branch where `pred` holds.
- `cq_invert_begin(); f(x); cq_invert_end();` applies the adjoint of `f`.
- `cq_measure(q)` measures `q` and returns the classical outcome.
- Loop bounds, angles and iteration counts are ordinary classical C (`floor`, `sqrt`, `acos`).

## Register representation

Both programs keep the register as a `bool` array, one qubit per element, with a fixed capacity
(`GROVER_MAX_N`, `DICKE_MAX_N`) of which the first `n` elements are used. Reasons:

- A one-qubit gate needs a one-bit l-value. `cq_theta(&x[i], a)` is an in-place Ry on exactly
  that cell (CR rule 2's in-place form on a memory cell), and `q[a] ^= q[b]` is a CNOT on two cells.
  With the bits of a `uint64_t`, a single-qubit Ry would need extracting the bit into a temporary
  and writing it back, which the C semantics turn into a fresh copy plus an overwrite: a
  rotated copy and a kept old value rather than a gate on the register.
- An integer view for the oracle is still one loop away (`value()` in `grover.c`), and is
  computed out of place and uncomputed by the compiler.
- A fixed capacity rather than a VLA makes the documented bound part of the type; `n` still
  varies at run time. Either way the array lives on the memory bus (CR rules 5, 20), and each
  gate on `x[i]` is a controlled swap of the cell, the gate, and the swap back.

## Lowering

With `cqcc` (from the repository root; the plugin defaults to `build/pass/libCQLower.so`):

    driver/cqcc -S examples/grover/grover.c -o grover.lowered.ll --save-temps grover.tmp
    driver/cqcc -S -cq-k-default=4 examples/dicke/dicke.c -o dicke.lowered.ll --save-temps dicke.tmp

`--save-temps` keeps `linked.ll` (the `-O1` module the pass reads). By hand:

    LLVM=/usr/local/opt/llvm@19/bin
    $LLVM/clang -O1 -S -emit-llvm -target x86_64-apple-macosx -include spec/CQ.h \
        examples/grover/grover.c -o grover.O1.ll
    $LLVM/opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-lower -cq-k-default=4 \
        -S grover.O1.ll -o grover.lowered.ll

## Checking

`cqcheck user` runs the lowered module in the classical evaluator and compares it with the C
program (CR §6) from an entry point. Run it from `checker/`:

    cd checker
    python3 -m cqcheck user --o1 ../grover.O1.ll --lowered ../grover.lowered.ll --entry grover_3

or in one step with `driver/cqcc -S --cq-check --cq-entry grover_3 examples/grover/grover.c`.
Exit status 0 is a pass, 1 a difference (the reasons are printed), 2 undecided. `--light` is a
quick smoke test with fewer samples, not a verdict.
