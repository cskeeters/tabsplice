#!/bin/bash

cd "${0%/*}"

rm -rf test

mkdir test
cd test
hg init

echo "Pre content" >> f1
hg ci -Am "Added f1"
echo "Change 1" >> f1
hg ci -Am "Appended to f1"

hg update 0

echo "Change 2" >> f1

# This will cause a merge conflict
hg update

# View the resulting output
echo -e "\nStatus"
hg sta
echo -e "\nDiff"
hg diff
echo -e "\nResolve"
hg resolve --list

# Open a shell to inspect the result
# bash

cd ..
rm -rf test
