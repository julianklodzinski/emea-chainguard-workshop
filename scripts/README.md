# Redis Supply Chain Attack Demonstration
## Why Container Security Scanners Fail & How Chainguard Prevents It

### Overview

This demonstration exposes critical vulnerabilities in container security scanning by showing how easily attackers can manipulate package metadata to hide CVEs from vulnerability scanners. We use Redis 8.2.1 (with 2 CRITICAL CVEs) as the target and demonstrate three attack vectors that defeat traditional scanning tools.

**Key Finding:** Metadata manipulation renders vulnerability scanners blind, while Chainguard's build-from-source architecture provides immunity to these attacks.

---

## Attack Demonstration: Three Phases

### Phase 1: Baseline Scan (Clean State)

**Image:** `redis:8.2.1` (Digest-pinned)
```
Size: 130 MB
CRITICAL CVEs: 2 (CVE-2025-46817, CVE-2025-49844)
HIGH CVEs: 8
TOTAL CVEs: 77
```

**Scanner Behavior:** Functions correctly when metadata is intact.

---

### Phase 2: Version Spoofing Attack

**Technique:** Manipulate the redis-server binary version string from `8.2.1` → `8.2.2`

**Attack Execution:**
```bash
# Extract binary
docker cp <container>:/usr/local/bin/redis-server /tmp/redis-server-orig

# Hex-edit version string (preserving binary integrity)
perl -pi -e 's/8\.2\.1/8\.2\.2/g' /tmp/redis-server-orig

# Inject back into image
docker cp /tmp/redis-server-orig <container>:/usr/local/bin/redis-server
```

**Result:**
```
Original Image:     2 CRITICAL | 8 HIGH | 77 TOTAL
Spoofed Image:      0 CRITICAL | 6 HIGH | 73 TOTAL

Hidden CVEs:
  ✗ CVE-2025-46817 (EPSS 16.9%) - HIDDEN
  ✗ CVE-2025-49844 (EPSS 6.8%)  - HIDDEN
```

**Scanner Verdict:** ✅ PASS (No CRITICAL CVEs detected)  
**Reality:** ❌ FULLY VULNERABLE (Binary unchanged, exploitability 100%)

**Why Scanners Fail:**
1. Grype/Trivy query: "What CVEs exist for redis version 8.2.2?"
2. CVE databases show: CVE-2025-46817 fixed in 8.2.2
3. Scanner logic: "If running 8.2.2, CVE is fixed" → FALSE NEGATIVE
4. Binary is actually 8.2.1 code with spoofed version metadata

---

### Phase 3: The Catastrophic Scenario (docker-slim + Metadata Loss)

**Technique:** Apply docker-slim optimization to spoofed image

**What docker-slim Does:**
- Removes OS packages (debian, apt, libc metadata)
- Strips package manager databases (`/var/lib/dpkg/*`, `/var/lib/apt/*`)
- Eliminates filesystem metadata
- **Result:** Only redis binary + minimal dependencies remain

**Attack Execution:**
```bash
docker-slim build --target redis:8.2.1-spoofed \
  --tag redis:8.2.1-spoofed-slim \
  --http-probe=false
```

**Image Transformation:**
```
Original:  130 MB | Full OS metadata | 77 CVEs detected
Slimmed:    15 MB | No OS metadata   | Scanner confusion
```

**Scanner Results - Grype:**
```
NAME   INSTALLED  TYPE    VULNERABILITY   SEVERITY
redis  8.2.2      binary  CVE-2022-0543   Critical  (99th percentile EPSS)
redis  8.2.2      binary  CVE-2022-3734   Critical
redis  8.2.2      binary  CVE-2025-49112  Low
```

**Scanner Hallucination:**
- Reports CVE-2022-0543 (from 2022, patched years ago)
- Reports CVE-2022-3734 (from 2022, patched years ago)
- **Misses actual 2025 CVEs completely**
- EPSS shows 99th percentile (misleading risk assessment)

**Scanner Results - Trivy:**
```
Number of language-specific files: num=0
[No vulnerabilities reported]
```

