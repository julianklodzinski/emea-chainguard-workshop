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
If you have not installed the chainctl yet [follow our documentation here and install it](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/). After you have installed the Chainctl run the below commands to make sure you are all good to go.

1. First connect your Chainctl with your Account
```
chainctl auth login
```
2. You can check the Status and some additional information
```
chainctl auth status
```
3. In case updates are available run the following command - chainctl will let you know anyways
```
chainctl update
```
4. To connect your Docker and Chainguard Image Catalog run the below
```
chainctl auth configure-docker
```

If configure-docker does not work for you [check out our pull tokens](https://edu.chainguard.dev/chainguard/chainguard-images/chainguard-registry/authenticating/#managing-pull-tokens-in-the-chainguard-console)

## Chainguard Images
Let's get you setup with the Images you need for the Workshop today. Execute the below commands in your favorite Terminal.

```
docker pull cgr.dev/emea-chainguard-workshop/python:latest
```
```
docker pull cgr.dev/emea-chainguard-workshop/python:latest-dev
```

You have now all Chainguard Images - let's get the public version as well :)

## Public Images
Run the following command to get the official public python image. Feel free to change the tag to your choice if you want to compare our Images to something else.
```
docker pull python:latest
```
## Security Scanner
At Chainguard we use plenty of Security Scanners and two we love the most - Grype and Trivy. Both Scanners do an outstanding job finding vulnerabilities. So go ahead let's scan the Images we have.
### Grype
Using Grype is easy and straight forward. To scan an image you run ```grype image:tag``` and it will do it's making. The Results of Grype are easy to understand and will look similar to this.
```
Cataloged contents                                                                                                                  ⠙ Vulnerability DB                ━━━━━━━━━━━━━━━━━━━━  [7.0 MB / 90 MB]  
 ⠙ Pulling image                   
 ✔ Vulnerability DB                
 ✔ Pulled image                    
 ✔ Loaded image                                                                                                                                                 
 ✔ Parsed image                                                                                                                  
 ✔ Cataloged contents                                                                                                                   
   ├── ✔ Packages                        [25 packages]  
   ├── ✔ Executables                     [128 executables]  
   ├── ✔ File metadata                   [1,666 locations]  
   └── ✔ File digests                    [1,666 files]  
 ✔ Scanned for vulnerabilities     [0 vulnerability matches]  
   ├── by severity: 0 critical, 0 high, 0 medium, 0 low, 0 negligible
   └── by status:   0 fixed, 0 not-fixed, 0 ignored 
```
Before you now start running the commands prepare notes where you can safe the results for later comparison. Now it's time for the truth - run the below:
```
grype cgr.dev/emea-chainguard-workshop/python:latest
```
```
grype cgr.dev/emea-chainguard-workshop/python:latest-dev
```

If you do this in a Group check with someone sitting next to you the results and discuss the differences between latest and latest-dev Images from Chainguard. If you do this workshop remotely feel free to go off mute or ask in the Chat.

Now let's do the same scan for the public python image.
```
grype python:latest
```
Now in your Group create a plan on how to analyze and fix the vulnerabilitites shown to you...
...
...
Just kidding :D Let's not do this, we would not finish this Workshop anywhere soon :D
### How Scanners work
### How to manipulate Scanners
## Verifying Container Image - Provenance
## Image Attestations
## SBOMs
## Build and Test Chainguard Python Image
## Build Multi-Stage Build mit Python
## Dockerfile Converter && DFC UI (Who is this???)
