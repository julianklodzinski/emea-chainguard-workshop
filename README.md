# 🔹 Why Join This Workshop
In this session, you’ll learn how to use Chainguard Images — secure, minimal, and continuously verified container images — in a practical, hands-on way.
## Common Challenges We’ll Address
If any of these sound familiar, this workshop is for you:
- “We want minimal and CVE-free images.”
- “We spend too much time chasing CVEs.”
- “Our customers require CVE-free software.”
- “We need to meet compliance targets.”

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

```docker pull cgr.dev/{{ORGANIZATION}}/{{IMAGE}}{TAGag}}```

- organization → your workshop organization name (e.g., mycompany.de or secureteam.uk)
- image → the image name (e.g., python)
- tag → the tag version (e.g., latest, latest-dev)
You can find your organization name in the top-left corner of the Chainguard Console — it usually matches your company name and ends with a region code like .de or .uk.

#### 💡 Simplify Your Commands

To make your workflow smoother, set your organization as an environment variable in your current shell: 

```export ORGANIZATION=yourOrgName```

Make sure to replace yourOrgName with the actual Name of your Organization like it is stated in the Chainguard Console. Now you can use that variable in your pull commands without retyping it each time.

⚠️ Note:
Environment variables are temporary — if you close your terminal or open a new shell, you’ll need to re-export this variable.

#### 📦 Pull Your Workshop Images
Now, let’s fetch the two main images we’ll be using:
```
docker pull cgr.dev/${ORGANIZATION}/python:latest-dev
```
```
docker pull cgr.dev/${ORGANIZATION}/python:latest
```
Once complete, you’ll have both the -dev (containing Shell and Package Manager) and minimal version without it available locally.

#### 🌍 Get the Public Version Too
To compare Chainguard Images to public alternatives, also pull the public Python image:
```
docker pull python:latest
```

## 🔍 Security Scanning with Grype and Trivy

At Chainguard, we rely on several vulnerability scanners to verify image integrity — and two of our favorites are Grype and Trivy.
Both tools do an excellent job of detecting and reporting vulnerabilities (CVEs) in container images.

### ⚙️ How Security Scanners Work

Security scanners like Grype and Trivy analyze container images, filesystems, or source code repositories to uncover known vulnerabilities. Here’s what happens behind the scenes:

**1️⃣ Dependency Mapping**

The scanner inspects the image to identify all installed software components and their versions — not only the direct dependencies you added, but also transitive dependencies (libraries that your libraries depend on).

**2️⃣ SBOM Ingestion**

Scanners can read Software Bills of Materials (SBOMs) to understand exactly what’s inside your image.
SBOMs provide a detailed inventory of packages, improving scan accuracy and transparency.

**3️⃣ Vulnerability Matching**

Each dependency version is compared against multiple vulnerability databases — such as:
- The National Vulnerability Database (NVD)
- Vendor advisories
- And the Wolfi SecDB (for Grype)

If a package matches a known vulnerable version, the scanner flags it as a finding.

**4️⃣ Reporting & Remediation**

The results include:
- A list of detected CVEs
- Severity ratings (Low, Medium, High, Critical)
- Possible fixes or recommended versions

Both Grype and Trivy support various output formats (table, JSON, SARIF), making them ideal for both manual review and CI/CD integration.

🧠 Interaction Tip

Ask the person to your right hand side *“Who here has integrated vulnerability scanning into their CI pipeline already? What tools or challenges have you seen?”*

### Scanning with Grype

Grype is one of the simplest and most effective vulnerability scanners available.
With a single command, you can analyze a container image and identify any known CVEs.

#### 🔹 Running a Scan

To scan an image, use the following format: ```grype image:tag```

Grype will automatically:
- Pull the image (if not already local),
- Catalog all packages and metadata,
- Compare dependencies against known vulnerability databases,
- And generate a summary report.

#### 📊 Example Output

Here’s what a successful scan might look like:
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
If you see “0 vulnerability matches” — congrats 🎉 You’re looking at a CVE-free image.

