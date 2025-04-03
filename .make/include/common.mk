init:
	@chmod -R +x .make/runnable/run.sh
	@cp -r .make/templates/_git/* .git

info:
	@.make/runnable/run.sh get_info
	
