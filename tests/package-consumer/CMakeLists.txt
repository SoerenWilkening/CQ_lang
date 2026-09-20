cmake_minimum_required(VERSION 3.20)
project(cq_package_consumer C)

find_package(CQ CONFIG REQUIRED)

if(NOT TARGET CQ::backend)
    message(FATAL_ERROR "CQ installation has no selected CQ::backend")
endif()
if(DEFINED CQ_EXPECTED_BACKEND AND
   NOT CQ_BACKEND_NAME STREQUAL CQ_EXPECTED_BACKEND)
    message(FATAL_ERROR
        "selected backend is ${CQ_BACKEND_NAME}, expected ${CQ_EXPECTED_BACKEND}")
endif()

add_executable(cq_package_consumer main.c)
target_link_libraries(cq_package_consumer PRIVATE CQ::backend)
