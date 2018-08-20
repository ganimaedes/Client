#!/usr/bin/env sh

# Check if OS is Ubuntu or Debian because of package manager restrictions
if [ `ls /etc/*release | grep lsb` ]; then
	if [ ! `uname -rv | grep -o "[UD][be][ub][ni][ta][un]"` ]; then
		echo "The Following script is for Debian/Ubuntu distros only."
		return 1
	fi
fi

# ------------------------------------------------------------------------------
# ------------------------ Install LanguageClient-neovim -----------------------
# Modified version by ganimaedes of the official repo by autozimu (install.sh)

# Removes the official install.sh and replaces it with a modified version if 
# LanguageClient-neovim is already installed via  a plugin manager.
# If not installed, installs LanguageClient-neovim manually.

# Check vim version to know where to install a plugin manager if none exist 
vim_version=`vim --version | grep -o "[0-9]\.[0-9]" | awk 'NR==1'`

install_lang_client() {
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
}

# Install vim-plug by default
install_vim_plug() {
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

vim_version_lang_install() {
    if [ "${vim_version%\.*}" -gt 7 ]; then 
		install_vim_plug "vim_eight"
		install_lang_client "$HOME/.vim/"
	else 
		install_vim_plug "nvim"
		install_lang_client "$HOME/.config/nvim/"
	fi
}

dir_lang=$(find "`pwd`" -type d -wholename "*/LanguageClient-neovim" 2>/dev/null)

if [ -d "$dir_lang" ]; then
	rm -rf "$dir_lang"/install.sh
else
	vim_version_lang_install
	dir_lang=$(find "`pwd`" -type d -wholename "*/LanguageClient-neovim" 2>/dev/null)
	rm -rf "$dir_lang"/install.sh
fi

command -v wget > /dev/null && wget \
https://raw.githubusercontent.com/ganimaedes/Client/master/install.sh -P "$dir_lang"

cd "$dir_lang"

source ./install.sh

# ---------------------- End Install LanguageClient-neovim ---------------------
# ------------------------------------------------------------------------------

# Make a sample project (in c++) and write compile_commands.json, CMakeLists.txt
# and settings.json 
mkdir -p "$HOME/project/build" 
wget https://raw.githubusercontent.com/ganimaedes/cmake/master/CMakeLists.txt -P "$HOME/project/"

mkdir -p "$HOME"/.config/nvim/

echo "{
  \"initializationOptions\": {
    \"cacheDirectory\": \"/tmp/cquery\"
  }
}" > "$HOME"/.config/nvim/settings.json

# Sample c++ files
cat /dev/null > test.h
cat /dev/null > test.cpp

echo "#include <string>" > "$HOME/project/test.h" 
sed -i 's/$/\nint bad;/g' "$HOME/project/test.h"

echo "#include \"test.h\"" > "$HOME/project/test.cpp"
sed -i 's/$/\n#include <iostream>\nint main(){return bad;}/g' "$HOME/project/test.cpp"

# Download a sample .vimrc/init.vim
if [ "${vim_version%\.*}" -lt 1 ]; then
	command -v wget > /dev/null && \
	wget https://raw.githubusercontent.com/ganimaedes/dot_files/master/init.vim -P "$HOME/.config/nvim"
else
	command -v wget > /dev/null && wget \
	https://raw.githubusercontent.com/ganimaedes/dot_files/master/.vimrc -P "$HOME"
fi

cd "$HOME/project/build"; cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=YES ..
ln -s build/compile_commands.json ..

# Make a .cquery file
cd ../..
cquery_folder=`find "/home/$(id -u -n)" -type d -iname "cquery" 2>/dev/null`
if [ -d "$cquery_folder" ]; then
	cd "$cquery_folder"
	clang_exec=`find "$(pwd -P)" -name  "clang++"`
	echo "$clang_exec" > "$HOME/project"/.cquery
fi

# Start the Cquery Server in your $HOME/project directory
cd "$HOME/project"
"$cquery_folder"/build/cquery --log-file /tmp/cquery_log.txt --init='{
  "cacheDirectory": "/tmp/cquery",
  "progressReportFrequencyMs": -1
}'

exit 0
