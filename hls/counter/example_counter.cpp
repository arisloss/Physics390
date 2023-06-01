#include <stdio.h>

// prototype
unsigned counter(unsigned &initV, bool reset, bool count_up, unsigned &count);


int main()
{
  unsigned count=0;
  unsigned initV=0;
  unsigned internal_count;

  // large number of trials is fine for csim
  // but not for cosim ...
  // for ( int i=0; i<500000000; i++ ) {
  for ( int i=0; i<2000; i++ ) {
    internal_count = counter(initV,false,true,count);
    if( i<10 || (i>=1000 && i<1010) ) 
      printf("i: %d internal_count: %u count : %u\n", i, internal_count, count);
  }
  printf("final: internal_count: %u count : %u\n", internal_count, count);
}
