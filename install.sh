#!/usr/bin/env bash
reset="\033[0m"
headline="\033[45m\033[1;37m"
pwd="$(pwd)"

task() {
    printf "\n${headline} %s ${reset}\n" "$*"
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
ln -sfv $(pwd)/dotfiles/.zshrc $(pwd)/dotfiles/.zprofile ~
ln -sfv $(pwd)/dotfiles/.gitconfig $(pwd)/dotfiles/.gitignore ~
for file in $(pwd)/dotfiles/.{path,exports,aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && ln -sfv "$file" ~ && source "$file"
done
task 'Copying scripts to ~/bin…'
mkdir -pv ~/bin && cp -Rfv $(pwd)/bin/* ~/bin

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
    export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"
fi

if commandExists avn; then
    echo ' seems already installed, skipping…'
else
    npm install -g avn avn-n
    avn setup
fi

task 'Installing (web) development setup…'
installComposer && mv -v composer.phar ~/bin/composer
# ln -sfv $(pwd)/etc/dnsmasq.conf $(brew --prefix)/etc/
# ln -sfv $(pwd)/etc/my.cnf $(brew --prefix)/etc/
# sudo mkdir /etc/resolver
# sudo ln -sfv $(pwd)/etc/resolver/* /etc/resolver/
# sudo launchctl unload /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null
# ln -sfv $(pwd)/etc/httpd.conf $(brew --prefix)/etc/httpd/
# mkdir -pv ~/Projects
# mkdir -pv ~/Sites/{logs,ssl,vhosts}
# ln -sfv $(pwd)/config/_default.conf ~/Sites/vhosts/

# (export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; cat > ~/Sites/ssl/ssl-shared-cert.inc <<EOF
# SSLEngine On
# SSLProtocol all -SSLv2 -SSLv3
# SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
# SSLCertificateFile "${USERHOME}/Sites/ssl/selfsigned.crt"
# SSLCertificateKeyFile "${USERHOME}/Sites/ssl/private.key"
# EOF
# )
# openssl req \
#   -new \
#   -newkey rsa:2048 \
#   -days 3650 \
#   -nodes \
#   -x509 \
#   -subj "/C=US/ST=State/L=City/O=Organization/OU=$(whoami)/CN=*.test" \
#   -keyout ~/Sites/ssl/private.key \
#   -out ~/Sites/ssl/selfsigned.crt

# sudo cp $(pwd)/config/co.echo.httpdfwd.plist /Library/LaunchDaemons/
# sudo chown root:wheel /Library/LaunchDaemons/co.echo.httpdfwd.plist
# sudo launchctl load -Fw /Library/LaunchDaemons/co.echo.httpdfwd.plist

# brew services restart httpd
# brew services restart dnsmasq
# brew services restart mysql

task 'Installing additional scripts…'
# @see https://github.com/bntzio/wipe-modules
curl -L https://raw.githubusercontent.com/bntzio/wipe-modules/master/wipe-modules.sh -o ~/bin/wipe-modules && chmod +x ~/bin/wipe-modules

task 'Linking configuration files…'
# Set up my preferred keyboard shortcuts
ln -sfv config/spectacle.json ~/Library/Application\ Support/Spectacle/Shortcuts.json
# Visual Code settings
ln -sfv config/code.json ~/Library/Application\ Support/Code/User/settings.json
