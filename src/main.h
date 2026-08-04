#ifndef MAIN_H
#define MAIN_H

#include <stdio.h>
#include <stddef.h>
#include <errno.h>
#include <stdlib.h>
#include "sha1.h"

typedef struct
{
    const char *command;
    int (*func)(int argc, char *argv[]);
} Args;

#ifdef _WIN32
#include <direct.h>
#define MKDIR(path) _mkdir(path)
#else
#include <sys/stat.h>
#include <sys/types.h>
#define MKDIR(path) mkdir(path, 0755)
#endif

#define UGIT_DIR ".ugit"
#define OBJECTS_DIR ".ugit/objects"
#define OBJ_BLOB "blob"
#define OBJ_TREE "tree"
#define OBJ_COMMIT "commit"

int cmd_init(int argc, char *argv[]);
int cmd_hash_object(int argc, char *argv[]);
int cmd_cat_file(int argc, char*argv[]);
int parse_args(int argc, char *argv[], Args *args);
int cat_file(const char *hash_hex);
int hash_object_file(const char *path, BYTE hash[20]);
char *read_file_alloc(const char *path, size_t *out_size);
int put_object(const void *data, size_t size, const char *type, BYTE hash[20]);
int write_file_chunk(FILE *file, const void *data, size_t size);
void hash_to_hex(const BYTE *hash, size_t size, char hex[]);
int ensure_dir(const char *path);
#endif
