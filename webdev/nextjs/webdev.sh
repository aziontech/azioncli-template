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

required_tools() {
    echo git jq node
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

if [ $# -lt 1 ]; then
    help
    exit 1
fi

case "$1" in
    init )
        install_cells_site_template ;;

    build )
        npx next build  || exit $?
        npx next export || exit $?
        cd azion/cells-site-template || exit $?
        npx --yes azion-framework-adapter@0.2.0 build --config ../kv.json \
                             --static-site --assets-dir ../../out || exit $? ;;

    publish )

        cd azion/cells-site-template || exit $?
        # Publish only assets
        npx --yes azion-framework-adapter@0.2.0 publish --config ../kv.json \
                               --only-assets --assets-dir ../../out || exit $? ;;
esac
