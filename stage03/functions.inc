TIMEOUT=10
VMTIMEOUT=100
VOLUMETIMEOUT=10
RECOVERTIMEOUT=100
STAGEDIR=$(dirname $(readlink -f ${0}))
TESTDIR=$(dirname ${STAGEDIR})
RUNAT=${TESTDIR}/etc/bin/runat
PREFIX=euca-
STATE=${TESTDIR}/status
CTX=${STATE}/context
DEBUG= #--debug
LOG=${STATE}/$(basename ${STAGEDIR})-debug.log
R=
ERR=
ZONE=test00

log() {
  printf "============================================================\n= %s\n------------------------------------------------------------\n" "${@}"
}
endlog() {
  echo "============================================================"
}
run() {
  EXEC=$1
  shift
  CMD="${EXEC//euca-/${PREFIX}}"
  echo "RUNNING ${CMD}" | tee -a ${LOG} >&2 
  OUTPUT="$(${RUNAT} ${TIMEOUT} ${CMD}  ${DEBUG} ${@})"
  R=${?}
  echo "${OUTPUT}" | sed 's/^/OUTPUT /g' >> ${LOG}
  echo "${OUTPUT}"
  return $R
}

fail() {
  echo "${@}" | sed 's/^/FAIL /g' >&2
  exit 1
}
