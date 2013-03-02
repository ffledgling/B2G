#!/bin/bash
#Script to set/view user preferences

SCRIPT_NAME=$(basename $0)
usage()
{
  echo "usage: ${SCRIPT_NAME} [-u] preferenceName [value] file ...">&2;
  echo -e "\nThis is a script to View or Change various user preferences\
\n-h  Print this help string\
\n-u  Set/Get preferences in/from /system/b2g/defaults/pref/user.js
"
  return 0;
}

if [ $# -lt 1 ]; then
  usage;
  exit 0;
fi

ADB=${ADB:-adb}
LOCAL_PREFS_JS=/tmp/local_prefs.js
LOCAL_USER_JS=/tmp/local_user.js
PROFILE_DIR=$(${ADB} shell echo -n "/data/b2g/mozilla/*.default")
REMOTE_PREFS_JS=${PROFILE_DIR}'/prefs.js'
REMOTE_USER_JS='/system/b2g/defaults/pref/user.js'

#Parse args
while getopts "uh" opt; do
  case "$opt" in
    u) user_pref=true;;
    h) usage;
       exit 0;;
    *) break;;
  esac
done
shift $(( ${OPTIND} - 1 ))
pref_name=$1;
pref_value=$2;

if [[ -n $user_pref ]]; then
  LOCAL_FILE=${LOCAL_USER_JS}
  REMOTE_FILE=${REMOTE_USER_JS}
  PREF_PREFIX=pref
# Remount filesystem for read-write
  ${ADB} remount

else
  LOCAL_FILE=${LOCAL_PREFS_JS}
  REMOTE_FILE=${REMOTE_PREFS_JS}
  PREF_PREFIX=user_pref
fi

${ADB} pull ${REMOTE_FILE} ${LOCAL_FILE}

#Regular expression to obtain Value of preference
REGEX="\(\".*\",(.*)\);"

if [ -z "$pref_value" ]; then
  grep "$pref_name" ${LOCAL_FILE}|
  while read line; do
    [[ $line =~ $REGEX ]]
    echo ${BASH_REMATCH[1]}
  done
  exit 0;
fi
grep -v "$pref_name" ${LOCAL_FILE} > ${LOCAL_FILE}.tmp
echo $PREF_PREFIX"(\""${pref_name}"\", "${pref_value}");" >> ${LOCAL_FILE}.tmp
${ADB} push ${LOCAL_FILE}.tmp ${REMOTE_FILE}
