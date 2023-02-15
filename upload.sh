#!/usr/bin/env bash

echo "Contanor contents" > ./uploads.txt

CONTAINER=$(safe files put ./uploads.txt | grep -o -P '(?<=").*(?=\?)')

for file in ./*
do
  SAFE_URL=$(safe files add -f "$file" $CONTAINER)
  echo "$SAFE_URL"
  echo "$SAFE_URL" >> ./uploads.txt
sleep 1
done
echo "Upload complete" >> ./uploads.txt
