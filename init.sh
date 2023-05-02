#!/usr/bin/env bash

npx husky install

npx husky add .husky/pre-commit "bash \"gitops-scripts/pre-commit.sh\""
git add .husky/pre-commit

npx husky add .husky/pre-push "bash \"gitops-scripts/pre-push.sh\""
git add .husky/pre-push

cp gitops-scripts/Makefile .
git add Makefile

touch .gitignore
echo "build" >> .gitignore
echo "cache" >> .gitignore
