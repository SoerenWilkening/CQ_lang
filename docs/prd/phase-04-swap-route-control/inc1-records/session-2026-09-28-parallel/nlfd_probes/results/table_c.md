| subject | twin | ORACLE | SUBJECT |
|---|---|---|---|
| `mtl` | `mtlT` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines ⟵ |
| `mtl` | `mtlN` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-IDENT** — exit 0, warn 1, dirty 1, 25 lines ⟵ |
| `mtlN` | `mtlT` | TRACE-DIFF — exit 0, warn 1, dirty 1, 25 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines |
| `ev1` | `ev1T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `ev1N` | `ev1T` | TRACE-IDENT — exit 0, warn 0, dirty 0, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines |
| `ev2` | `ev2T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `ev4` | `ev4T` | TRACE-IDENT — exit 0, warn 0, dirty 1, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `ev6` | `ev6T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `ev7` | `ev7T` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 2, 23 lines ⟵ |
| `ev7` | `ev7N` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-IDENT** — exit 0, warn 1, dirty 2, 23 lines ⟵ |
| `ev8` | `ev8T` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `ev9` | `ev9T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-DIFF** — exit 0, warn 1, dirty 2, 16 lines ⟵ |
| `ev9` | `ev9N` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 1, dirty 2, 16 lines ⟵ |
| `ev9N` | `ev9T` | TRACE-DIFF — exit 0, warn 1, dirty 2, 16 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 2, 16 lines |
| `ev7N` | `ev7T` | TRACE-DIFF — exit 0, warn 1, dirty 2, 23 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 2, 23 lines |
| `mt3` | `mt3T` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `mt3N` | `mt3T` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `mt2N` | `mt2T` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
