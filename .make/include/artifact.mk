clean:
	@.make/runnable/run.sh clean

format:
	@.make/runnable/run.sh format

lint:
	@.make/runnable/run.sh lint

sast:
	@.make/runnable/run.sh sast

verify:
	@.make/runnable/run.sh verify

test:
	@.make/runnable/run.sh test

package:
	@.make/runnable/run.sh package

deploy:
	@.make/runnable/run.sh deploy
