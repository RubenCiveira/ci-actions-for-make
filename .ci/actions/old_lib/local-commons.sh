
prepare() {
	chmod -R +x .ci/actions/
	cp -r .ci/actions/conf/templates/_git/* .git
}

pull_from_develop() {
	git checkout $DEVELOP_BRANCH
	git pull
	git checkout $CURRENT_BRANCH
	git fetch
	git merge origin/$DEVELOP_BRANCH
	git push
}

new_branch() {
	git checkout $DEVELOPMENT_BRANCH >/dev/null 2>&1
	git pull >/dev/null 2>&1
	git checkout -b "$1" >/dev/null 2>&1
	git push --set-upstream origin "$1" >/dev/null 2>&1
	
	move_branch "$1"
}