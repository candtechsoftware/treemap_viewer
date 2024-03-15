package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"


dir_table: map[string]^TreeNode
dir: string

add_dir_node :: proc(treemap: ^TreeMap, fullpath, name: string) {
	if fullpath == dir {return}
	parent: ^TreeNode
	path, _ := filepath.split(fullpath)
	if strings.has_suffix(path, "/") {
		path = strings.trim_right(path, "/")
	}
	if len(dir_table) == 0 {
		return

	}
	found_parent, ok := dir_table[path]
	if ok {
		parent = found_parent
	} else {
		parent = treemap.root
	}

	node := add_node(treemap, path, parent)
	dir_table[fullpath] = node

}
add_file_node :: proc(treemap: ^TreeMap, info: os.File_Info) {
	path, _ := filepath.split(info.fullpath)
	if strings.has_suffix(path, "/") {
		path = strings.trim_right(path, "/")
	}

	parent: ^TreeNode
	found_parent, ok := dir_table[path]
	if ok {
		parent = found_parent
	} else {
		parent = treemap.root
	}

	node := add_node(treemap, info.fullpath, parent)
	node.size = f64(info.size)
}


visit :: proc(
	info: os.File_Info,
	in_err: os.Errno,
	user_data: rawptr,
) -> (
	err: os.Errno,
	skip_dir: bool,
) {
	if info.is_dir {
		add_dir_node(transmute(^TreeMap)user_data, info.fullpath, info.name)
	} else {
		add_file_node(transmute(^TreeMap)user_data, info)
	}

	return 0, false
}

init_treemap :: proc(dir_arg: string) -> ^TreeMap {
	dir = dir_arg
	treemap: ^TreeMap = new(TreeMap)
	treemap.root = add_node(treemap, dir, nil)
	treemap.size = 1
	dir_table = make(map[string]^TreeNode)
	dir_table[dir] = treemap.root
	filepath.walk(dir, visit, treemap)

	return treemap
}
