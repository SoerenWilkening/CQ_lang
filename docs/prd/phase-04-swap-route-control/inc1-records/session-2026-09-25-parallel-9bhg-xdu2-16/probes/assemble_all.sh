#!/bin/bash
set -e
P=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/p9
A=$P/assemble.sh
bash $A rt1 taint_accept_spec_classical_return
bash $A rt2 taint_accept_spec_classical_return_arith
bash $A rt3 taint_accept_spec_classical_return_branch
bash $A ob1 taint_accept_spec_classical_return_clone_arg
bash $A rq1 taint_reject_spec_quantum_return_measure
bash $A rq2 taint_reject_spec_quantum_return_branch
bash $A rx1 taint_reject_quantum_return_mixed_spec
bash $A x taint_reject_scrubbed_handle_clone_arg $P/taint_reject_scrubbed_handle_clone_arg.body.ll
bash $A x taint_reject_scrubbed_handle_clone_arg_mixed $P/taint_reject_scrubbed_handle_clone_arg_mixed.body.ll
bash $A yo taint_reject_scrubbed_handle_clone_arg_layout
bash $A rs1 taint_reject_quantum_return_spec_seeded_theta
bash $A rm2 taint_reject_quantum_return_mixed_rets
bash $A fp3 spec_accept_fp_rebuilt_site_second_clone
