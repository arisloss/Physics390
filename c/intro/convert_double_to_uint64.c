#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char** argv) { 

  if( !argc ) { 
    fprintf(stderr, "convert needs at least one argument ...\n");
    return -1;
  }

  for( int i=1; i<argc; i++ ) {
    double dval   = strtod(argv[i],NULL);
    double * dptr = (double*)&dval;
    uint64_t * uptr = (uint64_t*)dptr;
    printf( "double : %lf uint64: 0x%016lx\n", *dptr, *uptr); 
  }

}
