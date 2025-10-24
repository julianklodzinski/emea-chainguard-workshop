# Redis Supply Chain Attack Demonstration

Demonstrates how container security scanners fail when images are manipulated through version spoofing and optimization. Shows why build-from-source architectures like Chainguard are essential for supply chain security.

## Overview

This demonstration proves three critical security failures:

1. **Version spoofing** defeats vulnerability scanners in 5 minutes
2. **Image optimization** creates complete scanner blindness
3. **Supply chain attacks** exploit these exact weaknesses (XZ Utils precedent)

## Prerequisites

### macOS
```bash
brew install grype syft jq docker-slim
```

### Linux
```bash
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh
# Install docker-slim from: https://github.com/slimtoolkit/slim/releases
```

## Workshop Steps

### Step 1: Baseline Scan
```bash
./redis-version-spoof.sh --scan-it
```

**What happens:**
- Pulls `redis:8.2.1` (digest-pinned)
- Scans with Grype
- Reports actual vulnerabilities

**Output:**
```
Detected Version: 8.2.1
Image Size: 130 MB

Severity        Count
CRITICAL        2
HIGH            8
TOTAL           77

CRITICAL CVEs Found:
- CVE-2025-46817 (EPSS 16.9%, Risk 14.7)
- CVE-2025-49844 (EPSS 6.8%, Risk 6.5)
```

**Key takeaway:** Scanners work correctly when metadata is intact.

---

### Step 2: Version Spoofing Attack
```bash
./redis-version-spoof.sh --spoof-it
```

**What happens:**
- Extracts redis-server binary from container
- Hex-edits version string: `8.2.1` → `8.2.2`
- Injects modified binary back
- Creates new image: `redis:8.2.1-spoofed`
- Re-scans with Grype

**Output:**
```
Attack Results Comparison

Image                    Version  Critical  High   Total
redis:8.2.1 (original)   8.2.1    2         8      77
redis:8.2.1-spoofed      8.2.2    0         6      73

Attack Impact:
- Hidden: 2 CRITICAL, 2 HIGH vulnerabilities
- CVE-2025-46817: HIDDEN ✓
- CVE-2025-49844: HIDDEN ✓
- Actual exploitability: 100% - Binary unchanged

Scanner verdict: PASS - No CRITICAL CVEs
Reality: Fully vulnerable, version string spoofed
```

**Key takeaway:** Binary code unchanged, but scanner reports clean. False negative achieved.

---

### Step 3: Metadata Destruction
```bash
./redis-version-spoof.sh --slim-it
```

**What happens:**
- Applies docker-slim to spoofed image
- Removes package metadata, OS distribution info
- Creates `redis:8.2.1-spoofed-slim`
- Scans with both Grype and Trivy
- Generates SBOMs for analysis

**Output:**
```
CATASTROPHIC SECURITY FAILURE

Image                        Version  Critical  High   Total  Size
redis:8.2.1-spoofed          8.2.2    0         6      73     148MB
redis:8.2.1-spoofed-slim     8.2.2    2         0      3      53MB

SBOM Analysis:
- Pre-slim SBOM:  90 packages detected
- Post-slim SBOM: 2 packages detected
- Removed: 88 of 90 packages from metadata
- Size reduction: 2.79x smaller (148MB → 53MB)

Scanner Chaos - Different Results:
  Trivy:  Finds NOTHING → Verdict: CLEAN
  Grype:  Reports CVE-2022-0543, CVE-2022-3734 (wrong CVEs from 2022)

Actual Security State:
  ✗ CVE-2025-46817 (CRITICAL): HIDDEN & EXPLOITABLE
  ✗ CVE-2025-49844 (CRITICAL): HIDDEN & EXPLOITABLE
  ✗ Binary code: Unchanged - 100% vulnerable
  ✗ Scanner reports: Unreliable/contradictory
```

**Key takeaway:** Complete scanner failure. Trivy reports clean. Grype reports wrong CVEs from 2022. Original 2025 vulnerabilities completely invisible. Image appears optimized and secure but remains fully exploitable.

---

## What This Demonstrates

### Scanner Architecture Weakness

**How scanners work:**
1. Extract metadata from `/var/lib/dpkg/`, binary version strings
2. Build SBOM
3. Query CVE database: "What CVEs affect redis 8.2.X?"
4. Filter: `if installed_version >= fixed_version: skip CVE`
5. Report remaining

