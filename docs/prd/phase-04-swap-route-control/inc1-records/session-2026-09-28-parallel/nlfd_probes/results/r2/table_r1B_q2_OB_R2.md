| subject | twin | ORACLE | SUBJECT |
|---|---|---|---|
| `q2/b1` | `q2/b1T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 13 lines ⟵ |
| `q2/b1` | `q2/b1N` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 1, dirty 1, 13 lines ⟵ |
| `q2/d2m` | `q2/c4T` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 20 lines ⟵ |
| `q2/d2m` | `q2/d2` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-IDENT** — exit 0, warn 1, dirty 1, 20 lines ⟵ |
| `q2/d2` | `q2/c4T` | TRACE-DIFF — exit 0, warn 1, dirty 1, 20 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 20 lines |
| `q2/c4` | `q2/c4T` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 34 lines ⟵ |
| `q2/c4` | `q2/c4N` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-IDENT** — exit 0, warn 1, dirty 1, 34 lines ⟵ |
| `q2/d1` | `q2/c4T` | TRACE-DIFF — exit 0, warn 1, dirty 1, 13 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 13 lines |
| `q2/d3` | `q2/c4T` | TRACE-DIFF — exit 0, warn 1, dirty 1, 34 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 34 lines |
| `q2/c1` | `q2/c1T` | VERDICT-DIFF — decline: cq specialization: callee contains a quantum primitive (cq_*); only cl | **VERDICT-DIFF** — decline: cq specialization: callee contains a quantum primitive (cq_*); only cl |
| `q2/c3` | `q2/c3T` | VERDICT-DIFF — decline: cq specialization: callee measures under quantum lift | **VERDICT-DIFF** — decline: cq specialization: callee measures under quantum lift |
| `q2/f1` | `q2/f1T` | TRACE-DIFF — exit 0, warn 0, dirty 0, 16 lines | **TRACE-DIFF** — exit 0, warn 0, dirty 0, 16 lines |
| `q2/f1` | `q2/f1N` | TRACE-IDENT — exit 0, warn 0, dirty 0, 16 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 16 lines |
| `q2/f2` | `q2/f2T` | VERDICT-DIFF — decline: cq taint escape: tainted value returned at non-i32 width | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 3 lines ⟵ |
| `q2/i1` | `q2/i1T` | TRACE-DIFF — exit 0, warn 0, dirty 0, 9 lines | **TRACE-DIFF** — exit 0, warn 0, dirty 0, 9 lines |
| `q2/n1` | `q2/n1N` | TRACE-IDENT — exit 0, warn 0, dirty 0, 26 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 26 lines |
| `q2/r1` | `q2/r1N` | TRACE-IDENT — exit 0, warn 0, dirty 0, 3 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 3 lines |
| `q2/r2` | `q2/r2N` | DECL-SAME — decline: cq specialization: callee contains tainted control flow under quantum  | **DECL-SAME** — decline: cq specialization: callee contains tainted control flow under quantum  |
| `q2/pa2` | `q2/paN` | DECL-DIFF — ABORT (exit 134) | **DECL-DIFF** — decline: cq specialization: callee contains a non-reversibilizable construct un |
| `q2/pa` | `q2/paN` | DECL-DIFF — decline: cq specialization: callee contains a non-reversibilizable construct un | **DECL-DIFF** — decline: cq specialization: callee contains a non-reversibilizable construct un |
