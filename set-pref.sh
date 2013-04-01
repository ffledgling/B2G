#!/bin/bash
#Script to set/view user preferences

SCRIPT_NAME=$(basename $0)
usage()
{
  echo "usage: ${SCRIPT_NAME} [-u] preferenceName [value]" >&2
  echo -e "\nThis is a script to View or Change various user preferences\
\n-h  Print this help string\
\n-u  Set/Get preferences in/from /system/b2g/defaults/pref/user.js
"
}

if [ $# -lt 1 ]; then
  usage
  exit 0
fi

#Initialize Files and Variables
ADB=${ADB:-adb}
LOCAL_PREFS_JS=/tmp/local_prefs.js
LOCAL_USER_JS=/tmp/local_user.js
PROFILE_DIR=$(${ADB} shell echo -n "/data/b2g/mozilla/*.default")
REMOTE_PREFS_JS=${PROFILE_DIR}'/prefs.js'
REMOTE_USER_JS='/system/b2g/defaults/pref/user.js'

#Parse args
while getopts "uph" opt; do
  case "$opt" in
    u)
        user_pref=true
        ;;
    p)
        TARGET_FILE=$OPTARG
        ;;
    h)
        usage
        exit 0
        ;;
    ?)
        usage
        exit 1
        ;;

  esac
done
shift $(( ${OPTIND} - 1 ))
if [[ -z $1 ]]; then
  echo "Prefrence name required"
  usage
  exit 1
fi
pref_name=$1;
pref_value=$2;

if [[ -n $user_pref ]]; then
  LOCAL_FILE=${LOCAL_USER_JS}
  REMOTE_FILE=${REMOTE_USER_JS}
  PREF_PREFIX=pref
  #Remount filesystem for read-write
  ${ADB} remount
else
  LOCAL_FILE=${LOCAL_PREFS_JS}
  REMOTE_FILE=${REMOTE_PREFS_JS}
  PREF_PREFIX=user_pref
fi

${ADB} pull ${REMOTE_FILE} ${LOCAL_FILE}

REGEX="\(\".*\",(.*)\);"

if [ -z "$pref_value" ]; then
  grep "$pref_name" ${LOCAL_FILE}|
  # Using a loop here enables a user to use wilcards
  # such as gecko.* while pulling preference Values
  while read line; do
    [[ $line =~ $REGEX ]]
    echo ${BASH_REMATCH[1]}
  done
  exit 0
fi
grep -v "$pref_name" ${LOCAL_FILE} > ${LOCAL_FILE}.tmp
if [[ $pref_val == true ]] || [[ $pref_val == false ]] || [[ -z ${pref_val/[0-9]*/} ]]
then
  echo $PREF_PREFIX"(\""${pref_name}"\", "${pref_value}");" >> ${LOCAL_FILE}.tmp
else
  echo $PREF_PREFIX"(\""${pref_name}"\", \""${pref_value}"\");" >> ${LOCAL_FILE}.tmp
fi
${ADB} push ${LOCAL_FILE}.tmp ${REMOTE_FILE}
