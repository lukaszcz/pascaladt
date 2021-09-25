#!/bin/sh

# PascalAdt library package creation script

if [ $1 ]; then
    PACKAGE=pascaladt-$1
    PACKAGE_DOCS=${PACKAGE}-docs
    PACKAGE_FILE=${PACKAGE}.src.tar.gz
    PACKAGE_DOCS_FILE=${PACKAGE}.docs.tar.bz2
    ./backup.sh > /dev/null 2>&1
    mv adt_save $PACKAGE
    tar -czf $PACKAGE_FILE $PACKAGE
    cp $PACKAGE_FILE ./versions/
    cp $PACKAGE_FILE ~/html/homepage/pascaladt/download/
    make cleandocs
    make docs VER=$1
    cp docs ~/html/homepage/pascaladt/docs/
    mv docs $PACKAGE_DOCS
    tar -cjf $PACKAGE_DOCS_FILE $PACKAGE_DOCS
    cp $PACKAGE_DOCS_FILE ./versions/
    cp $PACKAGE_DOCS_FILE ~/html/homepage/pascaladt/download/
else
    echo "usage: package.sh <version number>"
fi
