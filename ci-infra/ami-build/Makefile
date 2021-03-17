all:

docker:
	packer build github-runner-docker.json

ami-arm64:
	aws-vault exec osquery-dev -- packer build github-runner-ami-arm64.json
