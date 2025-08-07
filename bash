#!/usr/bin/env bash
iatest=$(expr index "$-" i)

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Enable bash programmable completion features in interactive shells
if [ -f /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi


# Disable the bell
if [[ $iatest -gt 0 ]]; then bind "set bell-style visible"; fi

# Expand the history size
export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T " # add timestamp to history

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
#shopt -s checkwinsize

# Causes bash to append to history instead of overwriting it so if you start a new terminal, you have old session history
shopt -s histappend
PROMPT_COMMAND='history -a'

# Allow ctrl-S for history navigation (with ctrl-R)
[[ $- == *i* ]] && stty -ixon

# Ignora mayusculas en autocompletado
if [[ $iatest -gt 0 ]]; then bind "set completion-ignore-case on"; fi

# To have colors for ls and all grep commands such as grep, egrep and zgrep
#export CLICOLOR=1
#
#export LS_COLORS='no=00:fi=00:di=01;38;5;73:ln=01;38;5;73:or=01;38;5;160:mi=01;38;5;160:ex=01;38;5;230'

# Archive files in #de935f (ANSI 173)
#export LS_COLORS+=':*.tar=38;5;173:*.tgz=38;5;173:*.zip=38;5;173:*.gz=38;5;173:*.bz2=38;5;173:*.rar=38;5;173:*.7z=38;5;173:*.xz=38;5;173'

# Other file types (keep your existing settings)
#export LS_COLORS+=':*.jpg=38;5;230:*.jpeg=38;5;230:*.png=38;5;230:*.gif=38;5;230:*.bmp=38;5;230:*.mp3=38;5;230:*.mp4=38;5;230:*.avi=38;5;230:*.pdf=38;5;230:*.doc=38;5;230:*.docx=38;5;230:*.xls=38;5;230:*.xlsx=38;5;230:*.ppt=38;5;230:*.pptx=38;5;230:*.sh=38;5;230:*.py=38;5;230:*.php=38;5;230:*.js=38;5;230:*.json=38;5;230:*.html=38;5;230:*.css=38;5;230:*.md=38;5;230:'

#######################################################
# GENERAL ALIASES
#######################################################

# aliases to modified commands
if command -v trash &> /dev/null; then
    alias rm='trash -v'
else
    alias rm='rm -i'  # fallback to interactive remove
fi

alias cls='clear'
alias vi='nvim'
alias vim='nvim'

# Change directory aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'


alias grep="grep --color=auto"

alias ls='lsd' # add colors and file type extensions

# Función para mostrar el estado del repositorio Git
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ git:\1/'
}

# Función para detectar cambios no commit/untracked
parse_git_dirty() {
    local STATUS
    STATUS=$(git status --porcelain 2>/dev/null)
    if [[ -n $STATUS ]]; then
        echo -e "\e[38;5;238m*\e[0m"  # Asterisco en gris medio (color 242)
    fi
}

# Configuración del prompt
set_bash_prompt() {
    local GIT_BRANCH
    GIT_BRANCH=$(parse_git_branch)
    
    # Reset colors and start with new line
    PS1="\[\e[0m\]\n"
    
    # Path in medium gray (color 245)
    PS1+=" \[\e[38;5;248m\]\w\[\e[0m\]"
    
    # Git branch in darker gray (color 242)
    if [[ -n $GIT_BRANCH ]]; then
        PS1+="\[\e[38;5;238m\]$GIT_BRANCH\[\e[0m\]"
        PS1+="$(parse_git_dirty)"  # Asterisco in gray
    fi

    if [[ -n "$VIRTUAL_ENV" ]]; then
        PS1+="\[\e[38;5;10m\]($(basename "$VIRTUAL_ENV")) \[\e[0m\]"
    fi 
    # New line and white $ prompt
    PS1+="\n \[\e[0m\]❯ "  # Reset colors and show white prompt
}

PROMPT_COMMAND=set_bash_prompt

eval "$(zoxide init bash)"

#Path de cargo (compilador de rust ?)
. "$HOME/.cargo/env"

