#!/usr/bin/env bash
# NavTA dev helper - run ON the Znuny host (test instance), from a git checkout.
#
#   sudo ./dev/navta.sh sync      copy package files into $ZNUNY_HOME + rebuild config + clear cache (fast dev loop)
#   sudo ./dev/navta.sh remove    remove files previously synced (based on .sopm filelist)
#   sudo ./dev/navta.sh build     build NavTA-<version>.opm into ./dist
#   sudo ./dev/navta.sh install   build + install/upgrade the .opm via package manager (production-like test)
#   sudo ./dev/navta.sh uninstall uninstall the package via package manager
#
# Env: ZNUNY_HOME (default /opt/znuny), ZNUNY_USER (default znuny), WEB_GROUP (default www-data)
set -euo pipefail

ZNUNY_HOME="${ZNUNY_HOME:-/opt/znuny}"
ZNUNY_USER="${ZNUNY_USER:-znuny}"
WEB_GROUP="${WEB_GROUP:-www-data}"
PKG_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOPM="$(ls "$PKG_DIR"/*.sopm | head -1)"
PKG_NAME="$(basename "$SOPM" .sopm)"
CONSOLE="$ZNUNY_HOME/bin/znuny.Console.pl"

as_znuny() { sudo -u "$ZNUNY_USER" "$@"; }
files() { grep -oP '<File[^>]*Location="\K[^"]+' "$SOPM"; }

rebuild() {
    as_znuny "$CONSOLE" Maint::Config::Rebuild --cleanup
    as_znuny "$CONSOLE" Maint::Cache::Delete
    # mod_perl caches compiled modules - reload apache so .pm changes are picked up
    if command -v systemctl >/dev/null && systemctl is-active --quiet apache2 2>/dev/null; then
        systemctl reload apache2
    else
        service apache2 reload >/dev/null 2>&1 || true
    fi
}

case "${1:-}" in
    sync)
        for F in $(files); do
            install -D -m 660 -o "$ZNUNY_USER" -g "$WEB_GROUP" "$PKG_DIR/$F" "$ZNUNY_HOME/$F"
            echo "synced $F"
        done
        rebuild
        ;;
    remove)
        for F in $(files); do rm -fv "$ZNUNY_HOME/$F"; done
        rebuild
        ;;
    build)
        mkdir -p "$PKG_DIR/dist"; chmod 777 "$PKG_DIR/dist"
        as_znuny "$CONSOLE" Dev::Package::Build --module-directory "$PKG_DIR" "$SOPM" "$PKG_DIR/dist"
        ls -1 "$PKG_DIR"/dist/*.opm
        ;;
    install)
        "$0" build
        VERSION="$(grep -oP '<Version>\K[^<]+' "$SOPM" | head -1)"
        OPM="$PKG_DIR/dist/$PKG_NAME-$VERSION.opm"
        if as_znuny "$CONSOLE" Admin::Package::List | grep -qE "Name: +$PKG_NAME\$"; then
            as_znuny "$CONSOLE" Admin::Package::Upgrade "$OPM" || as_znuny "$CONSOLE" Admin::Package::Reinstall "$OPM"
        else
            as_znuny "$CONSOLE" Admin::Package::Install "$OPM"
        fi
        rebuild
        ;;
    uninstall)
        as_znuny "$CONSOLE" Admin::Package::Uninstall "$PKG_NAME"
        rebuild
        ;;
    *)
        sed -n '2,12p' "$0"; exit 1 ;;
esac
