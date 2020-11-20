#!/bin/bash

# This file is part of Dana.
# Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
#
# Dana is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Dana is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Dana.  If not, see <https://www.gnu.org/licenses/>.

# This script is used to generate the .zip file for a Mod's release.
# The .zip will be created in the "build/" folder.

set -e

##########
# Config #
##########

# Name of the folder where the build sript will put the output & intermediates.
BUILD_FOLDER=build
# List of the files to exclude from the zip.
EXCLUDE_LIST=( '.git/*' '.luacov' 'build.sh' 'coverage.sh' '.busted' 'lua/*/tests/*' 'migrations/framework/tests/*' 'lua/testing/*')

########
# Main #
########

project_dir="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
version="$(jq -r '.version' "${project_dir}/info.json")"

build_path="${project_dir}/${BUILD_FOLDER}"
zip_folder_path="${build_path}/dana"
output_path="${build_path}/dana_${version}.zip"
ignored_file="${build_path}/git-ignored.txt"

rm -rf "${zip_folder_path}"
mkdir -p "${zip_folder_path}"

(
    cd "${project_dir}"
    for filename in * .[^.]*; do
        if [ "${filename}" != "${BUILD_FOLDER}" ]; then
            ln -s "../../${filename}" "${build_path}/dana/${filename}"
        fi
    done

    git ls-files -oi --exclude-standard --directory | sed -e 's#/$#/*#' -e 's#^#/dana/#' > "${ignored_file}"
)

(
    cd ${build_path}
    rm -f "${output_path}"
    zip -r9 "${output_path}" "dana" -x "${EXCLUDE_LIST[@]/#//dana/}" -x@"git-ignored.txt"
)
