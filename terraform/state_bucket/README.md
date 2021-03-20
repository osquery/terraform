

# STS crap

`aws sts get-caller-identity`

This works:

```
aws sts assume-role --role-arn arn:aws:iam::107349553668:role/IdentityAccountAccessRole --role-session-name test
```

## Bootstrap

This is a lot nicer now that terraform supports state migration
stuff. Sweet.

Comment out the bucket, and then invoke:

```
rm -rf .terraform
aws-vault exec osquery-identity-initial-tmp -- terraform init
aws-vault exec osquery-identity-initial-tmp -- terraform plan
aws-vault exec osquery-identity-initial-tmp -- terraform apply

# uncomment the s3 backend
vi provider.tf

# terraform will now move it for you
aws-vault exec osquery-identity-initial-tmp -- terraform init
aws-vault exec osquery-identity-initial-tmp -- terraform plan


```
