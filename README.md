# Git Flow + Semantic Versioning + Changelog Automation Template

This project provides a reusable Bash-based script template to manage Git development flows compatible with Git Flow, semantic versioning, and automated changelog generation.

## Requirements
- Git
- Make
- Bash 4+
- Project-specific tools (`maven`, `npm`, `composer`, etc.)

## Structure
- `.make/runnable/`: contains the runnable scripts.
- `run.sh`: entry point that loads project-type-specific logic defined in `properties.env`.

## Configuration
Edit the `properties.env` file with the following minimum values:

```env
MAIN_BRANCH=main
DEVELOP_BRANCH=develop
KIND=maven            # or npm, composer, etc.
AUTO_PUSH=false       # true to automatically push branches
FEATURE_USE_VERSION_PREFIX=true
CHANGELOG_INCLUDE_BODY=true
```

## Available Make Commands

### Start new feature
```bash
make start-feature-feature_name
```
Creates a new `feature/1.2.3-feature_name` branch from `develop`, using the current version prefix if enabled.

### Finish feature
```bash
make finish-feature-feature_name
```
Merges the feature branch into `develop`, deletes local and remote branch (if AUTO_PUSH is true).

### Start release candidate
```bash
make start-rc
```
Detects the increment type from commits (`feat`, `fix`, etc.), generates the next candidate version, creates a `release/x.y.z-rc.n` branch, updates the project version, and generates the changelog.

### Rebuild full changelog
```bash
make generate-changelog
```
Reconstructs the `CHANGELOG.md` file from scratch using all tags reachable from `main`, grouping commits by version.

## Customization
You can extend support for more project types by creating scripts like `.make/kind/maven.sh`, `.make/kind/npm.sh`, etc., and defining functions such as `get_version`, `set_version`, etc.

## License
Internal-use template. Feel free to adapt it to your own projects.