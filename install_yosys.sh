#!/bin/bash

# Yosys installation script for Ubuntu
# Following official instructions from https://github.com/YosysHQ/yosys

set -e  # Exit on error

echo "========================================"
echo "  Yosys Installation Script (Ubuntu)"
echo "========================================"
echo ""

# Install prerequisites
echo "Step 1: Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y gawk git make python3 lld bison clang flex \
    libffi-dev libfl-dev libreadline-dev pkg-config tcl-dev zlib1g-dev \
    curl graphviz xdot

# Install uv (Python package installer used by Yosys)
echo ""
echo "Step 2: Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clone Yosys repository with submodules (skip if already present)
echo ""
echo "Step 3: Cloning Yosys repository..."
cd /tmp
if [ -d "yosys/.git" ]; then
    echo "  Repository already exists – pulling latest changes..."
    cd yosys
    git pull --ff-only
    git submodule update --init --recursive
else
    git clone --recurse-submodules https://github.com/YosysHQ/yosys.git
    cd yosys
fi

# Build Yosys
echo ""
echo "Step 4: Building Yosys..."
echo "This may take several minutes..."
make -j$(nproc)

# Run tests (optional)
echo ""
read -p "Do you want to run tests? (y/n): " run_tests
if [ "$run_tests" = "y" ] || [ "$run_tests" = "Y" ]; then
    echo "Running tests..."
    make test || {
        echo ""
        echo "[WARN] One or more tests failed or returned warnings (exit code: $?)."
        echo "       This is non-fatal – continuing installation..."
        echo ""
    }
fi

# Install Yosys
echo ""
echo "Step 5: Installing Yosys..."
sudo make install

# Verify installation
echo ""
echo "Step 6: Verifying installation..."
yosys -V

echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo "Yosys has been successfully installed."
echo "You can now run 'yosys' from the command line."
echo ""
echo "For documentation, visit:"
echo "  https://yosyshq.readthedocs.io/"
