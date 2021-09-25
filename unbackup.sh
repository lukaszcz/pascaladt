#!/bin/sh

TEMPDIR=/tmp
SRCDIR=$PWD
CPOPTS="-rp"
SAVED_DIR="adt_save"
if [ $1 ]; then
    if [ -d $1 ]; then
	TARGETDIR=$1;
	if [ $2 = "update" ]; then
		CPOPTS="${CPOPTS}u";
	fi
    elif [ $1 = "update" ]; then
	CPOPTS="${CPOPTS}u"
    else
	echo "SYNTAX: unbackup [targetdir] [update]"
	echo "   If update is specified then only files newer than those already "
	echo "   existing are extracted."
    fi;
else
    TARGETDIR=${HOME}/pascal/adt/;
fi

cd $TEMPDIR
rm -r ${SAVED_DIR}
tar -xzf ${SRCDIR}/${SAVED_DIR}.tar.gz
cp $CPOPTS ${TEMPDIR}/${SAVED_DIR}/* $TARGETDIR
rm -r ${TEMPDIR}/${SAVED_DIR}

