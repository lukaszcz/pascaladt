#!/bin/bash
              #########################################
              # PascalAdt library installation script #
              #########################################

# VERSION is the number of the library version with nothing prepended
# or appended

VERSION="0.5.0"

# VERSION_SUFFIX must have a dash ("-") prepended and nothing should be
# appended to the version number 

VERSION_SUFFIX="-$VERSION"
DYNAMIC_LIB_STEM=libpascaladt
STATIC_LIB_STEM=libppascaladt
FILE_OVERWRITE=0
DEBUG_FILE_OVERWRITE=0
INSTALL_OPTS=
UNINST_SCRIPT_FILE="uninstall-pascaladt${VERSION_SUFFIX}.sh"
# a .ppu file present in every version; used to check for other versions
CRITICAL_INCLUDE_FILE=adtcont.ppu
CRITICAL_SMART_LIB_FILE=libpadtcont.a

function checked_eval()
{
    echo $*
    if ! eval $* ; then
	echo "install.sh: Error - exiting"
	exit 3
    fi
}

function check_persent()
{
    eval "$1 --version >/dev/null 2>&1"
    if [ "$?" != 127 ]; then
	return 0;
    else
	return 1;
    fi;
}

function check_dir()
{
    if [ ! -d "$1" ]; then
	read -n 1 -p "Directory $1 does not exist. Create? (y/n) "
	echo
	if [ "$REPLY" = n ]; then
	    echo "Not confirmed - exiting."
	    exit 1
	else
	    checked_eval mkdir $1
	fi
    fi    
}

function should_overwrite_ppu()
{
    eval '[ $'$1'FILE_OVERWRITE == 1 -o \( ! -f ${'$1'INCLUDE_DIR}${CRITICAL_INCLUDE_FILE} \) ]'
}

# processes a directory name in $REPLY; appends a slash if not already present
function process_dirname()
{
    REPLY=`eval 'echo -n '$REPLY` # to have path/tidle expansion work
    if [ ! "${REPLY:${#REPLY}-1:1}" == '/' ]; then
	REPLY=$REPLY/
    fi
}

# install_release() installs one of the release versions of the
# library $1 - make target; $2 - the name of the library file(s); $2
# is evaluated only after all the files are created (so that you may
# use wildcards); $3 - any additional options to install (including
# file permissions); $4 - additional options to the compiler;
# $5 - additional options to mcp;

function install_release()
{
    checked_eval "make fastclean > /dev/null 2>&1"
    checked_eval make release $1 OPTS="$4" VER="$VERSION_SUFFIX" MCP_OPTS="$5"
    LIB_FILES=`eval "echo -n $2"`
    
    checked_eval install $3 $INSTALL_OPTS $LIB_FILES $LIB_DIR
	
    if [ $MAKE_UNINST_SCRIPT == 1 ]; then
	echo "cd ${LIB_DIR}" >> $UNINST_SCRIPT_FILE
	echo "rm ${LIB_FILES}" >> $UNINST_SCRIPT_FILE
    fi
} # end install_release

echo
echo "PascalAdt $VERSION installation script."
echo
echo "You may pass additional options to the copiler by invoking this"
echo "script like this: install.sh <additional compiler options>"
echo "See the INSTALL file."
echo

if check_persent srcdoc; then
    SRCDOC_PRESENT=1
else
    SRCDOC_PRESENT=0
fi

read -e -p "Enter the library directory (default /usr/local/lib/): "
if [ $REPLY ]; then
    process_dirname
    LIB_DIR=$REPLY
else
    LIB_DIR="/usr/local/lib/"
fi

read -e -p "Enter the include directory (default /usr/local/include/): "
if [ $REPLY ]; then
    process_dirname
    INCLUDE_DIR=$REPLY
else
    INCLUDE_DIR="/usr/local/include/"
fi

read -n 1 -p "Make a dynamic library? (y/n) "
echo
if [ "$REPLY" != n ]; then
    MAKE_DYNAMIC=1
else
    MAKE_DYNAMIC=0
fi

read -n 1 -p "Make a smartlinked static library? (y/n) "
echo
if [ "$REPLY" != "n" ]; then
    MAKE_SMART=1
else
    MAKE_SMART=0
fi

read -n 1 -p "Make a non-smartlinked static library? (n/y) "
echo
if [ "$REPLY" != "y" ]; then
    MAKE_STATIC=0
else
    MAKE_STATIC=1
fi

read -n 1 -p "Install debug version also? (y/n) "
echo
if [ "$REPLY" == n ]; then
    INSTALL_DEBUG=0
else
    INSTALL_DEBUG=1
fi

if [ $INSTALL_DEBUG == 1 ]; then
    read -e -p "Enter the library directory for the debug version (default ${LIB_DIR}debug/): "
    if [ $REPLY ]; then
	process_dirname
	DEBUG_LIB_DIR=$REPLY
    else
	DEBUG_LIB_DIR="${LIB_DIR}debug/"
    fi

    read -e -p "Enter the include directory for the debug version (default ${INCLUDE_DIR}debug/): "
    if [ $REPLY ]; then
	process_dirname
	DEBUG_INCLUDE_DIR=$REPLY
    else
	DEBUG_INCLUDE_DIR="${INCLUDE_DIR}debug/"
    fi
fi

MCPOPTS=
read -n 1 -p "Generate template instatiations for Pointer? (n/y) "
echo
if [ "$REPLY" == "y" ]; then
    MCPOPTS="-dMCP_POINTER $MCPOPTS"
