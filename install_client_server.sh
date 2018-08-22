#!/usr/bin/env sh
# This script tries to install all the dependencies pertaining to the 
# LanguageClient-neovim and the cquery server  for a newly installed Debian/Ubuntu 
# distro. Unbeknownst to us, is the reason why the cquery server can't make any 
# autocompletion happen in c++. The LanguageClient-neovim client, however, works 
# flawlessly.

# Check if OS is Ubuntu or Debian because of package manager restrictions
if [ `ls /etc/*release | grep lsb` ]; then
	if [ ! `uname -rv | grep -o "[UD][be][ub][ni][ta][un]"` ]; then
		echo "The Following script is for Debian/Ubuntu distros only."
		return 1
	fi
fi

# Check if user is root
if [ `id -u` = 0 ]; then 
	echo "Please execute as root"
	return 1
fi

sudo apt install -y python3-dev python-dev build-essential libncurses5-dev cmake \
software-properties-common python-software-properties python-dev \
python-pip python3-dev python3-pip
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install g++-7 -y
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 --slave \
/usr/bin/g++ g++ /usr/bin/g++-7 
sudo update-alternatives --config gcc

# Install Vim if not already installed
if [ ! `which vim` ]; then
	[ `which git` ] || sudo apt install -y git
	git clone https://github.com/vim/vim.git
	cd vim/src
	./configure --enable-pythoninterp=yes \
            	--with-python-config-dir=/usr/lib/python2.7/config \
            	--enable-cscope \
            	--prefix=/usr 
	make
	sudo make install
	cd ../..
fi

# Install Rust
sudo apt install -y rustc

# Alternative version to install rust
#[ `which curl` ] || sudo apt install -y curl
#command -v curl https://sh.rustup.rs -sSf | sh
#source ~/.profile
#source ~/.cargo/env

# Install cquery with the stable clang version in $HOME
git clone https://github.com/cquery-project/cquery.git --recursive
cd cquery
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=release \
-DCMAKE_EXPORT_COMPILE_COMMANDS=YES
cmake --build .
cmake --build . --target install

# ------------------------------------------------------------------------------
# ------------------------ Install LanguageClient-neovim -----------------------
# Modified version by ganimaedes of the official repo by autozimu (install.sh)

# Removes the official install.sh and replaces it with a modified version if 
# LanguageClient-neovim is already installed. See the modified version here : 
# https://github.com/ganimaedes/Client/blob/master/install.sh
# If not installed, installs LanguageClient-neovim manually.

# Check vim version to know where to install a plugin manager if none exist 
vim_version=`vim --version | grep -o "[0-9]\.[0-9]" | awk 'NR==1'`

install_lang_client() {
	cd "${1}"
	folder_language=$(find "`pwd`" -type d -name "LanguageClient-neovim" 2>/dev/null)
	if [ ! -d "$folder_language" ]; then 
		if [ "${2}" = "vim_eight" ]; then
			mkdir -p "$HOME/.vim/plugged/" 
			cd $HOME/.vim/plugged/
		elif [ "${2}" = "nvim" ]; then
			mkdir -p "$HOME/.local/share/nvim/plugged/"
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
		install_lang_client "$HOME/.vim/" "vim_eight"
	else 
		install_vim_plug "nvim"
		install_lang_client "$HOME/.local/share/" "nvim"
	fi
}

dir_lang=$(find "`pwd`" -type d -wholename "*/LanguageClient-neovim" 2>/dev/null)

if [ -d "$dir_lang" ]; then
	rm -rf "$dir_lang"/install.sh
else
	vim_version_lang_install
	cd "$HOME"
	dir_lang=`find "/home/$(id -u -n)" -type d -wholename "*/LanguageClient-neovim" 2>/dev/null`
	rm -rf "$dir_lang"/install.sh
fi

command -v wget > /dev/null && wget \
https://raw.githubusercontent.com/ganimaedes/Client/master/install.sh -P "$dir_lang"

cd "$dir_lang"
sudo chmod a+x "$dir_lang"/install.sh
./install.sh

# ---------------------- End Install LanguageClient-neovim ---------------------
# ------------------------------------------------------------------------------

# Make a sample project (in c++) and write compile_commands.json, CMakeLists.txt
# and settings.json 
mkdir -p "$HOME/project/build" 
command -v wget > /dev/null && wget \
https://raw.githubusercontent.com/ganimaedes/cmake/master/CMakeLists.txt -P "$HOME/project/"

[ -d "$HOME/.config/nvim/" ] || mkdir -p "$HOME"/.config/nvim/

echo "{
  \"initializationOptions\": {
    \"cacheDirectory\": \"/tmp/cquery\"
  }
}" > "$HOME"/.config/nvim/settings.json

# Sample c++ files
cat /dev/null > "$HOME/project/sample.h"
cat /dev/null > "$HOME/project/sample.cpp"

echo "#include <string>" > "$HOME/project/sample.h" 
sed -i 's/$/\nint bad;/g' "$HOME/project/sample.h"

echo "#include \"sample.h\"" > "$HOME/project/sample.cpp"
sed -i 's/$/\n#include <iostream>\nint main(){return bad;}/g' "$HOME/project/sample.cpp"

# Download a sample .vimrc/init.vim
init_file=`find "/home/$(id -u -n)" -type f -name "init\.vim" 2>/dev/null`
rc_file=`find "/home/$(id -u -n)" -type f -name "\.vimrc" 2>/dev/null`
if [ ! "$init_file" ] && [ ! "$rc_file" ]; then
    if [ "${vim_version%\.*}" -lt 1 ]; then
	    command -v wget > /dev/null && \
	    wget https://raw.githubusercontent.com/ganimaedes/dot_files/master/init.vim -P \
	    "$HOME/.config/nvim"
    else
	    command -v wget > /dev/null && wget \
	    https://raw.githubusercontent.com/ganimaedes/dot_files/master/.vimrc -P "$HOME"
    fi
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
