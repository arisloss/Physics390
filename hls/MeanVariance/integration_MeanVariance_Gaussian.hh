#ifndef INTEGRATION_MEANVARIANCE
#define INTEGRATION_MEANVARIANCE

#include <vector>


#ifndef GCC
#include "hls_stream.h"
#endif

//
// set this when generating RTL for export
// take default RAND_MAX for cosim ...
///
//#define RAND_MAX 0xFFFFFFFF


typedef struct { 
  double integral;
  double variance;
  double error;
} MeanVarianceResults;

#ifdef GCC
MeanVarianceResults integrate_1D_MeanVariance_Gaussian( double params_0, double params_1, 
							double range_i, double range_f, 
							unsigned long ntrials,
							std::vector<unsigned> &rand );
#else
MeanVarianceResults integrate_1D_MeanVariance_Gaussian( double params_0, double params_1, 
							double range_i, double range_f, 
							unsigned long ntrials,
							hls::stream<unsigned> &rand );
#endif



#endif

