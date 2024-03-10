package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"


dir_table: map[string]^TreeNode
dir :: "/home/alexmatthewcandelario/Gits/ols" // TODO Get this from user

add_dir_node :: proc(treemap: ^TreeMap, fullpath, name: string) {
	if fullpath == dir {return}
	parent: ^TreeNode
	path, _ := filepath.split(fullpath)
	if strings.has_suffix(path, "/") {
		path = strings.trim_right(path, "/")
	}
	if len(dir_table) == 0 {
		fmt.printf("Table is empty\n")

	} else {
		found_parent, ok := dir_table[path]
		if ok {
			fmt.printf("FOUND fullpath %s, path %s name %s\n", fullpath, path, name)
			fmt.printf("NODE %v\n=======\n", found_parent)
			parent = found_parent
		} else {
			fmt.eprintf("Parent not found fullpath %s, path %s name %s\n", fullpath, path, name)
			parent = treemap.root
		}
	}

	node := add_node(treemap, path, parent)
	dir_table[fullpath] = node


	//node := add_node(treemap, name, parent)
}
add_file_node :: proc(treemap: ^TreeMap, info: os.File_Info) {
    fmt.printf("info: %#v\n", info)
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

init_treemap :: proc() {

	treemap: ^TreeMap = new(TreeMap)
	treemap.leaves = make(map[^TreeNode]bool)
	root := add_node(treemap, dir, nil)
	fmt.printfln("Root: %v", root)
	dir_table = make(map[string]^TreeNode)
	dir_table[dir] = root

	filepath.walk(dir, visit, treemap)
    for key, value  in treemap.leaves {
        if value {
            fmt.printfln("%v", key.name)
        }
    }
}
