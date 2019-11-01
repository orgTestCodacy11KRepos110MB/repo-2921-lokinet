set(EXE lokinet)
set(EXE_SRC main.cpp)
set(CTL lokinetctl)
set(CTL_SRC lokinetctl.cpp)

if(TRACY_ROOT)
    list(APPEND EXE_SRC ${TRACY_ROOT}/TracyClient.cpp)
endif()

if(SHADOW)
    set(LOKINET_SHADOW shadow-plugin-${SHARED_LIB})
    set(LOKINET_SHADOW_LIBS ${SHARED_LIB})
    add_shadow_plugin(${LOKINET_SHADOW} ${EXE_SRC})
    target_link_libraries(${LOKINET_SHADOW} ${LOKINET_SHADOW_LIBS})
    target_include_directories(${LOKINET_SHADOW} PUBLIC ${PROJECT_SOURCE_DIR}/include ${PROJECT_SOURCE_DIR}/llarp ${PROJECT_SOURCE_DIR}/crypto/include)
else()
    if(WIN32 AND NOT MSVC_VERSION)
        list(APPEND ${EXE_SRC} ../llarp/win32/version.rc)
        list(APPEND ${CTL_SRC} ../llarp/win32/version.rc)
    endif()

    add_executable(${EXE} ${EXE_SRC})
    add_executable(${CTL} ${CTL_SRC})

    add_log_tag(${EXE})
    add_log_tag(${CTL})

    install(TARGETS ${EXE} RUNTIME DESTINATION bin)
    install(TARGETS ${CTL} RUNTIME DESTINATION bin)
    if(WIN32)
        install(PROGRAMS ${CMAKE_SOURCE_DIR}/lokinet-bootstrap.exe DESTINATION bin)
    else()
        install(PROGRAMS ${CMAKE_SOURCE_DIR}/lokinet-bootstrap DESTINATION bin)
    endif()

    if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        install(CODE "execute_process(COMMAND setcap cap_net_admin,cap_net_bind_service=+eip ${CMAKE_INSTALL_PREFIX}/bin/lokinet)")
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
        target_link_directories(${EXE} PRIVATE /usr/local/lib)
        target_link_directories(${CTL} PRIVATE /usr/local/lib)
    endif()
    target_link_libraries(${EXE} PUBLIC ${EXE_LIBS} ${LIBS})
    target_link_libraries(${CTL} PUBLIC ${EXE_LIBS} ${LIBS})

    find_package(CURL)

    if(CURL_FOUND)
        target_include_directories(${CTL} PRIVATE ${CURL_INCLUDE_DIRS})
        target_link_libraries(${CTL} PRIVATE ${CURL_LIBRARIES})
        target_compile_definitions(${CTL} PRIVATE -DWITH_CURL=1)
    endif(CURL_FOUND)

endif(SHADOW)