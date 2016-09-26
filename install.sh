#!/bin/sh
reset="\033[0m"
headline="\033[45m\033[1;37m"
dim="\033[2m"
pwd=$(pwd)

function task {
    printf "\n${headline} %s ${reset}\n" "$*"
}

function run {
    printf "> %s${dim}\n" "$*"
    eval $*
    printf "${reset}\n"
}

task 'Install oh-my-zsh'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

task 'Linking dotfiles…'
run 'ln -sfv $pwd/.zshrc ~'
run 'ln -sfv $pwd/.zprofile ~'
for file in $pwd/.{path,exports,aliases,functions,extra}; do
    run 'ln -sfv $file ~' && source "$file"
done
run 'ln -sfv $pwd/.gitconfig ~'
run 'ln -sfv $pwd/.gitignore ~'
run 'mkdir ~/.atom'
run 'ln -sfv $pwd/.atom/config.cson ~/.atom'
run 'ln -sfv $pwd/.atom/keymap.cson ~/.atom'
run 'ln -sfv $pwd/.atom/snippets.cson ~/.atom'
run 'ln -sfv $pwd/.atom/toolbar.cson ~/.atom'
run 'ln -sfv $pwd/.atom/styles.less ~/.atom'

task 'Linking ~/bin…'
run 'ln -sfv $pwd/bin ~'

# task 'Installing Homebrew…'
# run '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
# run brew tap caskroom/fonts
# run brew tap homebrew/dupes
# run brew tap homebrew/versions
# run brew tap homebrew/homebrew-php
#
task 'Installing CLI apps…'
run brew install \
    autojump \
    composer \
    git \
    gnu-tar \
    z

task 'Setting up node…'
run brew install node
run npm install -g n npmbrew avn avn-n grunt

task 'Installing desktop apps…'
run brew cask install \
    1password \
    alfred \
    atom \
    cleanmymac \
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
run git clone https://github.com/rbenv/rbenv.git ~/.rbenv
run git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
run rbenv install 2.3.1
run rbenv global 2.3.1

task 'Installing fonts…'
run brew cask install font-fira-code font-camingocode font-inconsolata font-anonymous-pro

task 'Installing Atom packages/themes…'
run apm install emmet language-apache language-ini file-icons docblockr sort-lines todo-show \
pigments color-picker highlight-selected html-head-snippets pretty-json \
tool-bar git-control native-ui colornamer project-manager flex-tool-bar

task 'Installing (web) development setup…'
run brew install php70 --build-from-source --with-fpm
run brew install mysql php70-xdebug php70-apcu dnsmasq
run echo 'address=/.dev/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf
run echo 'listen-address=127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
run echo 'port=35353' >> $(brew --prefix)/etc/dnsmasq.conf
run cp -v $(brew --prefix mysql)/support-files/my-default.cnf $(brew --prefix)/etc/my.cnf
run sudo mkdir -v /etc/resolver
run sudo echo "nameserver 127.0.0.1" > /etc/resolver/dev
run sudo echo "port 35353" >> /etc/resolver/dev
run cat >> $(brew --prefix)/etc/my.cnf <<'EOF'

# Echo & Co. changes
max_allowed_packet = 1073741824
innodb_file_per_table = 1
EOF
sed -i '' 's/^#[[:space:]]*\(innodb_buffer_pool_size\)/\1/' $(brew --prefix)/etc/my.cnf
run sudo launchctl unload /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null
run brew install homebrew/apache/httpd24 --with-brewed-openssl --with-mpm-event
run brew install -v homebrew/apache/mod_fastcgi --with-homebrew-httpd24
sed -i '' '/fastcgi_module/d' $(brew --prefix)/etc/apache2/2.4/httpd.conf
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; export MODFASTCGIPREFIX=$(brew --prefix mod_fastcgi) ; cat >> $(brew --prefix)/etc/apache2/2.4/httpd.conf <<EOF

# Echo & Co. changes

# Load PHP-FPM via mod_fastcgi
LoadModule fastcgi_module    ${MODFASTCGIPREFIX}/libexec/mod_fastcgi.so

<IfModule fastcgi_module>
  FastCgiConfig -maxClassProcesses 1 -idle-timeout 1500

  # Prevent accessing FastCGI alias paths directly
  <LocationMatch "^/fastcgi">
    <IfModule mod_authz_core.c>
      Require env REDIRECT_STATUS
    </IfModule>
    <IfModule !mod_authz_core.c>
      Order Deny,Allow
      Deny from All
      Allow from env=REDIRECT_STATUS
    </IfModule>
  </LocationMatch>

  FastCgiExternalServer /php-fpm -host 127.0.0.1:9000 -pass-header Authorization -idle-timeout 1500
  ScriptAlias /fastcgiphp /php-fpm
  Action php-fastcgi /fastcgiphp

  # Send PHP extensions to PHP-FPM
  AddHandler php-fastcgi .php

  # PHP options
  AddType text/html .php
  AddType application/x-httpd-php .php
  DirectoryIndex index.php index.html
