git-feature-%:
	@.ci/actions/run.sh create_new_branch "feat/$*"

sync-dev:
	@.ci/actions/run.sh merge_from_develop

pr-to-dev:
	@.ci/actions/run.sh create_pr_to_develop

merge-to-dev:
	@.ci/actions/run.sh merge_pr_in_develop
	
pr-to-rc:
	@.ci/actions/run.sh create_pr_to_rc

merge-to-rc:
	@.ci/actions/run.sh merge_pr_in_rc

pr-to-main:
	@.ci/actions/run.sh create_pr_to_main

merge-to-main:
	@.ci/actions/run.sh merge_pr_in_main
	
	
version:
	@.ci/actions/run.sh version
