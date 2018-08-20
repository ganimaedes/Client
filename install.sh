#!/usr/bin/env sh

# --------------------------- Install languageclient ---------------------------
# --------------------------------- by autozimu --------------------------------
# https://github.com/autozimu/LanguageClient-neovim/blob/next/install.sh
# This script is a modified version by ganimaedes of the link above by autozimu
# Works only if vim-plug by junegunn is your plugin manager in vim8/neovim

version=0.1.110
name=languageclient
vim_version=`vim --version | grep -o "[0-9]\.[0-9]" | awk 'NR==1'`

try_curl() {
    command -v curl > /dev/null && curl --fail --location "${1}" --output ${2}/bin/$name
}

try_wget() {
    command -v wget > /dev/null && wget --output-document=${2}/bin/$name "${1}"
}

try_build() {
    if command -v cargo > /dev/null; then
        echo "Trying build locally ..."
        make release
    else
        return 1
    fi
}

get_executable() {
    if (try_curl "${2}" "${1}" || try_wget "${2}" "${1}"); then
        chmod +x "${1}"/bin/$name
        return
    else
        try_build || echo "Prebuilt binary might not be ready yet. Please check minutes later."
    fi
}

folder_to_search() {
	cd "${1}"
	folder_language=$(find "`pwd`" -type d -name "LanguageClient-neovim" 2>/dev/null)
	if [ ! -d "$folder_language" ]; then 
		if [ "${1}" = "*\.vim" ]; then
			cd $HOME/.vim/plugged/
		elif [ "${1}" = "*nvim*" ]; then
			cd $HOME/.local/share/nvim/plugged/
		fi
		git clone https://github.com/autozimu/LanguageClient-neovim/ --recursive
	fi
	get_executable "$folder_language" "${2}"
}

dir_vim() {
	if [ "${1}" = "vim_eight" ]; then
		if [ ! -d "$HOME/.vim/autoload" ]; then
			mkdir -p "$HOME/.vim/autoload"
		fi
		
		if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
			command -v wget > /dev/null && wget \
			https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
			-P "$HOME/.vim/autoload/"
		fi
	elif [ "${1}" = "nvim" ]; then
		if [ ! -d "$HOME/.config/nvim" ]; then 
			mkdir -p "$HOME/.config/nvim"
		fi
		mkdir -p "$HOME/.local/share/nvim/site/autoload"
		
		if [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]; then
			command -v wget > /dev/null && wget \
			https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
			-P "$HOME/.local/share/nvim/site/autoload/"
		fi
	fi
}

download() {
    echo "Downloading bin/${name}..."
   	url=https://github.com/autozimu/LanguageClient-neovim/releases/download/$version/${1}
    if [ "${vim_version%\.*}" -gt 7 ]; then 
		dir_vim "vim_eight"
		folder_to_search "$HOME/.vim/" "$url"
	elif [ "${vim_version%\.*}" -gt 1 ] && [ "${vim_version%\.*}" -lt 8 ]; then
		echo "
			  Please install Vim 8.
			  
		     "
		return 1
	else 
		dir_vim "nvim"
		folder_to_search "$HOME/.config/nvim/" "$url"
	fi
}

dir_lang=$(find "`pwd`" -type d -wholename "*/LanguageClient-neovim/bin" 2>/dev/null)
[ -d "$dir_lang" ] && rm -f "$dirLang"/languageclient

arch=$(uname -sm)
case "${arch}" in
    "Linux x86_64") download $name-$version-x86_64-unknown-linux-musl ;;
    "Linux i686") download $name-$version-i686-unknown-linux-musl ;;
    "Darwin x86_64") download $name-$version-x86_64-apple-darwin ;;
    "FreeBSD amd64") download $name-$version-x86_64-unknown-freebsd ;;
    *) echo "No pre-built binary available for ${arch}."; try_build ;;
esac
