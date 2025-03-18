prepare:
	@chmod -R +x .ci/actions/
	@cp -r .ci/actions/conf/templates/_git/* .git

info:
	@.ci/actions/run.sh get_info
	
	
