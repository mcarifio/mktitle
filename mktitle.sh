#!/usr/bin/env bash

# usage: mktitle.sh ${extension_path} # example mktitle.sh ~/snap/chromium_edge/common/chromium/Default/Extensions

set -euo pipefail
IFS=$'\n'

# Check that all supporting scripts are installed.
for _c in jq xz; do type ${_c} &> /dev/null ; done || { >&2 echo "${_c} not on path."; exit 1; }

_me=$(realpath -s ${BASH_SOURCE[0]})
_extension=$(basename ${_me})
_here=$(dirname ${_me})

_extensions=${1:-$(dirname ${_here})/..}
_extensions=$(realpath -s "${_extensions}")
mkdir -p "${_extensions}" &> /dev/null
_extension_root=$(realpath -s "${_extensions}"/${_extension%*.sh})
_profile_root=$(realpath -s $(dirname "${_extensions}"/../..))
_profile=$(basename ${_profile_root})
_top=$(dirname ${_profile_root})

_name=${1:-$(jq -er .profile.info_cache.${_profile}.name ${_top}/'Local State')}
_when=$(date -Iminutes)




# Generate js code. You can handcraft it afterwards as well.
_js=${_extension_root}/${_extension}.js
xz ${_js} &> /dev/null || true
cat <<EOF > ${_js} && >&2 echo "generated js ${_js} # edit to review"
// ${_me} ${_when}
let suffix = ' /* ${_profile} ${_name} */';
document.title += suffix; 
// console.log('${_js} adds: ' + suffix); // uncomment for debugging
EOF



# Generate the associated manifest.
_manifest=${_extension_root}/manifest.json
xz ${_manifest} &> /dev/null || true
cat <<EOF > ${_manifest} && >&2 echo "generated manifest ${_manifest}"
{
    "manifest_version": 2,
    "name": "${_here}",
    "version": "0.0.1",
    "description": "Suffix title with additional information (generated ${_when}).",
    "content_scripts": [
        {
            "run_at": "document_idle",
            "matches": [
                "<all_urls>"
            ],
            "js": ["$(realpath -s --relative-to ${_extension_root} ${_js})"]
        }
    ]
}
EOF

# Cleanup
mkdir -p ${_extension_root}/.backup &>/dev/null && mv --backup *.xz ${_extension_root}/.backup &> /dev/null

_content_script=$(jq -er .content_scripts[0].js[0] ${_manifest})
[[ -f ${_content_script} ]] || { >&2 echo "manifest references non-existant content_script ${_content_script}"; exit 1; }
