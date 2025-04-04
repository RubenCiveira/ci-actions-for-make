init:
	@chmod -R +x .make/runnable/run.sh
	@chmod -R +x .make/templates/_git/*
	@cp -r .make/templates/_git/* .git

info:
	@.make/runnable/run.sh get_info
	
