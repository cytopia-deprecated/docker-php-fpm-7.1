#!/bin/sh -eu


###
### Globals
###
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."


###
### Funcs
###
run() {
	_cmd="${1}"
	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


###
### Checks
###

# Check Dockerfile
if [ ! -f "${CWD}/Dockerfile" ]; then
	echo "Dockerfile not found in: ${CWD}/Dockerfile."
	exit 1
fi

# Get docker Name
if ! grep -q 'image=".*"' "${CWD}/Dockerfile" > /dev/null 2>&1; then
	echo "No 'image' LABEL found"
	exit
fi
NAME="$( grep 'image=".*"' "${CWD}/Dockerfile" | sed 's/^[[:space:]]*//g' | awk -F'"' '{print $2}' )"
DATE="$( date '+%Y-%m-%d' )"


###
### Build
###

# Update build date
run "sed -i'' 's/<small>\*\*Latest\sbuild.*/<small>**Latest build:** ${DATE}<\/small>/g' ${CWD}/README.md"
run "sed -i'' 's/build-date=\".*\"/build-date=\"${DATE}\"/g' ${CWD}/Dockerfile"

# Build Docker
run "docker build -t cytopia/${NAME} ${CWD}"


###
### Retrieve information afterwards and Update README.md
###

docker run -d --rm --name my_tmp_${NAME} -t cytopia/${NAME}
PHP_MODULES="$( docker exec my_tmp_${NAME} php -m )"
PHP_VERSION="$( docker exec my_tmp_${NAME} php -v | sed 's/\s*$//g' )"
BIN_COMP="$(    docker exec my_tmp_${NAME} composer         --version 2>/dev/null | grep -Eo '[0-9.]+' | head -1 )"
BIN_DRUSH="$(   docker exec my_tmp_${NAME} drush            --version 2>/dev/null | grep -Eo '[0-9.]+' | head -1 )"
BIN_DRUSHC="$(  docker exec my_tmp_${NAME} drupal            --version 2>/dev/null | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | grep -oE '[0-9.]+((-rc)*[0-9.]*)*' | head -1 )"
BIN_GIT="$(     docker exec my_tmp_${NAME} git              --version 2>/dev/null | grep -Eo '[0-9.]+' | head -1 )"
BIN_NODE="$(    docker exec my_tmp_${NAME} node             --version 2>/dev/null | grep -Eo '[0-9.]+' | head -1 )"
BIN_NPM="$(     docker exec my_tmp_${NAME} npm              --version 2>/dev/null | grep -Eo '[0-9.]+' | head -1 )"
BIN_MDS="$(     docker exec my_tmp_${NAME} mysqldump-secure --version 2>/dev/null | grep -Eo '[0-9.]+' | head -1 )"
BIN_WPC="$(     docker exec my_tmp_${NAME} wp --allow-root  --version 2>/dev/null | grep -Eo '[0-9.]+' | head -1 )"
BIN_MISC="$(    docker exec my_tmp_${NAME} ls /usr/bin/ | grep -E '(mongo|mysql|psql|pg_)' | sort -u | xargs )"
docker stop "$(docker ps | grep "my_tmp_${NAME}" | awk '{print $1}')"

PHP_MODULES="$( echo "${PHP_MODULES}" | sed '/^\s*$/d' )"       # remove empty lines
PHP_MODULES="$( echo "${PHP_MODULES}" | tr '\n' ',' )"          # newlines to commas
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/],/]\n\n/g' )"   # extra line for [foo]
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/,\[/\n\n\[/g' )" # extra line for [foo]
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/,$//g' )"        # remove trailing comma
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/,/, /g' )"       # Add space to comma
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/]/]**/g' )"      # Markdown bold
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/\[/**\[/g' )"    # Markdown bold

echo "${PHP_MODULES}"

sed -i'' '/##[[:space:]]Modules/q' "${CWD}/README.md"
echo ""                                   >> "${CWD}/README.md"
echo "**[Version]**"                      >> "${CWD}/README.md"
echo ""                                   >> "${CWD}/README.md"
echo "${PHP_VERSION}"                     >> "${CWD}/README.md"
echo ""                                   >> "${CWD}/README.md"
echo "${PHP_MODULES}"                     >> "${CWD}/README.md"
echo ""                                   >> "${CWD}/README.md"
echo "**[Tools]**"                        >> "${CWD}/README.md"
echo ""                                   >> "${CWD}/README.md"
echo "| tool           | version |"       >> "${CWD}/README.md"
echo "|----------------|---------|"       >> "${CWD}/README.md"
echo "| [composer](https://getcomposer.org)    | ${BIN_COMP} |"   >> "${CWD}/README.md"
echo "| [drush](http://www.drush.org)          | ${BIN_DRUSH} |"  >> "${CWD}/README.md"
echo "| [drupal-console](https://drupalconsole.com) | ${BIN_DRUSHC} |" >> "${CWD}/README.md"
echo "| [git](https://git-scm.com)             | ${BIN_GIT} |"    >> "${CWD}/README.md"
echo "| [node](https://nodejs.org)             | ${BIN_NODE} |"   >> "${CWD}/README.md"
echo "| [npm](https://www.npmjs.com)           | ${BIN_NPM} |"    >> "${CWD}/README.md"
echo "| [mysqldump-secure](https://mysqldump-secure.org) | ${BIN_MDS} |"  >> "${CWD}/README.md"
echo "| [wp-cli](https://wp-cli.org)           | ${BIN_WPC} |"    >> "${CWD}/README.md"
echo ""                                   >> "${CWD}/README.md"
echo "**[Misc Tools]**"                   >> "${CWD}/README.md"
echo ""                                   >> "${CWD}/README.md"
echo "${BIN_MISC}"                        >> "${CWD}/README.md"
