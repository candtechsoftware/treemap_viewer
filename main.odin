package main

import "core:fmt"
import "core:os"
import "core:strings"
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
	filename:     cstring,
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
	state.filename = "Test"

	if ttf.Init() < 0 {
		fmt.printf("Error initializing font")
		return nil, .InitFont
	}

	state.font = ttf.OpenFont("assets/font.ttf", 24)
	if state.font == nil {
		fmt.printf("Error opening font: %v", ttf.GetError())
		return nil, .InitFont
	}
	state.font_color = sdl2.Color{200, 200, 200, 255}


	return state, nil
}

draw_text :: proc(state: ^State) {
	surface := ttf.RenderText_Solid(state.font, state.filename, state.font_color)
	if surface == nil {
		fmt.printf("Surface is nil %v === %v \n", sdl2.GetError(), ttf.GetError)
	}
	texture := sdl2.CreateTextureFromSurface(state.renderer, surface)
	if texture == nil {
		fmt.printf("Texture is nil %v\n", sdl2.GetError())
	}
	text_w := surface.w
	text_h := surface.h
	defer sdl2.FreeSurface(surface)
	defer sdl2.DestroyTexture(texture)
	rect: sdl2.Rect = sdl2.Rect{0, 800 - text_h, text_w, text_h}
	if sdl2.RenderCopy(state.renderer, texture, nil, &rect) > 0 {
		fmt.printfln("RenderCopy failed", sdl2.GetError())
	}
}

draw_current_treeemap :: proc(using state: ^State) {
	for n in state.treemap.nodes {
		draw_current_treeemap_node(state, n)
	}
}

draw_current_treeemap_node :: proc(state: ^State, node: ^TreeNode) {
	if node.size == 0 do return
	color := sdl2.Color{200, 200, 200, 255}
	rect := sdl2.Rect{i32(node.x), i32(node.y), i32(node.w), i32(node.h)}
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
	fmt.println("compute_sizes completed")
	squarify_from_root(treemap)
	fmt.println("squarified done")
	print_tree(treemap)

	defer destroy_state(state)

	loop: for {
		sdl2.SetRenderDrawColor(state.renderer, 0, 0, 0, 255) // background color
		sdl2.RenderClear(state.renderer)

		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				break loop
			case .MOUSEMOTION:
				{
					x, y := event.motion.x, event.motion.y
					ok, name := get_node_name(state.treemap, i32(x), i32(y))
					if ok {
						state.filename = strings.clone_to_cstring(name)
					}
				}
			}
		}
        draw_text(state)
		draw_current_treeemap(state)
		sdl2.RenderPresent(state.renderer)
	}
}
