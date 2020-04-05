add_library(curl INTERFACE)
target_include_directories(curl INTERFACE include)

if("${CMAKE_GENERATOR_PLATFORM}" STREQUAL "x64" OR "${CMAKE_GENERATOR}" STREQUAL "Ninja")
    target_link_libraries(curl INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/libs/64bit/libcurl.lib")
else()
    target_link_libraries(curl INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/libs/32bit/libcurl_x86.lib")
endif()
