start-feature-%:
	@.make/runnable/run.sh start_feature "$*"

finish-feature-%:
	@.make/runnable/run.sh finish_feature "$*"

start-rc:
	@.make/runnable/run.sh start_release_candidate

generate-changelog:
	@.make/runnable/run.sh rebuild_tagged_changelog
