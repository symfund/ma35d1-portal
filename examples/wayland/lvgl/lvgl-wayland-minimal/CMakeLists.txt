cmake_minimum_required(VERSION 3.5)

project(lvgl-wayland-minimal LANGUAGES C)

# Change ${BR2_DIR} to actual path where Buildroot is located at.
set(BR2_DIR "/home/arthur/Projects/buildroot-2021.02.6-ma35xx/")
set(CMAKE_SYSROOT "${BR2_DIR}/output/host/aarch64-nuvoton-linux-gnu/sysroot")
include_directories(${CMAKE_SYSROOT}/usr/include/lvgl/lv_drivers)

#add_compile_definitions(LV_LVGL_H_INCLUDE_SIMPLE)

# Shared Library without prefix 'lib'
set( LINK_LIBS lvgl.so lv_drivers.so )
link_directories(${CMAKE_SYSROOT}/usr/lib)

add_executable(${PROJECT_NAME} main.c)
target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})

include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
