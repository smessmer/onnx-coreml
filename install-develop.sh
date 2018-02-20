#!/bin/bash

set -ex

# realpath might not be available on MacOS
script_path=$(python -c "import os; import sys; print(os.path.realpath(sys.argv[1]))" "${BASH_SOURCE[0]}")
top_dir=$(dirname "$script_path")
REPOS_DIR="$top_dir/third_party"
BUILD_DIR="$top_dir/build"

_check_submodule_present() {
    if [ ! -f "$REPOS_DIR/$@/setup.py" ]; then
       echo Didn\'t find $@ submodule. Please run: git submodule update --recursive --init
        exit 1
    fi
}

_check_submodule_present caffe2
_check_submodule_present onnx

if ! echo "$PATH" | grep ccache; then
    echo Warning: CCache is not in the path. Incremental builds will be slow.
    read -p "Press enter to continue"
fi


mkdir -p "$BUILD_DIR"

_pip_install() {
    if [[ -n "$CI" ]]; then
        ccache -z
    fi
    if [[ -n "$CI" ]]; then
        time pip install "$@"
    else
        pip install "$@"
    fi
    if [[ -n "$CI" ]]; then
        ccache -s
    fi
}

# Install caffe2
_pip_install -b "$BUILD_DIR/caffe2" "file://$REPOS_DIR/caffe2#egg=caffe2"

# Install onnx
_pip_install -e "$REPOS_DIR/onnx"

# Install onnx-coreml
_pip_install -e .
