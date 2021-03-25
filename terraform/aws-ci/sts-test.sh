#!/bin/bash

set -e

AWS_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

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
rm -f "$TMPFILE"

echo "New Role:"
aws sts get-caller-identity

echo "Test Secret Reading"
aws --region us-east-1 secretsmanager get-secret-value --secret-id OSQUERY_GITHUB_RUNNER_TOKEN | jq .ARN

echo "Drop Permissions"

# This is stupid
TMP_ASSOC=$(mktemp)

aws --region us-east-1 ec2 describe-iam-instance-profile-associations  \
    --filters Name=instance-id,Values="$AWS_INSTANCE_ID" \
    > $TMP_ASSOC

ASSOC_ID=$(jq -rc .IamInstanceProfileAssociations[0].AssociationId $TMP_ASSOC)

aws --region us-east-1 ec2 replace-iam-instance-profile-association \
    --association-id "$ASSOC_ID" \
    --iam-instance-profile Arn=arn:aws:iam::204725418487:instance-profile/GitHubRunnerRuntimeImplicitIamRole

# Is there a better logout?
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
