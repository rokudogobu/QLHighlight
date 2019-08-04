#!/bin/bash

# Copyright (c) 2019 rokudogobu
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function _usage() {
cat <<EOS
Usage: bash $( basename $BASH_SOURCE ) [-h|--help] [--tag2uti <path>] [--plist <path>] [--index <index>] set <ext or mime>...
   or: bash $( basename $BASH_SOURCE ) [-h|--help] [--tag2uti <path>] [--plist <path>] [--index <index>] unset <ext or mime>...
EOS
exit 0
}

function _err() {
	echo "*** error: $*" >&2
	exit 1
}

function _load() {
	"$PLISTBUDDY" -c "print $1" "$PLIST" 2>/dev/null
}

PLISTBUDDY=/usr/libexec/PlistBuddy
[ -x "$PLISTBUDDY" ] || _err "PlistBuddy not found."

INDEX=0
while true
do
	case "$1" in
		'--index'     ) INDEX=$(( $2 )); shift 2;;
		'--plist'     ) PLIST=$2; shift 2;;
		'--tag2uti'   ) TAG2UTI=$2; shift 2;;
		'-h'|'--help' ) _usage;;
		* ) break;;
	esac
done

[ -n "$TAG2UTI" ] || TAG2UTI=$( which tag2uti )
[ -x "$TAG2UTI" ] || TAG2UTI=$( cd "$( dirname "$BASH_SOURCE" )"; pwd )/tag2uti/tag2uti
[ -x "$TAG2UTI" ] || ( cd "$( dirname "$BASH_SOURCE" )"; [ -d tag2uti ] && cd tag2uti && make )
[ -x "$TAG2UTI" ] || _err "tag2uti not found."

[ -n "$PLIST" ] || PLIST=$( cd "$( dirname "$BASH_SOURCE" )"; cd ../; pwd )/QLHighlight/Info.plist
[ -f "$PLIST" ] || _err "$PLIST not found."

[ $# -lt 2 ] && _usage

case "$1" in
	'set'|'add'            ) FLAG_SET=1; shift;;
	'unset'|'del'|'delete' ) FLAG_DEL=1; shift;;
	* ) _err "unknown command '$1'.";;
esac

ENTRY=:CFBundleDocumentTypes:$INDEX

_load ${ENTRY} >/dev/null
[ $? -eq 0 ] || _err "$ENTRY does not exist."

role=$( _load ${ENTRY}:CFBundleTypeRole )
[ "$role" = "QLGenerator" ] || _err "the value for CFBundleTypeRole must be 'QLGenerator'."

ENTRY+=:LSItemContentTypes
if [ ${FLAG_SET:-0} -eq 1 ]; then
	utis=$( for item in $( _load "$ENTRY" | grep -e '^\s\+' ); do echo $item; done )
	for uti in $( for uti in $( "$TAG2UTI" "$@" ); do echo $uti; done | sort | uniq )
	do
		if [ -n "$( grep "$uti" <<<"$utis" )" ]; then
			echo "*** skip: $uti already set." >&2
		else
			echo "adding $uti ..." >&2
			"$PLISTBUDDY" -c "Add ${ENTRY}: string $uti" "$PLIST"
		fi
	done
elif [ ${FLAG_DEL:-0} -eq 1 ]; then
	idxs=()
	utis=$( for uti in $( "$TAG2UTI" "$@" ); do echo $uti; done | sort | uniq )

	i=0
	while true
	do
		uti=$( _load ${ENTRY}:$i )
		[ $? -eq 0                         ] || break
		[ -n "$( grep "$uti" <<<"$utis" )" ] && idxs+=( $i )
		i=$(( $i + 1 ))
	done

	for idx in $( IFS=$'\n'; sort -nr <<<"${idxs[*]}" )
	do
		echo "deleting $( _load ${ENTRY}:$idx ) ..." >&2
		"$PLISTBUDDY" -c "Delete ${ENTRY}:$idx" "$PLIST"
	done
else
	:
fi
