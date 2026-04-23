#!/bin/bash

echo "Quick Network Health Check"
echo "========================="

# Test 1: Internet connectivity
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "✓ Internet: OK"
else
    echo "✗ Internet: FAILED"
fi

# Test 2: DNS resolution
if dig +short google.com >/dev/null 2>&1; then
    echo "✓ DNS: Working"
else
    echo "✗ DNS: Failed"
fi

# Test 3: Local interface
if ip addr show | grep -q "inet "; then
    echo "✓ Network interface: Active"
else
    echo "✗ Network interface: No IP address"
fi
