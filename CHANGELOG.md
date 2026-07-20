# Changelog

All notable changes to this project will be documented in this file.

## [3.0.0](https://github.com/darellchua2/opencode-config-template/compare/v2.3.0...v3.0.0) (2026-07-20)

## [2.3.0](https://github.com/darellchua2/opencode-config-template/compare/v2.2.1...v2.3.0) (2026-07-20)

## [2.2.1](https://github.com/darellchua2/opencode-config-template/compare/v2.2.0...v2.2.1) (2026-07-20)

## [2.2.0](https://github.com/darellchua2/opencode-config-template/compare/v2.1.0...v2.2.0) (2026-07-19)

## [2.1.0](https://github.com/darellchua2/opencode-config-template/compare/v2.0.0...v2.1.0) (2026-07-19)

# [2.0.0](https://github.com/darellchua2/opencode-config-template/compare/v1.77.1...v2.0.0) (2026-07-19)


* feat(models)!: tier-based provider-agnostic model resolution (v2.0) [BT-74] ([f8b4de9](https://github.com/darellchua2/opencode-config-template/commit/f8b4de9940f3a32c065977c6f40faf4cc4ed0e1a))


### Bug Fixes

* **bt-74:** post-review fixes — --json writes, config.json unstale ([b20a2d1](https://github.com/darellchua2/opencode-config-template/commit/b20a2d13995fb5cc5541a3fc74348cfd7bec1dd4))
* **ci:** repoint release workflow lint at canonical opencode.json ([#250](https://github.com/darellchua2/opencode-config-template/issues/250)) ([b1f66bd](https://github.com/darellchua2/opencode-config-template/commit/b1f66bddd090d51d7f43e5d483346eb916e24d03)), closes [#231](https://github.com/darellchua2/opencode-config-template/issues/231) [#248](https://github.com/darellchua2/opencode-config-template/issues/248) [#249](https://github.com/darellchua2/opencode-config-template/issues/249) [#231](https://github.com/darellchua2/opencode-config-template/issues/231)
* **tests:** correct agent-tiers.json structure lookup in assertions [BT-74] ([1dbe59d](https://github.com/darellchua2/opencode-config-template/commit/1dbe59d3389bdddbc0efe3213cee00e485960668))
* **tests:** update autoresearch model assertions for v2.0 tier-based resolution [BT-74] ([ebf3be3](https://github.com/darellchua2/opencode-config-template/commit/ebf3be35dbbd201829991fcaee801c6526cb8070))
* **tui:** exit after interactive flows + show resolution progress [BT-74] ([4d938d2](https://github.com/darellchua2/opencode-config-template/commit/4d938d2d75ea4495b7bf5fd1432a73f8c45304b2))
* update SKILL ([952dc2d](https://github.com/darellchua2/opencode-config-template/commit/952dc2dac72b61ac83c5b3946ea612a4ffb535a8))


### Features

* **models:** per-category provider/model mixing (--mix) [BT-74] ([97eaea3](https://github.com/darellchua2/opencode-config-template/commit/97eaea3ca2a7e78039fcac76509ccb69310c01e1))


### BREAKING CHANGES

* agent .md files no longer carry a hardcoded model; redeploy via
./deploy/setup.sh (or setup.ps1) to resolve models from tiers. Existing v1.x
installs auto-migrate on first run. See MIGRATION.md.

## [1.77.1](https://github.com/darellchua2/opencode-config-template/compare/v1.77.0...v1.77.1) (2026-07-19)


### Bug Fixes

* **deploy:** harden setup.sh/ps1 against paths, errors, silent failures ([f4f9aa4](https://github.com/darellchua2/opencode-config-template/commit/f4f9aa452f154510015708972f5978de22f71845))

# [1.77.0](https://github.com/darellchua2/opencode-config-template/compare/v1.76.0...v1.77.0) (2026-07-19)


### Features

* **skills:** add threejs-nextjs-skill + repair frontmatter spec violations ([#245](https://github.com/darellchua2/opencode-config-template/issues/245)) ([#246](https://github.com/darellchua2/opencode-config-template/issues/246)) ([1e1fef7](https://github.com/darellchua2/opencode-config-template/commit/1e1fef7d5afef0595a0367115d9db70606383ed6))

# [1.76.0](https://github.com/darellchua2/opencode-config-template/compare/v1.75.2...v1.76.0) (2026-07-18)


### Features

* **autoresearch:** add core skill + 3 domain skills + 3 subagents ([#239](https://github.com/darellchua2/opencode-config-template/issues/239)) ([9785820](https://github.com/darellchua2/opencode-config-template/commit/9785820349a915a524815c5d6456719cf944ea79))
* **autoresearch:** retrofit Tier 1 + Tier 2 skills with iteration protocol ([#239](https://github.com/darellchua2/opencode-config-template/issues/239)) ([300b73e](https://github.com/darellchua2/opencode-config-template/commit/300b73e0828426df0823e5e1bd59b114d717bbbc))
* **autoresearch:** retrofit Tier 3 skills with iteration protocol ([#239](https://github.com/darellchua2/opencode-config-template/issues/239)) ([732350b](https://github.com/darellchua2/opencode-config-template/commit/732350b6729fd8202bd140bbbbaaf636b3159ccf))

## [1.75.2](https://github.com/darellchua2/opencode-config-template/compare/v1.75.1...v1.75.2) (2026-07-18)


### Bug Fixes

* update pm2 ([031c3fb](https://github.com/darellchua2/opencode-config-template/commit/031c3fbafdfeb69b4fe07f95fe56805844ba8b3b))

## [1.75.1](https://github.com/darellchua2/opencode-config-template/compare/v1.75.0...v1.75.1) (2026-07-18)


### Bug Fixes

* **deploy:** correct unbalanced parens in setup.ps1 Deploy-Agents function ([#242](https://github.com/darellchua2/opencode-config-template/issues/242)) ([a8e5cd9](https://github.com/darellchua2/opencode-config-template/commit/a8e5cd925ddcfd69f841c5720f9f63eb97d5811c)), closes [#241](https://github.com/darellchua2/opencode-config-template/issues/241)

# [1.75.0](https://github.com/darellchua2/opencode-config-template/compare/v1.74.0...v1.75.0) (2026-07-18)


### Features

* **agents:** add uiux-reviewer-subagent + uiux-review-skill (13-axis design review) ([#237](https://github.com/darellchua2/opencode-config-template/issues/237)) ([83ef55c](https://github.com/darellchua2/opencode-config-template/commit/83ef55c6455649fdfbe2fb4c0fa698eb890d2cc6))

# [1.74.0](https://github.com/darellchua2/opencode-config-template/compare/v1.73.0...v1.74.0) (2026-07-18)


### Features

* **agents:** add java-reviewer-subagent for Java code review ([#236](https://github.com/darellchua2/opencode-config-template/issues/236)) ([78b74d4](https://github.com/darellchua2/opencode-config-template/commit/78b74d48ff2b53cc56b31641b45778d05a9757ff)), closes [#234](https://github.com/darellchua2/opencode-config-template/issues/234)

# [1.73.0](https://github.com/darellchua2/opencode-config-template/compare/v1.72.0...v1.73.0) (2026-06-26)


### Features

* **agents:** add BRD + technical-design document-ladder stage [BT-73] ([#230](https://github.com/darellchua2/opencode-config-template/issues/230)) ([d881883](https://github.com/darellchua2/opencode-config-template/commit/d881883c29bc93609d1b74778a322bde7295bb2a))

# [1.72.0](https://github.com/darellchua2/opencode-config-template/compare/v1.71.0...v1.72.0) (2026-06-26)


### Features

* **agents:** restructure document workflow into software-house ladder [BT-72] ([#229](https://github.com/darellchua2/opencode-config-template/issues/229)) ([9fe2702](https://github.com/darellchua2/opencode-config-template/commit/9fe27020c48b7680b0813731809f3d989e1b01af))

# [1.71.0](https://github.com/darellchua2/opencode-config-template/compare/v1.70.0...v1.71.0) (2026-06-24)


### Features

* **cad:** Port 11 CAD skills from text-to-cad, consolidate 3 specialists into 1 [BT-71] ([#228](https://github.com/darellchua2/opencode-config-template/issues/228)) ([f8a24f7](https://github.com/darellchua2/opencode-config-template/commit/f8a24f7bc3b507aa921ce75a82f0e9bffc98a427))

# [1.70.0](https://github.com/darellchua2/opencode-config-template/compare/v1.69.0...v1.70.0) (2026-06-24)


### Features

* **DA-1421:** add Playwright responsive audit skill + wireframer skill + responsive-audit subagent ([#226](https://github.com/darellchua2/opencode-config-template/issues/226)) ([8dcbc03](https://github.com/darellchua2/opencode-config-template/commit/8dcbc03b587fd9dcafce913baf90fd576418d665)), closes [#1](https://github.com/darellchua2/opencode-config-template/issues/1)

# [1.69.0](https://github.com/darellchua2/opencode-config-template/compare/v1.68.0...v1.69.0) (2026-06-21)


### Features

* **BT-70:** import grill-with-docs skill suite (4 skills) + prd-specialist wiring ([#225](https://github.com/darellchua2/opencode-config-template/issues/225)) ([b0bb5b1](https://github.com/darellchua2/opencode-config-template/commit/b0bb5b1459dea5105111bb2a2b3c6fb1f4c579d8))

# [1.68.0](https://github.com/darellchua2/opencode-config-template/compare/v1.67.0...v1.68.0) (2026-06-21)


### Features

* add prd-creation-skill, prd-specialist-subagent, and image-analyzer shared utility ([#224](https://github.com/darellchua2/opencode-config-template/issues/224)) ([813958d](https://github.com/darellchua2/opencode-config-template/commit/813958d00865edfafb65e68195869d9462281e3b)), closes [#223](https://github.com/darellchua2/opencode-config-template/issues/223) [#223](https://github.com/darellchua2/opencode-config-template/issues/223)

# [1.67.0](https://github.com/darellchua2/opencode-config-template/compare/v1.66.1...v1.67.0) (2026-06-21)


### Features

* add openapi-contract-adherence-skill for API contract evolution ([#221](https://github.com/darellchua2/opencode-config-template/issues/221)) ([#222](https://github.com/darellchua2/opencode-config-template/issues/222)) ([5dee29a](https://github.com/darellchua2/opencode-config-template/commit/5dee29a31bb825b891982245897aa281e5612e7d))

## [1.66.1](https://github.com/darellchua2/opencode-config-template/compare/v1.66.0...v1.66.1) (2026-06-19)


### Bug Fixes

* code review fixes — step numbering, DRY detection, failure handling ([#220](https://github.com/darellchua2/opencode-config-template/issues/220)) ([d8ff686](https://github.com/darellchua2/opencode-config-template/commit/d8ff68692ed3bb9bf0c3850124b4307488a319d7))

# [1.66.0](https://github.com/darellchua2/opencode-config-template/compare/v1.65.1...v1.66.0) (2026-06-19)


### Features

* add git-branch-workflow-setup-skill for dev→uat→main orchestration ([#219](https://github.com/darellchua2/opencode-config-template/issues/219)) ([25c1260](https://github.com/darellchua2/opencode-config-template/commit/25c12608e4fe5721e70b75597d6d798f753f4c44)), closes [#218](https://github.com/darellchua2/opencode-config-template/issues/218) [#218](https://github.com/darellchua2/opencode-config-template/issues/218)

## [1.65.1](https://github.com/darellchua2/opencode-config-template/compare/v1.65.0...v1.65.1) (2026-06-19)


### Bug Fixes

* model ([55451b0](https://github.com/darellchua2/opencode-config-template/commit/55451b0bcdfbaa12cafbdd48b78cb47b75a19d8f))

# [1.65.0](https://github.com/darellchua2/opencode-config-template/compare/v1.64.0...v1.65.0) (2026-06-19)


### Features

* add version-bump-standard-skill and repo-ops-specialist-subagent ([#216](https://github.com/darellchua2/opencode-config-template/issues/216)) ([#217](https://github.com/darellchua2/opencode-config-template/issues/217)) ([baf628b](https://github.com/darellchua2/opencode-config-template/commit/baf628b6b01c83b46e2b4bda2f55815efc0af8af)), closes [fbca04/#d73a4a](https://github.com/darellchua2/opencode-config-template/issues/d73a4a)

# [1.64.0](https://github.com/darellchua2/opencode-config-template/compare/v1.63.0...v1.64.0) (2026-06-19)


### Features

* **agents:** mandatory learning gate + filesystem MCP doc accuracy [[#214](https://github.com/darellchua2/opencode-config-template/issues/214)] ([#215](https://github.com/darellchua2/opencode-config-template/issues/215)) ([9c78c30](https://github.com/darellchua2/opencode-config-template/commit/9c78c303d01fb5ddd2b97be3cf676921930ae51c))

# [1.63.0](https://github.com/darellchua2/opencode-config-template/compare/v1.62.1...v1.63.0) (2026-06-19)


### Features

* atomic plan steps, mandatory consumer traversal, subagent model tiering [[#212](https://github.com/darellchua2/opencode-config-template/issues/212)] ([#213](https://github.com/darellchua2/opencode-config-template/issues/213)) ([67e70a3](https://github.com/darellchua2/opencode-config-template/commit/67e70a33569c35794bd9efb4d80ba7028798362a))

## [1.62.1](https://github.com/darellchua2/opencode-config-template/compare/v1.62.0...v1.62.1) (2026-06-13)


### Bug Fixes

* **agents:** align skill permissions with actual skill names ([973210c](https://github.com/darellchua2/opencode-config-template/commit/973210c2726687250811e474a82a69c79cc1b719))

# [1.62.0](https://github.com/darellchua2/opencode-config-template/compare/v1.61.0...v1.62.0) (2026-06-13)


### Features

* **skills:** curate 48 learnings into 1 new + 18 existing skills [BT-69] ([#211](https://github.com/darellchua2/opencode-config-template/issues/211)) ([98cd42c](https://github.com/darellchua2/opencode-config-template/commit/98cd42c4d7ce972b17b70d01d986d0125347aed6))

# [1.61.0](https://github.com/darellchua2/opencode-config-template/compare/v1.60.0...v1.61.0) (2026-06-03)


### Features

* add opencode-goal-plugin, shell-strategy, type-inject, and unmoji plugins ([#210](https://github.com/darellchua2/opencode-config-template/issues/210)) ([feaf8a9](https://github.com/darellchua2/opencode-config-template/commit/feaf8a90a9b22c186f16443e662b620975d3603c)), closes [#209](https://github.com/darellchua2/opencode-config-template/issues/209)

# [1.60.0](https://github.com/darellchua2/opencode-config-template/compare/v1.59.0...v1.60.0) (2026-05-30)


### Features

* update general agent model to glm-5-turbo ([6a7e6aa](https://github.com/darellchua2/opencode-config-template/commit/6a7e6aacef8776e1eb73787109c9103028cfcaab))

# [1.59.0](https://github.com/darellchua2/opencode-config-template/compare/v1.58.0...v1.59.0) (2026-05-30)


### Features

* update explore agent model to glm-5-turbo ([57d6009](https://github.com/darellchua2/opencode-config-template/commit/57d60096ec6ede77d176571f02b216c975cacd0e))

# [1.58.0](https://github.com/darellchua2/opencode-config-template/compare/v1.57.0...v1.58.0) (2026-05-29)


### Features

* replace opencode-supermemory with opencode-superlocalmemory (100% local) ([#208](https://github.com/darellchua2/opencode-config-template/issues/208)) ([2be10ab](https://github.com/darellchua2/opencode-config-template/commit/2be10ab7429ae8b259c9c11ddaa28f0d3f959214)), closes [#207](https://github.com/darellchua2/opencode-config-template/issues/207)

# [1.57.0](https://github.com/darellchua2/opencode-config-template/compare/v1.56.0...v1.57.0) (2026-05-24)


### Features

* **agents,skills:** add ECC-inspired search-first, context-budget, and language reviewers [BT-55] ([#206](https://github.com/darellchua2/opencode-config-template/issues/206)) ([9360feb](https://github.com/darellchua2/opencode-config-template/commit/9360feb188ba77f677a8b7c01b2081d2a55b1822))

# [1.56.0](https://github.com/darellchua2/opencode-config-template/compare/v1.55.0...v1.56.0) (2026-05-24)


### Features

* **skills:** add documentation-consistency-skill — audit + auto-fix doc drift ([#205](https://github.com/darellchua2/opencode-config-template/issues/205)) ([865b844](https://github.com/darellchua2/opencode-config-template/commit/865b8448a91f73a60ce1fdb74c952f5826a2cd11)), closes [#204](https://github.com/darellchua2/opencode-config-template/issues/204)

# [1.55.0](https://github.com/darellchua2/opencode-config-template/compare/v1.54.0...v1.55.0) (2026-05-24)


### Features

* **agents:** add interactive workflow selection to ticket-creation-subagent ([#203](https://github.com/darellchua2/opencode-config-template/issues/203)) ([4caab48](https://github.com/darellchua2/opencode-config-template/commit/4caab480e3056af25c858d4f9e5397bc864dd654))

# [1.54.0](https://github.com/darellchua2/opencode-config-template/compare/v1.53.0...v1.54.0) (2026-05-24)


### Features

* **agents:** update ticket-creation-subagent with prompt-first workflow and architecture review [#201](https://github.com/darellchua2/opencode-config-template/issues/201) ([#202](https://github.com/darellchua2/opencode-config-template/issues/202)) ([55cce55](https://github.com/darellchua2/opencode-config-template/commit/55cce5527a603981ccc3f166ade9c3e7ae58235a))

# [1.53.0](https://github.com/darellchua2/opencode-config-template/compare/v1.52.0...v1.53.0) (2026-05-24)


### Features

* **skills:** add 11 new skills — security, devops, api, python [IBIS-215] ([#200](https://github.com/darellchua2/opencode-config-template/issues/200)) ([b1bb9b8](https://github.com/darellchua2/opencode-config-template/commit/b1bb9b82550488d93f39125c493627abc6b5e390)), closes [hi#value](https://github.com/hi/issues/value)

# [1.52.0](https://github.com/darellchua2/opencode-config-template/compare/v1.51.0...v1.52.0) (2026-05-24)


### Features

* **skills:** add git-compact-commits-skill [BT-54] ([#199](https://github.com/darellchua2/opencode-config-template/issues/199)) ([759bdd6](https://github.com/darellchua2/opencode-config-template/commit/759bdd6b31defbb6e1c9e8cf664552992a002d08))

# [1.51.0](https://github.com/darellchua2/opencode-config-template/compare/v1.50.3...v1.51.0) (2026-05-24)


### Features

* **mermaid:** MCP server + skill-only architecture, remove 2 diagram agents ([#198](https://github.com/darellchua2/opencode-config-template/issues/198)) ([fce0873](https://github.com/darellchua2/opencode-config-template/commit/fce0873a63959d97436efa03a08a8a670acc1eb8)), closes [#197](https://github.com/darellchua2/opencode-config-template/issues/197)

## [1.50.3](https://github.com/darellchua2/opencode-config-template/compare/v1.50.2...v1.50.3) (2026-05-22)


### Bug Fixes

* **ci:** update release workflow paths for deploy/ restructure ([#196](https://github.com/darellchua2/opencode-config-template/issues/196)) ([93295d3](https://github.com/darellchua2/opencode-config-template/commit/93295d3b044fb7ddf5c7b3ecc0f64662b1bac6c7)), closes [#194](https://github.com/darellchua2/opencode-config-template/issues/194)

## [Unreleased](https://github.com/darellchua2/opencode-config-template/compare/v1.50.2...HEAD)

### Code Refactoring

* **refactor:** move user-space deployment files into deploy/ folder for clearer separation ([#194](https://github.com/darellchua2/opencode-config-template/issues/194))
* **docs(codegraph):** add built-in subagent CodeGraph injection to AGENTS.md files ([#194](https://github.com/darellchua2/opencode-config-template/issues/194))

## [1.50.2](https://github.com/darellchua2/opencode-config-template/compare/v1.50.1...v1.50.2) (2026-05-21)


### Bug Fixes

* **config:** add missing codegraph MCP server to root config.json [[#190](https://github.com/darellchua2/opencode-config-template/issues/190)] ([#191](https://github.com/darellchua2/opencode-config-template/issues/191)) ([015dc14](https://github.com/darellchua2/opencode-config-template/commit/015dc14ccde090d11b3e0de3da370ebcb2a7ea44))

## [1.50.1](https://github.com/darellchua2/opencode-config-template/compare/v1.50.0...v1.50.1) (2026-05-21)


### Bug Fixes

* add strict input validation to y/n prompts in setup scripts (BT-53) ([#189](https://github.com/darellchua2/opencode-config-template/issues/189)) ([196289e](https://github.com/darellchua2/opencode-config-template/commit/196289eb0b776a0d9626aed224e30b1ba2ea1eca))

# [1.50.0](https://github.com/darellchua2/opencode-config-template/compare/v1.49.0...v1.50.0) (2026-05-21)


### Features

* add CodeGraph MCP server, split label skills, and remove code-quality-subagent ([#187](https://github.com/darellchua2/opencode-config-template/issues/187)) ([80d074b](https://github.com/darellchua2/opencode-config-template/commit/80d074b67b8c1cf496cfbb8d7dbe0fdfd74980aa)), closes [#186](https://github.com/darellchua2/opencode-config-template/issues/186) [#188](https://github.com/darellchua2/opencode-config-template/issues/188)

# [1.49.0](https://github.com/darellchua2/opencode-config-template/compare/v1.48.0...v1.49.0) (2026-05-17)


### Features

* add LEARNINGS infrastructure with dual-strategy knowledge persistence ([#184](https://github.com/darellchua2/opencode-config-template/issues/184)) ([c328240](https://github.com/darellchua2/opencode-config-template/commit/c3282402ca9214c7854be5310035e5e61b54a491))

# [1.48.0](https://github.com/darellchua2/opencode-config-template/compare/v1.47.1...v1.48.0) (2026-05-17)


### Features

* add frontend-design-skill and enhance pptx/docx/xlsx with anti-AI-slop aesthetics ([#179](https://github.com/darellchua2/opencode-config-template/issues/179)) ([5e09917](https://github.com/darellchua2/opencode-config-template/commit/5e099174bdd0674c7c1d9f91566ffe9b9b5f8f6f)), closes [#178](https://github.com/darellchua2/opencode-config-template/issues/178)

## [1.47.1](https://github.com/darellchua2/opencode-config-template/compare/v1.47.0...v1.47.1) (2026-05-17)


### Bug Fixes

* **agents:** correct task permission mismatches and document subagent chaining ([#170](https://github.com/darellchua2/opencode-config-template/issues/170)) ([#177](https://github.com/darellchua2/opencode-config-template/issues/177)) ([25a882b](https://github.com/darellchua2/opencode-config-template/commit/25a882b3789813b01bf5f44848dd2bd0abe83a49))

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

* change glm-5 to glm-5.2 ([4472334](https://github.com/darellchua2/opencode-config-template/commit/4472334464967f57ee21ab6f9b8d87202be17c56))

## [1.37.1](https://github.com/darellchua2/opencode-config-template/compare/v1.37.0...v1.37.1) (2026-03-30)


### Bug Fixes

* update the models ([e62277b](https://github.com/darellchua2/opencode-config-template/commit/e62277baf7845413a45e46b01dedaf5761b31b6d))
