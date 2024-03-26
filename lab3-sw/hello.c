/*
 * Userspace program that communicates with the vga_ball device driver
 * through ioctls
 *
 */

#include <stdio.h>
#include "vga_ball.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#define SCREEN_WIDTH 640 
#define SCREEN_HEIGHT 480
#define SPEED 1
#define BALL_RADIUS 40

int vga_ball_fd;

/* Read and print the background color */
void print_background_color() {
  vga_ball_arg_t vla;
  
  if (ioctl(vga_ball_fd, VGA_BALL_READ_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_READ_BACKGROUND) failed");
      return;
  }
  printf("%02x %02x %02x\n",
	 vla.background.red, vla.background.green, vla.background.blue);
}

/* Set the background color */
void set_background_color(const vga_ball_color_t *c)
{
  vga_ball_arg_t vla;
  vla.background = *c;
  if (ioctl(vga_ball_fd, VGA_BALL_WRITE_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_SET_BACKGROUND) failed");
      return;
  }
}

/* Set the ball coordinates */
void set_ball_coordinates(const vga_ball_coord_t *coord)
{
  vga_ball_arg_t vla;
  vla.coordinates = *coord;
  if (ioctl(vga_ball_fd, VGA_BALL_WRITE_COORD, &vla)) {
      perror("ioctl(VGA_BALL_SET_BALL_COORDINATES) failed");
      return;
  }
  //printf("%s \n", "Setting ball coords");
}

void print_ball_coordinates() {
  vga_ball_arg_t vla;
  
  if (ioctl(vga_ball_fd, VGA_BALL_READ_COORD, &vla)) {
      perror("ioctl(VGA_BALL_READ_COORD) failed");
      return;
  }
  printf("%d %d \n",
	 vla.coordinates.h, vla.coordinates.v);
}
int main()
{
  vga_ball_coord_t ball_coord; 
  short v_h,v_v; // speed 

  static const char filename[] = "/dev/vga_ball";
  static const vga_ball_color_t background = {0xFF, 0xFF, 0xFF};

  printf("VGA ball Userspace program started\n");

  if ( (vga_ball_fd = open(filename, O_RDWR)) == -1) {
    fprintf(stderr, "could not open %s\n", filename);
    return -1;
  }

  printf("initial state: ");
  set_background_color(&background);
  print_background_color();
  v_h = SPEED;
  v_v = SPEED;
  ball_coord = (vga_ball_coord_t){.h = SCREEN_WIDTH*7/8, .v = SCREEN_HEIGHT*7/8};

  while(1){
    // touch right edge
    if(ball_coord.h + SPEED + BALL_RADIUS > SCREEN_WIDTH){
	    v_h = -v_h;
	    printf("hit right");
    }
    // touch left edge
    else if(ball_coord.h - SPEED < 0){
	    v_h = -v_h;
	    printf("hit left");
    }
    // touch bottom edge
    else if(ball_coord.v + SPEED + BALL_RADIUS > SCREEN_HEIGHT){
	    v_v = -v_v;
	    printf("hit bottom");
    }
    // touch top edge
    else if(ball_coord.v - SPEED < 0){
	    v_v = -v_v;
	    printf("hit top");
    }

    ball_coord.h += v_h;
    ball_coord.v += v_v;
    
    set_ball_coordinates(&ball_coord);
    //printf("v = %d, h = %d , v_v = %d, v_h = %d \n", ball_coord.v, ball_coord.h, v_v, v_h);

    usleep(10000); // sleep for 0.01s (100FPS)
  }
  printf("VGA BALL Userspace program terminating\n");
  return 0;
}
