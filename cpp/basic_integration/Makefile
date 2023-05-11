CPP = g++
CPPFLAGS = -g -Iinclude -I../probability/include -fno-omit-frame-pointer
LDFLAGS = -L../probability/lib -Llib  -lprobability -lintegration

#CPPFLAGS =  -I../../glibc/include -Iinclude -I../probability/include -Wl,--rpath=../../glibc/lib:/usr/lib64 -Wl,--dynamic-linker=../../glibc/lib/ld-linux-x86-64.so.2  -pg
#LDFLAGS = -L../probability/lib -Llib  -lprobability -lintegration

ifdef PERF_TIME
CPPFLAGS := $(CPPFLAGS) -DPERF_TIME
endif

ifdef PERF_OPT
CPPFLAGS := $(CPPFLAGS) -O$(PERF_OPT)
endif

all : lib test

objs = integration_Naive.o integration_MeanVariance.o
objs := $(addprefix obj/, $(objs)) 

lib : $(objs)
	ar -r lib/libintegration.a $^ 

deplib : 
	$(MAKE) -C ../probability lib


bin/test_% : test/test_%.cc lib deplib
	$(CPP) $(CPPFLAGS) $(filter %.o %.cc, $^) $(LDFLAGS) -o $@

bin/% : src/%.cc lib
	$(CPP) $(CPPFLAGS) $(filter %.o %.cc, $^) $(LDFLAGS) -o $@

obj/%.o : src/%.cc 
	$(CPP) $(CPPFLAGS) -c $^ -o $@


test : bin/test_pi_1D_Naive bin/test_pi_1D_MeanVariance  bin/test_pi_1D_MeanVariance bin/test_importance bin/test_pi_2D_Naive bin/test_maxwell_boltzmann_MeanVariance bin/test_maxwell_boltzmann_Naive bin/test_my_maxwell_Naive




clean : 
	rm -f bin/*
	find  obj -name '*.o' -exec rm {} \;
	rm -f lib/*.a
	find ./ -name '*~' -exec rm {} \;
	find ./ -name '#*' -exec rm {} \;
	$(MAKE)  -C ../probability clean

realclean : clean
	rm -f bin/*.dat