**Complete Scanner Blindness:**
- Trivy: Reports ZERO vulnerabilities
- Grype: Hallucinates wrong CVEs from 2022
- Both fail to detect actual CRITICAL vulnerabilities

**Why Complete Failure:**
1. **No OS Package Metadata:** `/var/lib/dpkg/` removed
2. **No Distribution Info:** `/etc/os-release` stripped
3. **Binary-Only Analysis:** Scanners rely on version string (spoofed to 8.2.2)
4. **No Reference Point:** Cannot correlate binary to actual package versions
5. **Guessing Algorithm Failure:** Scanners guess wrong CVEs based on corrupted data

---

## Technical Autopsy: What We Manipulated

### 1. Version String Manipulation
**Target:** Redis binary embedded version string  
**Method:** Hex editing with byte-for-byte replacement  
**Impact:** Scanner metadata queries return wrong CVE mappings

### 2. Metadata Removal via docker-slim
**Removed:**
- `/var/lib/dpkg/status` (Debian package database)
- `/var/lib/apt/lists/*` (APT cache)
- `/etc/os-release` (Distribution identification)
- All .deb package metadata

**Impact:** Scanners lose reference points for CVE correlation

### 3. Preserved: Actual Vulnerable Code
**Binary:** Unchanged 8.2.1 vulnerable code  
**Exploitability:** 100% - All original CVEs exploitable  
**Scanner Detection:** 0% - Completely blind

---

## Why This Attack Works: Scanner Architecture Weakness

**Vulnerability Scanner Workflow:**
```
1. Extract metadata from image:
   ├─ Read /var/lib/dpkg/status
   ├─ Parse binary version strings  
   └─ Identify OS distribution

2. Build software inventory (SBOM)

3. Query CVE databases:
   "What CVEs affect redis 8.2.X on Debian 12?"

4. Filter CVEs based on version comparison:
   IF installed_version >= fixed_version THEN skip CVE

5. Report remaining vulnerabilities
```

**Attack Exploitation:**
- **Step 1:** Poisoned by version spoofing
- **Step 2:** SBOM contains wrong version
- **Step 3:** Query executed with wrong parameters  
- **Step 4:** Logic: "8.2.2 >= 8.2.2" → CVE filtered out
- **Step 5:** False negative reported

---

## Why Chainguard Prevents This Attack

### 1. Build-From-Source Architecture with VM Isolation

**Chainguard Process:**
```
Source Code (Git) 
    ↓
melange (APK builder - declarative YAML)
    ↓ 
QEMU microVM (hardware-backed isolation)
    ↓ [Build VM] → Separate [Test VM]
    ↓
apko (Image assembler)
    ↓
Signed & Attested Image (SLSA L3)
```

**Protection Mechanism:**
- **No distribution tarballs:** Eliminates tarball-injection attacks (XZ Utils CVE-2024-3094)
- **VM-level isolation:** Each build runs in dedicated QEMU microVM, not containers ("containers are screen doors")
- **Separate build/test VMs:** Compromise of build environment cannot affect test validation
- **Custom secure kernel:** Chainguard OS kernel built specifically for secure builds
- **Reproducible builds:** Bit-for-bit verification using nested virtualization (GKE)
- **Build-time SBOM:** Generated during compilation, not extracted from metadata
- **SLSA Level 3:** Hardware-backed provenance attestations with signing secrets isolated from build process

### 2. The Chainguard Factory: Industrial-Scale Security

**Automated Build Infrastructure:**
- **Custom Kubernetes build system** (migrated from GitHub Actions for observability/security)
- **Robotic automation:** Detects upstream releases within minutes, auto-generates PRs
- **AI-assisted diagnosis:** LLMs analyze build failures, suggest fixes in GitHub comments
- **10,000+ packages, 1,500+ images** rebuilt and tested daily
- **CVE Remediation SLA:** 7 days Critical, 14 days High/Medium/Low (often same-day)

