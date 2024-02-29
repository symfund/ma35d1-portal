#include <sys/time.h>
#include "lvgl/lvgl.h"
#include "lv_drivers/wayland/wayland.h"

int main(void)
{
    lv_disp_t *disp = NULL;
    bool open = true;

    /* intiate LVGL */
    lv_init();

    /* initiate Wayland for LVGL */
    lv_wayland_init();

    disp = lv_wayland_create_window(640, 360, "LVGL minimal with Wayland", NULL);

    while (open) {
        lv_timer_handler();
        usleep(5000);
        open = lv_wayland_window_is_open(disp);
    }

    lv_wayland_deinit();

    return 0;
}

/*Set in lv_conf.h as `LV_TICK_CUSTOM_SYS_TIME_EXPR`*/
uint32_t custom_tick_get(void)
{
    static uint64_t start_ms = 0;
    if(start_ms == 0) {
        struct timeval tv_start;
        gettimeofday(&tv_start, NULL);
        start_ms = (tv_start.tv_sec * 1000000 + tv_start.tv_usec) / 1000;
    }

    struct timeval tv_now;
    gettimeofday(&tv_now, NULL);
    uint64_t now_ms;
    now_ms = (tv_now.tv_sec * 1000000 + tv_now.tv_usec) / 1000;

    uint32_t time_ms = now_ms - start_ms;
    return time_ms;
}
