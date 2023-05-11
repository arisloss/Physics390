#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "integration_Naive.hh"
#include "probability.hh"

#ifdef PERF_TIME
#include <sys/time.h>
struct timeval t_start, t_stop;
#endif

// Copied and edited from test_pi_1D_Naive.cc

int 
main(int argc, char** argv ) 
{ 

  unsigned seed = strtoul(argv[1],NULL,10);
  unsigned long ntrials = strtoul(argv[2],NULL,10);
  unsigned verbose=0;
  if( argc > 3 ) { 
    verbose = 1;
  }

  Points2D points;
  double params[] = { 2. }; // Maxwell-Boltzmann param of a=2
  srand(seed);

  double area;

#ifdef PERF_TIME
  gettimeofday(&t_start,NULL);
#endif

  if( verbose ) area=integrate_1D_Naive(&pdf_maxwell_boltzmann, (double*)&params, 0., 10., ntrials, &points);
  else          area=integrate_1D_Naive(&pdf_maxwell_boltzmann, (double*)&params, 0., 10., ntrials );

#ifdef PERF_TIME
  gettimeofday(&t_stop,NULL);
  unsigned delta_t = 1e6*(t_stop.tv_sec - t_start.tv_sec) + (t_stop.tv_usec - t_start.tv_usec);

  // with true error
  // area under distribution is ~1
  //fprintf( stderr, "Area: %lf\terror: %lf\tNtrials: %lu\tusec: %lu\n", 
  //   area, binomial_error(ntrials, 1*ntrials), ntrials, delta_t);
#else

  // with true error
  //fprintf( stderr, "Area: %lf\terror: %lf\tNtrials: %lu\n", 
  //   area, binomial_error(ntrials, 1*ntrials), ntrials);
#endif

  // with estimated error
  fprintf( stderr, "Area: %lf\terror: %lf\tNtrials: %lu\n", area, binomial_error(ntrials, (area/100)*ntrials), ntrials);



}
