#!/bin/bash

# This file is part of Dana.
# Copyright (C) 2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

# This script checks that commited files have copyright notices containing the current year.

set -e

YEAR="$(date '+%Y')"
COPYRIGHT_LINE="Copyright.*${YEAR}"
exit_code=0

while read filename; do
	if ! grep -qe "${COPYRIGHT_LINE}" -- "${filename}"; then
		echo "${filename}: missing copyright notice." 1>&2
		exit_code=1
	fi
done < <(git diff --staged --name-only --diff-filter=MA)

if [ "${exit_code}" -ne 0 ]; then
  echo "" 2>&1
  echo "Files should contain a copyright notice as follows:" 2>&1
  echo "  Copyright (C) [XXXX-]YYYY Author Name <email@somewhere.com>" 2>&1
  echo "where YYYY is the current year." 2>&1
fi

exit "${exit_code}"
