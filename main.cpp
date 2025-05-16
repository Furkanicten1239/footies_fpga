#include "Vfighting_game_vga.h"
#include "verilated.h"
#include <iostream>

vluint64_t main_time = 0; // global simulation time

double sc_time_stamp() { return main_time; }

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Vfighting_game_vga* top = new Vfighting_game_vga;

    // Başlangıç değerleri
    top->CLOCK_50 = 0;
    top->SW = 0b0000000000;   // reset = aktif (SW[0] = 0)
    top->KEY = 0b1111;        // tüm tuşlar serbest

    // 10 cycle reset tut
    for (int i = 0; i < 20; i++) {
        top->CLOCK_50 ^= 1;
        top->eval();
        main_time++;
    }

    top->SW = 0b0000000001; // reset = pasif

    // FSM test döngüsü (clock ilerletme)
    for (int t = 0; t < 5000; t++) {
        // Clock toggle
        top->CLOCK_50 ^= 1;
        top->eval();
        main_time++;

        // Her 2 cycle’da bir FSM clock ilerler (yaklaşık 60Hz)
        if (main_time % 100 == 0) {
            std::cout << "[Time " << main_time << "] ";
            std::cout << "State: " << (int)top->HEX0 << ", ";
            std::cout << "Health1: " << (int)top->HEX1 << ", ";
            std::cout << "Health2: " << (int)top->HEX2 << ", ";
            std::cout << "GameOver1: " << top->LEDR & 0x01 << ", ";
            std::cout << "GameOver2: " << (top->LEDR >> 1) & 0x01 << std::endl;
        }

        // Örnek senaryo: KEY[0] basılı (saldırı tuşu)
        if (main_time > 100 && main_time < 200)
            top->KEY = 0b1110; // KEY[0] = 0 (aktif low)
        else
            top->KEY = 0b1111;
    }

    top->final();
    delete top;
    return 0;
}
