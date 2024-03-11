package main

import "core:fmt"
import "core:slice"
import "core:strings"

Vector4 :: struct {
	r, g, b, a: int,
}

Vector2 :: struct {
	x, y: int,
}

TreeMapDisplay :: struct {
	nodes:   [dynamic]^DisplayNode,
	treemap: ^TreeMap,
    dirty: bool
}

DisplayNode :: struct {
	index: int,
	color: Vector4,
}

TreeNode :: struct {
	name:     string,
	index:    int,
	size:     int,
	parent:   ^TreeNode,
	children: [dynamic]^TreeNode,
	flags:    enum {
		Leaf,
		Parent,
	},
}
TreeMap :: struct {
	nodes: [dynamic]^TreeNode,
	root:  ^TreeNode,
	dirty: bool,
}


add_node :: proc(treemap: ^TreeMap, name: string, parent: ^TreeNode) -> ^TreeNode {
	node: ^TreeNode = new(TreeNode)
	node.name = strings.clone(name)
	index := len(treemap.nodes)
	node.parent = parent
	node.index = index
	node.flags = .Leaf

	append(&treemap.nodes, node)
	if parent != nil {
		append(&parent.children, node)
		parent.flags = .Parent
	}

	return node
}


compute_sizes :: proc(treemap: ^TreeMap) {
	if !treemap.dirty do return
	treemap.dirty = false

	for k in treemap.nodes {
		if k.flags != .Leaf {
			k.size = 0
		}
	}

	#reverse for node in treemap.nodes {
		if node.parent != nil {
			node.parent.size += node.size
		}
	}

	for node in treemap.nodes {
		fmt.printfln("Nodes before: %v\n-----\n", treemap.nodes)
		slice.sort_by(treemap.nodes[:], proc(a, b: ^TreeNode) -> bool {
			return a.size > b.size
		})

		fmt.printfln("Nodes after: %v\n======\n", treemap.nodes)
	}


	if len(treemap.nodes) > 0 {
		root := treemap.nodes[0]
		fmt.printfln("Root: %d", root.size)
	}
}

init_treemap_display :: proc(treemap: ^TreeMap) -> ^TreeMapDisplay {
	display: ^TreeMapDisplay = new(TreeMapDisplay)
	display.treemap = treemap
	display.nodes = make([dynamic]^DisplayNode)

	return display
}

recompute_if_dirty :: proc(display: ^TreeMapDisplay) {
    if !display.dirty do return
    display.dirty = false
}
