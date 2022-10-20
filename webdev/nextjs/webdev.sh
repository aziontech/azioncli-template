#!/bin/sh
#
# Wrapper to azion-framework-adapter
#
# Requirements:
#
# Tools:
# - node (16.x or higher)
# - jq
# - git
#
# Environment variables:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY

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
    echo git jq node
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

install_cells_site_template() {
    if ! (
        cd azion || exit $?
        rm -rf cells-site-template
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

help_nextjs() {
    cat <<EOF

    [ General Instructions ]
    - Requirements:
        - Tools: $(required_tools)
        - AWS Credentials (./azion/webdev.env): $(required_envvars) 
        - Customize the path to static content - AWS S3 storage (.azion/kv.json)
    
    [ Usage ]
    - Build Command: npm run build
    - Publish Command: npm run deploy

    [ Notes ]
        - Node 16x or higher
EOF
}

if [ $# -lt 1 ]; then
    help
    exit 1
fi

case "$1" in
    init )
        check_tools || exit $?
        install_cells_site_template
        update_build_script
        update_deploy_script
        help_nextjs;;

    build )
        check_envvars || exit $?

        if [ ! -f ./azion/args.json ]; then
            echo "{}" > ./azion/args.json
        fi

        npx next build  || exit $?
        npx next export || exit $?
        cd azion/cells-site-template || exit $?
        npx --yes azion-framework-adapter@0.2.0 build --config ../kv.json \
                             --static-site --assets-dir ../../out || exit $? ;;

    publish )
        check_envvars || exit $?

        cd azion/cells-site-template || exit $?
        # Publish only assets
        npx --yes azion-framework-adapter@0.2.0 publish --config ../kv.json \
                               --only-assets --assets-dir ../../out || exit $? ;;
esac
