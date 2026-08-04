
#include "main.h"


int cmd_init(int argc, char *argv[])
{
    (void)argc;
    (void)argv;
    printf("run init \n");
    if (ensure_dir(UGIT_DIR) != 0)
    {
        return 1;
    }
    if (ensure_dir(OBJECTS_DIR) != 0)
    {
        return 1;
    }
    return 0;
}

int cmd_hash_object(int argc, char *argv[])
{
    BYTE hash[20];
    char hex[41];

    if (argc < 1)
    {
        printf("usage: ugit hash-object <file>\n");
        return 1;
    }

    if (hash_object_file(argv[0], hash) != 0)
    {
        return 1;
    }

    hash_to_hex(hash, 20, hex);
    printf("%s\n", hex);
    return 0;
}

int cmd_cat_file(int argc, char *argv[])
{
    if (argc < 1)
    {
        printf("usage: ugit cat-file <hash>\n");
        return 1;
    }

    if (cat_file(argv[0]) > 0)
    {
        return 1;
    }
    return 0;
}
