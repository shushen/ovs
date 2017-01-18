#!/bin/bash
set -ev
pip install --user six

brew uninstall libtool || true
brew install libtool || true
