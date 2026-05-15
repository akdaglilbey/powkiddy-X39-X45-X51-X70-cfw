#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <linux/fb.h>

static inline uint16_t rgb888_to_rgb565(
    uint8_t r,
    uint8_t g,
    uint8_t b)
{
    return ((r >> 3) << 11) |
           ((g >> 2) << 5)  |
           (b >> 3);
}

static int display_image(const char *path)
{
    /*
     * Open framebuffer
     */

    int fb = open("/dev/fb0", O_RDWR);

    if (fb < 0)
    {
        perror("open fb0");
        return -1;
    }

    struct fb_fix_screeninfo finfo;
    struct fb_var_screeninfo vinfo;

    ioctl(fb, FBIOGET_FSCREENINFO, &finfo);
    ioctl(fb, FBIOGET_VSCREENINFO, &vinfo);

    int screen_width  = vinfo.xres;
    int screen_height = vinfo.yres;

    size_t screensize =
        finfo.line_length * screen_height;

    /*
     * mmap framebuffer
     */

    uint8_t *fbp = mmap(
        NULL,
        screensize,
        PROT_READ | PROT_WRITE,
        MAP_SHARED,
        fb,
        0);

    if (fbp == MAP_FAILED)
    {
        perror("mmap");
        close(fb);
        return -1;
    }

    /*
     * Load image
     */

    int width;
    int height;
    int channels;

    uint8_t *img = stbi_load(
        path,
        &width,
        &height,
        &channels,
        3);

    if (!img)
    {
        printf("stbi_load failed: %s\n",
               stbi_failure_reason());

        munmap(fbp, screensize);
        close(fb);

        return -1;
    }

    /*
     * Check resolution
     */

    if (width != screen_width ||
        height != screen_height)
    {
        printf("Image resolution mismatch\n");
        printf("Image: %dx%d\n", width, height);
        printf("Screen: %dx%d\n",
               screen_width,
               screen_height);

        stbi_image_free(img);

        munmap(fbp, screensize);
        close(fb);

        return -1;
    }

    /*
     * Convert to RGB565 buffer
     */

    uint16_t *buffer565 =
        malloc(width * height * 2);

    if (!buffer565)
    {
        perror("malloc");

        stbi_image_free(img);

        munmap(fbp, screensize);
        close(fb);

        return -1;
    }

    for (int i = 0; i < width * height; i++)
    {
        uint8_t r = img[i * 3 + 0];
        uint8_t g = img[i * 3 + 1];
        uint8_t b = img[i * 3 + 2];

        buffer565[i] =
            rgb888_to_rgb565(r, g, b);
    }

    /*
     * Copy to framebuffer
     */

    if (finfo.line_length == width * 2)
    {
        /*
         * Fast path
         */

        memcpy(fbp,
               buffer565,
               width * height * 2);
    }
    else
    {
        /*
         * Stride mismatch
         */

        for (int y = 0; y < height; y++)
        {
            memcpy(
                fbp + y * finfo.line_length,
                buffer565 + y * width,
                width * 2);
        }
    }

    /*
     * Cleanup
     */

    free(buffer565);

    stbi_image_free(img);

    munmap(fbp, screensize);

    close(fb);

    return 0;
}

int main(int argc, char **argv)
{
    if (argc != 2)
    {
        printf("Usage: %s image\n",
               argv[0]);

        return 1;
    }

    return display_image(argv[1]);
}