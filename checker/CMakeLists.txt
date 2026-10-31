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

# The checker's tool cache (cq-8m6v): the evaluator runtime objects, the probe runtime and the C
# oracle's plugin, prebuilt so that no example run pays for them (checker/cqcheck/prebuild.py). Every
# entry is keyed by its sources' content; the stamp only spares a rerun of the (cheap) check.
file(GLOB CQCHECK_TOOL_INPUTS CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/rt/*" "${CMAKE_CURRENT_SOURCE_DIR}/oracle/*"
     "${CMAKE_CURRENT_SOURCE_DIR}/cqcheck/*.py" "${CMAKE_CURRENT_SOURCE_DIR}/native/*"
     "${CMAKE_SOURCE_DIR}/pass/lib/taint/*" "${CMAKE_SOURCE_DIR}/pass/lib/spine/*"
     "${CMAKE_SOURCE_DIR}/pass/lib/abi/*" "${CMAKE_SOURCE_DIR}/pass/lib/Common.cpp"
     "${CMAKE_SOURCE_DIR}/pass/include/*")
add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/cqcheck-tools/prebuild.stamp"
  COMMAND ${CMAKE_COMMAND} -E env "CQ_BUILD_DIR=${CMAKE_BINARY_DIR}"
          ${Python3_EXECUTABLE} -m cqcheck.prebuild
  COMMAND ${CMAKE_COMMAND} -E touch "${CMAKE_BINARY_DIR}/cqcheck-tools/prebuild.stamp"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  DEPENDS ${CQCHECK_TOOL_INPUTS}
  COMMENT "cqcheck: prebuilding the checker's tool cache")
add_custom_target(cqcheck_tools ALL DEPENDS "${CMAKE_BINARY_DIR}/cqcheck-tools/prebuild.stamp")
