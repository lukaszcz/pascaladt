#!/bin/sh

for file in test*
do
  if [ -x $file ]; then
      file=`echo $file | egrep -v "\.sh\>" | tr -d [:space:]`
      if [ $file ]; then 
	  if [ ! -d $file ]; then
	      rm $file 
	      if [ -a ${file}.o ]; then 
		  rm ${file}.o 
	      fi 
	  fi
      fi 
  fi 
done 
