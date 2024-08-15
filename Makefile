prepare:
	@chmod +x .actions/local/prepare.sh
	@.actions/local/prepare.sh
create-feature-branch-%:
	@.actions/local/create-new-branch.sh "feat/$*"
update-with-develop:
	@.actions/local/update-with-develop.sh

merge-public-release:
	@.actions/flow/merge-public-release.sh
request-public-release:
	@.actions/flow/request-public-release.sh
merge-release-candidate:
	@.actions/flow/merge-release-candidate.sh
request-release-candidate:
	@.actions/flow/request-release-candidate.sh
merge-add-feature:
	@.actions/flow/merge-add-feature.sh
request-add-feature:
	@.actions/flow/request-add-feature.sh

lint:
	@.actions/build/lint.sh
sast:
	@.actions/build/sast.sh
verify:
	@.actions/build/verify.sh
test:
	@.actions/build/test.sh
build:
	@.actions/build/build.sh
report:
	@.actions/build/report.sh
