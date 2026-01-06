#!/bin/bash
TOKEN=$1
ARN="${AWS_MFA_ARN}"

if [ -n ${AWS_ASSESS_KEY_ID} ]; then
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
fi

# 임시 토큰 발행 후 환경변수 추출
read -r AK SK ST <<< $(aws sts get-session-token --serial-number $ARN --token-code $TOKEN \
--output text --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]')

export AWS_ACCESS_KEY_ID=$AK
export AWS_SECRET_ACCESS_KEY=$SK
export AWS_SESSION_TOKEN=$ST

echo "MFA Session Token Exported!"