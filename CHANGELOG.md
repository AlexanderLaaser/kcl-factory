# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] - 2026-02-03

### Added

- Initial release
- CLI: `--manifest-root`, `--output-kustomize`, `--output-runtime-config`
- Optional: `--namespace`, `--kustomization-name`, `--dry-run`
- Generation of `kustomization.yaml` (ConfigMaps) and `runtime-config.yaml` (DeploymentRuntimeConfig)
- Support for `.k`, `.mod`, `.lock` files; ignore of `test*` folders
- Environment variables: `KUSTOMIZATION_NAME`, `RUNTIME_CONFIG_NAME`, `NAMESPACE`, `MOUNT_BASE`
- Makefile targets: `install`, `uninstall`, `test`, `help`
