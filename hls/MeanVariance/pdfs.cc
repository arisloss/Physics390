#include <math.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include "pdfs.hh"




// -----------------------------------------------------------------------------
// gaussian PDF
// -- interface updated for HLS 
// -----------------------------------------------------------------------------
double 
pdf_gaussian( double x, double (&params)[2] ) 
// -----------------------------------------------------------------------------
{ 
  double mu = params[0];
  double sigma = params[1];
  double arg_exp = -(x-mu)*(x-mu)/(2*sigma*sigma);
  double arg_amp = 1./(sigma*sqrt(2*M_PI));
  return arg_amp*exp(arg_exp);
}


