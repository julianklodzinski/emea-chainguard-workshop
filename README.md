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
1. If you have not installed the chainctl yet go here: https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/ and install it
Authenticate against the Chainguard Console
```
chainctl auth login
```
Check the Auth Status
```
chainctl auth status
```
Check if there are any updates available
```
chainctl update
```
Configure your Docker Engine to use our Images
```
chainctl auth configure-docker
```
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
