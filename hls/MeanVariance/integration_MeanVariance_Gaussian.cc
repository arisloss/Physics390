#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "integration_MeanVariance_Gaussian.hh"
#include "pdfs.hh"

//------------------------------------------------------------------------------
//
// Integrate by taking the average function value within a sample of many trials
// For HLS, with a hard-coded 1D gaussian
//
//------------------------------------------------------------------------------
#ifdef GCC
MeanVarianceResults
integrate_1D_MeanVariance_Gaussian( double params_0, double params_1, 
				    double range_i, double range_f, 
				    unsigned long ntrials,
				    std::vector<unsigned>  &prand)
#else
MeanVarianceResults
integrate_1D_MeanVariance_Gaussian( double params_0, double params_1, 
				    double range_i, double range_f, 
				    unsigned long ntrials,
				    hls::stream<unsigned>  &prand)
#endif
//------------------------------------------------------------------------------
{

  //
  // copy inputs
  //
  double integrand_params[2];
  integrand_params[0] = params_0;
  integrand_params[1] = params_1;


  MeanVarianceResults results;

  double sum=0, ssum=0.;
  double V = (range_f-range_i);
  for( int i=0; i<ntrials; i++ ) {
#ifdef GCC
    double x = range_i + V*prand[i]/RAND_MAX;
#else 
    double x = range_i + V*prand.read()/RAND_MAX;
#endif
    double y = pdf_gaussian(x,integrand_params);
    sum += y; ssum += y*y;
  } // trials

  double mean = sum/ntrials;

  results.integral     = V*mean;
  results.variance     = (1./(ntrials-1))*(ssum - ntrials*mean*mean); 
  results.error        = V*sqrt(results.variance/ntrials);
  return results;
}


