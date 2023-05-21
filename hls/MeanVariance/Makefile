CPP = g++
CPPFLAGS = -g -O0  -I./ -DGCC  -fno-omit-frame-pointer


all : cpp #hls

cpp : 
	$(CPP) $(CPPFLAGS) pdfs.cc integration_MeanVariance_Gaussian.cc integration_testbench.cpp  -o integration_testbench.exe -lm

hls : 
	vitis_hls -f run_hls.tcl


clean : 
	rm *.exe

