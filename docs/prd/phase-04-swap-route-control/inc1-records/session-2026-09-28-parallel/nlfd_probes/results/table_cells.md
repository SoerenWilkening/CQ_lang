| subject | twin | ORACLE | SUBJECT |
|---|---|---|---|
| `i_arg_mt_ns_cd` | `iT_arg_cd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_arg_mt_ns_pd` | `iT_arg_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_arg_mt_ns_lv` | `iT_arg_lv` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines ⟵ |
| `i_arg_mt_nn_cd` | `iT_arg_cd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `i_arg_mt_nn_pd` | `iT_arg_pd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `i_arg_mt_nn_lv` | `iT_arg_lv` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines ⟵ |
| `i_arg_tc_ns_cd` | `iT_arg_cd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_arg_tc_ns_pd` | `iT_arg_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_arg_tc_ns_lv` | `iT_arg_lv` | TRACE-DIFF — exit 0, warn 1, dirty 1, 25 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines |
| `i_arg_tc_nn_cd` | `iT_arg_cd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `i_arg_tc_nn_pd` | `iT_arg_pd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `i_arg_tc_nn_lv` | `iT_arg_lv` | TRACE-DIFF — exit 0, warn 1, dirty 1, 25 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines |
| `i_inst_mt_ns_cd` | `iT_inst_cd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_inst_mt_ns_pd` | `iT_inst_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_inst_mt_ns_lv` | `iT_inst_lv` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 28 lines ⟵ |
| `i_inst_mt_nn_cd` | `iT_inst_cd` | VERDICT-DIFF — ABORT (exit 134) | **VERDICT-DIFF** — decline: cq specialization: quantum argument to a parameter the lifted callee n |
| `i_inst_mt_nn_pd` | `iT_inst_pd` | VERDICT-DIFF — ABORT (exit 134) | **VERDICT-DIFF** — decline: cq specialization: quantum argument to a parameter the lifted callee n |
| `i_inst_mt_nn_lv` | `iT_inst_lv` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 28 lines ⟵ |
| `i_inst_tc_ns_cd` | `iT_inst_cd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_inst_tc_ns_pd` | `iT_inst_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_inst_tc_ns_lv` | `iT_inst_lv` | TRACE-DIFF — exit 0, warn 1, dirty 1, 28 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 28 lines |
| `i_inst_tc_nn_cd` | `iT_inst_cd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 15 lines | **VERDICT-DIFF** — decline: cq specialization: quantum argument to a parameter the lifted callee n ⟵ |
| `i_inst_tc_nn_pd` | `iT_inst_pd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 15 lines | **VERDICT-DIFF** — decline: cq specialization: quantum argument to a parameter the lifted callee n ⟵ |
| `i_inst_tc_nn_lv` | `iT_inst_lv` | TRACE-DIFF — exit 0, warn 1, dirty 1, 28 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 28 lines |
| `m_arg_mt_ns_cd` | `mT_arg_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_mt_ns_pd` | `mT_arg_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `m_arg_mt_ns_lv` | `mT_arg_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_mt_nn_cd` | `mT_arg_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_mt_nn_pd` | `mT_arg_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_mt_nn_lv` | `mT_arg_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_ns_cd` | `mT_arg_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_ns_pd` | `mT_arg_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines |
| `m_arg_tc_ns_lv` | `mT_arg_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_nn_cd` | `mT_arg_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_nn_pd` | `mT_arg_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_nn_lv` | `mT_arg_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_ns_cd` | `mT_inst_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_ns_pd` | `mT_inst_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `m_inst_mt_ns_lv` | `mT_inst_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_nn_cd` | `mT_inst_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_nn_pd` | `mT_inst_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_nn_lv` | `mT_inst_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_ns_cd` | `mT_inst_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_ns_pd` | `mT_inst_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines |
| `m_inst_tc_ns_lv` | `mT_inst_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_nn_cd` | `mT_inst_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_nn_pd` | `mT_inst_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_nn_lv` | `mT_inst_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
