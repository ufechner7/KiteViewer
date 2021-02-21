#!/bin/bash
if [ $(uname) != "Linux" ] ; then
    echo "For now, installation as app only working on Linux..."
    exit 1
fi

echo "Install KiteViewer.desktop in the folder ~/.local/share/applications"

# determine the directory of this script
APPDIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# "Copy KiteViewer.desktop.template"
cp ${APPDIR}/data/KiteViewer.desktop.template ~/.local/share/applications

# "Replace @APPDIR@ with APPDIR"
APPDIR2=${APPDIR//\//\\/} # escape all / characters with \
sed -i "s/@APPDIR@/${APPDIR2}/g" ~/.local/share/applications/KiteViewer.desktop.template
mv ~/.local/share/applications/KiteViewer.desktop.template ~/.local/share/applications/KiteViewer.desktop
