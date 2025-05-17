#include <stdio.h>
#include <SDL.h>
#include <verilated.h>
#include "Vtop_game.h"

const int H_RES = 640;
const int V_RES = 480;

typedef struct Pixel {
    uint8_t a, b, g, r;
} Pixel;

int main(int argc, char* argv[]) {
    Verilated::commandArgs(argc, argv);

    if (SDL_Init(SDL_INIT_VIDEO) < 0) return 1;

    Pixel screenbuffer[H_RES * V_RES] = {};

    SDL_Window* window = SDL_CreateWindow("Pixel Controlled by Verilog",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        H_RES, V_RES, SDL_WINDOW_SHOWN);

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_STREAMING, H_RES, V_RES);

    const Uint8* keyb_state = SDL_GetKeyboardState(NULL);
    Vtop_game* top = new Vtop_game;

    top->sim_rst = 1;
    top->clk_pix = 0; top->eval();
    top->clk_pix = 1; top->eval();
    top->sim_rst = 0;
    top->clk_pix = 0; top->eval();

    while (true) {
        top->btn_up = 0;
        top->btn_dn = keyb_state[SDL_SCANCODE_RIGHT];  // ← map Right Arrow to btn_dn
        top->btn_fire = 0;

        // Tick the simulation
        top->clk_pix = 1; top->eval();
        top->clk_pix = 0; top->eval();

        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) goto quit;
        }
        if (keyb_state[SDL_SCANCODE_Q]) break;

        // Clear frame
        memset(screenbuffer, 0, sizeof(screenbuffer));

        // Draw the pixel if enabled
int x = top->sdl_sx;
int y = top->sdl_sy;
if (top->sdl_de && x < H_RES && y < V_RES) {
    printf("DRAW at (%d, %d) Color = (%d, %d, %d)\n",
           x, y, top->sdl_r, top->sdl_g, top->sdl_b);

    Pixel* p = &screenbuffer[y * H_RES + x];
    p->a = 0xFF;
    p->r = top->sdl_r;
    p->g = top->sdl_g;
    p->b = top->sdl_b;
}


        SDL_UpdateTexture(texture, NULL, screenbuffer, H_RES * sizeof(Pixel));
        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

quit:
    top->final();
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
