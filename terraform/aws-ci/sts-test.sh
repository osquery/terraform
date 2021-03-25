#!/bin/bash

set -e

echo "Starting with Permissions: "
aws sts get-caller-identity

echo "Assuming new role"
TMPFILE=$(mktemp)

aws sts assume-role \
    --role-arn arn:aws:iam::204725418487:role/GitHubRunnerAssumedBootstrapRole \
    --role-session-name seph-test \
    > $TMPFILE


export AWS_ACCESS_KEY_ID=$(jq -rc .Credentials.AccessKeyId $TMPFILE)
export AWS_SECRET_ACCESS_KEY=$(jq -rc .Credentials.SecretAccessKey $TMPFILE)
export AWS_SESSION_TOKEN=$(jq -rc .Credentials.SessionToken $TMPFILE)

echo "New Role:"
aws sts get-caller-identity

echo "Test Secret Reading"
aws --region us-east-1 secretsmanager get-secret-value --secret-id OSQUERY_GITHUB_RUNNER_TOKEN | jq .ARN
