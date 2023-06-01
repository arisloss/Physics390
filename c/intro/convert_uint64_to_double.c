#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char** argv) { 

  if( !argc ) { 
    fprintf(stderr, "convert needs at least one argument ...\n");
    return -1;
  }

  printf("\n");
  for( int i=1; i<argc; i++ ) {
    uint64_t uval   = strtoul(argv[i],NULL,16);
    uint64_t * uptr = (uint64_t*)&uval;
    double   * dptr = (double*)uptr;
    printf( "uint64: 0x%016lx double : %lf\n", *uptr, *dptr); 
  }
  printf("\n");

}
