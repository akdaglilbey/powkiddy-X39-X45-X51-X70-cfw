#include <stdio.h>
#include <zlib.h>

int main(int argc, char **argv) {
    FILE *f = fopen(argv[1], "rb");
    unsigned char buf[4096];
    unsigned long crc = crc32(0L, Z_NULL, 0);
    size_t n;

    while ((n = fread(buf, 1, sizeof(buf), f)) > 0)
        crc = crc32(crc, buf, n);

    fclose(f);
    printf("%08lx\n", crc);
    return 0;
}
