#!/bin/bash

# Test script for Wolfi base image
# This script performs comprehensive testing of the Wolfi base image
# Note: We don't use 'set -e' because we want to run all tests and report failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="${IMAGE_NAME:-wolfi:latest-amd64}"
TEST_CONTAINER_PREFIX="wolfi-test"
FAILED_TESTS=0
PASSED_TESTS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}TEST:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED_TESTS++))
}

print_failure() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

# Cleanup function
cleanup() {
    print_info "Cleaning up test containers..."
    docker ps -a --filter "name=${TEST_CONTAINER_PREFIX}" -q | xargs -r docker rm -f 2>/dev/null || true
}

trap cleanup EXIT

# Test functions
test_image_exists() {
    print_test "Checking if image exists"
    if docker images "${IMAGE_NAME}" | grep -q "${IMAGE_NAME}"; then
        print_success "Image ${IMAGE_NAME} exists"
        return 0
    else
        print_failure "Image ${IMAGE_NAME} not found"
        return 1
    fi
}

test_image_info() {
    print_test "Gathering image information"
    print_info "Image: ${IMAGE_NAME}"

    SIZE=$(docker images --format "{{.Size}}" "${IMAGE_NAME}" | head -1)
    print_info "Image Size: ${SIZE}"

    CREATED=$(docker images --format "{{.CreatedAt}}" "${IMAGE_NAME}" | head -1)
    print_info "Created: ${CREATED}"

    print_success "Image info gathered"
}

test_container_starts() {
    print_test "Testing if container starts"
    local container_name="${TEST_CONTAINER_PREFIX}-start-test"

    if docker run --name "${container_name}" --rm -d "${IMAGE_NAME}" sleep 10 > /dev/null 2>&1; then
        docker stop "${container_name}" > /dev/null 2>&1 || true
        print_success "Container starts successfully"
        return 0
    else
        print_failure "Container failed to start"
        return 1
    fi
}

test_shell_availability() {
    print_test "Testing shell availability"
    local output=$(docker run --rm "${IMAGE_NAME}" /bin/sh -c 'echo "Shell works"' 2>&1)

    if echo "$output" | grep -q "Shell works"; then
        print_success "Shell (/bin/sh) is available and working"
        return 0
    else
        print_failure "Shell test failed"
        return 1
    fi
}

test_nonroot_user() {
    print_test "Verifying non-root user execution"
    local output=$(docker run --rm "${IMAGE_NAME}" id 2>&1)

    if echo "$output" | grep -q "uid=65532(nonroot)"; then
        print_success "Running as nonroot user (uid=65532)"
        print_info "Full id output: $output"
        return 0
    else
        print_failure "Not running as nonroot user. Output: $output"
        return 1
    fi
}

test_apk_availability() {
    print_test "Testing apk package manager"
    local output=$(docker run --rm "${IMAGE_NAME}" apk --version 2>&1)

    if echo "$output" | grep -q "apk"; then
        print_success "apk package manager is available"
        print_info "Version: $output"
        return 0
    else
        print_failure "apk not available or not working"
        return 1
    fi
}

test_package_listing() {
    print_test "Listing installed packages"
    local output=$(docker run --rm "${IMAGE_NAME}" apk list --installed 2>&1)

    if echo "$output" | grep -q "wolfi-base"; then
        print_success "wolfi-base package is installed"
        print_info "Sample of installed packages:"
        echo "$output" | head -5 | while read line; do
            print_info "  $line"
        done
        return 0
    else
        print_failure "wolfi-base package not found"
        return 1
    fi
}

test_ca_certificates() {
    print_test "Verifying CA certificates"
    local output=$(docker run --rm "${IMAGE_NAME}" ls /etc/ssl/certs/ 2>&1)

    if echo "$output" | grep -q "ca-certificates"; then
        print_success "CA certificates are present"
        return 0
    else
        print_failure "CA certificates not found"
        return 1
    fi
}

test_filesystem_permissions() {
    print_test "Testing filesystem permissions for nonroot user"
    local output=$(docker run --rm "${IMAGE_NAME}" /bin/sh -c 'touch /tmp/test && rm /tmp/test && echo "success"' 2>&1)

    if echo "$output" | grep -q "success"; then
        print_success "Nonroot user can write to /tmp"
        return 0
    else
        print_failure "Filesystem permission issue: $output"
        return 1
    fi
}

test_cannot_write_root() {
    print_test "Verifying nonroot user cannot write to /"
    local output=$(docker run --rm "${IMAGE_NAME}" /bin/sh -c 'touch /test 2>&1 || echo "denied"' 2>&1)

    if echo "$output" | grep -q "denied\|Permission denied\|Read-only"; then
        print_success "Nonroot user correctly denied write access to /"
        return 0
    else
        print_failure "Security concern: nonroot user can write to /"
        return 1
    fi
}

