#!/bin/sh
if [ $# -lt 2 ]
then
    echo "usage: `basename $0` <target[.so]> src1.a .. srcN.a [obj1.o .. objN.o]"
    exit 1
fi

OTMPDIR="/tmp/hb-mkslib-$$"
HB_SO_LIB="$1"
shift
case "${HB_SO_LIB}" in
    *.so)
	;;
    *)
	HB_SO_LIB="${HB_SO_LIB}.so"
	;;
esac
dir=`pwd`

cleanup()
{
    rm -fR "${OTMPDIR}"
}

trap cleanup EXIT &>/dev/null

rm -fR "${OTMPDIR}"
mkdir -p "${OTMPDIR}"
cd "${OTMPDIR}"

for f in $*
do
    if [ ! -r "${dir}/${f}" ]
    then
	echo "cannot read file: ${f}"
	exit 1
    fi
    case "${f}" in
	*.o)
	    cp "${dir}/${f}" "${OTMPDIR}" || exit 1
	    ;;
	*.a)
	    ar -x "${dir}/${f}" || exit 1
	    ;;
	*)
	    echo "unrecognized file: ${f}"
	    exit 1
	    ;;
    esac
done

cd "${dir}"
rm -f "${HB_SO_LIB}"
cd "${OTMPDIR}"

base=`basename "${HB_SO_LIB}"`
gcc -shared -o "${base}" *.o && \
    cd "${dir}" && \
    mv -f "${OTMPDIR}/${base}" "${HB_SO_LIB}"

stat="$?"
cleanup
exit "${stat}"
