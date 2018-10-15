# --------------------------------------------------------------------------
# PlusApp
SET(PLUSBUILD_ADDITIONAL_SDK_ARGS)

IF(BUILDNAME)
  SET(PLUSBUILD_ADDITIONAL_SDK_ARGS ${PLUSBUILD_ADDITIONAL_SDK_ARGS}
    -DBUILDNAME:STRING=${BUILDNAME}
  )
ENDIF()

IF(NOT DEFINED(PLUSAPP_GIT_REPOSITORY))
  SET(PLUSAPP_GIT_REPOSITORY "${GIT_PROTOCOL}://github.com/PlusToolkit/PlusApp.git" CACHE STRING "Set PlusApp desired git url")
ENDIF()
IF(NOT DEFINED(PLUSAPP_GIT_REVISION))
  SET(PLUSAPP_GIT_REVISION "master" CACHE STRING "Set PlusApp desired git hash (master means latest)")
ENDIF()

IF(PLUSBUILD_DOCUMENTATION)
  LIST(APPEND PLUSBUILD_ADDITIONAL_SDK_ARGS
    -DPLUSAPP_DOCUMENTATION_SEARCH_SERVER_INDEXED:BOOL=${PLUSBUILD_DOCUMENTATION_SEARCH_SERVER_INDEXED}
    -DPLUSAPP_DOCUMENTATION_GOOGLE_ANALYTICS_TRACKING_ID:STRING=${PLUSBUILD_DOCUMENTATION_GOOGLE_ANALYTICS_TRACKING_ID}
    -DDOXYGEN_DOT_EXECUTABLE:FILEPATH=${DOXYGEN_DOT_EXECUTABLE}
    -DDOXYGEN_EXECUTABLE:FILEPATH=${DOXYGEN_EXECUTABLE}
    )
ENDIF()

SET (PLUS_PLUSAPP_DIR ${CMAKE_BINARY_DIR}/PlusApp CACHE INTERNAL "Path to store PlusApp contents.")
SET (PLUSAPP_DIR ${CMAKE_BINARY_DIR}/PlusApp-bin CACHE PATH "The directory containing PlusApp binaries" FORCE)                
ExternalProject_Add(PlusApp
  "${PLUSBUILD_EXTERNAL_PROJECT_CUSTOM_COMMANDS}"
  SOURCE_DIR "${PLUS_PLUSAPP_DIR}" 
  BINARY_DIR "${PLUSAPP_DIR}"
  #--Download step--------------
  GIT_REPOSITORY ${PLUSAPP_GIT_REPOSITORY}
  GIT_TAG ${PLUSAPP_GIT_REVISION}
  #--Configure step-------------
  CMAKE_ARGS 
    ${ep_common_args}
    ${ep_qt_args}
    -DGIT_EXECUTABLE:FILEPATH=${GIT_EXECUTABLE}
    -DGITCOMMAND:FILEPATH=${GITCOMMAND}
    -DCMAKE_MODULE_PATH:PATH=${CMAKE_MODULE_PATH}
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}
    -DPlusLib_DIR:PATH=${PLUSLIB_DIR}
    -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS}
    -DPLUSAPP_OFFLINE_BUILD:BOOL=${PLUSBUILD_OFFLINE_BUILD}
    -DPLUSAPP_BUILD_DiagnosticTools:BOOL=ON
    -DPLUSAPP_BUILD_fCal:BOOL=ON
    -DPLUSAPP_TEST_GUI:BOOL=${PLUSAPP_TEST_GUI}
    -DBUILD_DOCUMENTATION:BOOL=${PLUSBUILD_DOCUMENTATION}
    -DPLUSAPP_PACKAGE_EDITION:STRING=${PLUSAPP_PACKAGE_EDITION}
    -DPLUSBUILD_DOWNLOAD_PLUSLIBDATA:BOOL=${PLUSBUILD_DOWNLOAD_PLUSLIBDATA}
    -DCMAKE_CXX_FLAGS:STRING=${ep_common_cxx_flags}
    -DCMAKE_C_FLAGS:STRING=${ep_common_c_flags}
    ${PLUSBUILD_ADDITIONAL_SDK_ARGS}
  #--Build step-----------------
  BUILD_ALWAYS 1
  #--Install step-----------------
  INSTALL_COMMAND ""
  DEPENDS ${PlusApp_DEPENDENCIES}
  )

# --------------------------------------------------------------------------
# Copy Qt binaries to CMAKE_RUNTIME_OUTPUT_DIRECTORY

# Determine shared library extension without the dot (dll instead of .dll)
STRING(SUBSTRING ${CMAKE_SHARED_LIBRARY_SUFFIX} 1 -1 CMAKE_SHARED_LIBRARY_SUFFIX_NO_SEPARATOR)

# Get all Qt shared library names
SET(RELEASE_REGEX_PATTERN .t5.*[^d][.]${CMAKE_SHARED_LIBRARY_SUFFIX_NO_SEPARATOR})
SET(DEBUG_REGEX_PATTERN .t5.*d[.]${CMAKE_SHARED_LIBRARY_SUFFIX_NO_SEPARATOR})
SET(PDB_REGEX_PATTERN .t5.*d[.]pdb)

# Copy shared libraries to bin directory to allow running Plus applications in the build tree
IF(MSVC OR ${CMAKE_GENERATOR} MATCHES "Xcode")
  FILE(COPY "${QT_BINARY_DIR}/"
    DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Release
    FILES_MATCHING REGEX ${RELEASE_REGEX_PATTERN}
    )
  FILE(COPY "${QT_BINARY_DIR}/"
    DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug
    FILES_MATCHING REGEX ${DEBUG_REGEX_PATTERN}
    )
  IF(MSVC)
    FILE(COPY "${QT_BINARY_DIR}/"
      DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug
      FILES_MATCHING REGEX ${PDB_REGEX_PATTERN}
      )
  ENDIF()
ELSE()
  FILE(COPY "${QT_BINARY_DIR}/"
    DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
    FILES_MATCHING REGEX .*${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
ENDIF()