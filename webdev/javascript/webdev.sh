#!/bin/sh
#
# Requirements:
#
# Tools:
# - jq
# - npm
# - git

required_tools() {
    echo npm jq git
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

check_requirements() {
    if [ ! -f package.json ]; then
        npm init --yes > /dev/null
    fi

    mkdir -p ${OUTPUT_DIR}
    npm install --save-dev clean-webpack-plugin
}

update_build_script() {
    tmpfile=$(mktemp)
    if ! jq '.scripts.build=$v' --arg v 'azioncli webapp build' >"$tmpfile" <package.json; then
        echo "Failed to update package.json build script"
        return 1
    fi
    mv $tmpfile package.json
}

update_deploy_script() {
    tmpfile=$(mktemp)
    if ! jq '.scripts.deploy=$v' --arg v 'azioncli webapp publish' >"$tmpfile" <package.json; then
        echo "Failed to update package.json deploy script"
        return 1
    fi
    mv $tmpfile package.json
}

help() {
    cat <<EOF
    Usage: $0 init | build
    Required tools: $(required_tools | sed 's/ /\n  - /g;s/^/\n  - /g')
EOF
}

if [ $# -lt 1 ]; then
    help
    exit 1
fi

case "$1" in
    init )
        check_tools || exit $?
        check_requirements
        update_build_script
        update_deploy_script;;

    build )
        if [ ! -f ./args.json ]; then
            echo "{}" > ./args.json
        fi
        npx --package=webpack@5.72.0 --package=webpack-cli@4.9.2 -- webpack --config ./azion/webpack.config.js -o ${OUTPUT_DIR} --mode production || exit $? ;;
esac