**Attack exploitation:**
- **Phase 1 → 2:** Version string poisoned (`8.2.1` → `8.2.2`) → wrong SBOM → wrong queries → CVEs filtered out
- **Phase 2 → 3:** Metadata removed (90 → 2 packages) → scanner confusion → Trivy finds nothing, Grype hallucinates old CVEs
- **Result:** False negatives, contradictory reports, invisible vulnerabilities

### Why This Is Catastrophic

**Perfect storm for supply chain attack:**

| Metric | Result | Reality |
|--------|--------|---------|
| Scanner verdict (Trivy) | ✓ CLEAN | ✗ 2 CRITICAL CVEs |
| Scanner verdict (Grype) | ✗ 2 CRITICAL (wrong CVEs from 2022) | ✗ 2 CRITICAL (2025 CVEs hidden) |
| Image size | ✓ 2.79x smaller (53MB) | Professional appearance |
| Package count | 2 packages (vs 90) | Appears minimal |
| Actual exploitability | 100% vulnerable | Binary unchanged |
| Traceability | Impossible | SBOM corrupted |

**Organizations cannot detect:**
- Version spoofing occurred before optimization
- Metadata destroyed by optimization tool
- Different scanners give contradictory results
- No way to trace back to original compromise
- Both original CRITICAL CVEs completely invisible

---

## Why Chainguard Prevents This

### 1. Build-from-Source Architecture

**No tarballs, no metadata manipulation:**
```
Git source → melange YAML → QEMU microVM → apko assembly → SLSA attestation
  ↑ CLEAN    ↑ DECLARATIVE   ↑ ISOLATED    ↑ SIGNED       ↑ PROVABLE
```

- Build-time SBOM generation (not extracted from metadata)
- Cryptographic signatures prevent tampering
- Version spoofing detected immediately (signature verification fails)

### 2. Real-World Validation: XZ Utils (CVE-2024-3094)

**March 2024 - CVSS 10.0 backdoor:**
- Injected into tarball distributions (NOT Git source)
- Traditional images: Vulnerable (Debian, Fedora, Ubuntu, Arch)
- Chainguard: Immune (never use tarballs, build from source only)
- Response time: Hours to detect, rollback, notify customers

**Why Chainguard was immune:**
```
Traditional workflow:
  upstream tarball → ./configure && make → .deb/.rpm → apt install
      ↑ BACKDOOR         ↑ COMPILED          ↑ DISTRIBUTED

Chainguard workflow:
  Git source → melange → QEMU microVM → apko → SLSA attestation
    ↑ CLEAN    ↑ ISOLATED   ↑ TESTED      ↑ SIGNED
```

### 3. Distroless Design

**What's excluded:**
- Shell, bash, package managers
- Package metadata databases
- SSH, systemd

**Why this matters:**
- No metadata to manipulate
- No extraction points for spoofing
- Immutable by design
- 97.6% CVE reduction on average

### 4. VM Isolation

**QEMU microVMs (not containers):**
- Hardware-backed separation
- Separate build and test VMs
- Custom Chainguard OS kernel
- Build compromise cannot affect test validation

### 5. Proactive Security

**Daily operations:**
- 10,000+ packages, 1,700+ images rebuilt nightly
- Upstream monitoring: detects releases in minutes
- CVE remediation: 7-day SLA for Critical (often same-day)
- OpenSSF compiler hardening (beyond industry standard)
- 22,000+ advisories in 6 months

### 6. Advisory Feeds (Scanner Integration)

**Not evasion - enrichment:**
- OSV.dev + Alpine security.json feeds
- Multi-scanner support: Grype, Trivy, Snyk, Docker Scout
- Provides context: "Fixed in version X"
- Customers verify independently via SLSA attestations

**Key difference from this attack:**
- **Attack approach:** Corrupts metadata to HIDE vulnerabilities
- **Chainguard approach:** Enriches metadata to SURFACE context and provide verifiable fix information

### 7. OIDC Distribution

**No long-lived tokens:**
- All auth via OpenID Connect
- Credentials expire in minutes
- Eliminates credential leak vector

---

## Attack Resistance Matrix

