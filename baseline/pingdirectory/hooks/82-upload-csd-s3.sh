#!/usr/bin/env sh

${VERBOSE} && set -x

# Allow overriding the log archive URL with an arg
test ! -z "${1}" && LOG_ARCHIVE_URL="${1}"
echo "Uploading to location ${LOG_ARCHIVE_URL}"

# Install AWS CLI if the upload location is S3
if test "${LOG_ARCHIVE_URL#s3}" == "${LOG_ARCHIVE_URL}"; then
  echo "Upload location is not S3"
  exit 0
elif ! which aws > /dev/null; then
  echo "Installing AWS CLI"
  apk --update add python3
  pip3 install --no-cache-dir --upgrade pip
  pip3 install --no-cache-dir --upgrade awscli
fi

FORMAT="+%d/%b/%Y:%H:%M:%S %z"
NOW=$(date "${FORMAT}")
AN_HOUR_AGO=$(date --date="@$(($(date +%s) - 3600))" "${FORMAT}")

cd "${OUT_DIR}"
"${SERVER_ROOT_DIR}"/bin/collect-support-data --timeRange "\"[${AN_HOUR_AGO}],[${NOW}]\""
CSD_OUT=$(find . -name support\*zip -type f | sort | tail -1)

echo "Uploading "${CSD_OUT}" to ${LOG_ARCHIVE_URL}"
DST_FILE=$(basename "${CSD_OUT}")
aws s3 cp "${CSD_OUT}" "${LOG_ARCHIVE_URL}/${DST_FILE}"

echo "Upload return code: ${?}"

rm -f "${CSD_OUT}"