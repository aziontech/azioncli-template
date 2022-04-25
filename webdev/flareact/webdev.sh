#!/bin/sh
#
# Wrapper to Flareact4azion
#
# Requirements
#
# Tools:
# - jq
# - npm
# - git
#
# Enviromental variables:
# - AWS_ACCESS_KEY_ID
# - AWS_USER
# - AWS_SECRET_ACCESS_KEY
# - AZION_SECRET
# - AZION_ID
#
# Note 1: Flareact4azion needs that the configuration file (azion.json) stayed at the project home dir:
#       cp ./azion/flareact4azion.json to <project_dir>/azion.json
#
# Note 2: The azion.json used by flareact4azion isn't the same that is used by the azioncli.

check_flareact4azion() {
    if ! command -v flareact4azion 2>&1 >/dev/null; then
        mkdir -p ./azion
        if ! install_flareact4azion; then
            echo "Failed to install flareact4azion"
            return 1
        fi
    fi
}

install_flareact4azion() {
    echo "Installing flareact4azion:"
    tmpdir=$(mktemp -d)
    git clone git@github.com:aziontech/flareact4azion.git  "$tmpdir"
    cd "$tmpdir"
    npm install
    npm run build
    npm install -g --production
    cd -
    echo "flareact4azion installed"
}

required_envvars() {
    echo AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_USER AZION_SECRET AZION_ID
}

check_envvars() {
    return_value=0
    for var in $(required_envvars); do
        # Use eval since we want to get the value of the variable
        eval "VAR=\$$var"
        if [ -z "$VAR" ]; then
            echo "$var variable not defined"
            return_value=1
        fi
    done
    return $return_value
}

required_tools() {
    echo git npm jq
}

check_tools() {
    return_value=0
    for dependency in $(required_tools); do
        if ! command -v "$dependency" 2>&1 >/dev/null; then
            echo "$dependency not found"
            return_value=1
        fi
    done
    return $return_value
}

update_build_script() {
    tmpfile=$(mktemp)
    if ! jq '.scripts.build=$v' --arg v 'flareact build && ./azion/webdev.sh build' >"$tmpfile" <package.json; then
        echo "Failed to update package.json build script"
        return 1
    fi
    mv $tmpfile package.json
}

update_deploy_script() {
    tmpfile=$(mktemp)
    if ! jq '.scripts.deploy=$v' --arg v 'flareact build && ./azion/webdev.sh publish' >"$tmpfile" <package.json; then
        echo "Failed to update package.json deploy script"
        return 1
    fi
    mv $tmpfile package.json
}

help() {
    cat <<EOF
    Usage: $0 init | build | publish
    Required tools: $(required_tools | sed 's/ /\n  - /g;s/^/\n  - /g')
    Required environment variables: $(required_envvars | sed 's/ /\n  - /g;s/^/\n  - /g')
EOF
}

if [ $# -lt 1 ]; then
    help
    exit 1
fi

case "$1" in
    init )
        check_tools || exit $?
        check_flareact4azion || exit $?

        update_build_script
        update_deploy_script
        cp ./azion/flareact4azion.json azion.json
        mkdir -p public ;;

    build )
        check_tools || exit $?
        check_envvars || exit $?

        flareact4azion build ;;

    publish )
        check_tools || exit $?
        check_envvars || exit $?

        flareact4azion publish ;;
esac
