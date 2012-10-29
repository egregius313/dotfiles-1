################################################################################
## Shell Config -- Master File
## Date 2012-08-11
################################################################################

##==============================================================================
## Sourcing
##==============================================================================

## TODO: is it possible to unify BSD and GNU here?
if [ "$OSTYPE" = "linux-gnu" ]; then
    SHELL_CURRENT="$(ps | awk -v shellpid=$$ '$0 ~ shellpid {print $4}')"
else
    SHELL_CURRENT="$(ps -c | awk -v shellpid=$$ '$0 ~ shellpid {print $5}')"
fi
SHELL_DIR="$HOME/.shell.d"

## Should be sourced first.
source "${SHELL_DIR}/main_rc"
source "${SHELL_DIR}/options_zsh"

## Source order should not matter.
source "${SHELL_DIR}/alias_rc"
source "${SHELL_DIR}/colors_zsh"    
source "${SHELL_DIR}/funs_rc"
source "${SHELL_DIR}/keys_zsh"
source "${SHELL_DIR}/personal_rc"

