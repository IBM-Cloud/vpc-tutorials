#!/bin/bash
#
# During development work in the work/ folder.
#
# Plublish the work/ folder into the root
# 
# symlinks are used in the work folder to allow common files to be interactively edited and kept up to date.
# this is not likely to work for windows.
set -e

# make the files writeable and delete
find part* -print | xargs chmod 775
rm -rf part*

cd work
for part in part*; do
  mkdir ../$part
  cp -r $part/* ../$part
  rm -rf ../$part/terraform* ../$part/.terraform
done
cd ..

# delete lines like ibmcloud_api_key these are not needed
for f in part*/*.tf; do
  sed -i '' '/DELETE_ON_PUBLISH/d' $f 
done

# make it read only to help me remember not to edit this stuff
find part* -type f -print | xargs chmod 440

# multicloud is the place to start
rm -rf multicloud
cp -r part1a multicloud
find multicloud -type d -print | xargs chmod 775
