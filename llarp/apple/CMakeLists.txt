
# 3.13+ so that we can add link libraries to parent targets
cmake_minimum_required(VERSION 3.13)

if (BUILD_SHARED_LIBS OR NOT BUILD_STATIC_DEPS OR NOT STATIC_LINK)
  message(FATAL_ERROR "macOS builds require a full static build; perhaps use the contrib/macos.sh script to build?")
endif()

# god made apple so that man may suffer

find_library(FOUNDATION Foundation REQUIRED)
find_library(NETEXT NetworkExtension REQUIRED)
find_library(COREFOUNDATION CoreFoundation REQUIRED)

target_sources(lokinet-util PRIVATE apple_logger.cpp)
target_link_libraries(lokinet-util PUBLIC ${FOUNDATION})

target_sources(lokinet-platform PRIVATE vpn_platform.cpp vpn_interface.cpp route_manager.cpp context_wrapper.cpp)

add_executable(lokinet-extension MACOSX_BUNDLE
  PacketTunnelProvider.m
  DNSTrampoline.m
  )
enable_lto(lokinet-extension)
target_link_libraries(lokinet-extension PRIVATE
  liblokinet
  ${COREFOUNDATION}
  ${NETEXT})

# Not sure what -fapplication-extension does, but XCode puts it in so...
# -fobjc-arc enables automatic reference counting for objective-C code
# -e _NSExtensionMain because the appex has that instead of a `main` function entry point, of course.
target_compile_options(lokinet-extension PRIVATE -fapplication-extension -fobjc-arc)
target_link_options(lokinet-extension PRIVATE -fapplication-extension -e _NSExtensionMain)

target_link_libraries(lokinet-extension PUBLIC
  liblokinet
  ${COREFOUNDATION}
  ${NETEXT})

set_target_properties(lokinet-extension PROPERTIES
  BUNDLE TRUE
  BUNDLE_EXTENSION appex
  MACOSX_BUNDLE_INFO_PLIST ${PROJECT_SOURCE_DIR}/contrib/macos/LokinetExtension.Info.plist.in
  XCODE_PRODUCT_TYPE com.apple.product-type.app-extension
  )

add_custom_command(TARGET lokinet-extension
  POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/contrib/macos/lokinet-extension.provisionprofile
  $<TARGET_BUNDLE_DIR:lokinet-extension>/Contents/embedded.provisionprofile
  )