#### 🧾 Prepare for Comparison

Before scanning, open a notes file or text editor where you can record the results.
You’ll use these later to compare the findings between Chainguard and public images.

**🚀 Try It Yourself**

Scan both of your Chainguard Images first:
```
grype cgr.dev/${ORGANIZATION}/python:latest
```
```
grype cgr.dev/${ORGANIZATION}/python:latest-dev
```
If you’re doing this in a group, pair up with the person next to you and compare results:
- Which image had more packages?
- Did either show vulnerabilities?
- What do you think explains the difference?

If you’re remote, share your findings in the chat or unmute to discuss!

**🌍 Scan the Public Image**

Now, let’s see how the public Python image compares:
```
grype python:latest
```
You’ll likely notice a big difference in the number of detected vulnerabilities —
this highlights how Chainguard Images dramatically reduce your security workload.

**😄 Bonus Interaction**

Once results are in plan with the one to your right on how to fix them

Just kidding 😅 — we’d be here all week!


### 🧰 Scanning with Trivy

Trivy is another excellent vulnerability scanner — simple, fast, and widely used in DevOps pipelines.
It performs a similar analysis to Grype but presents results in a different format and uses a slightly different vulnerability database.

#### 🔹 Running a Trivy Scan

Use the following command format: ```trivy image image:tag```

For example: ```trivy image cgr.dev/${ORGANIZATION}/python:latest```

Trivy will scan your image, compare package versions against known CVE databases, and produce a summary report.

**📊 Example Output**

Here’s what the output might look like for a clean Chainguard Image:

**Report Summary**
```
┌──────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                             Target                                   │    Type    │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ cgr.dev/${ORGANIZATION}/python:latest (chainguard 20230214)          │ chainguard │        0        │    -    │
└──────────────────────────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned  
- '0': Clean (no security findings detected)
```
Looks great, right?
But here’s the catch…

#### ⚠️ Important Insight

Trivy only reports vulnerabilities when a fix is available. That means if a vulnerability exists but no patch or updated version is currently published, Trivy will not display it.

This can be concerning if you’re relying on a single tool for complete visibility.
Different scanners use different data sources, and their reporting logic can vary — so it’s always best to compare results.

You don't believe us? Go ahead and scan a public image with Grype and Trivy and check for differences.

### ⚠️ Scanner Limitations — Why one scanner is not enough

```Important: We will not demonstrate methods to hide vulnerabilities. Instead we’ll discuss, at a high level, why scanners can miss things and how to design defenses so those gaps don’t matter.```

High-level reasons scanners can miss issues

- Scanners are very useful but have inherent limits — understanding those limits helps you build defenses:
- Visibility gaps: If the scanner doesn’t see an artifact (or the artifact metadata/SBOM is incomplete), it can’t flag what it can’t observe.
- Data/source differences: Scanners rely on vulnerability feeds and matching heuristics. Different tools consult different databases and use different heuristics, so results can differ.
- Metadata trust: Scanners often rely on manifest/SBOM metadata. If that metadata is inaccurate or manipulated, scan outputs can be misleading.
- Transitive dependencies: Vulnerabilities in indirectly included libraries (transitive deps) can be overlooked if the tooling doesn’t fully enumerate them.
- Fix availability logic: Some scanners show only vulnerabilities for which fixes exist; others show all known CVEs. This policy difference changes what you see.

#### Defensive takeaway

Because of these limits, don’t trust a single scan result by itself. Build defense in depth: multiple scanners, verified SBOMs, provenance/signatures, reproducible builds, and attestation.

**🔧 Concrete defensive checklist for teams** 

Use this checklist to harden image pipelines and detect tampering:

✅ Run multiple scanners (different feeds/heuristics) and compare outputs

✅ Require and verify SBOMs for every published image; ensure SBOM generation is part of CI

✅ Sign images and attestations; verify signatures in downstream environments (e.g., using cosign)

