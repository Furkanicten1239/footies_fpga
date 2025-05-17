#include <stdio.h>
#include <SDL.h>
#include <verilated.h>
#include "Vtop_game.h"

// Display resolution
const int H_RES = 640;
const int V_RES = 480;

// Pixel format for SDL texture (RGBA 32-bit)
typedef struct Pixel {
    uint8_t a, b, g, r;
} Pixel;

int main(int argc, char* argv[]) {
    Verilated::commandArgs(argc, argv);

    // ==== SDL INIT ====
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed\n");
        return 1;
    }

    // Allocate screen buffer and create SDL window
    Pixel screenbuffer[H_RES * V_RES] = {};

    SDL_Window* window = SDL_CreateWindow("10x10 Blue Square",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, H_RES, V_RES, SDL_WINDOW_SHOWN);

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_STREAMING, H_RES, V_RES);

    // ==== Instantiate and initialize Verilog module ====
    Vtop_game* top = new Vtop_game;

    top->sim_rst = 1;
    top->clk_pix = 0; top->eval();
    top->clk_pix = 1; top->eval();
    top->sim_rst = 0;
    top->clk_pix = 0; top->eval();

    // ==== Main Loop ====
    bool running = true;
    while (running) {
        // Clear inputs
        top->btn_up = 0;
        top->btn_dn = 0;
        top->btn_fire = 0;

        // Clear screen buffer to black
        memset(screenbuffer, 0, sizeof(screenbuffer));

        // Run one full frame: 640 * 480 pixels
        for (int i = 0; i < H_RES * V_RES; ++i) {
            // Toggle clock
            top->clk_pix = 1; top->eval();
            top->clk_pix = 0; top->eval();

            // Get pixel info from Verilog
            int x = top->sdl_sx;
            int y = top->sdl_sy;

            // If sdl_de (draw enable) is high, draw the pixel
            if (top->sdl_de && x < H_RES && y < V_RES) {
                Pixel* p = &screenbuffer[y * H_RES + x];
                p->a = 0xFF;
                p->r = top->sdl_r;
                p->g = top->sdl_g;
                p->b = top->sdl_b;
            }
        }

        // ==== SDL Render ====
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) running = false;
        }

        SDL_UpdateTexture(texture, NULL, screenbuffer, H_RES * sizeof(Pixel));
        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

    // ==== Cleanup ====
    top->final();
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
