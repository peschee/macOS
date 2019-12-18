#!/usr/bin/env bash
COLOR_RESET="\033[0m"
COLOR_HEADLINE="\033[45m\033[1;37m"
REPO_DIR=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)

# Change to script directory so we can use relative paths
cd "$(dirname "${BASH_SOURCE}")"

task() {
    printf "\n${COLOR_HEADLINE} %s ${COLOR_RESET}\n" "$*"
}

commandExists () {
    type "$1" &> /dev/null ;
}

installComposer() {
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
    then
        >&2 echo 'ERROR: Invalid installer signature'
        rm composer-setup.php
        exit 1
    fi

    php composer-setup.php --quiet
    RESULT=$?
    rm composer-setup.php
}

# Ask for the administrator password upfront
sudo -v

task 'Install oh-my-zsh'
# @see https://github.com/robbyrussell/oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# @see https://github.com/zsh-users/zsh-autosuggestions
[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ] && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# @see https://github.com/zsh-users/zsh-syntax-highlighting
[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# @see https://github.com/bhilburn/powerlevel9k
[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel9k ] && git clone https://github.com/bhilburn/powerlevel9k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel9k

task 'Linking dotfiles…'
ln -sfv ${REPO_DIR}/dotfiles/.zshrc ${REPO_DIR}/dotfiles/.zprofile ~
ln -sfv ${REPO_DIR}/dotfiles/.gitconfig ${REPO_DIR}/dotfiles/.gitignore ~
ln -sfv ${REPO_DIR}/dotfiles/.{vimrc,gemrc,grconfig.json} ~
for file in ${REPO_DIR}/dotfiles/.{path,exports,aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && ln -sfv "$file" ~ && source "$file"
done
task 'Copying scripts to ~/bin…'
mkdir -pv ~/bin && cp -Rfv bin/* ~/bin

which -s brew
if [[ $? != 0 ]] ; then
    task 'Installing Homebrew…'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    task 'Updating Homebrew…'
    brew update
fi

task 'Installing Homebrew bundle…'
brew bundle

task 'Installing n + avn…'
if [[ -d ~/n ]];then
    echo 'n seems already installed, skipping…'
else
    curl -L https://git.io/n-install | bash -s -- -n -y lts latest
    export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH = "$N_PREFIX/bin:$PATH"
fi

if commandExists avn; then
    echo 'avn seems already installed, skipping…'
else
    npm install -g avn avn-n
    avn setup
fi

task 'Installing composer…'
installComposer && mv -v composer.phar ~/bin/composer
mkdir -p ~/bin/.composer && ln -sfv "${REPO_DIR}/config/composer.lock" "${HOME}/.composer/composer.lock"
~/bin/composer global install

# Install web development setup
#
# A lot of this was initially taken from https://echo.co/blog/os-x-1010-yosemite-local-development-environment-apache-php-and-mysql-homebrew
# Since then, that guide has been taken down so we forked a copy on github
# @see https://gist.github.com/peschee/170732cd63b46e5910d87e0ffab46fa2
#
# tl;dr:
#   - stop built-in httd
#   - install and run homebrew httpd on non-privileged ports using the current user
#   - automatically forward all requests from 80 --> 9080 and 433 --> 9443 (to our httpd)
task 'Installing (web) development setup…'

# Link mysql config
ln -sfv "${REPO_DIR}/etc/my.cnf" $(brew --prefix)/etc

# Launch MySQL's secure installation script to set up root user
brew services start mysql@5.7
$(brew --prefix mysql@5.7)/bin/mysql_secure_installation

# Disable built-in httpd
sudo launchctl unload /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null

# Setup httpd
ln -sfv "${REPO_DIR}/etc/httpd.conf" $(brew --prefix)/etc/httpd
mkdir -pv ~/Sites/{logs,ssl,vhosts,inc,auto}
ln -sfv "${REPO_DIR}/config/_default.conf" ~/Sites/vhosts/
ln -sfv "${REPO_DIR}/config/options-ssl-apache.conf" ~/Sites/inc/
echo "<?php phpinfo();\n" > ~/Sites/index.php

# Setup self-signed SSL
mkcert -install
mkcert localhost 127.0.0.1 ::1
mv localhost*.pem ~/Sites/ssl

# Setup port forwarding 80 --> 9080 and 443 --> 9443
sudo cp config/co.echo.httpdfwd.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/co.echo.httpdfwd.plist
sudo launchctl load -Fw /Library/LaunchDaemons/co.echo.httpdfwd.plist

# Restart services
brew services restart httpd
brew services restart mysql@5.7
brew services restart php

task 'Installing additional scripts…'
# @see https://github.com/bntzio/wipe-modules
curl -L https://raw.githubusercontent.com/bntzio/wipe-modules/master/wipe-modules.sh -o ~/bin/wipe-modules && chmod +x ~/bin/wipe-modules

task 'Linking configuration files…'
# Set up my preferred keyboard shortcuts
ln -sfv "${REPO_DIR}/config/spectacle.json" "${HOME}/Library/Application Support/Spectacle/Shortcuts.json"

# Visual Code settings
ln -sfv "${REPO_DIR}/config/VSCode/settings.json" "${HOME}/Library/Application Support/Code/User/"
ln -sfv "${REPO_DIR}/config/VSCode/keybindings.json" "${HOME}/Library/Application Support/Code/User/"
ln -sfv "${REPO_DIR}/config/VSCode/snippets" "${HOME}/Library/Application Support/Code/User/"
