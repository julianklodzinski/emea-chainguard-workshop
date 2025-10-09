# 🔹 Why Join This Workshop
In this session, you’ll learn how to use Chainguard Images — secure, minimal, and continuously verified container images — in a practical, hands-on way.
## Common Challenges We’ll Address
If any of these sound familiar, this workshop is for you:
- “We want minimal and CVE-free images.”
Bloated base images increase your attack surface and maintenance burden.
- “We spend too much time chasing CVEs.”
Learn how automated rebuilds and trusted provenance reduce that overhead.
- “Our customers require CVE-free software.”
Chainguard Images make it easier to prove compliance and deliver secure builds.
- “We need to meet compliance targets.”
See how Chainguard’s signed, verifiable images align with frameworks like SOC 2, FedRAMP, and ISO 27001.

# ⚙️ Prework

Before joining the workshop, please make sure your environment is ready. This ensures you can fully participate in the hands-on exercises without interruptions.

## 🧰 Required Tooling
You’ll need the following tools installed and accessible from your terminal.
Follow the links for installation instructions:
| Tool         | Purpose                                            | Installation Link                                                                                   |
| ------------ | -------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **Chainctl** | CLI to interact with Chainguard services           | [Install Chainctl →](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/) |
| **Docker**   | Container runtime (any vendor/version is fine)     | [Docker Installation →](https://docs.docker.com/get-docker/)                                        |
| **Grype**    | Image vulnerability scanner                        | [Install Grype →](https://github.com/anchore/grype?tab=readme-ov-file#installation)                 |
| **Trivy**    | Image vulnerability and misconfiguration scanner   | [Install Trivy →](https://trivy.dev/latest/getting-started/installation/)                           |
| **jq**       | JSON processor                                     | [Install jq →](https://jqlang.org/download/)                                                        |
| **yq**       | YAML processor                                     | [Install yq →](https://github.com/mikefarah/yq?tab=readme-ov-file#install)                          |
| **cosign**   | Tool for signing and verifying container artifacts | [Install cosign →](https://docs.sigstore.dev/cosign/system_config/installation/)                    |
| **dfc**      | Diff and compare tool for Chainguard images        | [Install dfc →](https://github.com/chainguard-dev/dfc)                                              |

✅ Quick Check:
Run the following command to verify your setup:
```
chainctl version && docker version && grype version && trivy --version && jq --version && yq --version && cosign version && dfc version
```
All tools should return a version string.

## 🌐 Network Access
Make sure your system can reach the following endpoints, as they are required for the workshop labs:
- cgr.dev
- console.chainguard.dev
- data.chainguard.dev
- console-api.enforce.dev
- enforce.dev
- dl.enforce.dev
- issuer.enforce.dev
- apk.cgr.dev
- virtualapk.cgr.dev
- packages.cgr.dev
- packages.wolfi.dev

# 🧭 Workshop Step-by-Step Guide
The workshop begins with a short introduction to Chainguard and a demo of the final outcome so you can see what you’ll build.
After that, it’s your turn — you’ll get hands-on with your own Chainguard environment.

## 👥 Workshop Account Access
At the start of the session, you’ll receive an invite link granting access to your dedicated Workshop Organization in Chainguard.
Once you’ve accepted the invitation, you’ll be ready to authenticate using chainctl.

💡 Tip for facilitators:
Pause here for a moment to ensure everyone has successfully joined their organization before continuing. A quick thumbs-up check (or “✅ in chat”) helps keep the group aligned.

## 🔗 Check and Set Up chainctl
If you haven’t installed chainctl yet, please [follow our installation guide](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/) first.

1️⃣ Log in to your account
Authenticate and link your local CLI with your Chainguard credentials:
```
chainctl auth login
```
You’ll be redirected to a browser window to complete authentication.

2️⃣ Verify your authentication status
Check that you’re logged in and view details about your current session:
```
chainctl auth status
```

3️⃣ Update chainctl (optional but recommended)
If updates are available, chainctl will prompt you automatically.
You can also check manually:
```
chainctl update
```

4️⃣ Configure Docker authentication
This connects your local Docker client to the Chainguard Image Catalog, allowing you to pull and use Chainguard Images:
```
chainctl auth configure-docker
```

If you encounter issues with this step, you can also use [pull tokens instead](https://edu.chainguard.dev/chainguard/chainguard-images/chainguard-registry/authenticating/#managing-pull-tokens-in-the-chainguard-console).

## Working with Chainguard Images
Now that your environment and access are ready, let’s pull the images you’ll use in today’s workshop.
Chainguard Images are stored in your organization’s private registry on cgr.dev.

### 🔹 Pulling Chainguard Images
To pull an image from Chainguard, use the following command format: 

```docker pull cgr.dev/{{organization}}/{{image}}:{{tag}}```

- organization → your workshop organization name (e.g., mycompany.de or secureteam.uk)
- image → the image name (e.g., python)
- tag → the tag version (e.g., latest, latest-dev)
You can find your organization name in the top-left corner of the Chainguard Console — it usually matches your company name and ends with a region code like .de or .uk.

#### 💡 Simplify Your Commands

To make your workflow smoother, set your organization as an environment variable in your current shell: 

```export organization=yourOrgName```

Now you can use that variable in your pull commands without retyping it each time.

⚠️ Note:
Environment variables are temporary — if you close your terminal or open a new shell, you’ll need to re-export this variable.

#### 📦 Pull Your Workshop Images
Now, let’s fetch the two main images we’ll be using:
```
docker pull cgr.dev/${organization}/python:latest-dev
```
```
docker pull cgr.dev/${organization}/python:latest
```
Once complete, you’ll have both the -dev (containing Shell and Package Manager) and minimal version without it available locally.

#### 🌍 Get the Public Version Too
To compare Chainguard Images to public alternatives, also pull the public Python image:
```
docker pull python:latest
```

## Security Scanner
At Chainguard we use plenty of Security Scanners and two we love the most - Grype and Trivy. Both Scanners do an outstanding job finding vulnerabilities. So go ahead let's scan the Images we have.
### How Scanners work
Security scanners like Grype, Trivy and others are tools designed to detect vulnerabilities (CVEs) in software environments such as container images, filesystems, and source code repositories. They typically perform the following activities:

- Dependency Mapping: Both scanners analyze the software components included in a container image or filesystem. They identify both direct and transitive dependencies—meaning, not just what you’ve added, but also libraries your dependencies rely on. 
- SBOM Ingestion: Scanners can ingest Software Bills of Materials (SBOMs), giving comprehensive visibility into every package included in the artifact. This improves accuracy and coverage when scanning, as SBOMs provide detailed lists of all components. 
- Vulnerability Checking: Once dependencies are identified, the scanners compare those package versions against multiple vulnerability databases (like the NVD, vendor advisories, and others including Wolfi SecDB for Grype). If a dependency's version matches a known vulnerable version, the scanner flags it. 
- Reporting & Remediation: The scanner's output lists all detected CVEs, severity ratings, and (where possible) recommends available updates or patches. They offer different output formats for developer tooling and CI/CD integration, making it easy to include in automated pipelines.

### Grype
Using Grype is easy and straight forward. To scan an image you run ```grype image:tag``` and it will do it's making. The Results of Grype are easy to understand and will look similar to this.
```
Cataloged contents              ━━━━━━━━━━━━━━━━━━━━  [7.0 MB / 90 MB]
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
One Scanner is not enough! And that's why you need to build from source.

### How to trick Scanners
If you think you can't trick a Scanner to believe there is no CVE you are dead wrong. As you already saw in the Trivy vs. Grype scan there is no standard on how Scanners analyze an image and if you know how they do it it's faily easy to trick them by:

- Omitting Vulnerable Packages from SBOMs: If a SBOM is manually created or edited to exclude packages known to be vulnerable, the scanner won't see or report those 
vulnerabilities. This hides risks from the scan results.

- Falsifying Package Versions in Metadata: Changing version numbers in SBOMs or metadata to ones perceived as safe (even if the actual software is outdated or vulnerable) can prevent scanners from flagging CVEs. Scanners match version numbers to vulnerability databases, so supplying incorrect data misleads them.

- Renaming or Repackaging Components: Packaging a vulnerable library under a different name, or with custom metadata fields, can prevent scanners from properly identifying the component and its vulnerabilities.

- Using Untracked or Private Packages: Including dependencies that aren’t published in common databases (NVD, upstream advisories, etc.), or modifying open source codebases to diverge significantly from tracked versions, can keep real vulnerabilities hidden from scanners.

- Suppressing Transitive Dependencies: Many vulnerabilities come from libraries that are included indirectly (transitive dependencies). Not listing these in SBOMs or metadata, or using tools that don’t detect them, limits what a scanner can find.

- Manipulating Build Metadata: Changing how certain packages are recorded in build manifests or image labels can cause scanners to overlook them or misinterpret their version/status.

That is why the SLSA Framework is in place and you should only trust sources which can verify that nothing of this happend - like Chainguard.

## Provenance - Verify Container Images from Chainguard
Container image provenance verification is the process of confirming that a container image originates from a trusted source and is built exactly as claimed. This is crucial for ensuring software supply chain integrity and defending against tampering or hidden vulnerabilities.

All Chainguard container images contain verifiable signatures and high-quality SBOMs (software bill of materials), features that enable users to confirm the origin of each image build and have a detailed list of everything that is packed within.

You'll need [cosign](https://docs.sigstore.dev/cosign/system_config/installation/) and [jq](https://jqlang.org/download/) in order to download and verify image attestations.

So let's get started :)

### Verifying python Image Signatures
The python Chainguard Containers are signed using Sigstore, and you can check the included signatures using cosign. The cosign verify command will pull detailed information about all signatures found for the provided image.
```
Provide Command here as soon as Catalog is provisioned
```

### Downloading Python Image Attestations
To download an attestation, use the cosign download attestation command and provide both the predicate type and the build platform. For example, the following command will obtain the SBOM for the python image on linux/amd64:
```
Provide Command here as soon as Catalog is provisioned
```

### Verifying python Image Attestations
You can use the cosign verify-attestation command to check the signatures of the python image attestations:
```
Provide Command here as soon as Catalog is provisioned
```

Now you have verified that the Image you just downloaded was coming from us and was not changed on the way to you. In other words the Question "Can I trust this image actually comes from Chainguard and hasn’t been changed or tampered with?" you can answer with "Yes" now.

Try to verify the public Python image as well and discuss in the room how you would do it.

## Build and Test Chainguard Python Image
Now you might wonder, wait, no CVEs, a lot smaller, there is something wrong... these images can't work! You are wrong, but let's find out together and build a simple Python App together.
```
cd examples/python/starter
```
Check out the Python Application. IT will print out the Operating System it runs on. The Output will look similiar to this: ```Hello Wordl! From Linux operating system on 64bit ELF architecture``` Now build your image:
```
docker build -f dockerfile -t crg-python:standard .
```
And run it yourself with
```
docker run -v .:/app crg-python:standard
```
You can also change the Chainguard Image to the public Python Image if you want to spot differences in the OS.

This has worked easily. But it is also a very simple example. So let's have a look at a more relalistic approach where we need to install dependencies.

## Build Multi-Stage Build mit Python
Navigate into the Folder ```multi-stage``` - depending on where you are in your Shell you might have to use a different command.
```
cd examples/python/multi-stage
```
Explore the linky.py Application Code and the requirements.txt file which we use to include some libraries.

Next: Pull down an Image for our Python Application. The App will show the Image in your Shell :) Pretty cool, isn't it?
```
curl -O https://raw.githubusercontent.com/chainguard-dev/edu-images-demos/main/python/linky/linky.png
```
Go and explore your Dockerfile - especially line 1 and 15 are important as we start our build with a -dev Image, install all dependencies, and move over to a minimal image.

Now build your Image
```
docker build . --pull -t linky
```
and of course run it and see what happens
```
docker run --rm linky
```
As you can see, Chainguard Images do work. And Multi-Stage builds are one way of customizing them to your needs.

## Dockerfile Converter && DFC UI (Who is this???)
At some point in time you might wonder about the migration efforts from your current estate towards Chainguard. If you haven't yet I'm sure you will now :D
We tried to make it as easy as possible for our users to consume Chainguard. This includes also migrations.

Navigate into the folder ```dfc`` under examples to play around with our Dockerfile Converter. Depending on where you are you might want to run the following
```
cd examples/dfc 
```

In this folder you will find a classic dockerfile which pulls and builds a Python Image.

Analyze the Dockerfile and if you fully understood what is happening move on and run the following command.

```
dfc dockerfile --org emea-chainguard-workshop >> dockerfile.cgr
```
Now spend some time to see what happend to your Dockerfile and what pieces of the File got changed. Share in your Group the Number of changes dfc has performed.

## APK add and search
As you might have realized already Chainguard Images use apk as a manager. If you are looking for packages an easy way to do so is the following
```
docker run -it --rm --entrypoint /bin/sh cgr.dev/chainguard/wolfi-base
```

```
apk update
```

```
apk search php*8.2*xml*
```
You should get a very similiar output to this one
```
php-8.2-simplexml-8.2.17-r0
php-8.2-simplexml-config-8.2.17-r0
php-8.2-xml-8.2.17-r0
php-8.2-xml-config-8.2.17-r0
php-8.2-xmlreader-8.2.17-r0
php-8.2-xmlreader-config-8.2.17-r0
php-8.2-xmlwriter-8.2.17-r0
php-8.2-xmlwriter-config-8.2.17-r0
php-simplexml-8.2.11-r1
php-xml-8.2.11-r1
php-xmlreader-8.2.11-r1
php-xmlwriter-8.2.11-r1
```
You can also search for commands providing you with an indication of where it is part of
```
apk search cmd:useradd
```
And the result should pretty much look like this: ```shadow-4.18.0-r5```
And to top it - to find dependencies try this 
```
apk -R info shadow
```
Which should deliver something similiar to
```
...
shadow-4.15.1-r0 depends on:
so:ld-linux-x86-64.so.2
so:libbsd.so.0
so:libc.so.6
so:libcrypt.so.1
so:libpam.so.0
so:libpam_misc.so.0
```
## Thank you :)