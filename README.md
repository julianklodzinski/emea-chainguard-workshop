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
### How Scanners work
Security scanners like Grype, Trivy and others are tools designed to detect vulnerabilities (CVEs) in software environments such as container images, filesystems, and source code repositories. They typically perform the following activities:

1. Dependency Mapping: Both scanners analyze the software components included in a container image or filesystem. They identify both direct and transitive dependencies—meaning, not just what you’ve added, but also libraries your dependencies rely on. 
2. SBOM Ingestion: Scanners can ingest Software Bills of Materials (SBOMs), giving comprehensive visibility into every package included in the artifact. This improves accuracy and coverage when scanning, as SBOMs provide detailed lists of all components. 
3. Vulnerability Checking: Once dependencies are identified, the scanners compare those package versions against multiple vulnerability databases (like the NVD, vendor advisories, and others including Wolfi SecDB for Grype). If a dependency's version matches a known vulnerable version, the scanner flags it. 
4. Reporting & Remediation: The scanner's output lists all detected CVEs, severity ratings, and (where possible) recommends available updates or patches. They offer different output formats for developer tooling and CI/CD integration, making it easy to include in automated pipelines.

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

### Trivy
Trivy will provide a pretty similar summary just in a different design. BUT Trivy does not report any Vulnerabilities where there is no fix available - concerning? Yes!
```
Report Summary

┌──────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                             Target                                   │    Type    │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ cgr.dev/emea-chainguard-workshop/python:latest (chainguard 20230214) │ chainguard │        0        │    -    │
└──────────────────────────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

### Learnings
One Scanner is not enough!

### How to manipulate Scanners
## Verifying Container Image - Provenance
## Image Attestations
## SBOMs
## Build and Test Chainguard Python Image
## Build Multi-Stage Build mit Python
## Dockerfile Converter && DFC UI (Who is this???)
