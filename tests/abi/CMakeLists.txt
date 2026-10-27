# Module abi (cq-w0-abi). Unit tests of Abi.h and Common.h's type helpers, and the corpus check:
# every cqrt_*/cq_template_*/__cq_q_* function of every examples/*/*.lowered.ll parses, names back
# to itself, and (templates and core gates) declares with the corpus signature.
cq_add_unit_test(abi_unit abi_unit.cpp)

add_executable(abi_corpus abi_corpus.cpp)
target_link_libraries(abi_corpus PRIVATE cq_pass_objs LLVM)
add_test(NAME abi_corpus COMMAND abi_corpus ${CQ_SPEC_DIR}/examples)
