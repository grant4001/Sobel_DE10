# Sobel_DE10

In this project, the Sobel operator is implemented on the Terasic DE10-Nano platform with the D8M-GPIO 8M Pixel camera module. The DE10-Nano streams the output video via HDMI, which the user can toggle on/off via an onboard slide switch.

The incoming video stream (at 60 fps, 25 MHz) is converted into high luminosity grayscale, which provides greater contrast. The sobel filter is then applied in the form of two 3x3 kernels (x and y gradidents). 

![Sobel Sample](/images/sobel_cap.png)


The following aspects were implemented on the Cyclone V FPGA:

1. Verilog-to-VHDL interfacing between the D8M and Sobel modules, respectively.

2. FIFO instantiation for data buffering between the camera, grayscale, Sobel, and HDMI modules.

3. Using FIFOs to cross clock domains from the MIPI interface clock to image processing clock, and back to the HDMI clock.

4. Fast RGB-to-grayscale conversion via the luminosity approximation (bit shifts only).

5. Line buffering to store 3x3 sliding window.

6. Matrix multiplication via an inline function between the kernels and the gradient taps.

7. User can toggle between the Sobel-filtered or regular video stream.

Simulation and timing verification were done on ModelSim. Synthesis, PnR, Fitter, and timing analysis were done on Quartus Prime Lite.

References:

Terasic DE10-Nano Platform (datasheet): https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1046

Terasic D8M-GPIO Camera module (demo and datasheet): http://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1011

VGA timing guide (completely applicable to HDMI): https://timetoexplore.net/blog/video-timings-vga-720p-1080p

Sobel reference: https://docs.opencv.org/2.4/doc/tutorials/imgproc/imgtrans/sobel_derivatives/sobel_derivatives.html

Grayscale conversions: https://www.johndcook.com/blog/2009/08/24/algorithms-convert-color-grayscale/