fi
read -n 1 -p "Generate template instatiations for Integer? (n/y) "
echo
if [ "$REPLY" == "y" ]; then
    MCPOPTS="-dMCP_INTEGER $MCPOPTS"
fi
read -n 1 -p "Generate template instatiations for Cardinal? (n/y) "
echo
if [ "$REPLY" == "y" ]; then
    MCPOPTS="-dMCP_CARDINAL $MCPOPTS"
fi
read -n 1 -p "Generate template instatiations for Real? (n/y) "
echo
if [ "$REPLY" == "y" ]; then
    MCPOPTS="-dMCP_REAL $MCPOPTS"
fi

if [ $SRCDOC_PRESENT == 1 ]; then
    read -n 1 -p "Make documentation also? (y/n) "
    echo
    if [ "$REPLY" == n ]; then
	MAKE_DOCUMENTATION=0
    else
	MAKE_DOCUMENTATION=1
    fi
else
    MAKE_DOCUMENTATION=0
fi

read -n 1 -p "Generate uninstallation script? (y/n) "
echo
if [ "$REPLY" == n ]; then
    MAKE_UNINST_SCRIPT=0
else
    MAKE_UNINST_SCRIPT=1
    rm $UNINST_SCRIPT_FILE > /dev/null 2>&1
fi

echo

# create directories if not already exist

check_dir ${LIB_DIR}
check_dir ${INCLUDE_DIR}

if [ $INSTALL_DEBUG == 1 ]; then
    check_dir ${DEBUG_LIB_DIR}
    check_dir ${DEBUG_INCLUDE_DIR}
fi

# check for older versions

if [ -f ${INCLUDE_DIR}${CRITICAL_INCLUDE_FILE} ]; then
    echo "Another version of PascalAdt found. The binary library files"
    echo "will be preserved, but if the .ppu files are overwritten linking "
    echo "with the old debug version may no longer be possible."
    read -n 1 -p "Overwrite files? (n/y) "
    echo
    echo
    if [ "$REPLY" == "y" ]; then
	FILE_OVERWRITE=1
    fi
fi

if [ $INSTALL_DEBUG == 1 ]; then
    if [ -f ${DEBUG_INCLUDE_DIR}${CRITICAL_INCLUDE_FILE} ]; then
	echo "Another debug version of PascalAdt found. The binary library files"
	echo "will be preserved, but if the .ppu files are overwritten linking "
	echo "with the old debug version may no longer be possible."
	read -n 1 -p "Overwrite files? (n/y) "
	echo
	echo
	if [ "$REPLY" == "y" ]; then
	    DEBUG_FILE_OVERWRITE=1
	fi
    fi
fi

# compile and install the release version(s)

if [ $MAKE_DYNAMIC == 1 ]; then
    install_release dynamic ${DYNAMIC_LIB_STEM}${VERSION_SUFFIX}.so " " "$*" "$MCPOPTS";
fi

if [ $MAKE_SMART == 1 ]; then
    install_release smart '*.a' "-m 644" "$*" "$MCPOPTS";
fi

if [ $MAKE_STATIC == 1 ]; then
    install_release static ${STATIC_LIB_STEM}${VERSION_SUFFIX}.a "-m 644" "$*" "$MCPOPTS";
fi

if should_overwrite_ppu "" ; then
    checked_eval install -m 644 $INSTALL_OPTS *.ppu $INCLUDE_DIR
fi

if [ $MAKE_UNINST_SCRIPT == 1 ] && should_overwrite_ppu "" ; then
    echo "cd ${INCLUDE_DIR}" >> $UNINST_SCRIPT_FILE
    echo rm *.ppu >> $UNINST_SCRIPT_FILE
fi


# compile and install the debug version

if [ $INSTALL_DEBUG == 1 ]; then
    DEBUG_LINK_PATH=${DEBUG_LIB_DIR}${STATIC_LIB_STEM}.a
    DEBUG_LIB_PATH=${DEBUG_LIB_DIR}${STATIC_LIB_STEM}${VERSION_SUFFIX}.a
    checked_eval "make fastclean > /dev/null 2>&1"
    checked_eval make debug static OPTS=$* VER="$VERSION_SUFFIX" MCP_OPTS="$MCPOPTS"
    checked_eval install -m 644 $INSTALL_OPTS ${STATIC_LIB_STEM}${VERSION_SUFFIX}.a ${DEBUG_LIB_DIR}
    if should_overwrite_ppu DEBUG_ ; then
	checked_eval install -m 664 $INSTALL_OPTS *.ppu ${DEBUG_INCLUDE_DIR}
    fi

    if [ $MAKE_UNINST_SCRIPT == 1 ]; then
	echo "rm ${DEBUG_LIB_PATH}" >> $UNINST_SCRIPT_FILE
	if should_overwrite_ppu DEBUG_ ; then
	    echo "cd ${DEBUG_INCLUDE_DIR}" >> $UNINST_SCRIPT_FILE
	    echo rm *.ppu >> $UNINST_SCRIPT_FILE
	fi
    fi
fi


# make the documentation

if [ $MAKE_DOCUMENTATION == 1 ]; then
    checked_eval "make cleandocs"
    checked_eval "make docs VER=${VERSION}"
fi


echo
echo "Installation finished."
if [ $MAKE_UNINST_SCRIPT == 1 ]; then
    chmod +x $UNINST_SCRIPT_FILE
    echo "Uninstallation script written to $UNINST_SCRIPT_FILE"
fi
if [ $MAKE_DOCUMENTATION == 0 ]; then
    echo "You may download the documentation from http://students.mimuw.edu.pl/~lc235951/pascaladt/"
fi
