# minimum version necessary for cmake to work
cmake_minimum_required ( VERSION 2.8.12 )
project ( blink1-toys )

set ( CPACK_PACKAGE_VERSION_MAJOR 1 )
set ( CPACK_PACKAGE_VERSION_MINOR 0 )
set ( CPACK_PACKAGE_VERSION_PATCH "0SNAPSHOT" ) # dev versions are SNAPSHOT like java
set ( CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}" )

# Make the default build type Release
if ( NOT CMAKE_BUILD_TYPE )
  message ( STATUS "No build type selected, default to Release." )
  set( CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE )
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
    "MinSizeRel" "RelWithDebInfo")
endif ()

######################################################################
# look for dependencies
find_library( BLINK1_LIB libblink1.so ) #blink1-lib.h )
message( STATUS "${BLINK1_LIB}")

if(${CMAKE_VERSION} VERSION_GREATER 3.1.0 OR ${CMAKE_VERSION} VERSION_EQUAL 3.1.0)
  set(CMAKE_CXX_STANDARD 14)
  set(CMAKE_CXX_STANDARD_REQUIRED 11)
else()
  include(CheckCXXCompilerFlag)
  CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
  CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
  if(COMPILER_SUPPORTS_CXX14)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
  elseif(COMPILER_SUPPORTS_CXX11)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  endif()
endif()

set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSE_HIDAPI" )

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