</IfModule>

# Include our VirtualHosts
Include ${USERHOME}/Sites/httpd-vhosts.conf
EOF
)
run mkdir -pv ~/Sites/{logs,ssl}
run touch ~/Sites/httpd-vhosts.conf
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; cat > ~/Sites/httpd-vhosts.conf <<EOF
#
# Listening ports.
#
#Listen 9080  # defined in main httpd.conf
Listen 9443

#
# Use name-based virtual hosting.
#
NameVirtualHost *:9080
NameVirtualHost *:9443

#
# Set up permissions for VirtualHosts in ~/Sites
#
<Directory "${USERHOME}/Sites">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    <IfModule mod_authz_core.c>
        Require all granted
    </IfModule>
    <IfModule !mod_authz_core.c>
        Order allow,deny
        Allow from all
    </IfModule>
</Directory>

# For http://localhost in the users' Sites folder
<VirtualHost _default_:9080>
    ServerName localhost
    DocumentRoot "${USERHOME}/Sites"
</VirtualHost>
<VirtualHost _default_:9443>
    ServerName localhost
    Include "${USERHOME}/Sites/ssl/ssl-shared-cert.inc"
    DocumentRoot "${USERHOME}/Sites"
</VirtualHost>

#
# VirtualHosts
#

## Manual VirtualHost template for HTTP and HTTPS
#<VirtualHost *:9080>
#  ServerName project.dev
#  CustomLog "${USERHOME}/Sites/logs/project.dev-access_log" combined
#  ErrorLog "${USERHOME}/Sites/logs/project.dev-error_log"
#  DocumentRoot "${USERHOME}/Sites/project.dev"
#</VirtualHost>
#<VirtualHost *:9443>
#  ServerName project.dev
#  Include "${USERHOME}/Sites/ssl/ssl-shared-cert.inc"
#  CustomLog "${USERHOME}/Sites/logs/project.dev-access_log" combined
#  ErrorLog "${USERHOME}/Sites/logs/project.dev-error_log"
#  DocumentRoot "${USERHOME}/Sites/project.dev"
#</VirtualHost>

#
# Automatic VirtualHosts
#
# A directory at ${USERHOME}/Sites/webroot can be accessed at http://webroot.dev
# In Drupal, uncomment the line with: RewriteBase /
#

# This log format will display the per-virtual-host as the first field followed by a typical log line
LogFormat "%V %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combinedmassvhost

# Auto-VirtualHosts with .dev
<VirtualHost *:9080>
  ServerName dev
  ServerAlias *.dev

  CustomLog "${USERHOME}/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Sites/logs/dev-error_log"

  VirtualDocumentRoot ${USERHOME}/Sites/%-2+
</VirtualHost>
<VirtualHost *:9443>
  ServerName dev
  ServerAlias *.dev
  Include "${USERHOME}/Sites/ssl/ssl-shared-cert.inc"

  CustomLog "${USERHOME}/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Sites/logs/dev-error_log"

  VirtualDocumentRoot ${USERHOME}/Sites/%-2+
</VirtualHost>
EOF
)
(export USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') ; cat > ~/Sites/ssl/ssl-shared-cert.inc <<EOF
SSLEngine On
SSLProtocol all -SSLv2 -SSLv3
SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
SSLCertificateFile "${USERHOME}/Sites/ssl/selfsigned.crt"
SSLCertificateKeyFile "${USERHOME}/Sites/ssl/private.key"
EOF
)
run openssl req \
  -new \
  -newkey rsa:2048 \
  -days 3650 \
  -nodes \
  -x509 \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=$(whoami)/CN=*.dev" \
  -keyout ~/Sites/ssl/private.key \
  -out ~/Sites/ssl/selfsigned.crt
sudo bash -c 'export TAB=$'"'"'\t'"'"'
cat > /Library/LaunchDaemons/co.echo.httpd.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
${TAB}<key>Label</key>
${TAB}<string>co.echo.httpd</string>
${TAB}<key>ProgramArguments</key>
${TAB}<array>
${TAB}${TAB}<string>sh</string>
${TAB}${TAB}<string>-c</string>
${TAB}${TAB}<string>echo "rdr pass proto tcp from any to any port {80,9080} -> 127.0.0.1 port 9080" | pfctl -a "com.apple/260.HttpFirewall" -Ef - &amp;&amp; echo "rdr pass proto tcp from any to any port {443,9443} -> 127.0.0.1 port 9443" | pfctl -a "com.apple/261.HttpFirewall" -Ef - &amp;&amp; sysctl -w net.inet.ip.forwarding=1</string>
${TAB}</array>
${TAB}<key>RunAtLoad</key>
${TAB}<true/>
${TAB}<key>UserName</key>
${TAB}<string>root</string>
</dict>
</plist>
EOF'
run sudo launchctl load -Fw /Library/LaunchDaemons/co.echo.httpd.plist
run brew services start httpd24
run brew services start dnsmasq
run brew services start mysql
