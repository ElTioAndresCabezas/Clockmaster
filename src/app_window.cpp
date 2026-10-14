#include "app_window.hpp"

#include <algorithm>
#include <chrono>
#include <utility>

AppWindow::AppWindow()
    : m_ui(MainWindow::create()),
      m_model(std::make_shared<slint::VectorModel<TimerData>>()),
      m_timer_manager(std::make_shared<TimerManager>(m_model)) {
    m_ui->set_timers(m_model);
    setup_callbacks();
}

AppWindow::AppWindow(std::shared_ptr<TimerManager> timer_manager,
                     std::shared_ptr<slint::VectorModel<TimerData>> model)
    : m_ui(MainWindow::create()),
      m_model(std::move(model)),
      m_timer_manager(std::move(timer_manager)) {
    m_ui->set_timers(m_model);
    setup_callbacks();
}

AppWindow::~AppWindow() {
    if (m_refresh_timer.running()) {
        m_refresh_timer.stop();
    }
}

int AppWindow::run() {
    m_ui->run();
    return 0;
}

void AppWindow::show() {
    m_ui->show();
}

void AppWindow::hide() {
    m_ui->hide();
}

void AppWindow::handle_add_timer(std::string name) {
    m_timer_manager->add_timer(std::move(name));
}

void AppWindow::handle_toggle_timer(int id) {
    m_timer_manager->toggle_timer(id);
    update_timer_state();
}

void AppWindow::handle_reset_timer(int id) {
    m_timer_manager->reset_timer(id);
    update_timer_state();
}

void AppWindow::handle_remove_timer(int id) {
    m_timer_manager->remove_timer(id);
    update_timer_state();
}

std::shared_ptr<TimerManager> AppWindow::timer_manager() const {
    return m_timer_manager;
}

slint::ComponentHandle<MainWindow> AppWindow::ui_handle() const {
    return m_ui;
}

void AppWindow::setup_callbacks() {
    m_ui->on_add_timer([this](slint::SharedString name) {
        handle_add_timer(std::string(name));
    });

    m_ui->on_toggle_timer([this](int id) {
        handle_toggle_timer(id);
    });

    m_ui->on_reset_timer([this](int id) {
        handle_reset_timer(id);
    });

    m_ui->on_remove_timer([this](int id) {
        handle_remove_timer(id);
    });
}

void AppWindow::update_timer_state() {
    if (m_timer_manager->has_running_timers()) {
        if (!m_refresh_timer.running()) {
            m_refresh_timer.start(
                slint::TimerMode::Repeated,
                std::chrono::milliseconds(250),
                [this]() {
                    m_timer_manager->tick_update();
                    update_window_title();
                }
            );
        }
        update_window_title();
    } else {
        if (m_refresh_timer.running()) {
            m_refresh_timer.stop();
        }
        update_window_title();
    }
}

void AppWindow::update_window_title() {
    const std::string default_title = "Clockmaster";
    auto running = m_timer_manager->get_running_timers();

    if (running.empty()) {
        m_current_title_timer_id = -1;
        if (m_last_rendered_title != default_title) {
            m_last_rendered_title = default_title;
            m_ui->set_window_title(slint::SharedString(default_title));
        }
        return;
    }

    auto now = std::chrono::steady_clock::now();
    static constexpr std::chrono::seconds ROTATION_INTERVAL { 3 };

    if (running.size() == 1) {
        m_current_title_timer_id = running[0].id;
        std::string title = TimerManager::format_window_title(running[0].name, running[0].elapsed_seconds);
        if (m_last_rendered_title != title) {
            m_last_rendered_title = title;
            m_ui->set_window_title(slint::SharedString(title));
        }
        return;
    }

    // Rotación entre múltiples cronómetros activos
    auto it = std::find_if(running.begin(), running.end(), [this](const auto& item) {
        return item.id == m_current_title_timer_id;
    });

    if (it == running.end()) {
        it = running.begin();
        m_current_title_timer_id = it->id;
        m_last_title_rotation = now;
    } else if (now - m_last_title_rotation >= ROTATION_INTERVAL) {
        size_t cur_idx = std::distance(running.begin(), it);
        size_t next_idx = (cur_idx + 1) % running.size();
        it = running.begin() + next_idx;
        m_current_title_timer_id = it->id;
        m_last_title_rotation = now;
    }

    std::string title = TimerManager::format_window_title(it->name, it->elapsed_seconds);
    if (m_last_rendered_title != title) {
        m_last_rendered_title = title;
        m_ui->set_window_title(slint::SharedString(title));
    }
}

