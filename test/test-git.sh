#!/bin/bash -x

cd "${0%/*}"

rm -rf test

mkdir test
cd test
git init

echo "Pre content" >> f1
git add f1
git commit -m "Added f1"
echo "Change 1" >> f1
git commit -am "Appended to f1"

git checkout master^

echo "Change 2" >> f1

git stash
git checkout master
git stash pop

git mergetool

# View the resulting output
echo -e "\nStatus"
git status
echo -e "\nDiff"
git diff --staged

# Open a shell to inspect the result
#bash

cd ..
rm -rf test

