#pragma once

#include "app_window.h"

#include <chrono>
#include <memory>
#include <string>
#include <vector>

class TimerManager {
public:
    struct TimerRecord {
        int id;
        std::string name;
        int64_t accumulated_ms = 0;
        bool is_running = false;
        std::chrono::steady_clock::time_point last_start {};

        int64_t get_elapsed_seconds() const;
    };

    struct RunningTimerInfo {
        int id;
        std::string name;
        int64_t elapsed_seconds;
    };

    explicit TimerManager(std::shared_ptr<slint::VectorModel<TimerData>> model);

    int add_timer(std::string name);
    void toggle_timer(int id);
    void reset_timer(int id);
    void remove_timer(int id);
    void tick_update();
    bool has_running_timers() const;
    size_t count() const;
    std::vector<RunningTimerInfo> get_running_timers() const;

    static std::string format_seconds(int64_t total_seconds);
    static std::string format_window_title(const std::string& name, int64_t elapsed_seconds);

private:
    TimerData to_timer_data(const TimerRecord& rec) const;
    std::vector<TimerRecord>::iterator find_record_it(int id);

    int m_next_id = 1;
    std::vector<TimerRecord> m_records;
    std::shared_ptr<slint::VectorModel<TimerData>> m_model;
};
