#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


is_dpkg(){
    PACKAGE=$1
    if [ "x$CITELLUS_LIVE" = "x1" ]; then
        dpkg -l *$1*|egrep ^ii | awk -v PACKAGE=$PACKAGE '$2==PACKAGE {print $3}'|egrep "."
    elif [ "x$CITELLUS_LIVE" = "x0" ]; then
        is_required_file "${CITELLUS_ROOT}/installed-debs"
        awk -v PACKAGE=$PACKAGE '$2==PACKAGE {print $3}' "${CITELLUS_ROOT}/installed-debs"|egrep "."
    fi
}

is_required_dpkg(){
    if ! is_dpkg $1 >/dev/null 2>&1; then
        echo "required package $1 not found." >&2
        exit ${RC_SKIPPED}
    fi
}

is_dpkg_over(){
    is_required_dpkg $1
    VERSION=$(is_dpkg $1|sort -V|tail -1)
    LATEST=$(echo ${VERSION} $2|tr " " "\n"|sort -V|tail -1)

    if [ "$(echo ${VERSION} $2|tr " " "\n"|sort -V|uniq|wc -l)" == "1" ];then
        # Version and $2 are the same (only one line, so we're on latest)
        return 0
    fi

    if [ "$VERSION" != "$LATEST" ]; then
        # "package $1 version $VERSION is lower than required ($2)."
        return 1
    fi
    return 0
}

is_required_dpkg_over(){
    is_required_dpkg $1
    VERSION=$(is_dpkg $1 2>&1|sort -V|tail -1)
    if ! is_dpkg_over "${@}" ; then
        echo "package $1 version $VERSION is lower than required ($2)." >&2
        exit ${RC_FAILED}
    fi
}