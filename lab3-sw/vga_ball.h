
#ifndef _VGA_BALL_H
#define _VGA_BALL_H

#include <linux/ioctl.h>

typedef struct {
	unsigned char red, green, blue;
} vga_ball_color_t;
  
typedef struct {
	signed short h, v;
} vga_ball_coord_t;

typedef struct {
  vga_ball_color_t background;
  vga_ball_coord_t coordinates;
} vga_ball_arg_t;

#define VGA_BALL_MAGIC 'q'

/* ioctls and their arguments */
#define VGA_BALL_WRITE_BACKGROUND _IOW(VGA_BALL_MAGIC, 1, vga_ball_arg_t *)
#define VGA_BALL_READ_BACKGROUND  _IOR(VGA_BALL_MAGIC, 2, vga_ball_arg_t *)

#define VGA_BALL_WRITE_COORD _IOW(VGA_BALL_MAGIC, 3, vga_ball_arg_t *)
#define VGA_BALL_READ_COORD _IOR(VGA_BALL_MAGIC, 4, vga_ball_arg_t *)

#endif
