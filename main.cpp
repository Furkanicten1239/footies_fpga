#include <stdio.h>
#include <SDL.h>
#include <verilated.h>
#include "Vtop_game.h"

// VGA resolution
const int H_RES = 640;
const int V_RES = 480;

// SDL pixel struct
typedef struct Pixel {
    uint8_t a;  // alpha
    uint8_t b;
    uint8_t g;
    uint8_t r;
} Pixel;

int main(int argc, char* argv[]) {
    Verilated::commandArgs(argc, argv);

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed: %s\n", SDL_GetError());
        return 1;
    }

    Pixel screenbuffer[H_RES * V_RES] = {};

    SDL_Window* window = SDL_CreateWindow("Verilator VGA Test",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        H_RES, V_RES, SDL_WINDOW_SHOWN);
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
        SDL_TEXTUREACCESS_STREAMING, H_RES, V_RES);
    if (!texture) {
        printf("Texture creation failed: %s\n", SDL_GetError());
        return 1;
    }

    const Uint8* keyb_state = SDL_GetKeyboardState(NULL);
    Vtop_game* top = new Vtop_game;

    // Reset the module
    top->sim_rst = 1;
    top->clk_pix = 0; top->eval();
    top->clk_pix = 1; top->eval();
    top->sim_rst = 0;
    top->clk_pix = 0; top->eval();

    printf("Simulation running. Press Q or close window to quit.\n");

    bool running = true;
    while (running) {
        // Tick simulation clock
        top->clk_pix = 1; top->eval();
        top->clk_pix = 0; top->eval();

        // Read pixel position and color from Verilog
        int x = top->sdl_sx;
        int y = top->sdl_sy;

        if (x < H_RES && y < V_RES) {
            Pixel* p = &screenbuffer[y * H_RES + x];
            p->a = 0xFF;
            p->r = top->sdl_r;
            p->g = top->sdl_g;
            p->b = top->sdl_b;
        }

        // Frame update based on fixed coordinates
        if (top->sdl_sx == 100 && top->sdl_sy == 100) {
            // Handle input
            SDL_Event e;
            while (SDL_PollEvent(&e)) {
                if (e.type == SDL_QUIT) running = false;
            }

            if (keyb_state[SDL_SCANCODE_Q]) running = false;

            // Draw the frame
            SDL_UpdateTexture(texture, NULL, screenbuffer, H_RES * sizeof(Pixel));
            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, NULL, NULL);
            SDL_RenderPresent(renderer);
        }
    }

    // Cleanup
    top->final();
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
