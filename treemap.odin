package main

import "core:fmt"
import "core:slice"
import "core:strings"
import "vendor:sdl2"

TreeNode :: struct {
	name:     string,
	index:    int,
	parent:   ^TreeNode,
	children: [dynamic]^TreeNode,
	flags:    enum {
		Leaf,
		Parent,
	},
	size:     f64,
	coord:    struct {
		x, y, w, h: int,
	},
}
TreeMap :: struct {
	nodes: [dynamic]^TreeNode,
	root:  ^TreeNode,
	size:  int,
}


add_node :: proc(treemap: ^TreeMap, name: string, parent: ^TreeNode) -> ^TreeNode {
	node: ^TreeNode = new(TreeNode)
	node.name = strings.clone(name)
	index := len(treemap.nodes)
	node.parent = parent
	node.index = index
	node.flags = .Leaf
	treemap.size += 1

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

	for node in treemap.nodes {
		slice.sort_by(treemap.nodes[:], proc(a, b: ^TreeNode) -> bool {
			return a.size > b.size
		})

	}


	if len(treemap.nodes) > 0 {
		root := treemap.nodes[0]
		fmt.printfln("Root: %d", root.size)
	}
}

traverse_treemap :: proc(treemap: ^TreeMap) -> [dynamic]^TreeNode {
	nodes: [dynamic]^TreeNode = make([dynamic]^TreeNode)
	root := treemap.root
	if root == nil {
		return nil
	}
	fmt.printfln("%T", nodes)
	fmt.printfln("%T", root)
	append(&nodes, root)
	traverse_nodes(root, &nodes)
	return nodes
}

traverse_nodes :: proc(node: ^TreeNode, nodes: ^[dynamic]^TreeNode) {
	if node == nil {
		return
	}
	append(nodes, node)
	if node.children == nil || len(node.children) == 0 {
		return
	}
	for child in node.children {
		traverse_nodes(child, nodes)
	}
}

get_node_name :: proc(nodes: [dynamic]^TreeNode, x, y: int) -> (bool, string){
	text := ""
    flag := false
	for n in nodes {
		if is_in_node(n, x, y) {
			text = n.name
            flag = true
		}
	}
	return flag, text

}

is_in_node :: proc(node: ^TreeNode, x, y: int) -> bool {
	return(
		node.coord.x >= x &&
		node.coord.y >= y &&
		node.coord.x <= x + node.coord.w &&
		node.coord.y <= y + node.coord.h \
	)
}
