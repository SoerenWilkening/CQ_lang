# Sourced by <experiment>/run.sh. cq_run <cqcc inputs and flags...>: one executable from the given
# sources, with the C library and SoftFloat taken precompiled (../build_lib.sh) and the counting
# backend; then runs it and prints gates, depth and qubits.
cq_run() {
    E=$(cd .. && pwd)
    test -s "$E/lib/libqc.a" || { echo "run ../build_lib.sh first" >&2; exit 1; }
    mkdir -p build
    echo "== lower and link"
    time "$E/../driver/cqcc" "$@" -include math.h -w --cq-roots "$E/lib/libc.roots" \
        --backend "-L$E/lib" --backend -lqc \
        --backend "-L$E/lib/backend" --backend -lcq_backend --backend -lcq_gates_count \
        --save-temps build/tmp -o build/q
    echo "== build the circuit and count"
    time env CQ_COUNT=build/counts.txt build/q || true      # exit status is the measured value
    cat build/counts.txt
}