✅ Enforce reproducible builds and retain build artifacts and attestations

✅ Adopt a provenance/attestation standard such as SLSA — require authenticated, auditable build inputs

✅ Include SBOM and provenance verification as gate checks in CI/CD

✅ Monitor for unexpected packages or package counts in images (automated guardrails)



## 🧾 Provenance — Verify Container Images from Chainguard

Container image provenance verification is the process of confirming that a container image:

- Comes from a trusted source, and
- Was built exactly as claimed, without tampering or hidden components.

This step is a critical part of securing your software supply chain. It ensures every image you deploy has traceable, auditable origins.

### 🔐 Why Provenance Matters

Even if your images pass a vulnerability scan, you still need to trust:

- Who built the image
- What source code was used
- What tools and dependencies were included

Chainguard Images solve this by embedding:

- Verifiable signatures — proof that the image was built and signed by Chainguard.
- High-quality SBOMs — complete inventories of all packages and components inside each image.

Together, these enable you to verify integrity, confirm authenticity, and understand exactly what’s running in your environment.

### 🧰 Tools You’ll Need

Make sure you have these installed:

cosign
 — for verifying signatures and attestations

jq
 — for parsing and inspecting JSON output

✅ Both tools were part of your prework checklist — if not yet installed, please do so now.

### Verifying Python Image Signatures

Every Chainguard Image is digitally signed at build time using Sigstore Cosign. This signature ensures that the image was built by a trusted Chainguard system and hasn’t been modified since.

To verify the signature, we’ll use the ```cosign verify``` command. It retrieves and validates the digital signatures associated with an image.

**🔹 Command Overview**

Here’s the general syntax for verifying a Chainguard image signature:
```
cosign verify \
  --certificate-oidc-issuer=https://issuer.enforce.dev \
  --certificate-identity-regexp="https://issuer.enforce.dev/(${CATALOG_SYNCER}|${APKO_BUILDER})" \
  cgr.dev/{{ORGANIZATION}}/{{IMAGE}}:{{TAG}} | jq

```
This command tells Cosign to:

- Validate the signature issuer (issuer.enforce.dev),
- Match the identity used during signing (CATALOG_SYNCER or APKO_BUILDER),
- And output the full verification result in JSON via jq.

**🧰 Prepare Your Variables**

Set up your environment variables first — this will make subsequent commands simpler:

```
IMAGE=python
TAG=latest
```
Next, retrieve the Chainguard signing identities associated with your organization:

```
CATALOG_SYNCER=$(chainctl iam account-associations describe $ORGANIZATION -o json | jq -r '.[].chainguard.service_bindings.CATALOG_SYNCER')
APKO_BUILDER=$(chainctl iam account-associations describe $ORGANIZATION -o json | jq -r '.[].chainguard.service_bindings.APKO_BUILDER')
```

✅ Verify the Image Signature

Now run the verification:
```
cosign verify \
  --certificate-oidc-issuer=https://issuer.enforce.dev \
  --certificate-identity-regexp="https://issuer.enforce.dev/($CATALOG_SYNCER|$APKO_BUILDER)" \
  cgr.dev/$ORGANIZATION/$IMAGE:$TAG | jq
```
If successful, Cosign will confirm that:

- The image was built by Chainguard, and
- Has not been tampered with since signing.

You’ll see output showing valid certificates, identities, and timestamps — proof of authenticity.

### 📥 Downloading Python Image Attestations

Every Chainguard Image includes attestations — cryptographically signed statements describing how and what was built.
One key attestation is the SBOM (Software Bill of Materials), detailing every component in the image.

To download the SBOM attestation for the Python image (on linux/amd64):

```
cosign download attestation \
  --platform=linux/amd64 \
  --predicate-type=https://spdx.dev/Document \
  cgr.dev/$ORGANIZATION/$IMAGE:$TAG | jq -r .payload | base64 -d | jq .predicate
```

This command:

- Fetches the attestation from the registry,
- Decodes it, and
- Displays the SBOM contents in a readable JSON format.

