# minimum version necessary for cmake to work
cmake_minimum_required ( VERSION 2.8.12 )
project ( blink1-toys )

set ( CPACK_PACKAGE_VERSION_MAJOR 1 )
set ( CPACK_PACKAGE_VERSION_MINOR 0 )
set ( CPACK_PACKAGE_VERSION_PATCH "0SNAPSHOT" ) # dev versions are SNAPSHOT like java
set ( CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}" )

######################################################################
# look for dependencies
find_library( BLINK1_LIB libblink1.so ) #blink1-lib.h )
message( STATUS "${BLINK1_LIB}")

set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSE_HIDAPI -std=c++0x" )

######################################################################
# files to use for building
set ( SRC_FILES
      clock-blink1.cpp )

include_directories(${CMAKE_CURRENT_BINARY_DIR})
add_executable( clock-blink1 MACOSX_BUNDLE ${SRC_FILES} )
target_link_libraries ( clock-blink1 ${BLINK1_LIB} )

INSTALL(TARGETS clock-blink1
    BUNDLE DESTINATION . COMPONENT Runtime
    RUNTIME DESTINATION bin COMPONENT Runtime
    )

include (CPack) # have cpack do its thing
