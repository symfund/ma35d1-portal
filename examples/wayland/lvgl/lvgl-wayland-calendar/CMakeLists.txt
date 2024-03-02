cmake_minimum_required(VERSION 3.5)

project(lvgl-wayland-calendar LANGUAGES C)

set(CMAKE_SYSROOT "/path/to/sysroot")
include_directories(${CMAKE_SYSROOT}/usr/include/lvgl/lv_drivers)

#add_compile_definitions(LV_LVGL_H_INCLUDE_SIMPLE)

# Shared Library without prefix 'lib'
set( LINK_LIBS lvgl.so lv_drivers.so )
link_directories(${CMAKE_SYSROOT}/usr/lib)

add_executable(${PROJECT_NAME} main.c)
target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})

include(GNUInstallDirs)
install(TARGETS lvgl-wayland-calendar
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