**Quality Assurance at Scale:**
- Package tests run on every update
- K3s clusters for cloud-native validation
- Full EKS clusters for AWS-integrated images (EBS CSI Driver)
- GPU testing infrastructure for ML workloads
- Malcontent scanning for malware detection

**Automated Remediation Workflow:**
1. Grype scans with extended sensitivity detect CVEs
2. Automation attempts fixes (Go dependency bumps, rebuilds)
3. Test validation in separate microVM
4. Human review queue for complex cases
5. Advisory feed updates (22,000+ advisories in 6 months)
6. Image rebuild and tag update
7. Scanner notification via OSV/security.json feeds

**Result:** Proactive vulnerability elimination before CVE assignment, often fixing issues before scanners detect them.

### 3. Distroless Design + Hardened Compiler Flags

**What's NOT in Chainguard Images:**
- ❌ Shell (`/bin/sh`, `/bin/bash`)
- ❌ Package managers (`apt`, `apk`)
- ❌ Package metadata databases
- ❌ Unnecessary OS utilities
- ❌ SSH, systemd, or runtime modification tools

**Why This Matters:**
- **Minimal attack surface:** Only application + runtime dependencies
- **No metadata to manipulate:** Nothing to spoof or corrupt
- **Immutable by design:** No package manager = no runtime modifications
- **Scanner integrity:** No extraction points for false information

**Proactive Compiler Hardening (Beyond Industry Standard):**

Chainguard goes beyond typical distributions by implementing OpenSSF's full Compiler Options Hardening Guide:

- **Stack protection:** `-z noexecstack` (non-executable stack memory, prevents DEP attacks)
- **Control flow integrity (x86):** `-fcf-protection=full` (ROP/JOP protection)
- **Branch protection (ARM64):** `-mbranch-protection=standard` (ARMv8.3+ security)
- **Position independent execution:** Full ASLR implementation
- **Fortify source:** Buffer overflow detection at compile-time

