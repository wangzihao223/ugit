#include <stdio.h>
#include <string.h>

#include "main.h"

int main(int argc, char **argv)
{
    Args args;
    if (!parse_args(argc, argv, &args))
    {
        printf("error: command error\n");
        return 1;
    }

    return args.func(argc - 2, argv + 2);
}

int parse_args(int argc, char *argv[], Args *args)
{
    if (argc > 1)
    {
        if (strcmp(argv[1], "init") == 0)
        {
            args->command = "init";
            args->func = cmd_init;
            return 1;
        }
        if (strcmp(argv[1], "hash-object") == 0)
        {
            args->command = "hash-object";
            args->func = cmd_hash_object;
            return 1;
        }
        if (strcmp(argv[1], "cat-file") == 0)
        {
            args->command = "cat-file";
            args->func = cmd_cat_file;
            return 1;
        }
        if (strcmp(argv[1], "write-tree") == 0)
        {
            args->command = "write-tree";
            args->func = write_tree;
            return 1;
        }
    }
    return 0;
}

int cat_file(const char *hash_hex)
{
    char path[256];
    char buffer[256];
    size_t n;

    snprintf(path, sizeof(path), "%s/%s", OBJECTS_DIR, hash_hex);

    FILE *file = fopen(path, "rb");
    if (file == NULL)
    {
        perror("fopen object");
        return 1;
    }

    while ((n = fread(buffer, 1, sizeof(buffer), file)) > 0)
    {
        if (fwrite(buffer, 1, n, stdout) != n)
        {
            perror("fwrite");
            fclose(file);
            return 1;
        }
    }

    if (ferror(file))
    {
        perror("fread");
        fclose(file);
        return 1;
    }

    fclose(file);
    return 0;
}

int hash_object_file(const char *path, BYTE hash[20])
{
    char *data;
    size_t size;

    data = read_file_alloc(path, &size);
    if (data == NULL)
    {
        return 1;
    }

    if (put_object(data, size, OBJ_BLOB, hash) != 0)
    {
        free(data);
        return 1;
    }

    free(data);
    return 0;
}

char *read_file_alloc(const char *path, size_t *out_size)
{
    FILE *file = fopen(path, "rb");
    if (file == NULL)
    {
        perror("fopen");
        return NULL;
    }

    if (fseek(file, 0, SEEK_END) != 0)
    {
        perror("fseek");
        fclose(file);
        return NULL;
    }

    long file_size = ftell(file);
    if (file_size < 0)
    {
        perror("ftell");
        fclose(file);
        return NULL;
    }

    rewind(file);

    char *data = malloc((size_t)file_size);
    if (data == NULL && file_size > 0)
    {
        fclose(file);
        return NULL;
    }

    size_t read_size = fread(data, 1, (size_t)file_size, file);
    if (read_size != (size_t)file_size)
    {
        free(data);
        fclose(file);
        return NULL;
    }

    fclose(file);

    if (out_size != NULL)
    {
        *out_size = (size_t)file_size;
    }

    return data;
}

int write_file_chunk(FILE *file, const void *data, size_t size)
{
    if (file == NULL)
    {
        return 1;
    }
    if (fwrite(data, 1, size, file) != size)
    {
        perror("fwrite");
        return 1;
    }
    return 0;
}

void hash_to_hex(const BYTE *hash, size_t size, char hex[])
{
    for (size_t i = 0; i < size; i++)
    {
        sprintf(hex + i * 2, "%02x", hash[i]);
    }
    hex[size * 2] = '\0';
}

int ensure_dir(const char *path)
{
    errno = 0;
    if (MKDIR(path) == 0)
    {
        return 0;
    }
    if (errno == EEXIST)
    {
        return 0;
    }
    perror("mkdir");
    return 1;
}

int put_object(const void *data, size_t size, const char *type, BYTE hash[20])
{
    const char *object_type = type != NULL ? type : OBJ_BLOB;
    size_t type_len = strlen(object_type);
    char hex[41];
    char write_path[256];
    FILE *file;
    SHA1_CTX ctx;

    sha1_init(&ctx);
    sha1_update(&ctx, (const BYTE *)object_type, type_len);
    sha1_update(&ctx, (const BYTE *)"\0", 1);
    if (size > 0)
    {
        sha1_update(&ctx, (const BYTE *)data, size);
    }
    sha1_final(&ctx, hash);

    if (ensure_dir(UGIT_DIR) != 0 || ensure_dir(OBJECTS_DIR) != 0)
    {
        return 1;
    }

    hash_to_hex(hash, 20, hex);
    snprintf(write_path, sizeof(write_path), "%s/%s", OBJECTS_DIR, hex);

    file = fopen(write_path, "wb");
    if (file == NULL)
    {
        perror("fopen object");
        return 1;
    }

    if (write_file_chunk(file, object_type, type_len) != 0 ||
        write_file_chunk(file, "\0", 1) != 0 ||
        (size > 0 && write_file_chunk(file, data, size) != 0))
    {
        fclose(file);
        return 1;
    }

    fclose(file);
    return 0;
}
