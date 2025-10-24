# 🔹 Why Join This Workshop
In this Workshop, you’ll learn how to use Chainguard Images — secure, minimal, and continuously verified container images — in a practical, hands-on way.

If anything like this sounds familar to you:
- “We want minimal and CVE-free images.”
- “We spend too much time chasing CVEs.”
- “Our customers require CVE-free software.”
- “We need to meet compliance targets.”
- "We have a golden Image programm"
- "We lost the overview about where all the images come from and what is in them"

# Chainguard Products
```
┌────────────────────────────────┐ ┌────────────────────────────────┐ ┌────────────────────────────────┐
│     Chainguard Containers      │ │     Chainguard Libraries       │ │         Chainguard VMs         │
│         1700+ Projects         │ │    Python Java JavaScript      │ │                                │
│     Distroless & CVE free      │ │ Maleware Mitigating & CVE free │ │        On-prem and Cloud       │
└────────────────────────────────┘ └────────────────────────────────┘ └────────────────────────────────┘
```

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
| **Syft**     | SBOM generator                                     | [Install Syft →](https://github.com/anchore/syft?tab=readme-ov-file#installation)                   |
| **Trivy**    | Image vulnerability and misconfiguration scanner   | [Install Trivy →](https://trivy.dev/latest/getting-started/installation/)                           |
| **jq**       | JSON processor                                     | [Install jq →](https://jqlang.org/download/)                                                        |
| **yq**       | YAML processor                                     | [Install yq →](https://github.com/mikefarah/yq?tab=readme-ov-file#install)                          |
| **cosign**   | Tool for signing and verifying container artifacts | [Install cosign →](https://docs.sigstore.dev/cosign/system_config/installation/)                    |
| **dfc**      | Diff and compare tool for Chainguard images        | [Install dfc →](https://github.com/chainguard-dev/dfc)                                              |
| **git**      | To manage Code Repositories                        | [Install git →](https://git-scm.com/downloads)                                              |

✅ Quick Check:
Run the following command to verify your setup:
```
chainctl version && docker version && grype version && syft --version && trivy --version && jq --version && yq --version && cosign version && dfc version && git --version
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

## 👥 Workshop Account Access
At the start of the session, you’ll receive an invite link granting access to your dedicated Workshop Organization in Chainguard. For authorization you need an account in one of the three providers:
- Google
- Gitlab
- Github

# Chainguard - Your Safe Source for Open Source
