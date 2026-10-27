# cq-w0-tmpl-fenv: differential test of checker/rt/tmpl_fenv.c against native x86-64 code
# (native.c, clang-19 -O1 under FENV_ACCESS), an f16/bf16/wide-integer reference and the CR table.
# The family is linked directly with a test-only registry (mock_core.c), not with cqe_rt.
add_executable(tmpl_fenv_difftest
  difftest.c native.c mock_core.c ${CMAKE_SOURCE_DIR}/checker/rt/tmpl_fenv.c)
target_include_directories(tmpl_fenv_difftest PRIVATE ${CMAKE_SOURCE_DIR}/checker/rt)
set_target_properties(tmpl_fenv_difftest PROPERTIES C_STANDARD 17)
# native.c is the operation under comparison: exactly -O1, as the corpus compiles C.
set_source_files_properties(native.c PROPERTIES COMPILE_OPTIONS "-O1")
target_link_libraries(tmpl_fenv_difftest PRIVATE m)
add_test(NAME tmpl-fenv-difftest COMMAND tmpl_fenv_difftest 4000)
set_tests_properties(tmpl-fenv-difftest PROPERTIES TIMEOUT 1800)
