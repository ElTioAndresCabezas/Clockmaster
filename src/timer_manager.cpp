#include "timer_manager.hpp"

#include <algorithm>
#include <iomanip>
#include <sstream>

int64_t TimerManager::TimerRecord::get_elapsed_seconds() const {
    int64_t total_ms = accumulated_ms;
    if (is_running) {
        auto now = std::chrono::steady_clock::now();
        total_ms += std::chrono::duration_cast<std::chrono::milliseconds>(now - last_start).count();
    }
    return total_ms / 1000;
}

TimerManager::TimerManager(std::shared_ptr<slint::VectorModel<TimerData>> model)
    : m_model(std::move(model)) {}

int TimerManager::add_timer(std::string name) {
    // Eliminar espacios en blanco en los extremos
    name.erase(0, name.find_first_not_of(" \t\n\r"));
    auto last_non_space = name.find_last_not_of(" \t\n\r");
    if (last_non_space != std::string::npos) {
        name.erase(last_non_space + 1);
    } else {
        name.clear();
    }

    if (name.empty()) {
        name = "Tarea " + std::to_string(m_next_id);
    }

    TimerRecord rec;
    rec.id = m_next_id++;
    rec.name = name;
    rec.accumulated_ms = 0;
    rec.is_running = false;

    m_records.push_back(rec);
    m_model->push_back(to_timer_data(rec));
    return rec.id;
}

void TimerManager::toggle_timer(int id) {
    auto it = find_record_it(id);
    if (it == m_records.end()) {
        return;
    }

    size_t index = std::distance(m_records.begin(), it);
    auto now = std::chrono::steady_clock::now();

    if (it->is_running) {
        it->accumulated_ms += std::chrono::duration_cast<std::chrono::milliseconds>(now - it->last_start).count();
        it->is_running = false;
    } else {
        it->last_start = now;
        it->is_running = true;
    }

    m_model->set_row_data(index, to_timer_data(*it));
}

void TimerManager::reset_timer(int id) {
    auto it = find_record_it(id);
    if (it == m_records.end()) {
        return;
    }

    size_t index = std::distance(m_records.begin(), it);
    it->accumulated_ms = 0;
    if (it->is_running) {
        it->last_start = std::chrono::steady_clock::now();
    }

    m_model->set_row_data(index, to_timer_data(*it));
}

void TimerManager::remove_timer(int id) {
    auto it = find_record_it(id);
    if (it == m_records.end()) {
        return;
    }

    size_t index = std::distance(m_records.begin(), it);
    m_records.erase(it);
    m_model->erase(index);
}

void TimerManager::tick_update() {
    for (size_t i = 0; i < m_records.size(); ++i) {
        if (m_records[i].is_running) {
            m_model->set_row_data(i, to_timer_data(m_records[i]));
        }
    }
}

bool TimerManager::has_running_timers() const {
    return std::any_of(m_records.begin(), m_records.end(), [](const TimerRecord& rec) {
        return rec.is_running;
    });
}

size_t TimerManager::count() const {
    return m_records.size();
}

std::vector<TimerManager::RunningTimerInfo> TimerManager::get_running_timers() const {
    std::vector<RunningTimerInfo> running;
    for (const auto& rec : m_records) {
        if (rec.is_running) {
            running.push_back({rec.id, rec.name, rec.get_elapsed_seconds()});
        }
    }
    return running;
}

std::string TimerManager::format_window_title(const std::string& name, int64_t elapsed_seconds) {
    if (name.empty()) {
        return "Clockmaster";
    }
    return "[" + format_seconds(elapsed_seconds) + "] " + name + " - Clockmaster";
}

std::string TimerManager::format_seconds(int64_t total_seconds) {
    int64_t hours = total_seconds / 3600;
    int64_t minutes = (total_seconds % 3600) / 60;
    int64_t seconds = total_seconds % 60;

    std::ostringstream oss;
    oss << std::setfill('0') << std::setw(2) << hours << ":"
        << std::setfill('0') << std::setw(2) << minutes << ":"
        << std::setfill('0') << std::setw(2) << seconds;
    return oss.str();
}

TimerData TimerManager::to_timer_data(const TimerRecord& rec) const {
    TimerData data;
    data.id = rec.id;
    data.name = slint::SharedString(rec.name);
    data.time_display = slint::SharedString(format_seconds(rec.get_elapsed_seconds()));
    data.is_running = rec.is_running;
    return data;
}

std::vector<TimerManager::TimerRecord>::iterator TimerManager::find_record_it(int id) {
    return std::find_if(m_records.begin(), m_records.end(), [id](const TimerRecord& rec) {
        return rec.id == id;
    });
}
