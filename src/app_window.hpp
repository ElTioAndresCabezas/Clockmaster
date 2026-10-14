#pragma once

#include "app_window.h"
#include "timer_manager.hpp"

#include <chrono>
#include <memory>
#include <string>

class AppWindow {
public:
    AppWindow();
    explicit AppWindow(std::shared_ptr<TimerManager> timer_manager,
                       std::shared_ptr<slint::VectorModel<TimerData>> model);
    ~AppWindow();

    int run();
    void show();
    void hide();

    void handle_add_timer(std::string name);
    void handle_toggle_timer(int id);
    void handle_reset_timer(int id);
    void handle_remove_timer(int id);

    std::shared_ptr<TimerManager> timer_manager() const;
    slint::ComponentHandle<MainWindow> ui_handle() const;

private:
    void setup_callbacks();
    void update_timer_state();
    void update_window_title();

    slint::ComponentHandle<MainWindow> m_ui;
    std::shared_ptr<slint::VectorModel<TimerData>> m_model;
    std::shared_ptr<TimerManager> m_timer_manager;
    slint::Timer m_refresh_timer;

    std::chrono::steady_clock::time_point m_last_title_rotation {};
    int m_current_title_timer_id = -1;
    std::string m_last_rendered_title;
};
