# [1.47.0](https://github.com/darellchua2/opencode-config-template/compare/v1.46.0...v1.47.0) (2026-05-01)


### Features

* **scripts:** add git pull to pm2 restart script ([e7454eb](https://github.com/darellchua2/opencode-config-template/commit/e7454eb484717e8f43c4508af22fe097f90fa756))

# [1.46.0](https://github.com/darellchua2/opencode-config-template/compare/v1.45.0...v1.46.0) (2026-04-28)


### Features

* **scripts:** add PM2 restart script for opencode serve ([#173](https://github.com/darellchua2/opencode-config-template/issues/173)) ([4474384](https://github.com/darellchua2/opencode-config-template/commit/4474384464eda5d98c3ff8de1a0ba9942afa0227))

# [1.45.0](https://github.com/darellchua2/opencode-config-template/compare/v1.44.0...v1.45.0) (2026-04-27)


### Features

* **docker:** add code execution, persistent volumes, folder passthrough, and git support ([#172](https://github.com/darellchua2/opencode-config-template/issues/172)) ([ace6f49](https://github.com/darellchua2/opencode-config-template/commit/ace6f49eaae05effe87ba402452712e084e258cb)), closes [#171](https://github.com/darellchua2/opencode-config-template/issues/171)

# [1.44.0](https://github.com/darellchua2/opencode-config-template/compare/v1.43.0...v1.44.0) (2026-04-22)


### Bug Fixes

* resolve docker-entrypoint.sh auth.json generation error ([62b1a1b](https://github.com/darellchua2/opencode-config-template/commit/62b1a1b823e2f11687e79448c49d58bbaabab23d))
* rewrite docker-entrypoint.sh to build auth.json in single pass ([6476d9b](https://github.com/darellchua2/opencode-config-template/commit/6476d9bb2f764e75f7925feda8b8d27a8da07bff))
* **setup:** correct echo formatting in print_summary skill listings ([75270c5](https://github.com/darellchua2/opencode-config-template/commit/75270c53dde6107b209643e2173f021a4be23bc8))


### Features

* implement dual-mode repo with Docker standalone and user-space deploy ([5724429](https://github.com/darellchua2/opencode-config-template/commit/572442911089c78a49d9fbf48bda22b98b30d8a4)), closes [#166](https://github.com/darellchua2/opencode-config-template/issues/166)

# [1.43.0](https://github.com/darellchua2/opencode-config-template/compare/v1.42.1...v1.43.0) (2026-04-22)


### Features

* **agents:** add built-in subagent task permissions to top 5 agents ([b76be5e](https://github.com/darellchua2/opencode-config-template/commit/b76be5ef17ad317ec7cc9a52a3e27dec20c9ac57)), closes [#167](https://github.com/darellchua2/opencode-config-template/issues/167)

## [1.42.1](https://github.com/darellchua2/opencode-config-template/compare/v1.42.0...v1.42.1) (2026-04-15)


### Bug Fixes

* resolve Python syntax errors in thumbnail.py and base.py validator ([95b42a8](https://github.com/darellchua2/opencode-config-template/commit/95b42a8f90d576eaa72ced6c6efc2f13e6392fa0))
* udpate gitignore ([1766328](https://github.com/darellchua2/opencode-config-template/commit/17663286c7c345689daec953270a4c4c3dc93a0b))

# [1.42.0](https://github.com/darellchua2/opencode-config-template/compare/v1.41.0...v1.42.0) (2026-04-15)


### Bug Fixes

* model override for explore and general ([025bb26](https://github.com/darellchua2/opencode-config-template/commit/025bb26e7b0634f67d181efdc8b64a8b8d9b783d))


### Features

* add plan-execution-skill and update documentation sync ([d5bef75](https://github.com/darellchua2/opencode-config-template/commit/d5bef75fb30d9ef00644a7a67d7c201bc31194a5))

# [1.41.0](https://github.com/darellchua2/opencode-config-template/compare/v1.40.1...v1.41.0) (2026-04-14)


### Features

* add semantic-release-convention governance skill and standardize release pipeline ([#159](https://github.com/darellchua2/opencode-config-template/issues/159)) ([90fd218](https://github.com/darellchua2/opencode-config-template/commit/90fd218932fe4056b3944d11a3c6980a15407d6c)), closes [#158](https://github.com/darellchua2/opencode-config-template/issues/158)

## [1.40.1](https://github.com/darellchua2/opencode-config-template/compare/v1.40.0...v1.40.1) (2026-04-12)


### Bug Fixes

* comprehensive quality review and enhancement of skills and agents ([#154](https://github.com/darellchua2/opencode-config-template/issues/154)) ([ccd2850](https://github.com/darellchua2/opencode-config-template/commit/ccd2850d5073082065a003753055a6d690cb9796))

# [1.40.0](https://github.com/darellchua2/opencode-config-template/compare/v1.39.1...v1.40.0) (2026-04-12)


### Features

* add backup retention cleanup, unit tests, and 4 agent optimization skills ([#150](https://github.com/darellchua2/opencode-config-template/issues/150)) ([#151](https://github.com/darellchua2/opencode-config-template/issues/151)) ([fb153b0](https://github.com/darellchua2/opencode-config-template/commit/fb153b0a8978ab143091d29412c73f9777e0aa08))

## [1.39.1](https://github.com/darellchua2/opencode-config-template/compare/v1.39.0...v1.39.1) (2026-04-10)


### Bug Fixes

* **mcp:** migrate Atlassian MCP endpoint from /v1/sse to /v1/mcp ([23913d5](https://github.com/darellchua2/opencode-config-template/commit/23913d52e468a34c79fb6dbf6a7fb697f1e86a8b)), closes [#148](https://github.com/darellchua2/opencode-config-template/issues/148)

# [1.39.0](https://github.com/darellchua2/opencode-config-template/compare/v1.38.0...v1.39.0) (2026-04-07)


### Features

* **plugins:** add opencode-gemini-auth and fix md-table-formatter scope ([a3698cc](https://github.com/darellchua2/opencode-config-template/commit/a3698ccfcf6c0837351078457d8a3c12e6b4d23e)), closes [#144](https://github.com/darellchua2/opencode-config-template/issues/144)
* **plugins:** remove opencode-claude-auth ([2e42868](https://github.com/darellchua2/opencode-config-template/commit/2e428680959b148fa92640a67ded46053068f56c))

# [1.38.0](https://github.com/darellchua2/opencode-config-template/compare/v1.37.3...v1.38.0) (2026-04-05)


### Features

* **skills:** add changelog-python-cliff skill for Python projects using git-cliff ([529f1ee](https://github.com/darellchua2/opencode-config-template/commit/529f1ee1699b6dece5790b86141d6a9f4ff880ac)), closes [#142](https://github.com/darellchua2/opencode-config-template/issues/142)

## [1.37.3](https://github.com/darellchua2/opencode-config-template/compare/v1.37.2...v1.37.3) (2026-03-30)


### Bug Fixes

* standardize agent models and remove skill-broker-subagent ([51b368e](https://github.com/darellchua2/opencode-config-template/commit/51b368e1f46184d3614ef290f5b5878db593c15e))

## [1.37.2](https://github.com/darellchua2/opencode-config-template/compare/v1.37.1...v1.37.2) (2026-03-30)


### Bug Fixes

* change glm-5 to glm-5.1 ([4472334](https://github.com/darellchua2/opencode-config-template/commit/4472334464967f57ee21ab6f9b8d87202be17c56))

## [1.37.1](https://github.com/darellchua2/opencode-config-template/compare/v1.37.0...v1.37.1) (2026-03-30)


### Bug Fixes

* update the models ([e62277b](https://github.com/darellchua2/opencode-config-template/commit/e62277baf7845413a45e46b01dedaf5761b31b6d))