# Vim en terminal 
set -o vi

# setup esp-idf
alias stesp='. $HOME/esp/v5.2.5/esp-idf/export.sh'

#tmux alias
alias tmuxk='tmux kill-session -t'
alias tmuxa='tmux attach -t'
alias tmuxn='tmux new -s'

# pulseaudio
alias pls='pulseaudio --start'
alias yz='yazi'


export MYSQL_USER='root'
export MYSQL_PWD='admin'
export MYSQL_PASSWORD='admin'
export MYSQL_HOST='172.17.0.2'

function compareDb
{
	json_regex="";

	mysqldump --skip-add-drop-table -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -d $1 | \
		sed -E 's/longtext DEFAULT NULL CHECK.*/json DEFAULT NULL/g' | \
		sed 's/longtext DEFAULT NULL CHECK.*/json DEFAULT/' | \
		sed 's/ENGINE=.*/;/' | \
		sed 's/ COLLATE.\w\+//' | \
		sed 's/ CHARACTER SET \w\+//' | \
		pv > /tmp/compare_db_a.sql

	nvim /tmp/compare_db_a.sql "+:g/CREATE/norm! @f+" "+:w!" "+:q!"
	mysqldump --skip-add-drop-table -u$MYSQL_USER -p$MYSQL_PWD -h $MYSQL_HOST -d $2 | sed 's/ENGINE=.*/;/' | sed 's/ COLLATE.\w\+//' | sed 's/ CHARACTER SET \w\+//' | pv > /tmp/compare_db_b.sql
    nvim /tmp/compare_db_b.sql "+:g/CREATE/norm! @f+" "+:w!" "+:q!"

	meld -n --diff /tmp/compare_db_a.sql /tmp/compare_db_b.sql &
}

export MYSQL_COMPAT_EXEC=/usr/bin/mysql

function copyDbFromPosco()
{
	if [ "$#" -ne 2 ]; then
		echo "Illegal number of parameters"
		return 2;
	fi

	date_str=`date +%Y-%m-%d-%H%M%S`;
	$MYSQL_COMPAT_EXEC -u $MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST <<< "DROP DATABASE IF EXISTS $2; CREATE DATABASE $2"
	#mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST <<< "DROP DATABASE IF EXISTS $2; CREATE DATABASE $2"
	echo 'ssh posco mysqldump -u dbuser -p $1 | gzip > /tmp/test_$date_str.sql.gz';
	ssh posco mysqldump --skip-add-drop-table -udbuser -pSoluciones01 $1 | gzip > /tmp/test_$date_str.sql.gz
	echo "pv /tmp/test_$date_str.sql.gz | gunzip | mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $2";
	pv /tmp/test_$date_str.sql.gz | \
		gunzip | \
		sed 's/ COLLATE.\w\+//' | \
		sed 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' | \
		$MYSQL_COMPAT_EXEC -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST $2;
}

#// compareDbFromProduction2 localdb remotedb
compareFromProduction2()
{
	echo "Comparing local $1 with remote $2";
	date_str=`date +%Y-%m-%d-%H%M%S`;mariadb
	mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST <<< "DROP DATABASE IF EXISTS $2; CREATE DATABASE $2"
	echo 'ssh produccion2 mysqldump -d -u dbuser -p $1 | gzip > /tmp/test_$date_str.sql.gz';
	ssh produccion2 mysqldump -d -udbuser -pSoluciones01 $1 | gzip > /tmp/test_$date_str.sql.gz
	echo 'pv /tmp/test_$date_str.sql.gz | gunzip | mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $2';
	pv /tmp/test_$date_str.sql.gz | gunzip | sed 's/ COLLATE.\w\+//' | mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST $2;

}

compareFromProduction2()
{
	copyDbFromProduction2 $2 test && compareDb $1 test
}


alias reds="redshift -O 3500"
alias sapache="sudo systemctl start apache2.service"
alias rapache="sudo systemctl restart apache2.service"
alias stapache="sudo systemctl stop apache2.service"


