# 1. Workshop Account Access
# 2. Workshop Preparations
In order to follow along the Workshop please make sure you have the following tools installed.
 - Chainctl
 - Docker
 - Podman
 - Grype
 - Trivy
 - jq
 - yq
 - cosign
# 3. Workshop Content
## Chainguard Demo
### Chainguard Intro
### Chainguard Demo
### Chainguard Workshop Demo
## Chainctl
If you have not installed the chainctl yet go here: https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/. After you have installed the Chainctl run the below commands to make sure you are all good to go.

First connect your Chainctl with your Account
```
chainctl auth login
```
You can check the Status and some additional information
```
chainctl auth status
```
In case updates are available run the following command - chainctl will let you know anyways
```
chainctl update
```
To connect your Docker and Chainguard Image Catalog run the below
```
chainctl auth configure-docker
```

If configure-docker does not work for you check our pull tokens: https://edu.chainguard.dev/chainguard/chainguard-images/chainguard-registry/authenticating/#managing-pull-tokens-in-the-chainguard-console
## Chainguard Images
## Security Scanner
### How Scanners work
### How to manipulate Scanners
## Verifying Container Image - Provenance
## Image Attestations
## SBOMs
## Build and Test Chainguard Python Image
## Build Multi-Stage Build mit Python
## Dockerfile Converter && DFC UI (Who is this???)
