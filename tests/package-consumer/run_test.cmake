if(NOT DEFINED cq_source_dir OR NOT DEFINED cq_build_dir)
  message(FATAL_ERROR "cq_source_dir and cq_build_dir are required")
endif()

set(work "${cq_build_dir}/package-install-test")
set(prefix "${work}/prefix")
set(consumer "${work}/consumer")
file(REMOVE_RECURSE "${work}")

set(install_command "${CMAKE_COMMAND}" --install "${cq_build_dir}"
                    --prefix "${prefix}")
if(cq_config)
  list(APPEND install_command --config "${cq_config}")
endif()
execute_process(COMMAND ${install_command} RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "CQ package installation failed: ${result}")
endif()
if(NOT EXISTS "${prefix}/bin/cqc")
  message(FATAL_ERROR "CQ package installation did not install bin/cqc")
endif()

set(package_dir "${prefix}/${cq_install_libdir}/cmake/CQ")
file(WRITE "${package_dir}/CQBackendSelection.cmake"
"# package_install_trace\n\
add_library(CQ::backend INTERFACE IMPORTED)\n\
set_property(TARGET CQ::backend PROPERTY\n\
             INTERFACE_LINK_LIBRARIES CQ::trace_backend)\n\
set(CQ_BACKEND_NAME \"trace\")\n")

execute_process(
  COMMAND "${CMAKE_COMMAND}"
          -S "${cq_source_dir}/tests/package-consumer"
          -B "${consumer}"
          "-DCMAKE_PREFIX_PATH=${prefix}"
          -DCQ_EXPECTED_BACKEND=trace
  RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "CQ package consumer configuration failed: ${result}")
endif()

set(build_command "${CMAKE_COMMAND}" --build "${consumer}")
if(cq_config)
  list(APPEND build_command --config "${cq_config}")
endif()
execute_process(COMMAND ${build_command} RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "CQ package consumer build failed: ${result}")
endif()

set(executable "${consumer}/cq_package_consumer")
if(cq_config AND EXISTS "${consumer}/${cq_config}/cq_package_consumer")
  set(executable "${consumer}/${cq_config}/cq_package_consumer")
endif()
execute_process(COMMAND "${executable}" RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "CQ package consumer failed: ${result}")
endif()
