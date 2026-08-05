
#include <string.h>

#include "main.h"

int write_tree(int argc, char *argv[])
{
    if (argc < 1)
    {
        printf("usage: ugit write-tree <dir>\n");
        return 1;
    }
    if (write_tree_1(argv[0]))
    {
        return 1;
    }
    return 0;

}


int write_tree_1(const char *dir)
{
    char pattern[1024];
    struct __finddata64_t file;
    intptr_t handle;
    snprintf(pattern, sizeof(pattern), "%s\\*", dir);

    // list full
    handle = _findfirst64(pattern, &file);
    if(handle == -1){
        perror("_findfirst64");
        return 1;
    }
    do {
        // do somthing
        if (strcmp(file.name, ".") == 0 || strcmp(file.name, "..") == 0){
            continue;
        }
        if (strcmp(file.name, UGIT_DIR) == 0){
            continue;
        }

        char full_path[1024];
        snprintf(full_path, sizeof(full_path), "%s\\%s", dir, file.name);

        if(file.attrib & _A_SUBDIR){
            // dir 
            printf("[DIR] %s\n", full_path);
            if (write_tree_1(full_path) != 0)
            {
                _findclose(handle);
                return 1;
            }
        }else{
            //file
            printf("[FILE] %s\n", full_path);
        }
    }while(_findnext64(handle, &file) == 0);
    _findclose(handle);
    return 0;
}
