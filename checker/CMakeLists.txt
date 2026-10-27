# The checker runtime (scaffold): every checker/rt/*.c, C17. Adding a family file
# (checker/rt/tmpl_*.c, rt_*.c) never touches this file.
#
# An OBJECT library, not a static archive (cq-f69): each family registers only from an
# __attribute__((constructor)) function that nothing references, and a linker drops an archive
# member nothing references, so linking an archive would silently lose families unless every
# consumer remembered -force_load / --whole-archive. A target that links cqe_rt gets every object.
# checker/cqcheck/run.py does the same outside CMake: it links every checker/rt/*.c as objects.
file(GLOB CQE_RT_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/rt/*.c")
add_library(cqe_rt OBJECT ${CQE_RT_SOURCES})
target_include_directories(cqe_rt PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/rt")
set_target_properties(cqe_rt PROPERTIES C_STANDARD 17 C_STANDARD_REQUIRED ON POSITION_INDEPENDENT_CODE ON)
target_compile_options(cqe_rt PRIVATE -Wall -Wextra)