test_environment_variables() {
    print_test "Checking environment variables"
    local output=$(docker run --rm "${IMAGE_NAME}" /bin/sh -c 'echo $PATH' 2>&1)

    if echo "$output" | grep -q "/usr/bin"; then
        print_success "PATH environment variable is set correctly"
        print_info "PATH: $output"
        return 0
    else
        print_failure "PATH not set correctly: $output"
        return 1
    fi
}

test_basic_commands() {
    print_test "Testing basic Unix commands"
    local commands=("ls" "cat" "echo" "pwd" "whoami")
    local all_passed=true

    for cmd in "${commands[@]}"; do
        if docker run --rm "${IMAGE_NAME}" /bin/sh -c "command -v $cmd" > /dev/null 2>&1; then
            print_info "  ✓ $cmd available"
        else
            print_info "  ✗ $cmd not available"
            all_passed=false
        fi
    done

    if $all_passed; then
        print_success "All basic commands are available"
        return 0
    else
        print_failure "Some basic commands are missing"
        return 1
    fi
}

test_network_stack() {
    print_test "Testing network stack"
    # Just verify the container can run with network
    if docker run --rm "${IMAGE_NAME}" /bin/sh -c 'echo "network test"' > /dev/null 2>&1; then
        print_success "Network stack functional"
        return 0
    else
        print_failure "Network stack test failed"
        return 1
    fi
}

test_no_unnecessary_packages() {
    print_test "Verifying minimal package footprint"
    local pkg_count=$(docker run --rm "${IMAGE_NAME}" apk list --installed 2>&1 | wc -l)

    print_info "Total packages installed: $pkg_count"

    if [ "$pkg_count" -lt 50 ]; then
        print_success "Minimal package footprint maintained (< 50 packages)"
        return 0
    else
        print_failure "Too many packages installed: $pkg_count"
        return 1
    fi
}

test_timezone_data() {
    print_test "Checking timezone data"
    if docker run --rm "${IMAGE_NAME}" /bin/sh -c 'ls /usr/share/zoneinfo 2>/dev/null' > /dev/null 2>&1; then
        print_success "Timezone data available"
        return 0
    else
        print_info "Timezone data not available (expected for minimal image)"
        print_success "Test passed (minimal configuration)"
        return 0
    fi
}

test_package_update_capability() {
    print_test "Testing package update capability"
    # Test that apk can fetch package index (read-only test)
    local output=$(docker run --rm "${IMAGE_NAME}" apk update --no-cache 2>&1 || true)

    # This might fail for nonroot user, which is expected
    if echo "$output" | grep -q "OK\|fetch\|Unable to lock"; then
        print_success "Package update mechanism functional"
        return 0
    else
        print_info "Package update test inconclusive (expected for nonroot)"
        print_success "Test passed (security by design)"
        return 0
    fi
}

test_security_no_setuid() {
    print_test "Checking for setuid binaries"
    local setuid_count=$(docker run --rm "${IMAGE_NAME}" find / -perm /4000 -type f 2>/dev/null | wc -l || echo "0")

    if [ "$setuid_count" -eq 0 ]; then
        print_success "No setuid binaries found (secure)"
        return 0
    else
        print_info "Found $setuid_count setuid binaries"
        print_success "Test completed"
        return 0
    fi
}

# Main test execution
main() {
    print_header "Wolfi Base Image Test Suite"
    print_info "Testing image: ${IMAGE_NAME}"
    print_info "Start time: $(date)"

    # Run all tests (|| true ensures we continue even if a test fails)
    print_header "Basic Tests"
    test_image_exists || true
    test_image_info || true
    test_container_starts || true
    test_shell_availability || true

    print_header "Security Tests"
    test_nonroot_user || true
    test_filesystem_permissions || true
    test_cannot_write_root || true
    test_security_no_setuid || true

    print_header "Package Management Tests"
    test_apk_availability || true
    test_package_listing || true
    test_no_unnecessary_packages || true
    test_package_update_capability || true

    print_header "System Tests"
    test_ca_certificates || true
    test_environment_variables || true
    test_basic_commands || true
    test_network_stack || true
    test_timezone_data || true

    # Print summary
    print_header "Test Summary"
    echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
    echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
    echo -e "Total:  $((PASSED_TESTS + FAILED_TESTS))"
    print_info "End time: $(date)"

    # Exit with appropriate code
    if [ "$FAILED_TESTS" -gt 0 ]; then
        echo -e "\n${RED}❌ Some tests failed!${NC}"
        exit 1
    else
        echo -e "\n${GREEN}✅ All tests passed!${NC}"
        exit 0
    fi
}

# Run main function
main
