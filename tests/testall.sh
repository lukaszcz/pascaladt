#!/bin/sh

./testmem | tee testmem.log
./testdarray | tee testdarray.log
./testsegarray | tee testsegarray.log
./testallconts | tee testallconts.log
./testallalgs | tee testallalgs.log
./teststralgs | tee teststralgs.log

grep FAILED *.log
