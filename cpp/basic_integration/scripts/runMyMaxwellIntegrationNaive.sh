#!/bin/bash

ntrials=1000
sample_sizes=( 10 100 1000 10000 100000 1000000 10000000 );

i=0;
while (( $i < ${#sample_sizes[*]} )); 
  do 
  samples=${sample_sizes[$i]}
  fname=./data/maxwell_${ntrials}_samples_${samples}.dat

  if [ -e $fname  ]; then
      rm $fname 
  fi;

  echo "running sample size $samples"

  j=0;
  while (( $j < $ntrials )); 
    do 
    ./bin/test_my_maxwell_Naive $RANDOM $samples 2>> $fname
    (( j++ ));
  done;

  (( i++ ));

done ;
