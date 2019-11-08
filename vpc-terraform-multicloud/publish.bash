#!/bin/bash
#
# NEVER WORK IN THE ROOT folder
#
# Plublish the work/ folder into the root
# 
# symlinks are used in the work folder to allow common files to be interactively edited and kept up to date.
# this is not likely to work for windows.
set -e
rm -rf part*
cd work
for part in part*; do
  mkdir ../$part
  cp -r $part/* ../$part
done
cd ..
find part* -type f -print | xargs chmod 400