### 🧾 Verifying Image Attestations

Finally, verify that the attestation itself is signed and trusted:

```
cosign verify-attestation \
  --type https://spdx.dev/Document \
  --certificate-oidc-issuer=https://issuer.enforce.dev \
  --certificate-identity-regexp="https://issuer.enforce.dev/($CATALOG_SYNCER|$APKO_BUILDER)" \
  cgr.dev/$ORGANIZATION/$IMAGE:$TAG
```
This confirms:
- The SBOM (and other metadata) is authentic,
- It came directly from Chainguard’s build systems, and
- It hasn’t been modified in transit.

**🧠 What You’ve Just Proven**

You can now confidently answer the question:

“Can I trust that this image actually comes from Chainguard and hasn’t been tampered with?”

**✅ Yes — you can.**

You’ve verified both the signature and the provenance attestation, proving authenticity and integrity end-to-end.

## 🧪 Build & Test a Chainguard Python Image
“No CVEs and much smaller — surely these images can’t work?” You might think now... Well, they do.

Move to the starter apps directory
```
cd examples/python/starter
```
Have a look at the app.py file and what it does and don't forget to replace {{ORGANIZATION}} with your Organization Name. It will print out the Operating System it runs on. The Output will look similiar to this: ```Hello Wordl! From Linux operating system on 64bit ELF architecture```

Now build your image:
```
docker build -f dockerfile -t crg-python:standard .
```

And run it yourself with

```
docker run -v .:/app crg-python:standard
```

You can also change the Chainguard Image to the public Python Image if you want to spot differences in the OS.

This has worked easily. But it is also a very simple example. So let's have a look at a more relalistic approach where we need to install dependencies.

## 🏗️ Build a Multi-Stage Image with Python

When your app needs to install dependencies, use a multi-stage build:

Stage 1 (builder): start from a Chainguard -dev image (has shell + package manager), create a venv, and install dependencies.

Stage 2 (runtime): copy only what you need into the minimal Chainguard image (no shell, tiny attack surface). 

Navigate into the Folder ```multi-stage``` - depending on where you are in your Shell you might have to use a different command.
```
cd examples/python/multi-stage
```
Explore the files:
- linky.py — simple Python app
- requirements.txt — Python dependencies
- Check the Dockerfile and make sure you change {{ORGANIZATION}} to your Organization

**Get the demo asset**
```
curl -O https://raw.githubusercontent.com/chainguard-dev/edu-images-demos/main/python/linky/linky.png
```
The app will reference this image and show output in your terminal.

**Inspect the Dockerfile**
Key idea: start from ```python:latest-dev```, install, then switch to ```python:latest``` and copy in only what’s needed. Run the following commands to build your Application.

```
docker build . --pull -t linky
```
and of course run it and see what happens
```
docker run --rm linky
```
**🤩 Bonus**
- Scan your build image with Grype and Trivy
- What ends up in the final image, and what’s left behind in the builder?
- How would you gate this image in CI (scan, SBOM, provenance verify)?

**🧠 Why this matters**

- Security: minimal runtime, fewer moving parts, signed base.
- Performance: smaller pulls and faster cold starts.
- Maintainability: clear separation of build tooling vs runtime.

## 🔁 Dockerfile Converter (dfc)

Migrating existing Dockerfiles to Chainguard can be fast with the Dockerfile Converter (dfc). You’ll use it to transform a classic Python image build into a Chainguard-friendly one

**Go to the dfc example folder**

```
cd examples/dfc 
```
In this folder you’ll find a classic dockerfile that builds a Python app. Open the dockerfile and make sure you understand each step (base image, copies, installs, entrypoint) and feel free to discuss this with your neighbour.

Now run the following command to convert it into a Dockerfile using Chainguard Images.
```
dfc dockerfile --org ${organization} >> dockerfile.cgr
```
Compare the original to the converted file and what you’ll typically notice:
- Base image switched to Chainguard (often minimal + non-root by default).
- Build steps adjusted to multi-stage (dev stage → runtime)
- Package installs shifted to the -dev image and uses apk add

