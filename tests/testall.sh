#!/bin/sh

./testmem | tee testmem.log
./testdarray | tee testdarray.log
./testsegarray | tee testsegarray.log
./testallconts | tee testsegarray.log
./testallalgs | tee testsegarray.log
./teststralgs | tee testsegarray.log

