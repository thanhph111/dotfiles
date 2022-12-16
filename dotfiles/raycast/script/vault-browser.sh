#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Vault browser
# @raycast.mode silent

# Optional parameters:
# @raycast.icon https://store-images.s-microsoft.com/image/apps.11439.0b8be4c6-88ed-428d-8764-e7c0ace2d4f2.f1cc22bd-40f3-410b-b7e3-cadeafadf38f.662ded9a-39c2-42bb-8a39-eaa009ba83bd
# @raycast.iconDark https://assets-global.website-files.com/615c74524e4640851781a6d5/615cb15955c90dfe6ec6f3d5_Footer_Stack_White.png
# @raycast.argument1 { "type": "text", "placeholder": "Account ID", "percentEncoded": true, "optional": true }
# @raycast.argument2 { "type": "text", "placeholder": "Process ID", "percentEncoded": true, "optional": true }
# @raycast.packageName Tracer

# Documentation:
# @raycast.description Browse Vault resources from IDs
# @raycast.author Thanh Phan
# @raycast.authorURL https://github.com/thanhph111

if [[ -n "$1" ]]; then
    open "https://ops-demo.grasshopper.tmachine.io/customers/account?accountId=$1"
    echo "Opening Account $1"
elif [[ -n "$2" ]]; then
    open "https://ops-demo.grasshopper.tmachine.io/processes/$2"
    echo "Opening Process $2"
fi
