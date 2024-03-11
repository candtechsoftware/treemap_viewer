package main

import "core:fmt"
import "core:os"
import "vendor:sdl2"
import "vendor:sdl2/ttf"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 800

State :: struct {
	window:       ^sdl2.Window,
	renderer:     ^sdl2.Renderer,
	surface:      ^sdl2.Surface,
	current_time: int,
	font:         ^ttf.Font,
	font_color:   sdl2.Color,
}

init_state :: proc() -> (^State, Error) {
	state: ^State = new(State)

	if sdl2.Init(sdl2.INIT_VIDEO) < 0 {
		fmt.eprintf("Error initializing sdl2 video %v", Error.InitVideo)
		return nil, .InitVideo
	}

	state.window = sdl2.CreateWindow(
		"Tree Map Viewer",
		sdl2.WINDOWPOS_UNDEFINED,
		sdl2.WINDOWPOS_UNDEFINED,
		WINDOW_HEIGHT,
		WINDOW_WIDTH,
		nil,
	)

	if state.window == nil {
		fmt.eprintln("Error creating window")
		return nil, .InitVideo
	}

	state.renderer = sdl2.CreateRenderer(state.window, -1, nil)

	if ttf.Init() < 0 {
		return nil, .InitFont
	}

	state.font = ttf.OpenFont("assets/font.ttf", 24)
	if state.font == nil {
		fmt.printf("Error opening font: %v", ttf.GetError())
		return nil, .InitFont
	}
	state.font_color = sdl2.Color{255, 255, 255, 0}


	return state, nil
}

draw_text :: proc(state: ^State) {
	surface := ttf.RenderText_Solid(state.font, "FileName", state.font_color)
	texture := sdl2.CreateTextureFromSurface(state.renderer, surface)
	text_w := surface.w
	text_h := surface.h
	defer sdl2.FreeSurface(surface)
	rect: sdl2.Rect = sdl2.Rect{0, 800 - text_h, text_w, text_h}
	sdl2.RenderCopy(state.renderer, texture, nil, &rect)
}

draw_current_treeemap :: proc(state: ^State) {
	x0: i32 = WINDOW_WIDTH / 20
	x1: i32 = WINDOW_WIDTH - x0

	y0 := x0
	y1: i32 = WINDOW_HEIGHT / 10


	rect := sdl2.Rect{x0, x1, y0, y1}
	color := sdl2.Color{0, 255, 0, 255}

	surface := sdl2.GetWindowSurface(state.window)
	sdl2.FillRect(surface, &rect, sdl2.MapRGBA(nil, 0, 255, 0, 255))

}

draw_current_treeemap_node :: proc(state: ^State) {
	draw_text(state)
}

main :: proc() {
	if len(os.args) <= 1 {
		fmt.eprint("Error need to provide directory")
		return
	}

	init_treemap(os.args[1])
	state, _ := init_state()

	loop: for {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			#partial switch event.type {
			case .KEYDOWN, .QUIT:
				break loop
			}
		}
		sdl2.SetRenderDrawColor(state.renderer, 0xFF, 0xFF, 0xFF, 0xFF) // background color

        // Clear window
		sdl2.RenderClear(state.renderer)



		draw_current_treeemap(state)
		draw_current_treeemap_node(state)
		sdl2.RenderPresent(state.renderer)
	}
}
