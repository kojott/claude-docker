# Changelog

## [1.2.0](https://github.com/kojott/claude-docker/compare/v1.1.0...v1.2.0) (2026-03-07)


### Features

* add cross-platform clipboard support via OSC 52 ([47a408d](https://github.com/kojott/claude-docker/commit/47a408d13a5a77d761b2f159d2340506b582d6b4))
* add runtime volume persistence and bashrc wizard fallback ([3d7099c](https://github.com/kojott/claude-docker/commit/3d7099cf902813ba7f003539fbaffd777276a89a))

## [1.1.0](https://github.com/kojott/claude-docker/compare/v1.0.2...v1.1.0) (2026-03-07)


### Features

* add security-guidance plugin and PostToolUse auto-save hook ([1a4c12a](https://github.com/kojott/claude-docker/commit/1a4c12ae3c93bc8ad8102f12aad4bc4761019f2b))

## [1.0.2](https://github.com/kojott/claude-docker/compare/v1.0.1...v1.0.2) (2026-03-04)


### Bug Fixes

* add OCI source label for automatic ghcr.io repository linking ([4fd66d8](https://github.com/kojott/claude-docker/commit/4fd66d8850e32d89600def6e4b50d0b0ebc3c327))

## [1.0.1](https://github.com/kojott/claude-docker/compare/v1.0.0...v1.0.1) (2026-03-03)


### Bug Fixes

* **ci:** address code review findings ([be843b9](https://github.com/kojott/claude-docker/commit/be843b9d6560e9f6a66ad3489fe0640487ea7ecb))
* export OAuth token as env var to bypass login screen on restart ([89e8cb1](https://github.com/kojott/claude-docker/commit/89e8cb16d27a3833a372f4252f6648579dc6b429))
* persist Claude Code credentials across container rebuilds ([0f8b5b6](https://github.com/kojott/claude-docker/commit/0f8b5b639aa7714f8a4293512f382c5df3c9193e))
* prevent re-onboarding after Claude Code updates ([763036f](https://github.com/kojott/claude-docker/commit/763036f0b7f89083d0a396807f53b8819e384d00))
