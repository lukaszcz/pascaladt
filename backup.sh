#!/bin/sh

# PascalAdt library backup script

# warning: files other than *.pas, *.inc, *.sh Makefile or
# Makefile.fpc or INSTALL or README or NEWS or LICENSE are not saved;
# directories other than tests or docsrc or delphi are not saved; all
# files from docsrc are saved, from tests and its units subdirectory
# only those mentioned above.

SAVED_DIR="adt_save"
OTHER_FILES_TO_SAVE="Makefile Makefile.fpc INSTALL README NEWS LICENSE"
FILES_TO_SAVE="*.pas *.sh *.inc *.i *.mcp *.mac *.txt ${OTHER_FILES_TO_SAVE}"
CP_OPTS=-dup

if [ ! -d ${SAVED_DIR} ]; then
	if [ -a ${SAVED_DIR} ]; then
		rm ${SAVED_DIR};
	fi
	mkdir ${SAVED_DIR};
fi

if [ ! -d ${SAVED_DIR}/demo ]; then
	if [ -a ${SAVED_DIR}/demo ]; then
		rm ${SAVED_DIR}/demo;
	fi
	mkdir ${SAVED_DIR}/demo;
fi

if [ ! -d ${SAVED_DIR}/demo/customer ]; then
	if [ -a ${SAVED_DIR}/demo/customer ]; then
		rm ${SAVED_DIR}/demo/customer;
	fi
	mkdir ${SAVED_DIR}/demo/customer;
fi

if [ ! -d ${SAVED_DIR}/tests ]; then
	if [ -a ${SAVED_DIR}/tests ]; then
		rm ${SAVED_DIR}/tests;
	fi
	mkdir ${SAVED_DIR}/tests;
fi

if [ ! -d ${SAVED_DIR}/tests/units ]; then
	if [ -a ${SAVED_DIR}/tests/units ]; then
		rm ${SAVED_DIR}/tests/units;
	fi
	mkdir ${SAVED_DIR}/tests/units;
fi

if [ ! -d ${SAVED_DIR}/tests/units/cpu ]; then
	if [ -a ${SAVED_DIR}/tests/units/cpu ]; then
		rm ${SAVED_DIR}/tests/units/cpu;
	fi
	mkdir ${SAVED_DIR}/tests/units/cpu;
fi

if [ ! -d ${SAVED_DIR}/docs ]; then
    if [ -a ${SAVED_DIR}/docs ]; then
	rm ${SAVED_DIR}/docs;
    fi
    mkdir ${SAVED_DIR}/docs;
fi

if [ ! -d ${SAVED_DIR}/delphi ]; then
    if [ -a ${SAVED_DIR}/delphi ]; then
	rm ${SAVED_DIR}/delphi;
    fi
    mkdir ${SAVED_DIR}/delphi;
fi

if [ ! -d ${SAVED_DIR}/z_other ]; then
	if [ -a ${SAVED_DIR}/z_other ]; then
		rm ${SAVED_DIR}/z_other;
	fi
	mkdir ${SAVED_DIR}/z_other;
fi

cp ${CP_OPTS} *.inc *.i *.pas.mcp ${OTHER_FILES_TO_SAVE} ./${SAVED_DIR}
for NAME in adt*.pas
do
  if [ ! -f ${NAME}.mcp ]; then
      cp ${CP_OPTS} ${NAME} ./${SAVED_DIR}
  fi
done
for NAME in *.sh
do
  if [ ! `echo -n $NAME | grep uninstall` ]; then
      cp ${CP_OPTS} ${NAME} ./${SAVED_DIR}
  fi
done
cd demo
cp ${CP_OPTS} ${FILES_TO_SAVE} ../${SAVED_DIR}/demo
cd customer
cp ${CP_OPTS} ${FILES_TO_SAVE} ../../${SAVED_DIR}/demo/customer
cd ../../tests
cp ${CP_OPTS} ${FILES_TO_SAVE} ../${SAVED_DIR}/tests
cd units
cp ${CP_OPTS} ${FILES_TO_SAVE} ../../${SAVED_DIR}/tests/units
cd cpu
cp ${CP_OPTS} ${FILES_TO_SAVE} ../../../${SAVED_DIR}/tests/units/cpu
cd ../../../
cp ${CP_OPTS} -R tools ./${SAVED_DIR}
cp ${CP_OPTS} -R docsrc ./${SAVED_DIR}
cp ${CP_OPTS} -R delphi ./${SAVED_DIR}
other_files=`ls *.pas | egrep -v '(\badt.*\.pas\b)|(\btest.*\.pas\b)'`
if [ `echo $other_files | tr -d '[:space:]'` ]; then
    cp ${CP_OPTS} $other_files ./${SAVED_DIR}/z_other;
else
    rmdir ./${SAVED_DIR}/z_other
fi
tar -czf ${SAVED_DIR}.tar.gz ./${SAVED_DIR}

if [ $1 -a -d $1 ]; then
    SAVEDIR="${1}/${SAVED_DIR}"
    if [ ! -d $SAVEDIR ]; then
	mkdir $SAVEDIR;
    fi
    cp ${SAVED_DIR}.tar.gz $SAVEDIR;
    SEDSTR="s|\$PWD|\"${SAVEDIR}\"|"
    cat unbackup.sh | sed $SEDSTR > ${SAVEDIR}/unbackup;
fi

