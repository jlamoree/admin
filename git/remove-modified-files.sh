#/bin/bash

T="/tmp/$$.tmp"

if [ ! -d .git ]; then
  echo "Error: Current directory is not in the Git repo root."
  exit 1
fi

git status | awk '/(modified: +)(.*)/ {print $3}' > $T
for F in `cat $T`; do
  echo "Deleting $F"
  rm "$F"
done

rm $T
