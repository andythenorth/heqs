#     make-nml NewGRF build framework
#     (c) 2014 planetmaker and others
#     Contact: planetmaker@openttd.org
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License along
#     with this program; if not, write to the Free Software Foundation, Inc.,
#     51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

# This file is derived from OpenTTD's version check


# Arguments given? Show help text.
if [ "$#" != "0" ]; then
	cat <<EOF
Usage: ./findversion.sh
Finds the current revision and if the code is modified.

Output: <HASH>\t<VERSION>\t<MODIFIED>\t<TAG>\t<DISPLAY_VERSION>\t<BRANCH>
HASH
    a string unique to the version of the code the current checkout is
    based on. The exact format of this string depends on the version
    control system in use, but it tries to identify the revision used as
    close as possible (using the svn revision number or hg/git hash).
    This also includes an indication of whether the checkout was
    modified and which branch was checked out. This value is not
    guaranteed to be sortable, but is mainly meant for identifying the
    revision and user display.

    If no revision identifier could be found, this is left empty.
VERSION
    the version number to be reported to OpenTTD (aka NewGRF version).
    This usually is the number of days passed since 1.1.2000 up to the
    date of the last commit in the repository.

    This number should be sortable. Within a given branch or trunk, a
    higher number means a newer version. However, when using git or hg,
    this number will not increase on new commits.

    If no revision number could be found, this is left empty.
MODIFIED
    Whether (the src directory of) this checkout is modified or not. A
    value of 0 means not modified, a value of 2 means it was modified.
    Modification is determined in relation to the commit identified by
    REV, so not in relation to the svn revision identified by REV_NR.

    A value of 1 means that the modified status is unknown, because this
    is not an svn/git/hg checkout for example.
TAG
    the tag of the commit (if any) - used to indicate and name releases
DISPLAY_VERSION
    The version string shown to the user of the NewGRF
BRANCH
    The branch the version is based on


By setting the AWK environment variable, a caller can determine which
version of "awk" is used. If nothing is set, this script defaults to
"awk".
EOF
exit 1;
fi

# Allow awk to be provided by the caller.
if [ -z "$AWK" ]; then
	AWK=awk
fi

# Find out some dirs
cd `dirname "$0"`
ROOT_DIR=`pwd`

# Determine if we are using a modified version
# Assume the dir is not modified
MODIFIED=""
REPO_DATE="2000,1,1"
if [ -d "$ROOT_DIR/.hg" ]; then
	# We are a hg checkout
	if [ -n "`hg status -S | grep -v '^?'`" ]; then
		MODIFIED="M"
	fi
	HASH=`LC_ALL=C hg id -i | cut -c1-12`
	REV="h`echo $HASH | cut -c1-8`"
	BRANCH="`hg branch | sed 's@^default$@@'`"
	TAG="`hg id -t | grep -v 'tip$'`"
	REPO_DATE="`hg log -r$HASH --template='{date|shortdate}' | sed s/-/,/g | sed s/,0/,/g`"
	VERSION=`python -c "from datetime import date; print (date($REPO_DATE)-date(2000,1,1)).days"`
	DISPLAY_VERSION="v${VERSION}"
	if [ -n "$TAG" ]; then
		BRANCH=""
		DISPLAY_VERSION="${TAG}"
	fi
elif [ -f "$ROOT_DIR/.rev" ]; then
	# We are an exported source bundle
	cat $ROOT_DIR/.rev
	exit
else
	# We don't know
	HASH=""
	VERSION="0"
	MODIFIED=""
	BRANCH=""
	TAG=""
	DISPLAY_VERSION="noRev"
fi

DISPLAY_VERSION="${DISPLAY_VERSION}${MODIFIED}"

if [ -n "$BRANCH" ]; then
	DISPLAY_VERSION="$BRANCH-${DISPLAY_VERSION}"
fi

if [ -z "${TAG}" -a -n "${HASH}" ]; then
	DISPLAY_VERSION="${DISPLAY_VERSION} (${HASH})"
fi

echo "$HASH	$VERSION	$MODIFIED	$TAG	$DISPLAY_VERSION	$BRANCH"
