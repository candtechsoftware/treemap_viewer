package main

import "core:strings"
import "core:fmt"

Vector4 :: struct {
	r, g, b, a: int,
}

Vector2 :: struct {
	x, y: int,
}

TreeMapDisplay :: struct {
	nodes:   [dynamic]^DisplayNode,
	treemap: ^TreeMap,
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
	nodes:  [dynamic]^TreeNode,
	root:   ^TreeNode,
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
    if len(treemap.nodes) > 0 {
        root := treemap.nodes[0]
        fmt.printfln("Root: %d", root.size)
    }
}
