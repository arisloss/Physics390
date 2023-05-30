#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <sys/time.h>
#include <iostream>
#include "integration_MeanVariance_Gaussian.hh"


#ifdef GCC
#define NTRIALS 1000000
#else 
#define NTRIALS 1
#endif

#define NEVENTS 10000
//#define NEVENTS 1000

int main()
{

  std::vector<unsigned> deltaT, deltaTs, deltaTus;
  std::vector<double> int_val, int_err;
  struct timeval t_start, t_stop;
#ifdef GCC
  std::vector<unsigned> prng;
#else 
  hls::stream<unsigned> prng;
#endif

  const double range_i = -5.;
  const double range_f = 5.;
  const double mean = 0.;
  const double sigma = 1.;
  double gaussian_params[] = {mean, sigma};

  for ( int i=0; i<NTRIALS; i++ ) {

#ifdef GCC
    prng.clear();
#endif

    for( int j=0; j<NEVENTS; j++ ) { 
      unsigned rnum = rand();
#ifdef GCC      
      prng.push_back(rnum);
#else
      prng.write(rnum);
#endif
    }
  
    gettimeofday(&t_start,NULL);
    MeanVarianceResults results = 
      integrate_1D_MeanVariance_Gaussian( gaussian_params[0], gaussian_params[1],
    range_i, range_f, NEVENTS, prng );

    gettimeofday(&t_stop,NULL);
    deltaT.push_back(1e6*(t_stop.tv_sec-t_start.tv_sec) + (t_stop.tv_usec-t_start.tv_usec));
    int_val.push_back(results.integral);
    int_err.push_back(results.error);
  }

  for( int i=0; i<NTRIALS; i++ )
    printf("i: %d integral: %lf error: %lf deltaT: %u\n",// deltaTs: %u deltaTus: %u\n", 
	   i, int_val[i], int_err[i], deltaT[i]);//, deltaTs[i], deltaTus[i]);
}
