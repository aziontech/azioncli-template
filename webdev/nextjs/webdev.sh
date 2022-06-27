#!/bin/sh
#
# Wrapper to azion-framework-adapter
#
# Requirements:
#
# Tools:
# - jq
# - npm
# - git
#
# Environment variables:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY

check_azion_framework_adapter() {
    if ! command -v azion-framework-adapter 2>&1 >/dev/null; then
        mkdir -p ./azion
        if ! install_azion_framework_adapter; then
            echo "Failed to install azion-framework-adapter"
            return 1
        fi
    else
        echo "azion-framework-adapter already installed"
    fi
}

install_azion_framework_adapter() {
    echo "Installing azion-framework-adapter"
    tmpdir=$(mktemp -d)
    git clone https://github.com/aziontech/azion-framework-adapter.git  "$tmpdir"
    cd "$tmpdir"
    if ! (npm install && npm run build && npm install -g --production); then
        echo "Failed to install azion-framework-adapter"
        exit 1;
    fi
    cd -
    echo "Installed azion-framework-adapter successfully"
}

required_envvars() {
    echo AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
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

update_deploy_script() {
    tmpfile=$(mktemp)
    if ! jq '.scripts.deploy=$v' --arg v 'azioncli publish' >"$tmpfile" <package.json; then
        echo "Failed to update package.json deploy script"
        return 1
    fi
    mv $tmpfile package.json
}

install_cells_site_template() {
    if ! (
        cd azion || exit $?
        git clone https://github.com/aziontech/cells-site-template.git
    ); then
        echo "Failed to clone cells-site-template";
        return 1
    fi
    if ! (
        cd azion/cells-site-template || exit $?
        npm ci
    ); then
        echo "Failed to install cells-site-template dependencies";
        return 1
    fi
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
        check_azion_framework_adapter || exit $?
        install_cells_site_template
        update_deploy_script;;

    build )
        check_envvars || exit $?
        check_azion_framework_adapter || exit $?

        cd azion/cells-site-template || exit $?
        azion-framework-adapter build --config ../kv.json \
                             --static-site --assets-dir ../../out;;

    publish )
        check_envvars || exit $?
        check_azion_framework_adapter || exit $?

        cd azion/cells-site-template || exit $?
        # Publish only assets
        azion-framework-adapter publish --config ../kv.json \
                               --only-assets --assets-dir ../../out
        echo "{}" > ./args.json;;
esac