**Real Example - glibc Hardening:**
- Chainguard engineers debugged complex GCC/glibc interaction bugs to enable full hardening
- Contributed upstream fixes to GCC (bug #120653) and glibc (bug #33088)
- Result: Industry-first hardened glibc with stack unwinding fixes for Python/C++ exceptions
- ARM64-specific fixes for Google Axion processors (glibc bug #33112)

**Image Comparison:**
```
Traditional Redis:  130 MB | 500+ packages | 77 CVEs | Standard compile flags
Chainguard Redis:    20 MB |  ~15 packages |  0 CVEs | Full OpenSSF hardening
```

### 4. Scanner Integration: Working WITH Detection, Not Against It

**The Metadata Manipulation Problem:**
Our demonstration exploits scanner architecture: Extract metadata → Build SBOM → Query CVE DB → Filter by version

**Attack succeeds because:** Poisoned metadata at step 1 → Wrong SBOM → Wrong queries → False negatives

**Chainguard's Solution:**
```
Build-time SBOM Generation (during compilation)
    ↓
Advisory Feed Integration (Alpine security.json + OSV format)
    ↓
Multi-Scanner Support (Grype, Trivy, Snyk, Docker Scout, etc.)
    ↓
Continuous Validation (detect vulnerabilities before scanners)
```

**How Advisory Feeds Work:**
1. **Detection:** Internal Grype with extended sensitivity finds CVE
2. **Timestamp:** Advisory records first detection time
3. **Remediation:** Automated fix attempt (dependency bump, rebuild, test)
4. **Validation:** Separate test microVM confirms fix
5. **Advisory Update:** Record fix in security.json and OSV.dev
6. **Scanner Notification:** Supported scanners read advisory and suppress false positives

**Multi-Format Support:**
- **Alpine security.json:** For Wolfi (public) and Chainguard (private) packages
- **OSV format:** Unified feed viewable on https://osv.dev/list?ecosystem=Chainguard
- **Console integration:** Advisory history visible in Chainguard Console per-image

**Scanner Partnership:**
- Built vulnerability-scanner-support repository for scanner vendors
- Automated regression testing for scanner implementations
- Direct engagement with Grype, Trivy, Snyk, Docker Scout, and others
- Educational resources for scanner developers

**Key Difference:** 
- **Attack approach:** Corrupts metadata to HIDE vulnerabilities
- **Chainguard approach:** Enriches metadata to SURFACE context (fixed versions, exploitability)

**Trust Model:**
- Chainguard doesn't "grade its own exam"
- Customers use their preferred scanner
- Advisory feeds provide context: "We fixed this in version X"
- Scanner independently verifies through CVE database correlation
- **Result:** Scanners trust Chainguard's advisory data because it's cryptographically verifiable via SLSA attestations

### 5. Nightly Rebuilds & Distribution Security

**Continuous Security:**
- Every Chainguard image rebuilt nightly from upstream source
- Automated upstream monitoring detects new releases within minutes
- CVE remediation SLA: 7 days for CRITICAL (often same-day or pre-emptive)
- Multiple version streams automatically maintained
- EOL packages automatically deprecated from public Wolfi repository
- No reliance on distribution maintainer patching cycles
- Proactive vulnerability elimination before CVEs published

**Distribution Security (OIDC-Based):**
- **No long-lived tokens:** All auth via OpenID Connect (short-lived, revocable)
- **Narrow scoping:** Credentials limited to specific images/registries
- **Credential helper:** `chainctl` tool automates secure authentication
- **Audit trail:** All pulls logged with OIDC identity
- **Result:** Eliminates credential leak attack vector (credentials expire in minutes, not years)

### 6. Cryptographic Verification (SLSA Level 3)

**Build Integrity:**
```
✓ Sigstore signatures (Cosign)
✓ SLSA v1.1 provenance attestations  
✓ Build-time SBOMs (not extracted metadata)
✓ Reproducible builds (bit-for-bit verification via nested virtualization)
✓ Hardware-backed isolation (QEMU microVMs, not containers)
✓ Separate signing secrets (isolated from build/test processes)
```

**Verify Chainguard's Claims:**
```bash
# Download and inspect SLSA provenance
cosign download attestation \
  --predicate-type=https://slsa.dev/provenance/v1 \
  cgr.dev/chainguard/redis:latest | \
  jq -r .payload | base64 -d | jq .predicate

# Verify signature
cosign verify cgr.dev/chainguard/redis:latest \
  --certificate-identity-regexp='.*' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

**Attack Prevention Matrix:**
- **Version spoofing:** ✅ Impossible - SBOM generated at build-time, signed
- **Metadata manipulation:** ✅ Irrelevant - No extractable metadata, distroless design
- **Binary tampering:** ✅ Detected - Signature verification fails immediately
- **Supply chain injection:** ✅ Blocked - Source-only builds, VM isolation, provenance trail
- **Build compromise:** ✅ Mitigated - Separate build/test VMs, hardware isolation
- **Tarball attacks (XZ-style):** ✅ Immune - Never use distribution tarballs

---

## Comparison: Attack Resistance

| Attack Vector | Traditional Images | Chainguard |
|---------------|-------------------|------------|
| Version string spoofing | ❌ Vulnerable | ✅ Immune (build-time SBOM) |
| Package metadata removal | ❌ Scanner blind | ✅ Not applicable (distroless) |
| Tarball injection (XZ-style) | ❌ Vulnerable | ✅ Immune (source-only builds) |
| Distribution layer compromise | ❌ Vulnerable | ✅ Immune (no distro packages) |
| Binary tampering | ❌ Undetected | ✅ Signature verification |

---

## Real-World Parallel: XZ Utils (CVE-2024-3094)

**March 2024 Supply Chain Attack:**
- Backdoor injected into XZ Utils versions 5.6.0 and 5.6.1
- **Injection method:** Malicious code in tarball distributions, NOT in Git source repository
- **Build process exploitation:** Obfuscated code in test files extracted during `./configure`
- **Target:** SSH authentication bypass (liblzma modification)
- Compromised: Debian testing/unstable, Fedora Rawhide, Ubuntu (devel), Arch, openSUSE Tumbleweed
- **Multi-year social engineering:** JiaT75 account created 2021, became maintainer 2023, deployed backdoor Feb 2024
- CVSS: 10.0 (Critical)
- **Detection:** Microsoft engineer Andres Freund noticed 500ms SSH delay

**Attack Method:** Virtually identical to our demonstration's Phase 3
1. Malicious code hidden in tarball (not source Git repository)
2. Build process modified via m4 macros during `./configure`
3. Binary code extracted from "test files" during compilation
4. Injected into liblzma.so at link time
5. Distribution packages contained backdoor
6. Scanners: Blind (no CVE existed initially)

**Why Traditional Images Were Vulnerable:**
```
Debian/Ubuntu/Fedora Workflow:
  upstream tarball (XZ 5.6.1) 
      ↓ [BACKDOOR INJECTED HERE]
  ./configure && make
      ↓ [BACKDOOR COMPILED INTO BINARY]
  .deb/.rpm package
      ↓
  Container image FROM debian:bookworm
      ↓ [apt install xz-utils]
  RESULT: Backdoored liblzma in production
```

**Why Chainguard Was Immune:**

**1. Build-from-Source (No Tarballs):**
```
Chainguard Workflow:
  Git source repository (CLEAN - no backdoor)
      ↓
  melange declarative build (YAML)
      ↓ [Tarball NEVER downloaded]
  Compilation in QEMU microVM
      ↓
  apko assembly
      ↓
  RESULT: Clean binary, no backdoor possible
```

**2. Distroless Architecture:**
Chainguard's sshd analysis revealed liblzma was NOT linked in Chainguard images due to minimal design
- SSH not included by default (distroless)
- liblzma not a dependency
- **Attack surface didn't exist**

**3. Rapid Response (Hours, Not Days):**
Within hours of disclosure, Chainguard identified XZ usage, withdrew affected versions, rebuilt with 5.4.6
- Internal Grype detected package presence
- Automated rollback to 5.4.6
- Customer notification via advisory feeds
- No customer action required (automated updates)

**4. Continuous Monitoring Advantage:**
Chainguard's approach to rapid updates and nightly testing catches complex bugs that upstream projects aren't aware of

**Traditional Images (Debian/Ubuntu/Fedora):**
- ❌ **Affected:** Used distribution packages built from tarballs
- ❌ **Scanner blind:** No CVE to detect initially  
- ❌ **Detection delay:** Discovered by chance (SSH performance issue)
- ❌ **Response delay:** Emergency patching, manual customer intervention required
- ❌ **Verification:** No way to prove clean rebuild without tarball

**Chainguard Response:**
- ✅ **Not affected:** Source-only builds, never used tarballs
- ✅ **Scanner accurate:** Advisory feeds updated immediately
- ✅ **Proactive detection:** Internal testing would have caught abnormal SSH behavior
- ✅ **Instant response:** Automated rollback within hours
- ✅ **Cryptographic proof:** SLSA attestations prove build from clean source

**The Critical Insight:**

The XZ backdoor demonstrates **exactly** what our demonstration proves:
- **Metadata/binary manipulation defeats traditional security**
- **Distribution-layer compromises bypass all scanning**
- **Source-to-binary verification is the only reliable defense**

XZ was discovered by accident (SSH performance degradation). How many similar attacks exist undetected because they don't cause performance issues?

**Chainguard's Architecture Provides Immunity Because:**
1. **No tarballs** = No tarball injection vector
2. **VM isolation** = Compromised build can't persist or escape
3. **Reproducible builds** = Bit-for-bit verification possible
4. **SLSA attestations** = Cryptographic proof of source provenance
5. **Distroless design** = Attack surface minimization eliminates entire vulnerability classes

---

## Implications for Enterprise Security

### The False Security of Scanning Alone

**Common Misconception:** "Scanner shows 0 CRITICAL CVEs = secure"

**Reality Demonstrated:**
- **5 minutes:** Version string manipulation hides 2 CRITICAL CVEs
- **15 minutes:** docker-slim optimization causes complete scanner blindness/hallucination
- **No sophistication required:** Shell script + hex editor + docker-slim
- **Zero detection:** Scanners report "clean" while fully vulnerable

**What This Reveals:**
1. **Vulnerability scanners are necessary but insufficient** for supply chain security
2. **Metadata integrity cannot be assumed** in traditional image architectures
3. **Image optimization tools create blind spots** that attackers exploit
4. **Supply chain attacks exploit these exact weaknesses** (XZ Utils precedent proves this)

### The Chainguard Advantage: Architecture vs. Detection

**Traditional Approach:**
```
Build from distribution packages
    ↓
Extract metadata
    ↓
Scan for vulnerabilities
    ↓
Patch when found
    ↓
Re-scan to verify
    ↓
[Vulnerable to: tarball injection, metadata manipulation, 
 distribution compromise, scanner evasion]
```

**Chainguard Approach:**
```
Build from source in isolated VMs
    ↓
Generate cryptographic attestations
    ↓
Continuous proactive patching (before CVEs)
    ↓
Advisory feed integration (enrich scanner data)
    ↓
Nightly rebuilds (zero CVE accumulation)
    ↓
[Immune to: tarball attacks, metadata manipulation,
 distribution compromise, build compromise]
```

### Defense-in-Depth: Why Chainguard's Architecture Matters

**Layer 1: Eliminate Attack Vectors (Distroless)**
- ❌ No SSH, bash, package managers
- ❌ No metadata databases to corrupt
- ✅ 97.6% reduction in CVEs on average
- **Principle:** Reduce attack surface > Detect attacks after compromise

**Layer 2: Build Integrity (SLSA L3)**
- ✅ VM isolation (hardware-backed, not container "screen doors")
- ✅ Separate build/test environments
- ✅ Custom secure kernel (Chainguard OS)
- ✅ Provenance attestations with isolated signing
- **Principle:** Prevent compromise > Respond to compromise

**Layer 3: Source Transparency (No Tarballs)**
- ✅ Git-only source
- ✅ No distribution tarballs
- ✅ Reproducible builds (bit-for-bit verification)
- **Principle:** Verify source > Trust distribution

**Layer 4: Proactive Security (Hardened Compilation)**
- ✅ Full OpenSSF compiler hardening
- ✅ Stack protection, CFI, ASLR
- ✅ Beyond industry standard flags
- **Principle:** Prevent exploitation > Patch vulnerabilities

**Layer 5: Continuous Validation (Factory Automation)**
- ✅ Nightly rebuilds from source
- ✅ Automated upstream monitoring (minutes)
- ✅ 22,000+ advisories in 6 months
- ✅ AI-assisted build diagnosis
- **Principle:** Continuous security > Point-in-time scanning

**Layer 6: Scanner Partnership (Advisory Feeds)**
- ✅ OSV + Alpine security.json feeds
- ✅ Multi-scanner support (Grype, Trivy, Snyk, etc.)
- ✅ Vulnerability-scanner-support repository
- **Principle:** Enrich detection > Evade detection

### Operational Benefits

**For Security Teams:**
- **No false negatives from metadata corruption**
- **No emergency patching for distribution-layer compromises**
- **CVE backlog eliminated by design** (nightly rebuilds)
- **Compliance evidence through SLSA attestations**
- **7-day Critical CVE SLA** (often same-day)
- **Cryptographic verification** of entire supply chain

**For Development Teams:**
- **No breaking changes from base image switches**
- **No testing overhead for upstream vulnerabilities**
- **Predictable update cadence** (nightly)
- **Minimal images** = faster pulls, smaller attack surface
- **FIPS/STIG compliance** out-of-the-box (where applicable)

**For Compliance/Audit:**
- **SLSA Level 3 certification**
- **Reproducible builds** for audit verification
- **Complete SBOM** generated at build-time
- **Provenance attestations** cryptographically signed
- **Advisory history** for every image
- **No long-lived credentials** (OIDC-only)

### Cost of Not Using Build-from-Source

**Hidden Costs in Traditional Approaches:**
1. **Engineering time:** Triaging scanner false positives/negatives
2. **Vulnerability debt:** Accumulation while waiting for upstream patches
3. **Emergency patching:** Reactive response to supply chain attacks
4. **Compliance overhead:** Manual SBOM generation, attestation management
5. **Trust deficit:** No cryptographic proof of build integrity
6. **Unknown exposure:** Undiscovered XZ-style backdoors

**Chainguard Investment:**
- **Upfront:** Migration effort (Dockerfile changes, testing)
- **Vendor lock-in:** Wolfi ecosystem (APK incompatibility with Alpine)
- **Learning curve:** New tools (melange, apko, chainctl)

**ROI Calculation:**
```
Traditional: Low migration cost + High ongoing operational cost + Unknown compromise risk
Chainguard:  High migration cost + Low ongoing operational cost + Cryptographically proven security
```

For organizations facing:
- **State-sponsored threats**
- **Strict compliance requirements** (FedRAMP, FIPS, PCI-DSS)
- **High-value targets** (financial, healthcare, critical infrastructure)
- **Zero-trust architecture** implementation

**Chainguard's approach is not optional—it's the only architecture that provides cryptographic proof against supply chain compromise.**

---

## Running the Demonstration

### Prerequisites
```bash
# Install required tools
brew install grype syft jq
brew install docker-slim  # For phase 3

# Or on Linux:
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh
```

### Execution
```bash
# Phase 1: Baseline scan
./redis-version-spoof.sh --scan-it

# Phase 2: Version spoofing attack  
./redis-version-spoof.sh --spoof-it

# Phase 3: Catastrophic scenario (slim + metadata loss)
./redis-version-spoof.sh --slim-it

# Full demo (all phases)
./redis-version-spoof.sh --full-demo
```

### Expected Output
- Phase 1: 2 CRITICAL, 8 HIGH CVEs detected
- Phase 2: 0 CRITICAL CVEs (false negative)
- Phase 3: Scanner confusion (wrong CVEs or none)

---

## Conclusion

**This demonstration proves three critical truths:**

1. **Vulnerability scanners can be trivially defeated** through metadata manipulation that requires no sophisticated tooling or expertise

2. **Image optimization creates scanner blind spots** that make vulnerability detection unreliable or impossible

3. **Supply chain attacks exploit these exact weaknesses** with real-world precedent (XZ Utils CVE-2024-3094)

**Traditional security approaches—reactive patching and runtime scanning—are fundamentally inadequate** against determined adversaries. Our demonstration shows that an attacker can:
- Hide CRITICAL CVEs with 5 minutes of work
- Cause complete scanner blindness with standard optimization tools
- Deploy compromised images that pass all security gates

**Chainguard's architecture represents a paradigm shift** from reactive detection to proactive prevention:

| Security Principle | Traditional Approach | Chainguard Approach |
|-------------------|---------------------|-------------------|
| **Trust Model** | Trust distribution tarballs | Build from source only |
| **Isolation** | Container-level (screen doors) | VM-level (hardware-backed) |
| **Verification** | Extract metadata, scan | Generate attestations, prove |
| **Patching** | Reactive (after CVE) | Proactive (before CVE) |
| **Build Integrity** | Assumed | SLSA L3 certified |
| **Scanner Interaction** | Extract → Scan → Report | Build → Attest → Enrich → Verify |

**The engineering sophistication required** for Chainguard's approach cannot be understated:
- **Custom Kubernetes build system** (not GitHub Actions)
- **QEMU microVM isolation** (nested virtualization in GKE)
- **Separate build and test VMs** (attack containment)
- **Custom secure kernel** (Chainguard OS for build integrity)
- **OpenSSF compiler hardening** (beyond industry standard)
- **22,000+ advisory updates** (6-month period)
- **Multi-scanner integration** (Grype, Trivy, Snyk, Docker Scout)
- **SLSA Level 3 compliance** (hardware-backed attestations)

**This is hard work.** As Chainguard's CTO says: "We don't do this because it's easy, we do it because we thought it would be easy." The reality is that building a secure software supply chain requires:
- Bootstrapping an entire Linux distribution (Wolfi)
- Managing 10,000+ packages and 1,500+ images
- Nightly rebuilds with comprehensive testing
- AI-assisted build failure diagnosis
- Direct upstream engagement (GCC, glibc bug fixes)
- Full EKS clusters for integration testing
- OIDC-based credential management

**For organizations requiring defense against sophisticated supply chain attacks** (state-sponsored APT groups, targeted campaigns), Chainguard's architecture is not just superior—**it's the only approach that provides cryptographic proof of supply chain integrity.**

**The choice is clear:**
- **Continue with traditional images:** Accept metadata manipulation risk, XZ-style backdoor exposure, scanner evasion, and reactive security posture
- **Adopt Chainguard:** Invest in migration, gain immunity to demonstrated attacks, achieve SLSA L3 compliance, eliminate CVE backlog

For security-critical environments, this is not a cost-benefit analysis—**it's a matter of architecture that can or cannot be compromised.**

---

## Learn More: Chainguard's "This Shit Is Hard" Series

Dive deeper into the engineering sophistication behind Chainguard's approach:

1. **[Inside the Chainguard Factory](https://www.chainguard.dev/unchained/this-shit-is-hard-inside-the-chainguard-factory)**  
   - Custom Kubernetes build system
   - Automated robots detecting upstream releases in minutes
   - AI-assisted build failure diagnosis
   - K3s and full EKS cluster testing infrastructure

2. **[Hardening glibc](https://www.chainguard.dev/unchained/this-shit-is-hard-hardening-glibc)**  
   - OpenSSF compiler hardening implementation
   - Upstream GCC and glibc bug fixes contributed
   - Stack protection, control-flow integrity, branch protection
   - ARM64-specific optimizations for Google Axion

3. **[Vulnerability Scanner Integration](https://www.chainguard.dev/unchained/this-shit-is-hard-vulnerability-scanner-integration)**  
   - OSV and Alpine security.json advisory feeds
   - Multi-scanner support (Grype, Trivy, Snyk, Docker Scout)
   - 22,000+ advisories in 6 months
   - Detecting vulnerabilities before scanners

4. **[SLSA L3 and Beyond](https://www.chainguard.dev/unchained/this-shit-is-hard-slsa-l3-and-beyond)**  
   - QEMU microVM isolation (not container "screen doors")
   - Separate build and test VMs
   - Custom Chainguard OS kernel
   - Hardware-backed provenance attestations
   - Nested virtualization architecture

---

## References

**Vulnerability Databases:**
- National Vulnerability Database: https://nvd.nist.gov
- GitHub Advisory Database: https://github.com/advisories
- OSV.dev (Chainguard): https://osv.dev/list?ecosystem=Chainguard

**Supply Chain Security:**
- XZ Utils Backdoor (CVE-2024-3094): CVSS 10.0
- Chainguard Response: https://www.chainguard.dev/unchained/chainguards-response-to-cve-2024-3094
- SLSA Framework: https://slsa.dev
- OpenSSF Compiler Hardening Guide: https://best.openssf.org/Compiler-Hardening-Guides/

**Tools:**
- docker-slim: https://github.com/slimtoolkit/slim
- Grype (Anchore): https://github.com/anchore/grype
- Syft (Anchore): https://github.com/anchore/syft
- melange (Chainguard): https://github.com/chainguard-dev/melange
- apko (Chainguard): https://github.com/chainguard-dev/apko

---

**Author:** Supply Chain Security Research  
**License:** MIT  
**Purpose:** Educational demonstration of container security weaknesses and architectural solutions

**Acknowledgments:**  
- Chainguard Engineering for "This Shit Is Hard" series insights
- Anchore for Grype/Syft open-source scanning tools
- OpenSSF for compiler hardening guidance
- XZ Utils maintainers and Andres Freund for disclosure
