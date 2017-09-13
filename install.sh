#!/usr/bin/env bash
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
ln -sfv $(pwd)/dotfiles/.gemrc ~
for file in $(pwd)/dotfiles/.{path,exports,aliases,functions,extra}; do
    ln -sfv "$file" ~ && source "$file"
done
task 'Linking ~/bin…'
ln -sfv $(pwd)/bin ~

task 'Installing Homebrew…'
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

task 'Installing Homebrew bundle…'
brew tap Homebrew/bundle
brew install mas
brew bundle

task 'Setting up node…'
npm install -g n npmbrew avn avn-n grunt-cli
node -v

task 'Installing rbenv…'
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv install 2.3.1
rbenv global 2.3.1
ruby -v

task 'Installing Atom config…'
mkdir ~/.atom
ln -sfv $(pwd)/dotfiles/.atom/{config,keymap,snippest,toolbar}.cson ~/.atom
ln -sfv $(pwd)/dotfiles/.atom/styles.less ~/.atom

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
ln -sfv $(pwd)/etc/dnsmasq.conf $(brew --prefix)/etc/
ln -sfv $(pwd)/etc/my.cnf $(brew --prefix)/etc/
sudo mkdir /etc/resolver
sudo ln -sfv $(pwd)/etc/resolver/* /etc/resolver/
sudo launchctl unload /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null
ln -sfv $(pwd)/etc/apache/2.4/httpd.conf $(brew --prefix)/etc/apache2/2.4/
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

sudo cp $(pwd)/config/co.echo.httpdfwd.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/co.echo.httpdfwd.plist
sudo launchctl load -Fw /Library/LaunchDaemons/co.echo.httpdfwd.plist

brew services restart httpd24
brew services restart dnsmasq
brew services restart mysql
