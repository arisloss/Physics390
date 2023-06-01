#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "integration_MeanVariance.hh"


//------------------------------------------------------------------------------
//
// Integrate by taking the average function value within a sample of many trials
//
//------------------------------------------------------------------------------
MeanVarianceResults
integrate_1D_MeanVariance( double (*function)(double, double*), 
			   double* params, 
			   double range_i, double range_f, 
			   unsigned long ntrials)
//------------------------------------------------------------------------------
{

  MeanVarianceResults results;

  double sum=0, ssum=0.;
  double V = (range_f-range_i);
  for( int i=0; i<ntrials; i++ ) {
    double x = range_i + V*rand()/RAND_MAX;
    double y = function(x,params);
    sum += y; ssum += y*y;
  } // trials

  double mean = sum/ntrials;
  results.integral     = V*mean;
  results.variance     = (1./(ntrials-1))*(ssum - ntrials*mean*mean); 
  results.error        = V*sqrt(results.variance/ntrials);
  return results;
}