| Attack Vector | Traditional Images | Chainguard |
|---------------|-------------------|------------|
| Version spoofing | ❌ Vulnerable (5 minutes) | ✅ Build-time SBOM, signed |
| Metadata removal | ❌ Scanner blind | ✅ Distroless, no metadata |
| Tarball injection | ❌ Vulnerable (XZ Utils) | ✅ Source-only builds |
| Distribution compromise | ❌ Vulnerable | ✅ No distro packages |
| Binary tampering | ❌ Undetected | ✅ Signature verification fails |
| Build compromise | ❌ Uncontained | ✅ Separate VMs, isolated |
| Scanner confusion | ❌ Contradictory results | ✅ Advisory feeds provide truth |

---

## Enterprise Implications

**What this proves:**

1. **Scanners defeated in 5 minutes** - Version spoofing hides 2 CRITICAL CVEs
2. **Optimization tools create blind spots** - docker-slim removes 88 of 90 packages from metadata
3. **Scanner chaos** - Trivy reports clean, Grype reports wrong CVEs, neither finds real vulnerabilities
4. **Supply chain attacks exploit these weaknesses** - XZ Utils backdoor proves real-world feasibility

**Traditional security is insufficient:**
- Relies on metadata integrity (can be corrupted)
- Reactive patching (detect after compromise)
- Single scanner trust (contradictory results possible)
- No cryptographic verification chain

**Chainguard provides:**
- Build-from-source (no metadata manipulation possible)
- Cryptographic proof (SLSA Level 3 attestations)
- Proactive patching (before CVEs assigned)
- Architectural immunity (no attack surface)
- Advisory feeds (enrich scanner accuracy)

**For security-critical environments:**
- State-sponsored threats
- FedRAMP, FIPS, PCI-DSS compliance
- Financial, healthcare, critical infrastructure
- Zero-trust architecture

This is not cost-benefit analysis - it's architecture that can or cannot be compromised.

---

## Defense Requirements

**BEFORE optimization:**
- ✓ Cryptographic signing (Cosign/Notary) - MANDATORY
- ✓ SBOM generation and signing
- ✓ SLSA provenance attestation
- ✓ Verify source authenticity
- ✓ Multiple scanner validation

**AFTER optimization:**
- ✓ Re-sign the optimized image
- ✓ Generate NEW SBOM for optimized image
- ✓ Link to original provenance chain
- ✓ Admission controllers verify ALL signatures
- ✓ Runtime integrity monitoring

**RUNTIME:**
- ✓ Behavioral monitoring (Falco/Tetragon)
- ✓ Binary integrity verification
- ✓ Network traffic analysis
- ✓ Syscall monitoring
- ✓ Anomaly detection

**Critical rules:**
- **NEVER optimize images without cryptographic verification**
- **NEVER trust a single scanner**
- **ALWAYS verify SBOM integrity**

---

## Resources

**Chainguard Engineering:**
- [Inside the Chainguard Factory](https://www.chainguard.dev/unchained/this-shit-is-hard-inside-the-chainguard-factory) - Build automation, 10,000+ packages
- [Hardening glibc](https://www.chainguard.dev/unchained/this-shit-is-hard-hardening-glibc) - OpenSSF compiler hardening, upstream contributions
- [Vulnerability Scanner Integration](https://www.chainguard.dev/unchained/this-shit-is-hard-vulnerability-scanner-integration) - Advisory feeds, 22,000+ advisories
- [SLSA L3 and Beyond](https://www.chainguard.dev/unchained/this-shit-is-hard-slsa-l3-and-beyond) - QEMU microVMs, attestations

**Supply Chain Security:**
- [Chainguard's XZ Utils Response](https://www.chainguard.dev/unchained/chainguards-response-to-cve-2024-3094)
- [SLSA Framework](https://slsa.dev)
- [OpenSSF Compiler Hardening](https://best.openssf.org/Compiler-Hardening-Guides/)

---

## Cleanup
```bash
docker rmi redis:8.2.1-spoofed redis:8.2.1-spoofed-slim
rm -rf ./sbom-analysis
```

---

## License

MIT

## Author

Denis Maligin, Chainguard, Inc.

## Warning

**For security research and educational purposes only.** This demonstrates why cryptographic verification is non-negotiable in supply chain security.
