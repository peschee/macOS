# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# @see https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# @see https://github.com/romkatv/powerlevel10k
# @see https://github.com/romkatv/powerlevel10k/blob/master/README.md#what-do-different-symbols-in-git-status-mean
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="dd.mm.yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    composer
    docker
    docker-compose
    git-extras
    last-working-dir
    ng
    symfony2
    vagrant
    yarn
    z
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Initialize completions
autoload -U compinit && compinit

# @see https://stackoverflow.com/questions/20037364/why-zsh-tries-to-expand-and-bash-does-not
setopt nonomatch

# Initialize z
[[ -s $(brew --prefix)/etc/profile.d/z.sh ]] && . $(brew --prefix)/etc/profile.d/z.sh

# Init rbenv
# @see https://github.com/rbenv/rbenv
#eval "$(rbenv init -)"

# jenv
# @see http://www.jenv.be/
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# n
# @see https://github.com/mklement0/n-install
export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || export PATH="$N_PREFIX/bin:$PATH"

# avn
# @see https://github.com/wbyoung/avn
[[ -s "$HOME/.avn/bin/avn.sh" ]] && source "$HOME/.avn/bin/avn.sh"

# iterm2 shell integration
# @see https://www.iterm2.com/documentation-shell-integration.html
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# @see https://github.com/bhilburn/powerlevel9k#prompt-customization
# @see https://github.com/romkatv/powerlevel10k/blob/master/README.md#does-powerlevel10k-always-render-exactly-the-same-prompt-as-powerlevel9k-given-the-same-config
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs)
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND='000'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc' ]; then . '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc' ]; then . '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'; fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
