| subject | twin | ORACLE | SUBJECT |
|---|---|---|---|
| `sa1` | `mtT` | TRACE-IDENT — exit 0, warn 1, dirty 1, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 1, 14 lines |
| `mt1` | `mtT` | TRACE-IDENT — exit 0, warn 0, dirty 1, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `mtN` | `mtT` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `mm1` | `mmT` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `mmN` | `mmT` | TRACE-IDENT — exit 0, warn 0, dirty 0, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines |
| `mt2` | `mt2T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
