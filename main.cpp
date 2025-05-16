// Verilator + SDL Simulation for Fighting Game
#include <stdio.h>
#include <SDL.h>
#include <verilated.h>
#include "Vtop_game.h"

// VGA resolution
const int H_RES = 640;
const int V_RES = 480;

// SDL pixel format
typedef struct Pixel {
    uint8_t a;  // alpha
    uint8_t b;  // blue
    uint8_t g;  // green
    uint8_t r;  // red
} Pixel;

int main(int argc, char* argv[]) {
    Verilated::commandArgs(argc, argv);

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed: %s\n", SDL_GetError());
        return 1;
    }

    Pixel screenbuffer[H_RES * V_RES];

    SDL_Window* window = SDL_CreateWindow("Fighting Game VGA",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, H_RES, V_RES, SDL_WINDOW_SHOWN);
    if (!window) {
        printf("Window creation failed: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!renderer) {
        printf("Renderer creation failed: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_TARGET, H_RES, V_RES);
    if (!texture) {
        printf("Texture creation failed: %s\n", SDL_GetError());
        return 1;
    }

    const Uint8* keyb_state = SDL_GetKeyboardState(NULL);
    printf("Simulation running. Press 'Q' in window to quit.\n");

    Vtop_game* top = new Vtop_game;

    // Reset sequence
    top->sim_rst = 1;
    top->clk_pix = 0; top->eval();
    top->clk_pix = 1; top->eval();
    top->sim_rst = 0;
    top->clk_pix = 0; top->eval();

    uint64_t frame_count = 0;
    uint64_t start_ticks = SDL_GetPerformanceCounter();

    while (1) {
        // Clock step
        top->clk_pix = 1; top->eval();
        top->clk_pix = 0; top->eval();

// FORCE GREEN RECTANGLE CENTER OF SCREEN (just to test rendering path)
for (int y = 200; y < 280; y++) {
    for (int x = 270; x < 370; x++) {
        Pixel* p = &screenbuffer[y * H_RES + x];
        p->a = 0xFF;
        p->r = 0;
        p->g = 255;
        p->b = 0;
    }
}


        // Sync at end of frame
        if (top->sdl_sy == V_RES && top->sdl_sx == 0) {
            SDL_Event e;
            if (SDL_PollEvent(&e) && e.type == SDL_QUIT) break;
            if (keyb_state[SDL_SCANCODE_Q]) break;

            // Update inputs from keyboard
            top->btn_up   = keyb_state[SDL_SCANCODE_UP];
            top->btn_dn   = keyb_state[SDL_SCANCODE_DOWN];
            top->btn_fire = keyb_state[SDL_SCANCODE_SPACE];

            // Render frame
            SDL_UpdateTexture(texture, NULL, screenbuffer, H_RES * sizeof(Pixel));
            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, NULL, NULL);
            SDL_RenderPresent(renderer);
            frame_count++;
        }
    }

    uint64_t end_ticks = SDL_GetPerformanceCounter();
    double duration = (double)(end_ticks - start_ticks) / SDL_GetPerformanceFrequency();
    double fps = (double)frame_count / duration;
    printf("Frames per second: %.1f\n", fps);

    // Clean up
    top->final();
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
