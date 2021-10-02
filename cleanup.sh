#!/bin/bash

FAST=0
if [ $1 ] && [ "$1" = "noprompt" ]; then
    REPLY="yes"
elif [ $1 ] && [ "$1" = "fast" ]; then
    FAST=1
    REPLY="yes"
else
    echo "This script will remove all files with extensions other than"
    echo ".pas or .inc or .sh or .mcp or with names other than ''Makefile'' or"
    echo "''Makefile.fpc'' or ''INSTALL'' or ''LICENSE'', etc."
    echo "It will leave the docs, docsrc, versions and delphi directories intact."
    echo "Do you want to proceed? (yes/no) "
    read
fi

FILES_TO_RETAIN='(\.pas$)|(\.inc$)|(\.i$)|(\.sh$)|(\.mcp$)|(\.mac$)|(^\.backup\.bpl$)'

if [ "$REPLY" = "yes" ]; then
    rm -f `ls -1 | grep '~'`;
    if [ $FAST = 0 ]; then
        rm -f uninstall*.sh
    fi
    rm -f -r `ls -1 | egrep -v "${FILES_TO_RETAIN}"'|(Makefile)|(Makefile\.fpc)|(INSTALL)|(README)|(LICENSE)|(NEWS)|(tests$)|(^docs$)|(docsrc)|(versions)|(delphi)|(^demo$)|(^tools$)'`;
    for FILENAME in *.mcp
    do
      if [ ! `ls -1 *.pas.mcp | grep $FILENAME` ]; then
          rm $FILENAME
      fi
    done
    for FILENAME in adt*.pas
    do
      if [ -f ${FILENAME}.mcp ]; then
          rm ${FILENAME}
      fi
    done

    cd tests
    rm -f `ls -1 | grep '~'`
    rm -f `ls -1 | egrep -v "${FILES_TO_RETAIN}"'|(units)'`;
    cd units
    rm -f `ls -1 | grep '~'`
    rm -f `ls -1 | egrep -v "${FILES_TO_RETAIN}"'|(cpu)'`;
    cd ../../demo
    rm -f `ls -1 | grep '~'`
    rm -f `ls -1 | egrep -v "${FILES_TO_RETAIN}"'|(customer)|(Makefile)'`;
    cd customer
    rm -f `ls -1 | grep '~'`
    rm -f `ls -1 | egrep -v "${FILES_TO_RETAIN}"'|(Makefile)'`;
    cd ../../docs
    rm -f `ls -1 | grep '~'`
    cd ../docsrc
    rm -f `ls -1 | grep '~'`
fi
