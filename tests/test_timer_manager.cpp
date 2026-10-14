#include "timer_manager.hpp"

#include <cassert>
#include <iostream>
#include <memory>

void test_format_seconds() {
    assert(TimerManager::format_seconds(0) == "00:00:00");
    assert(TimerManager::format_seconds(5) == "00:00:05");
    assert(TimerManager::format_seconds(59) == "00:00:59");
    assert(TimerManager::format_seconds(60) == "00:01:00");
    assert(TimerManager::format_seconds(61) == "00:01:01");
    assert(TimerManager::format_seconds(3599) == "00:59:59");
    assert(TimerManager::format_seconds(3600) == "01:00:00");
    assert(TimerManager::format_seconds(3661) == "01:01:01");
    assert(TimerManager::format_seconds(86400) == "24:00:00");
    std::cout << "[PASS] test_format_seconds\n";
}

void test_format_window_title() {
    assert(TimerManager::format_window_title("", 0) == "Clockmaster");
    assert(TimerManager::format_window_title("Tarea 1", 0) == "[00:00:00] Tarea 1 - Clockmaster");
    assert(TimerManager::format_window_title("Tarea 1", 75) == "[00:01:15] Tarea 1 - Clockmaster");
    assert(TimerManager::format_window_title("Desarrollo", 3661) == "[01:01:01] Desarrollo - Clockmaster");
    std::cout << "[PASS] test_format_window_title\n";
}

void test_timer_manager_running_list() {
    auto model = std::make_shared<slint::VectorModel<TimerData>>();
    TimerManager manager(model);

    assert(manager.count() == 0);
    assert(!manager.has_running_timers());
    assert(manager.get_running_timers().empty());

    // Agregar cronómetro
    int id1 = manager.add_timer("Tarea Alpha");
    assert(manager.count() == 1);
    assert(!manager.has_running_timers());
    assert(manager.get_running_timers().empty());

    // Iniciar cronómetro 1
    manager.toggle_timer(id1);
    assert(manager.has_running_timers());
    auto running = manager.get_running_timers();
    assert(running.size() == 1);
    assert(running[0].id == id1);
    assert(running[0].name == "Tarea Alpha");

    // Agregar e iniciar segundo cronómetro
    int id2 = manager.add_timer("Tarea Beta");
    assert(manager.count() == 2);
    assert(manager.get_running_timers().size() == 1);

    manager.toggle_timer(id2);
    running = manager.get_running_timers();
    assert(running.size() == 2);
    assert(running[0].id == id1);
    assert(running[1].id == id2);
    assert(running[1].name == "Tarea Beta");

    // Pausar el cronómetro 1
    manager.toggle_timer(id1);
    assert(manager.has_running_timers());
    running = manager.get_running_timers();
    assert(running.size() == 1);
    assert(running[0].id == id2);
    assert(running[0].name == "Tarea Beta");

    // Pausar el cronómetro 2
    manager.toggle_timer(id2);
    assert(!manager.has_running_timers());
    assert(manager.get_running_timers().empty());

    // Eliminar cronómetro
    manager.remove_timer(id1);
    assert(manager.count() == 1);

    std::cout << "[PASS] test_timer_manager_running_list\n";
}

int main() {
    std::cout << "--- Ejecutando pruebas unitarias de Clockmaster ---\n";
    test_format_seconds();
    test_format_window_title();
    test_timer_manager_running_list();
    std::cout << "--- Todas las pruebas pasaron exitosamente ---\n";
    return 0;
}
