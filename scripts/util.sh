# Be strict about errors:
set -e

###############################################################################
# Bash function to check for a flag in 'args'.
# Returns true if flag was found.
###############################################################################

resolved_args="$@" # Create a mutable copy of the program arguments
function has_flag(){
    flag=$1
    for arg in $resolved_args ; do
        if [ $arg = $flag ] ; then
            return 0; # True!
        fi
    done
    return 1; # False!
}

###############################################################################
# Bash function to check for a flag in 'args' and remove it.
# Treats 'args' as one long string. 
# Returns true if flag was found and removed.
###############################################################################

function resolve_flag(){
    flag=$1
    local new_resolved_args
    local got
    got=1 # False!
    for arg in $resolved_args ; do
        if [ $arg = $flag ] ; then
            resolved_args="${args/$flag/}"
            got=0 # True!
        else
            new_resolved_args="$new_args $arg"
        fi
    done
    resolved_args="$new_args"
    return $got # False!
}

function pushd() {
    command pushd "$@" > /dev/null
}

function popd() {
    command popd "$@" > /dev/null
}
