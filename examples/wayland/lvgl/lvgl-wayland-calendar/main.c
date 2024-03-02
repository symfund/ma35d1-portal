#include <sys/time.h>
#include "lvgl/lvgl.h"
#include "lv_drivers/wayland/wayland.h"

static void event_handler(lv_event_t * e)
{
    lv_event_code_t code = lv_event_get_code(e);
    lv_obj_t * obj = lv_event_get_current_target(e);

    if(code == LV_EVENT_VALUE_CHANGED) {
        lv_calendar_date_t date;
        if(lv_calendar_get_pressed_date(obj, &date)) {
            LV_LOG_USER("Clicked date: %02d.%02d.%d", date.day, date.month, date.year);
        }
    }
}

void lv_example_calendar_1(void)
{
    /*transparent background*/
    lv_obj_t *scr = lv_scr_act();
    lv_obj_set_style_bg_opa(scr, LV_OPA_COVER, 0);

    lv_obj_t *calendar = lv_calendar_create(scr);
    lv_obj_set_style_bg_opa(calendar, LV_OPA_COVER, 0);

    lv_obj_set_size(calendar, 600, 300);
    lv_obj_align(calendar, LV_ALIGN_CENTER, 0, 0);
    lv_obj_add_event_cb(calendar, event_handler, LV_EVENT_ALL, NULL);

    lv_calendar_set_today_date(calendar, 2024, 01, 26);
    lv_calendar_set_showed_date(calendar, 2024, 01);

    lv_calendar_header_arrow_create(calendar);
}

int main(void)
{
    lv_disp_t *disp = NULL;
    bool open = true;

    /* intiate LVGL */
    lv_init();

    /* initiate Wayland for LVGL */
    lv_wayland_init();

    disp = lv_wayland_create_window(640, 360, "LVGL calendar with Wayland", NULL);

    lv_example_calendar_1();

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
