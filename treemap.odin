package main

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
}

DisplayNode :: struct {
	index: int,
	color: Vector4,
}

TreeNode :: struct {
	name:   string,
	index:  int,
	size:   f64,
	parent: ^TreeNode,
    children: [dynamic]^TreeNode,
}
TreeMap :: struct {
	nodes: [dynamic]^TreeNode,
	root:  ^TreeNode,
}


add_node :: proc(treemap: ^TreeMap, name: string, parent: ^TreeNode) -> ^TreeNode {
	node: ^TreeNode = new(TreeNode)
	node.name = strings.clone(name)
	index := len(treemap.nodes)
    node.parent = parent
	node.index = index

    append(&treemap.nodes, node)
    if parent != nil {
        append(&parent.children, node)
    }
	return node
}