## 📦 Working with apk: Add & Search Packages
Chainguard images use apk as their package manager — the same tool used by Alpine and Wolfi.
If you ever want to explore what packages are available, or check which image provides a specific command, you can do that interactively.

**🧰 Start an interactive shell**

Run the following to start a temporary container with Wolfi base:
```
docker run -it --rm --entrypoint /bin/sh cgr.dev/chainguard/wolfi-base
```
This drops you into a shell inside the container.

**🔄 Update the package index**

```
apk update
```
This fetches the latest package list from Wolfi’s repositories.

**🔎 Search for packages**

For example, to search for PHP 8.2 XML-related packages:
```
apk search php*8.2*xml*
```
You’ll see results similar to:
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
🧠 Tip: Use wildcards (*) to match patterns, versions, or submodules.

**🧭 Search by command**

You can also search by command name to find which package provides it:
```
apk search cmd:useradd
```
Expected output: ```shadow-4.18.0-r5```

This tells you the useradd command is part of the shadow package.

**🧩 Inspect dependencies**

To see what libraries or packages a specific package depends on:
```
apk -R info shadow
```
Example output:
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
## 🧱 Custom Assembly — Build Your Own "Golden Image"
So far, you’ve explored, verified, and tested Chainguard Images.
Now let’s go one step further — what if you want to create your own “Golden Image”, preloaded with your preferred tools, signed, and published in your Chainguard Catalog, complete with provenance and SBOMs?

That’s exactly what Custom Assembly does.

### 🧩 What is Custom Assembly?
Custom Assembly allows you to:
- Clone an existing Chainguard image (like python),
- Add or remove packages, and
- Publish it as a new, verifiable image with Chainguard’s provenance and SBOM automatically attached.

You can do this via the CLI (chainctl) or directly in the Chainguard Console UI.

### 🧰 CLI Walkthrough — Create Your Own Custom Python Image
Let’s create a personalized Python image that includes a couple of extra utilities. Run the below commands to set everything up. Make sure you provide in Step 1 your name!

1. Run: ```NAME=ENTER_YOUR_FIRST_NAME_HERE```
2. Run: ```NEW_IMAGE_NAME=python-$NAME```
3. Run: ```chainctl image repo build edit --parent $ORGANIZATION --repo $IMAGE --save-as $NEW_IMAGE_NAME```
This command:
- Opens an interactive YAML editor in your shell,
- Starts from the original image definition, and
- Lets you modify the image contents before saving.

**✍️ Edit Your Image Definition**
When the YAML opens, follow these steps carefully:
1. Remove the brackets {}
2. Add the following to the file:
```
contents:
  packages:
  - curl
  - bash
```
*(You must type this manually — pasting may not work properly in some terminals.)*

3. Confirm a few times until you see the Diff and get ask if you want to continue - **‼️ Warning**: This might be annoying 🤣
4. Confirm again

### 🏗️ Watch the Build Process
Once confirmed, the new image build starts in the background.

It may take a few minutes up to an hour, depending on the packages added, backend load and batch job size.

✅ Tip: You can monitor build progress in your Chainguard Console → Images → Builds tab.

### 🖥️ Explore Your Image in the Console

While the build runs:
1. Open the Chainguard Console.
2. Navigate to your Python image.
3. In the top-right corner, click Customize Image.
4. Use the search bar to browse available packages you could add.
*You can try these later on your new custom image — for now, keep the standard python image as-is.*

**🧠 What You’ve Achieved**

Created a customized, signed image based on Chainguard Python.
- Added tools (curl and bash) to extend functionality.
- Triggered a verified build that produces provenance and SBOMs automatically.
- Your organization now has its own Golden Image, built securely and reproducibly — ready to use in production or as a foundation for your teams.

# This is the End of the Workshop - Thank you very much for following along - We hope your enjoyed it! Thank you :)
