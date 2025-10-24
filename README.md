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

Before joining one of the workshops, please make sure your environment is ready. This ensures you can fully participate in the hands-on exercises without interruptions. A detailed list and instructions which tools are required are in the Workshop Instructions.

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

# Chainguard - Workshops
## [Chainguard Images Hand-on Workshop →](https://github.com/julianklodzinski/emea-chainguard-workshop/tree/main/images) 
## [Chainguard Libraries Hands-on Workshop →](https://github.com/julianklodzinski/emea-chainguard-workshop/tree/main/libraries)