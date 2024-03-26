		input logic [7:0]  writedata, // changed to 16 bits (use iowrite16 in the sw part)
		input logic 	   write,
		input 		   chipselect,
		input logic [2:0]  address,

		output logic [7:0] VGA_R, VGA_G, VGA_B,
		output logic 	   VGA_CLK, VGA_HS, VGA_VS,
		                   VGA_BLANK_n,
		output logic 	   VGA_SYNC_n);

   logic [10:0]	   hcount;
   logic [9:0]     vcount;

   logic [7:0]	   h_ball_lsb; // horizontal coordinate ball
   logic [7:0]	   h_ball_msb; 
   logic [7:0]	   v_ball_lsb; 
   logic [7:0]	   v_ball_msb;

   logic [15:0] h_ball;
   logic [15:0] v_ball;

   logic [7:0] 	   background_r, background_g, background_b;
	
   vga_counters counters(.clk50(clk), .*);

   always_ff @(posedge clk)
     if (reset) begin
	background_r <= 8'h0;
	background_g <= 8'h0;
	background_b <= 8'h80;
    h_ball <= 16'd150;
    v_ball <= 16'd150;
     end else if (chipselect && write)
       case (address)
	 3'h0 : background_r <= writedata;
	 3'h1 : background_g <= writedata;
	 3'h2 : background_b <= writedata;
	 3'h3 : h_ball_msb <= writedata; // read horizontal coordinate ball
	 3'h4 : h_ball_lsb <= writedata; 
	 3'h5 : v_ball_msb <= writedata;
	 3'h6 : v_ball_lsb <= writedata;
       endcase
   /*
   always_comb begin
       v_ball = {v_ball_msb, v_ball_lsb};
       h_ball = {h_ball_msb, h_ball_lsb};
      {VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0};
      
      if (VGA_BLANK_n) begin
        
          if (hcount[10:1] > h_ball[9:0] && hcount[10:1] < h_ball[9:0] + 10'd10 && 
              vcount > v_ball[9:0] && vcount[9:0] < v_ball + 10'd10) begin
            {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'h00}; // Change color from white to black
           end else
          {VGA_R, VGA_G, VGA_B} = {background_r, background_g, background_b};
        end
   end
   */

  /* Logic for ball */ 
  always_comb begin 
       v_ball = {v_ball_msb, v_ball_lsb};
       h_ball = {h_ball_msb, h_ball_lsb};
      {VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0};

      if (VGA_BLANK_n) begin
          if ((hcount[10:1] - (h_ball + 20))**2 + (vcount- (v_ball+20))**2 <= 20**2) begin
            {VGA_R, VGA_G, VGA_B} = {8'hff, 8'h00, 8'h00}; // Change color to red
          end
          else begin
            {VGA_R, VGA_G, VGA_B} = {background_r, background_g, background_b};
          end
      end
  end  

endmodule

module vga_counters(
 input logic 	     clk50, reset,
 output logic [10:0] hcount,  // hcount[10:1] is pixel column
 output logic [9:0]  vcount,  // vcount[9:0] is pixel row
 output logic 	     VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

/*
 * 640 X 480 VGA timing for a 50 MHz clock: one pixel every other cycle
 * 
 * HCOUNT 1599 0             1279       1599 0
 *             _______________              ________
 * ___________|    Video      |____________|  Video
 * 
 * 
 * |SYNC| BP |<-- HACTIVE -->|FP|SYNC| BP |<-- HACTIVE
 *       _______________________      _____________
 * |____|       VGA_HS          |____|
 */
   // Parameters for hcount
   parameter HACTIVE      = 11'd 1280,
             HFRONT_PORCH = 11'd 32,
             HSYNC        = 11'd 192,
             HBACK_PORCH  = 11'd 96,   
             HTOTAL       = HACTIVE + HFRONT_PORCH + HSYNC +
                            HBACK_PORCH; // 1600
   
   // Parameters for vcount
   parameter VACTIVE      = 10'd 480,
             VFRONT_PORCH = 10'd 10,
             VSYNC        = 10'd 2,
             VBACK_PORCH  = 10'd 33,
             VTOTAL       = VACTIVE + VFRONT_PORCH + VSYNC +
                            VBACK_PORCH; // 525

   logic endOfLine;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          hcount <= 0;
     else if (endOfLine) hcount <= 0;
     else  	         hcount <= hcount + 11'd 1;

   assign endOfLine = hcount == HTOTAL - 1;
       
   logic endOfField;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          vcount <= 0;
     else if (endOfLine)
       if (endOfField)   vcount <= 0;
       else              vcount <= vcount + 10'd 1;

   assign endOfField = vcount == VTOTAL - 1;

   // Horizontal sync: from 0x520 to 0x5DF (0x57F)
   // 101 0010 0000 to 101 1101 1111
   assign VGA_HS = !( (hcount[10:8] == 3'b101) &
		      !(hcount[7:5] == 3'b111));
   assign VGA_VS = !( vcount[9:1] == (VACTIVE + VFRONT_PORCH) / 2);

   assign VGA_SYNC_n = 1'b0; // For putting sync on the green signal; unused
   
   // Horizontal active: 0 to 1279     Vertical active: 0 to 479
   // 101 0000 0000  1280	       01 1110 0000  480
   // 110 0011 1111  1599	       10 0000 1100  524
   assign VGA_BLANK_n = !( hcount[10] & (hcount[9] | hcount[8]) ) &
			!( vcount[9] | (vcount[8:5] == 4'b1111) );

   /* VGA_CLK is 25 MHz
    *             __    __    __
    * clk50    __|  |__|  |__|
    *        
    *             _____       __
    * hcount[0]__|     |_____|
    */
   assign VGA_CLK = hcount[0]; // 25 MHz clock: rising edge sensitive
   
endmodule
