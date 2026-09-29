SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
MY=$SP/rev_r2_2dfk
D() { python3 "$SP/rev_r2_2dfk_drv.py" "$@"; }
C=$SP/rev_r2_cache
T1='^e2e-slice-(specialize-2file|multi-2file|specialize-select|spec-lift-quantum-base|classical-call-under-control)$'
T3='^e2e-slice-(libm-real-coshl|libm-real-atan2l|spec-qram-read|spec-qram-read-under-control|spec-qrom-read-arm-escape)$'
T4='^e2e-slice-(theta-add-measure|qq-hl-arith)$'
