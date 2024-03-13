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
	treemap:      ^TreeMap,
	nodes:        [dynamic]^TreeNode,
}

destroy_state :: proc(state: ^State) {
	sdl2.DestroyRenderer(state.renderer)
	sdl2.DestroyWindow(state.window)
	sdl2.FreeSurface(state.surface)
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
		fmt.printf("Error initializing font")
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

draw_current_treeemap :: proc(using state: ^State) {
	root := treemap.root
	if root == nil {
		fmt.println("Root is null")
		return
	}

    prev_size := root.size
	for node, index in state.nodes {
		draw_current_treeemap_node(state, node, i32(prev_size), i32(index))
		prev_size = node.size
	}


}

draw_current_treeemap_node :: proc(state: ^State, node: ^TreeNode, prev_size, index: i32) {
	if node.size == 0 do return
	parent_size: i32 =
		node.parent != nil ? i32(int(node.parent.size) % int(WINDOW_HEIGHT)) : WINDOW_HEIGHT
	size := i32(int(node.size) % int(parent_size))

	rect := sdl2.Rect {
		index + prev_size % WINDOW_HEIGHT,
		index + prev_size % WINDOW_HEIGHT,
		i32(size),
		i32(size),
	}


	color := sdl2.Color{u8(index + size) % 255, u8(index + 200) % 255, 128, 255}

	sdl2.SetRenderDrawColor(state.renderer, color.r, color.g, color.b, color.a)
	sdl2.RenderDrawRect(state.renderer, &rect)

}

main :: proc() {
	if len(os.args) <= 1 {
		fmt.eprint("Error need to provide directory")
		return
	}

	treemap := init_treemap(os.args[1])
	state, _ := init_state()
	state.treemap = treemap
	compute_sizes(treemap)

	nodes := traverse_treemap(treemap)
	state.nodes = nodes

	defer destroy_state(state)

	loop: for {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			#partial switch event.type {
			case .KEYDOWN, .QUIT:
				break loop
			}
		}
		sdl2.SetRenderDrawColor(state.renderer, 128, 128, 128, 255) // background color
		sdl2.RenderClear(state.renderer)
		draw_current_treeemap(state)
		sdl2.RenderPresent(state.renderer)


	}
}
