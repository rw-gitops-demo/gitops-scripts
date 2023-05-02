# GitOps Scripts

This repository provides a set of scripts for validating and diffing the rendered manifests of a GitOps repo built with Kustomize.
The repo is intended to be added as a submodule, and provides an init script to install Husky pre-commit and pre-push hooks.

Note that the scripts assume that the target manifests are held in `envs` folders throughout the GitOps repo.
The scripts also rely on [Kubeconform](https://github.com/yannh/kubeconform), which can be installed via Homebrew:
```shell
brew install kuebconform
```

## Installation

Install the repo as a submodule and initialise it with:
```shell
git submodule add https://github.com/rw-gitops-demo/gitops-scripts.git
./gitops-scripts/init.sh
```
This will install Husky pre-commit and pre-push hooks and create a Makefile to run the commands.

Note that you will need to use the `--no-verify` flag to push the commit that installs the submodule, i.e.
```shell
git push --no-verify
```
The pre-push hook will attempt to switch to `origin/main` to diff the changes against the current state, but this will fail because `origin/main` does not yet have the submodule.

## Working with the installed submodule

With the submodule installed in your repo, the default `git clone` command will not clone the submodule files.
Instead, your team members should use the `--recurse-submodules` flag, e.g.
```shell
git clone --recurse-submodules git@github.com:rw-gitops-demo/app-manifests.git
```
and then install the hooks with
```shell
npx husky install
```

To update the submodule files, your uses should use:
```shell
git submodule update --remote
```
We suggest you add these instructions to your project's README.
