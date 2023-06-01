#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "integration_MeanVariance.hh"
#include "probability.hh"



int 
main(int argc, char** argv ) 
{ 
  
  unsigned seed = strtoul(argv[1],NULL,10);
  unsigned long ntrials = strtoul(argv[2],NULL,10);
  unsigned long nevents = strtoul(argv[3],NULL,10);

  double params = { 0., 1. };  // mu, sigma
  srand(seed);

  double range_i = -5.;
  double range_f =  5.;


  MeanVarianceResults results; 
  for(int i=0; i<ntrials; i++ ) {


    results  = integrate_1D_MeanVariance(&pdf_gaussian, (double*)&params, range_i, range_f, nevents );
    fprintf( stderr, "i: %d\tintegral: %lf\terror: %lf\tNevents: %lu\n", 
	     i, results.integral, results.error, nevents);
  }
}
