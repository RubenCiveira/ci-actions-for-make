clean:
	@.ci/actions/run.sh mvn_clean

format:
	@.ci/actions/run.sh mvn_format

lint:
	@.ci/actions/run.sh mvn_lint

sast:
	@.ci/actions/run.sh mvn_sast

verify:
	@.ci/actions/run.sh mvn_verify

test:
	@.ci/actions/run.sh mvn_test

report:
	@.ci/actions/run.sh mvn_report

