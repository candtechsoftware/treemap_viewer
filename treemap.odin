package main

import "core:fmt"
import "core:slice"
import "core:strings"
import "vendor:sdl2"


OFFSET :: 2.0
Viewport :: struct {
	x:              f64,
	y:              f64,
	w:              f64,
	h:              f64,
	center_x:       f64,
	center_y:       f64,
	is_highlighted: bool,
}

TreeNode :: struct {
	using viewport: Viewport,
	name:           string,
	index:          int,
	parent:         ^TreeNode,
	children:       [dynamic]^TreeNode,
	flags:          enum {
		Leaf,
		Parent,
	},
	size:           f64,
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
}

print_tree :: proc(treemap: ^TreeMap) {
	for n in treemap.nodes {
		print_node(n)
	}
}

print_node :: proc(node: ^TreeNode) {
	fmt.printf("Node: %#v\n", node)
	if node.children == nil || len(node.children) == 0 {
		return
	}
	for child in node.children {
		print_node(child)
	}

}


get_node_name :: proc(treemap: ^TreeMap, x, y: i32) -> (bool, string) {
	text := ""
	flag := false
	for n in treemap.root.children {
		if is_in_node(n, x, y) {
			text = n.name
			flag = true
		}
	}
	return flag, text

}

is_in_node :: proc(node: ^TreeNode, x, y: i32) -> bool {
	p := sdl2.Point{x, y}
    r := sdl2.Rect{i32(node.x), i32(node.y), i32(node.w), i32(node.h)}
	return  bool(sdl2.PointInRect(&p, &r))
}

squarify_from_root :: proc(treemap: ^TreeMap) {
	if treemap.root == nil {
		return
	}
	viewport: Viewport = {
		x              = 0,
		y              = 0,
		w              = WINDOW_WIDTH,
		h              = WINDOW_HEIGHT - 20,
		center_x       = 0,
		center_y       = 0,
		is_highlighted = false,
	}
	treemap.root.viewport = viewport
	squarify(treemap.root)
}

squarify :: proc(node: ^TreeNode) {
	fmt.printf("Node: %v\n", node)
	if node.flags != .Leaf && node.size != 0 {
		canvasX := node.x + OFFSET
		canvasY := node.y + OFFSET
		canvasWidth := node.w - (OFFSET * 2.0)
		canvasHeight := node.h - (OFFSET * 2.0)

		canvasArea := canvasWidth * canvasHeight
		vaRatio := canvasArea / node.size
		i := 0
		for i < len(node.children) {
			fmt.printf("While loop %d Len: %d\n", i, len(node.children))
			shorterSide: f64
			if canvasWidth < canvasHeight {
				shorterSide = canvasWidth
			} else {
				shorterSide = canvasHeight
			}
			if shorterSide <= 0 {
				shorterSide = 10
			}
			fmt.printf("Short loop %d Node: %#v\n", shorterSide, node)

			value := node.children[i].size
			anotherSideC1 := value * vaRatio / shorterSide
			aspectRatioC1: f64
			if anotherSideC1 < shorterSide {
				aspectRatioC1 = shorterSide / anotherSideC1
			} else {
				aspectRatioC1 = anotherSideC1 / shorterSide
			}
			if i + 1 == len(node.children) {
				child := node.children[i]
				child.x = canvasX
				child.y = canvasY
				child.w = canvasWidth
				child.h = canvasHeight
				i += 1
			}

			for j := i + 1; j < len(node.children); j += 1 {
				c2Value := node.children[j].size
				fmt.printf("J loop: %v %#v\n", j, node.children[j])
				sumOfValue := value + c2Value
				anotherSideC2 := sumOfValue * vaRatio / shorterSide
				aspectRatioC2: f64
				fmt.printf("J loop: %v %v %v\n", sumOfValue, anotherSideC2, shorterSide)
				fmt.printf("AS loop: %v %v %v\n", sumOfValue, anotherSideC2, shorterSide)
				if anotherSideC2 < (shorterSide * (c2Value / sumOfValue)) {
					aspectRatioC2 = (shorterSide * (c2Value / sumOfValue)) / anotherSideC2
				} else {
					aspectRatioC2 = anotherSideC2 / (shorterSide * (c2Value / sumOfValue))
				}
				fmt.printf("AS loop: %v %v %#v\n", aspectRatioC1, aspectRatioC2, node)
				if (aspectRatioC2 < aspectRatioC1) {
					aspectRatioC1 = aspectRatioC2
					anotherSideC1 = anotherSideC2
					value = sumOfValue
				} else {
					fmt.printf("J Else loop: %v %v %v\n", sumOfValue, anotherSideC2, shorterSide)
					x := canvasX
					y := canvasY
					for k := i; k < j; k += 1 {
						child := node.children[k]
						child.x = x
						child.y = y
						childValue := child.size
						if canvasWidth < canvasHeight {
							child.w = (shorterSide * (childValue / value))
							child.h = (anotherSideC1)
							x += shorterSide * (childValue / value)
						} else {
							child.w = (anotherSideC1)
							child.h = (shorterSide * (childValue / value))
							y += shorterSide * (childValue / value)
						}
					}
					i = j
					if (canvasWidth < canvasHeight) {
						canvasY += anotherSideC1
						canvasHeight -= anotherSideC1
					} else {
						canvasX += anotherSideC1
						canvasWidth -= anotherSideC1
					}
					break
				}
			}
		}

		for n := 0; n < len(node.children); n += 1 {
			squarify(node.children[n])
		}
	}
}
