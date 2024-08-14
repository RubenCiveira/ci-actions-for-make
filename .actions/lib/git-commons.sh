#!/bin/bash

source .actions/lib/repos-gitlab.sh

format_commit() {
	local commit_line="$1"
	HASH=$(echo "$commit_line" | awk -F'|' '{print $1}' | xargs)
	DATE=$(echo "$commit_line" | awk -F'|' '{print $2}' | xargs)
	AUTHOR=$(echo "$commit_line" | awk -F'|' '{print $3}' | xargs)
	EMAIL=$(echo "$commit_line" | awk -F'|' '{print $4}' | xargs)
	DESCRIPTION=$(echo "$commit_line" | awk -F'|' '{sub(/^[ ]*[a-zA-Z]+:[ ]*/, "", $5); print $5}' | xargs)
	echo " * $DESCRIPTION ($HASH) - ($AUTHOR at $DATE)"
}

git_current_version() {
	local FINAL="$1"
	local COMMIT_LIST=$(get_version_commits "$1")
	local PREV_COMMIT=""
	for COMMIT in $COMMIT_LIST; do
	    if [[ -n "$PREV_COMMIT" ]]; then
	    	:
	    else
	    	local MAYORS=$(mayors_beetween $COMMIT HEAD)
			local MINORS=$(minors_beetween $COMMIT HEAD)
			local PATCHES=$(patches_beetween $COMMIT HEAD)
	    	local RELEASE_INFO=$(release_message $COMMIT)
			DATE=${RELEASE_INFO%% *}
			VERSION=${RELEASE_INFO##* }
			
			VERSION_BASE=$(echo "$VERSION" | cut -d'-' -f1)
			if [[ "$FINAL" == "final" ]]; then
				local CURRENT_VERSION=$(echo $VERSION_BASE)
			else
				local CURRENT_VERSION=$(echo $VERSION)
			fi
	    fi
	    PREV_COMMIT=$COMMIT
	done
	if [[ "$CURRENT_VERSION" == "" ]]; then
		if [[ "$FINAL" == "snapshot" ]]; then
			echo "0.0.1-SNAPSHOT"
		elif [[ "$FINAL" == "release" ]]; then
			echo "0.0.1-RC-1"
		else
			echo "0.0.1"
		fi
	else
		echo $CURRENT_VERSION
	fi
}

git_next_version() {
	local FINAL="$1"
	if [[ "$FINAL" == "snapshot" ]]; then
		local COMMIT_LIST=$(get_version_commits "release")
	else
		local COMMIT_LIST=$(get_version_commits "final")
	fi
	local PREV_COMMIT=""
	for COMMIT in $COMMIT_LIST; do
	    if [[ -n "$PREV_COMMIT" ]]; then
	    	:
	    else
	    	local MAYORS=$(mayors_beetween $COMMIT HEAD)
			local MINORS=$(minors_beetween $COMMIT HEAD)
			local PATCHES=$(patches_beetween $COMMIT HEAD)
	    
	    	local RELEASE_INFO=$(release_message $COMMIT)
			DATE=${RELEASE_INFO%% *}
			VERSION=${RELEASE_INFO##* }
			NEXT_VERSION=$(next_version "$FINAL" "$VERSION" "$MAYORS" "$MINORS" "$PATCHES")
	    fi
	    PREV_COMMIT=$COMMIT
	done
	if [[ "$NEXT_VERSION" == "" ]]; then
		if [[ "$FINAL" == "snapshot" ]]; then
			echo "0.0.1-SNAPSHOT"
		elif [[ "$FINAL" == "release" ]]; then
			echo "0.0.1-RC-1"
		else
			echo "0.0.1"
		fi
	else
		echo $NEXT_VERSION
	fi
}

git_change_log() {
    local FINAL="$1"
	local COMMIT_LIST=$(get_version_commits "$FINAL")
	local PREV_COMMIT=""
	for COMMIT in $COMMIT_LIST; do
	    if [[ -n "$PREV_COMMIT" ]]; then
	    	changelog_beetween "$FINAL" "$COMMIT" "$PREV_COMMIT"
	    else
	    	changelog_beetween "$FINAL" "$COMMIT" "HEAD"
	    fi
	    # Actualizar PREV_COMMIT para el próximo ciclo
	    PREV_COMMIT=$COMMIT
	done
	changelog_beetween "$FINAL" "$PREV_COMMIT"
}

get_version_commits() {
    local FINAL="$1"
    if [[ "$FINAL" == "final" ]]; then
    	# git log  --grep='^chore(release): [0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}$' --pretty=format:"%H | %ad | %an | %ae | %s"  --date=short
		git log  --grep='^chore(release): [0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}$' --pretty=format:'%H'  --date=short
	elif [[ "$FINAL" == "release" ]]; then
		# git log --grep='^chore(release): ' --pretty=format:"%H | %ad | %an | %ae | %s"  --date=short | grep -v SNAPSHOT
		git log --grep='^chore(release): ' --pretty=format:"%H | %ad | %an | %ae | %s"  --date=short | grep -v SNAPSHOT | awk '{print $1}'
	else
		# git log --grep='^chore(release): ' --pretty=format:"%H | %ad | %an | %ae | %s"  --date=short
    	git log --grep='^chore(release): ' --pretty=format:'%H'  --date=short
	fi
}

changelog_beetween() {
	local FINAL=$1
	local MAYORS=$(mayors_beetween $2 $3)
	local MINORS=$(minors_beetween $2 $3)
	local PATCHES=$(patches_beetween $2 $3)
	if [[ "$MAYORS$MINORS$PATCHES" != "" ]]; then
		if [[ "$3" == "" ]]; then
			local RELEASE_INFO=$(release_message $2)
			local DATE=${RELEASE_INFO%% *}
			local VERSION=${RELEASE_INFO##* }
			echo "## $VERSION ($DATE)"
		elif [[ "$3" == "HEAD" ]]; then
			local RELEASE_INFO=$(release_message $2)
			local DATE=${RELEASE_INFO%% *}
			local VERSION=${RELEASE_INFO##* }
			local NEXT_VERSION=$(next_version "$FINAL" "$VERSION" "$MAYORS" "$MINORS" "$PATCHES")
			echo "## Unversion ($NEXT_VERSION)"
		else
			local RELEASE_INFO=$(release_message $3)
			local DATE=${RELEASE_INFO%% *}
			local VERSION=${RELEASE_INFO##* }
			echo "## $VERSION ($DATE)"
		fi
		print_changes "Mayors" "$MAYORS"
		print_changes "Minors" "$MINORS"
		print_changes "Patches" "$PATCHES"
	fi
}

next_version() {
	local FINAL="$1"
	local VERSION="$2"
	local MAYORS="$3"
	local MINORS="$4"
	local PATCHES="$5"
	
	# Separar el descriptor (si lo hay)
	local VERSION_BASE=$(echo "$VERSION" | cut -d'-' -f1)
	
	
	if [[ "$FINAL" == "final" ]]; then
		local SUFFIX=""
	elif [[ "$FINAL" == "release" ]]; then
		local SUFFIX="-RC-1"		
	else
		local SUFFIX="-SNAPSHOT"	
	fi

	# Dividir en MAYOR, MINOR, PATCH
	local MAYOR=$(echo "$VERSION_BASE" | cut -d'.' -f1)
	local MINOR=$(echo "$VERSION_BASE" | cut -d'.' -f2)
	local PATCH=$(echo "$VERSION_BASE" | cut -d'.' -f3)
	local RC_SUFFIX=$(echo "$VERSION" | awk -F'-RC-' '{print $2}')
	
	if [[ "$FINAL" == "release" && "$RC_SUFFIX" != "" ]]; then
    	local NEW_RC_NUMBER=$((RC_SUFFIX + 1))
    	echo "${VERSION_BASE}-RC-${NEW_RC_NUMBER}"
	elif [[ "$MAYORS" != "" ]]; then
		local NEW_MAJOR=$((MAYOR + 1))
		echo "$NEW_MAJOR.0.0$SUFFIX"
	elif [[ "$MINORS" != "" ]]; then
		local NEW_MINOR=$((MINOR + 1))
		echo "$MAYOR.$NEW_MINOR.0$SUFFIX"
	elif [[ "$PATCHES" != "" ]]; then
		local NEW_PATCH=$((PATCH + 1))
		echo "$MAYOR.$MINOR.$NEW_PATCH$SUFFIX"
	else
		# next version is always a patch
		local NEW_PATCH=$((PATCH + 1))
		echo "$MAYOR.$MINOR.$NEW_PATCH$SUFFIX"
	fi
}

release_message() {
	git show -s --format="%ad | %s" --date=short $1 | sed -E 's/^([0-9-]+) \| chore\(release\): ([0-9]+\.[0-9]+\.[0-9]+)$/\1 \2/'
}

commits_beetween() {
	local FROM=$1
	local TO=$2
	if [[ "$TO" == "" ]]; then
		git log --pretty=format:"%h | %ad | %an | %ae | %s" --date=short $FROM
	else
		git log --pretty=format:"%h | %ad | %an | %ae | %s" --date=short $FROM..$TO
	fi
}

patches_beetween() {
	commits_beetween $1 $2 | grep "^.*|.*|.*|.*| fix:" | grep -v "BREAKING CHANGE"
}

minors_beetween() {
	commits_beetween $1 $2 | grep "^.*|.*|.*|.*| feat:" | grep -v "BREAKING CHANGE"
}

mayors_beetween() {
	commits_beetween $1 $2 | grep "BREAKING CHANGE"
}

print_changes() {
	local KIND="$1"
	local COMMITS="$2"
	
	if [[ "$COMMITS" != "" ]]; then
	    echo "  ### $KIND:"
	    while IFS= read -r commit; do
	    	format_commit "$commit"
	    done <<< "$COMMITS"
	fi
}

lookup_repository_api() {
	local SOURCE_BRANCH="$1"
    local TARGET_BRANCH="$2"
    
    local REPO_URL=$(git config --get remote.origin.url)
    local REPO_HOST=$(echo $REPO_URL | sed -e 's,^[^/]*//,,g' -e 's,/.*,,')
    local REPO_PROTOCOL=$(echo $REPO_URL | sed -e 's,:.*,,')
    
	local CREDENTIALS=$(echo "protocol=$REPO_PROTOCOL
host=$REPO_HOST" | git credential fill)
		
	# Extraer username y password/token
		
	local USERNAME=$(read_from_properties "username" "$CREDENTIALS")
	local PASSWORD=$(read_from_properties "password" "$CREDENTIALS")
	
	# local USERNAME=$(echo "$CREDENTIALS" | grep username | cut -d= -f2)
	# local PASSWORD=$(echo "$CREDENTIALS" | grep password | cut -d= -f2)

	if [[ -z "$REPOSITORY_KIND" ]]; then
	    # Si REPOSITORY_KIND no tiene valor, se realiza la comprobación basada en la URL
	    if [[ $REPO_URL == *"github.com"* ]]; then
	        REPOSITORY_KIND="GitHub"
	    elif [[ $REPO_URL == *"gitlab.com"* || $REPO_URL == *"gitlab."* ]]; then
	        REPOSITORY_KIND="GitLab"
	    else
	        REPOSITORY_KIND="Desconocido"
	    fi
	fi
	
	if [[ "$REPOSITORY_KIND" == "GitHub" ]]; then
		echo "private-token=$PASSWORD"
	    echo "project-api-url=https://api.github.com/repos/$USERNAME/$(basename -s .git $REPO_URL)"
	    echo "repository-kind=GitHub"
	elif [[ "$REPOSITORY_KIND" == "GitLab" ]]; then
	    # Para GitLab, se puede usar username y password o un token privado de acceso
	    local PROJECT_PATH=$(echo $REPO_URL | sed -e 's,https://gitlab.com/,,;s,\.git$,,;s,/,%2F,g')

		# Define la URL de la API para obtener la información del proyecto
		local GITLAB_API_URL="https://gitlab.com/api/v4/projects/$PROJECT_PATH"
		
		# Realiza la solicitud a la API para obtener el Project ID
		local PROJECT_ID=$(curl --header "PRIVATE-TOKEN: $PASSWORD" -s "$GITLAB_API_URL" | grep -o '"id":[0-9]*' | head -n 1 | grep -o '[0-9]*')
	    local GITLAB_API_URL="https://$REPO_HOST/api/v4/projects/$PROJECT_ID"
		
		echo "private-token=$PASSWORD"
		echo "project-api-url=$GITLAB_API_URL"
		echo "repository-kind=GitLab"
	else
		echo "Error: El tipo de repositorio es desconocido. Es necesario indicarlo manualmente."
		echo "Merge y push"
	fi
}

#create_pr_from_persistent_branch() {
	# Si estamos creando con una rama persistente, la descripcion la sacamos del changelog
	# aplicado a los cambios entre el head de $3 y el head de $4
#	local MESSAGE=$(changelog_beetween $2 $3)
#	run_create_pr "$1" "$MESSAGE" "$2" "$3" "false" "false"
#}

#
# Create a new PR with changes for a new version to a branch from temporal branch
#
create_upgrade_pr() {
	# Si estamos creando con una rama persistente, la descripcion la sacamos del changelog
	# aplicado a los cambios entre el head de $3 y el head de $4
	local MESSAGE=$(changelog_beetween $2 $3)
	# Escapar barras y comillas
	local ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/\\/\\\\/g; s/"/\\"/g')
	# Escapar saltos de línea usando awk
	ESCAPED_MESSAGE=$(echo "$ESCAPED_MESSAGE" | awk '{printf "%s\\n", $0}')
	# Eliminar la última \n adicional si no se desea
	ESCAPED_MESSAGE=${ESCAPED_MESSAGE%\\n}
	create_pr "$1" "$ESCAPED_MESSAGE" "$2" "$3" "true" "false"
}

#
# Create a new PR with a branch that will be deleted when merged
#
create_merge_pr() {
	# Si estamos creando con una rama persistente, la descripcion la sacamos del changelog
	# aplicado a los cambios entre el head de $3 y el head de $4
	# local MESSAGE=$(changelog_beetween $2 $3)
	create_pr "$1" "$2" "$3" "$4" "true" "false"
}

branch_metadata() {
	local KIND="${CURRENT_BRANCH%%/*}"
	# Eliminar KIND y la primera '/'
	local REST="${CURRENT_BRANCH#*/}"
	# Verificar si hay otro separador '/'
	if [[ "$REST" == */* ]]; then
	    # Si hay otro '/', entonces la segunda parte es ISSUE y el resto es TITLE
	    local ISSUE="${REST%%/*}"
	    local TITLE="${REST#*/}"
	else
	    # Si no hay otro '/', entonces REST es el TITLE y ISSUE está vacío
	    local ISSUE=""
	    local TITLE="$REST"
	fi
	echo "kind=$KIND"
	echo "issue=$ISSUE"
	echo "title=$TITLE"
}

#
# Create a new PR and mark for squash
# It also try to the the issue details from branch name
# to create name and description
#
create_squash_merge() {
	local METADATA=$(branch_metadata)
	
	local KIND=$(read_from_properties "kind" "$METADATA") 
	local TITLE=$(read_from_properties "title" "$METADATA")
	local ISSUE=$(read_from_properties "issue" "$METADATA")

	local MESSAGE="Development"
	if [[ "$ISSUE" != "" ]]; then
		local INFO=$(get_issue "$ISSUE")
		MESSAGE=$(read_from_properties description "$INFO")
		TITLE=$(read_from_properties title "$INFO")
		MESSAGE="${MESSAGE}\n\nRefs: #${ISSUE}"
	fi

	if [[ "$KIND" == feat* ]]; then
		TITLE="feat: ${TITLE}"
	else
		TITLE="fix: ${TITLE}"
	fi
		
	# TODO: still in develop, keep the branck open
	# after verify: we call true and true to delete remote branch after feature add
	create_pr "$TITLE" "$MESSAGE" "$1" "$2" "true" "true"
}

lookup_pr() {
	local BASE="$1"
	local HEAD="$2"

	local INFO=$(lookup_repository_api)
	
	local PRIVATE_TOKEN=$(read_from_properties "private-token" "$INFO")
	local PROJECT_API_URL=$(read_from_properties "project-api-url" "$INFO")
	local REPOSITORY_KIND=$(read_from_properties "repository-kind" "$INFO")
	
	if [[ "$REPOSITORY_KIND" == "GitHub" ]]; then
		:
	elif [[ "$REPOSITORY_KIND" == "GitLab" ]]; then
		run_lookup_pr_gitlab "$BASE" "$HEAD"
	else
		echo "Error: El tipo de repositorio es desconocido. Es necesario indicarlo manualmente."
		echo "Merge y push"
		exit 1
	fi
}

create_pr() {
	local TITLE="$1"
	local BODY="$2"
	local BASE="$3"
	local HEAD="$4"
	local DELETE_SOURCE="$5"
	local SQUASH="$6"

	local INFO=$(lookup_repository_api)
	
	local PRIVATE_TOKEN=$(read_from_properties "private-token" "$INFO")
	local PROJECT_API_URL=$(read_from_properties "project-api-url" "$INFO")
	local REPOSITORY_KIND=$(read_from_properties "repository-kind" "$INFO")
	
	if [[ "$REPOSITORY_KIND" == "GitHub" ]]; then
		:
	elif [[ "$REPOSITORY_KIND" == "GitLab" ]]; then
		run_create_pr_gitlab "$TITLE" "$BODY" "$BASE" "$HEAD" "$DELETE_SOURCE" "$SQUASH"
	else
		echo "Error: El tipo de repositorio es desconocido. Es necesario indicarlo manualmente."
		echo "Merge y push"
		exit 1
	fi
}

merge_pr() {
	local BASE="$1"
	local HEAD="$2"
	
	local INFO=$(lookup_repository_api)
	
	local PRIVATE_TOKEN=$(read_from_properties "private-token" "$INFO")
	local PROJECT_API_URL=$(read_from_properties "project-api-url" "$INFO")
	local REPOSITORY_KIND=$(read_from_properties "repository-kind" "$INFO")
	
	if [[ "$REPOSITORY_KIND" == "GitHub" ]]; then
		:
	elif [[ "$REPOSITORY_KIND" == "GitLab" ]]; then
	    run_merge_pr_gitlab "$BASE" "$HEAD"
	    local prev_branch=$(git rev-parse --abbrev-ref HEAD  >/dev/null 2>&1)
	    if [[ "$BASE" != "$prev_branch" ]]; then
	    	git checkout $BASE  >/dev/null 2>&1
	    	git pull >/dev/null 2>&1
	    else
	    	git pull >/dev/null 2>&1
	    fi
	else
		echo "Error: El tipo de repositorio es desconocido. Es necesario indicarlo manualmente."
		echo "Merge y push"
		exit 1
	fi
}

check_sync_branchs() {
	printf -- "- Checking sync with $(IFS=,; echo "$*"):"
	local first=1
	
    for arg in "$@"; do
		local result=$(check_sync_state_branch "$arg")
		if [[ "$local" != "" ]]; then
			printf "\n"
			echo "$local"
			exit 1
		fi
    	if [ $first -eq 1 ]; then
            first=0  # Marcar que la primera iteración ya pasó
        else
            printf ","  # Agregar una coma antes de los siguientes argumentos
        fi
    	printf " $arg [ok]"
	done
	printf "\n"
}

#
# check if the branch is sync, and exit if there is not sync
# private
#
check_sync_branch() {
	local result=$(check_sync_branch "$1")
	echo "$local"
	if [[ "$local" != "" ]]; then
		exit 1
	fi
}

#
# check if the branch is sync, and print a warn
# private
#
check_sync_state_branch() {
	if [ "$CURRENT_BRANCH" != "$1" ]; then
		git checkout $1 >/dev/null 2>&1
	fi

	# Verificar si hay cambios pendientes
	if [ -n "$(git status --porcelain)" ]; then
	    echo "Error: Hay cambios pendientes de $1 en el repositorio. Por favor, confirma o descarta los cambios antes de continuar."
	else
		# Actualizar la información del remoto
		git fetch >/dev/null 2>&1
		
		# Verificar si la rama local está sincronizada con la remota
		LOCAL_COMMIT=$(git rev-parse @)
		REMOTE_COMMIT=$(git rev-parse @{u})
		BASE_COMMIT=$(git merge-base @ @{u})
		
		if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
		    :
		elif [ "$LOCAL_COMMIT" = "$BASE_COMMIT" ]; then
		    echo "Error: Tu rama $1 local está desactualizada. Debes hacer un 'git pull' para descargar los últimos cambios."
		    echo "git fetch && git checkout \"$1\" && git pull && git checkout \"$CURRENT_BRANCH\""
		elif [ "$REMOTE_COMMIT" = "$BASE_COMMIT" ]; then
		    echo "Error: Tienes commits locales en $1 que aún no has subido al remoto. Debes hacer un 'git push'."
		    echo "git checkout \"$1\" && git push && git checkout \"$CURRENT_BRANCH\""
		else
		    echo "Error: Para $1, la rama local y remota han divergido. Debes resolver los conflictos manualmente."
		    echo "git fetch && git checkout \"$1\" && git pull && git checkout \"$CURRENT_BRANCH\""
		fi
	fi
}

check_branch_ahead_of() {
	local main_branch="$1"
	local release_branch="$2"

	local num=$(git rev-list --count $release_branch..$main_branch)
	
	if [[ "$num" == "0" ]]; then
		echo "ok"
	else
		# Hay diferencias de branches.
		echo "DIFERENCIAS ENTRE $release_branch y $main_branch"
		# git checkout $rele
		
		echo "ko - $num commits ahead"
	fi
}

check_in_branch() {
	# Verificar si hay cambios pendientes
	if [ -n "$(git status --porcelain)" ]; then
	    echo "Error: Hay cambios pendientes en el repositorio. Por favor, confirma o descarta los cambios antes de continuar."
	    exit 1
	fi

	local CURRENT_BRANCH=$(git branch --show-current)
	if [ "$CURRENT_BRANCH" != "$1" ]; then
        echo "Error: Es necesario estar en la rama $1 para ejecutar, y estamos en la rama $CURRENT_BRANCH."
	fi
}
