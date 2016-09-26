#!/bin/bash
reset="\033[0m"
headline="\033[45m\033[1;37m"
pwd="$(pwd)"

task() {
    printf "\n${headline} %s ${reset}\n" "$*"
}

task 'Install oh-my-zsh'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

task 'Linking dotfiles…'
ln -sfv $(pwd)/dotfiles/.zshrc $(pwd)/dotfiles/.zprofile ~
ln -sfv $(pwd)/dotfiles/.gitconfig $(pwd)/dotfiles/.gitignore ~
for file in $(pwd)/dotfiles/.{path,exports,aliases,functions,extra}; do
    ln -sfv "$file" ~ && source "$file"
done
mkdir ~/.atom
ln -sfv $(pwd)/dotfiles/.atom/{config,keymap,snippest,toolbar}.cson ~/.atom
ln -sfv $(pwd)/dotfiles/.atom/styles.less ~/.atom

task 'Linking ~/bin…'
ln -sfv $(pwd)/bin ~

task 'Installing Homebrew…'
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap \
    caskroom/fonts \
    homebrew/dupes \
    homebrew/versions \
    homebrew/homebrew-php

task 'Installing CLI apps…'
brew install \
    autojump \
    composer \
    git \
    gnu-tar \
    z

task 'Setting up node…'
brew install node
npm install -g n npmbrew avn avn-n grunt-cli
node -v

task 'Installing desktop apps…'
brew cask install \
    1password \
    alfred \
    atom \
    cleanmymac \
    default-folder-x \
    divvy \
    dropbox \
    fantastical \
    firefox \
    flux \
    font-anonymous-pro \
    font-camingocode \
    font-fira-code \
    font-inconsolata \
    google-chrome \
    google-drive \
    harvest \
    hazel \
    istat-menus \
    iterm2 \
    opera \
    sequel-pro \
    shiori \
    slack \
    spectacle \
    transmission \
    vlc


task 'Installing rbenv…'
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
source ~/.zshrc && source ~/.zprofile
rbenv install 2.3.1
rbenv global 2.3.1
ruby -v

task 'Installing fonts…'
brew cask install \
    font-fira-code \
    font-camingocode \
    font-inconsolata \
    font-anonymous-pro

task 'Installing Atom packages/themes…'
apm install \
    color-picker \
    colornamer \
    docblockr \
    emmet \
    file-icons \
    flex-tool-bar
    git-control \
    highlight-selected \
    html-head-snippets \
    language-apache \
    language-ini \
    native-ui \
    pigments \
    pretty-json \
    project-manager \
    sort-lines \
    todo-show \
    tool-bar

task 'Installing (web) development setup…'

brew install php70 --build-from-source --with-fpm
brew install php70-xdebug php70-apcu php70-opcache mysql dnsmasq
ln -sfv $(pwd)/etc/dsmasq.conf $(brew --prefix)/etc/dnsmasq.conf
ln -sfv $(pwd)/etc/my.cnf $(brew --prefix)/etc/my.cnf
sudo mkdir /etc/resolver
sudo ln -sfv $(pwd)/etc/resolver/* /etc/resolver/

sudo launchctl unload /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null
brew install httpd24 --with-brewed-openssl --with-mpm-event
brew install homebrew/apache/mod_fastcgi --with-homebrew-httpd24
ln -sfv $(pwd)/etc/apache/2.4/httpd.conf $(brew --prefix)/etc/apache/2.4/httpd.conf

mkdir -pv ~/Projects
mkdir -pv ~/Sites/{logs,ssl,vhosts}
ln -sfv $(pwd)/config/_default.conf ~/Sites/vhosts/

(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; cat > ~/Sites/ssl/ssl-shared-cert.inc <<EOF
SSLEngine On
SSLProtocol all -SSLv2 -SSLv3
SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
SSLCertificateFile "${USERHOME}/Sites/ssl/selfsigned.crt"
SSLCertificateKeyFile "${USERHOME}/Sites/ssl/private.key"
EOF
)
openssl req \
  -new \
  -newkey rsa:2048 \
  -days 3650 \
  -nodes \
  -x509 \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=$(whoami)/CN=*.dev" \
  -keyout ~/Sites/ssl/private.key \
  -out ~/Sites/ssl/selfsigned.crt

sudo ln -sfv $(pwd)/config/co.echo.httpfwd.plist /Library/LaunchDaemons/
sudo launchctl load -Fw /Library/LaunchDaemons/co.echo.httpd.plist

brew services restart httpd24
brew services restart dnsmasq
brew services restart mysql
