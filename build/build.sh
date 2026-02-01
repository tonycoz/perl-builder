#!/bin/bash

set -ex

VERSION=$1
ROOT=$(pwd)

SRCURL=https://www.cpan.org/src/5.0/
GITURL=https://github.com/Perl/perl5.git

SRCDIR="${ROOT}/perl"
[ -e "${SRCDIR}" ] && rm -rf "${SRCDIR}"

# use git for blead (aka trunk) or maint and CPAN for releases
# I doubt maint will be used
case $VERSION in
blead|maint-*)
    BRANCH=${VERSION}
    VERSION=${VERSION}-$(date +%Y%m%d)

    # Setup perl checkout
    git clone --depth 1 --single-branch -b "${BRANCH}" "${GITURL}" "${SRCDIR}"

    REF=refs/heads/${BRANCH}
    REVISION=$(git ls-remote "${GITURL}" "${REF}" | cut -f 1)
    ;;
*)
    BASENAME="perl-$VERSION"
    FILE="${BASENAME}.tar.gz"
    ARCHIVEURL="${SRCURL}${FILE}"
    cd "${ROOT}"

    [ -e "${FILE}" ] && rm "${FILE}"
    curl -o "${FILE}" "${ARCHIVEURL}"

    # creates perl-X.XX.X aka $BASENAME
    [ -e "${BASENAME}" ] && rm -rf "${BASENAME}"
    tar xzf "${FILE}"
    mv "${BASENAME}" "${SRCDIR}"

    # patches older perls to build on modern systems
    perl -MDevel::PatchPerl -e 'Devel::PatchPerl->patch_source(@ARGV)' \
         "${VERSION}" "${SRCDIR}"
    REVISION="${VERSION}"
    ;;
esac

FULLNAME=perl-${VERSION}
OUTPUT=$2/${FULLNAME}.tar.xz

# determine build revision
LAST_REVISION="${3}"

echo "ce-build-revision:${REVISION}"
echo "ce-build-output:${OUTPUT}"

if [[ "${REVISION}" == "${LAST_REVISION}" ]]; then
  echo "ce-build-status:SKIPPED"
  exit
fi

STAGING_DIR=/opt/compiler-explorer/${FULLNAME}
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

# Configure build
# modern perls can use -Dmksymlinks to do an out of
# tree build, but I don't trust it for older perls
#
# -de - -d use defaults, -e don't prompt to build Makefile etc
# -s (silent) is also common here but may make diagnosis harder
# -Dusedevel - required to build blead, harmless for other builds except
#   it sets -Dversiononly
# -Uversiononly - installs a "perl" binary, not just perl$VERSION
# -Dusethreads - enable threads, commonly set by vendors
# -Dman1dir=none -Dman3dir=none - don't install man pages
# -Doptimize="-O2 -g" - -O2 is on by default, -g isn't
cd "${SRCDIR}"
./Configure \
    -de \
    -Dusedevel \
    -Uversiononly \
    -Dprefix="${STAGING_DIR}" \
    -Dusethreads \
    -Dman1dir=none \
    -Dman3dir=none \
    -Doptimize="-O2 -g"

# Build and install artifacts
make -j $(nproc)
make install

# make sure it works
"${STAGING_DIR}/bin/perl" -V

export XZ_DEFAULTS="-T 0"
tar Jcf ${OUTPUT} --transform "s,^./,./${FULLNAME}/," -C ${STAGING_DIR} .

echo "ce-build-status:OK"

