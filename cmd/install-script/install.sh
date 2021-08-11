#!/bin/sh
set -e

RESET="\\033[0m"
RED="\\033[31;1m"
GREEN="\\033[32;1m"
YELLOW="\\033[33;1m"
BLUE="\\033[34;1m"
WHITE="\\033[37;1m"

print_unsupported_platform()
{
    >&2 say_red "error: We're sorry, but it looks like minectl is not supported on your platform"
    >&2 say_red "       We support 64-bit versions of Linux and macOS and are interested in supporting"
    >&2 say_red "       more platforms.  Please open an issue at https://github.com/diren/minectl and"
    >&2 say_red "       let us know what platform you're using!"
}

say_green()
{
    [ -z "${SILENT}" ] && printf "%b%s%b\\n" "${GREEN}" "$1" "${RESET}"
    return 0
}

say_red()
{
    printf "%b%s%b\\n" "${RED}" "$1" "${RESET}"
}

say_yellow()
{
    [ -z "${SILENT}" ] && printf "%b%s%b\\n" "${YELLOW}" "$1" "${RESET}"
    return 0
}

say_blue()
{
    [ -z "${SILENT}" ] && printf "%b%s%b\\n" "${BLUE}" "$1" "${RESET}"
    return 0
}

say_white()
{
    [ -z "${SILENT}" ] && printf "%b%s%b\\n" "${WHITE}" "$1" "${RESET}"
    return 0
}

at_exit()
{
    # shellcheck disable=SC2181
    # https://github.com/koalaman/shellcheck/wiki/SC2181
    # Disable because we don't actually know the command we're running
    if [ "$?" -ne 0 ]; then
        >&2 say_red
        >&2 say_red "We're sorry, but it looks like something might have gone wrong during installation."
    fi
}

trap at_exit EXIT

VERSION=""
SILENT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --version)
            if [ "$2" != "latest" ]; then
                VERSION=$2
            fi
            ;;
        --silent)
            SILENT="--silent"
            ;;
     esac
     shift
done


if [ -z "${VERSION}" ]; then
    if ! VERSION=$(curl -sI https://github.com/dirien/minectl/releases/latest | grep -i "location:" | awk -F"/v" '{ printf "%s", $NF }' | tr -d '\r'); then
        >&2 say_red "error: could not determine latest version of Pulumi, try passing --version X.Y.Z to"
        >&2 say_red "       install an explicit version"
        exit 1
    fi
fi

OS=""
case $(uname) in
    "Linux") OS="linux";;
    "Darwin") OS="darwin";;
    *)
        print_unsupported_platform
        exit 1
        ;;
esac

ARCH=""
case $(uname -m) in
    "x86_64") ARCH="amd64";;
    "arm64") ARCH="arm64";;
    "aarch64") ARCH="arm64";;
    *)
        print_unsupported_platform
        exit 1
        ;;
esac
TARBALL_URL="https://github.com/dirien/minectl/releases/download/v${VERSION}/minectl_${VERSION}_${OS}_${ARCH}.tar.gz"

if ! command -v minectl >/dev/null; then
    say_blue "=== Installing minectl ${VERSION} ==="
else
    say_blue "=== Upgrading minectl to ${VERSION} ==="
fi

say_white "+ Downloading ${TARBALL_URL}..."

TARBALL_DEST=$(mktemp -t minectl.tar.gz.XXXXXXXXXX)

# shellcheck disable=SC2046
# https://github.com/koalaman/shellcheck/wiki/SC2046
# Disable to allow the `--silent` option to be omitted.
if curl --fail $(printf %s "${SILENT}") -L -o "${TARBALL_DEST}" "${TARBALL_URL}"; then
    say_white "+ Extracting to $HOME/.minectl/"

    # If `~/.minectl/ exists, clear it out
    if [ -e "${HOME}/.minectl/" ]; then
        rm -rf "${HOME}/.minectl/"
    fi

    mkdir -p "${HOME}/.minectl"

    # Yarn's shell installer does a similar dance of extracting to a temp
    # folder and copying to not depend on additional tar flags
    EXTRACT_DIR=$(mktemp -d minectl.XXXXXXXXXX)
    tar zxf "${TARBALL_DEST}" -C "${EXTRACT_DIR}"

    if [ -d "${EXTRACT_DIR}/minectl" ]; then
        mv "${EXTRACT_DIR}/minectl" "${HOME}/.minectl/"
    else
        cp -r "${EXTRACT_DIR}/minectl" "${HOME}/.minectl/"
    fi

    rm -f "${TARBALL_DEST}"
    rm -rf "${EXTRACT_DIR}"
else
    >&2 say_red "error: failed to download ${TARBALL_URL}"
    exit 1
fi

# Now that we have installed minectl, if it is not already on the path, let's add a line to the
# user's profile to add the folder to the PATH for future sessions.
if ! command -v minectl >/dev/null; then
    # If we can, we'll add a line to the user's .profile adding $HOME/.minectl/bin to the PATH
    SHELL_NAME=$(basename "${SHELL}")
    PROFILE_FILE=""

    case "${SHELL_NAME}" in
        "bash")
            # Terminal.app on macOS prefers .bash_profile to .bashrc, so we prefer that
            # file when trying to put our export into a profile. On *NIX, .bashrc is
            # prefered as it is sourced for new interactive shells.
            if [ "$(uname)" != "Darwin" ]; then
                if [ -e "${HOME}/.bashrc" ]; then
                    PROFILE_FILE="${HOME}/.bashrc"
                elif [ -e "${HOME}/.bash_profile" ]; then
                    PROFILE_FILE="${HOME}/.bash_profile"
                fi
            else
                if [ -e "${HOME}/.bash_profile" ]; then
                    PROFILE_FILE="${HOME}/.bash_profile"
                elif [ -e "${HOME}/.bashrc" ]; then
                    PROFILE_FILE="${HOME}/.bashrc"
                fi
            fi
            ;;
        "zsh")
            if [ -e "${ZDOTDIR:-$HOME}/.zshrc" ]; then
                PROFILE_FILE="${ZDOTDIR:-$HOME}/.zshrc"
            fi
            ;;
    esac

    if [ -n "${PROFILE_FILE}" ]; then
        LINE_TO_ADD="export PATH=\$PATH:\$HOME/.minectl/"
        if ! grep -q "# add minectl to the PATH" "${PROFILE_FILE}"; then
            say_white "+ Adding \$HOME/.minectl/ to \$PATH in ${PROFILE_FILE}"
            printf "\\n# add minectl to the PATH\\n%s\\n" "${LINE_TO_ADD}" >> "${PROFILE_FILE}"
        fi

        EXTRA_INSTALL_STEP="+ Please restart your shell or add $HOME/.minectl/ to your \$PATH"
    else
        EXTRA_INSTALL_STEP="+ Please add $HOME/.minectl/ to your \$PATH"
    fi
elif [ "$(command -v minectl)" != "$HOME/.minectl/minectl" ]; then
    say_yellow
    say_yellow "warning: minectl has been installed to $HOME/.minectl/, but it looks like there's a different copy"
    say_yellow "         on your \$PATH at $(dirname "$(command -v minectl)"). You'll need to explicitly invoke the"
    say_yellow "         version you just installed or modify your \$PATH to prefer this location."
fi

say_blue
say_blue "=== minectl is now installed! ==="
if [ "$EXTRA_INSTALL_STEP" != "" ]; then
    say_white "${EXTRA_INSTALL_STEP}"
fi