#!/bin/bash
### VARIABLES ###
# Frequency, in seconds, to poll for project status.
# Probably best not to set this to too small an interval.
POLL_FREQUENCY=60

# Path to blink-tool(1)
BLINK1_TOOL="`which blink1-tool`"
BLINK2_TOOL="`which blink2-tool`"

# URL of mantid jenkins
URL="http://builds.mantidproject.org/job/"

# Build to monitor
PROJECT="develop_incremental"
PROJECT2="develop_clean"

COLOR_GREEN="0,255,0"
COLOR_RED="255,0,0"
COLOR_YELLOW="255,220,0"
COLOR_BLUE="0,0,255"
COLOR_GREEN_BUILDING="0,100,0"
COLOR_RED_BUILDING="100,0,0"
COLOR_YELLOW_BUILDING="100,90,0"
COLOR_BLUE_BUILDING="0,0,100"
COLOR_ERROR="255,255,255" # White
COLOR_ABORTED="200,200,200" # light grey
COLOR_ABORTED="100,100,100" # light grey

### FUNCTIONS ###

# Set the Blink(1) to a color in "R,G,B" format, which must be supplied
# as an argument.
function set_blink1_color
{
    $BLINK1_TOOL --rgb ${1} --led ${2} > /dev/null 2>&1
}

# return the string to pass for information about blinking to blink2-tool
function get_blink
{
    if [ $BLINK2_TOOL ]; then
        if [[ "$1" == *_anime ]]; then
            if [[ "$2" == *_anime ]]; then
                echo "-b both -n $POLL_FREQUENCY"
            else
                echo "-b 1 -n $POLL_FREQUENCY"
            fi
        elif [[ $2 == *_anime ]]; then
            echo "-b 2 -n $POLL_FREQUENCY"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

function get_color
{
    COLOR=$(echo $1 | sed -e 's,<color>,,' -e 's,</color>,,')
    if [ $BLINK2_TOOL ]; then
        COLOR=$(echo $1 | sed 's,_anime,,g')
    fi

    if [ "${COLOR}" == "blue" ]; then
       echo ${COLOR_BLUE}
    elif [ "${COLOR}" == "yellow" ]; then
       echo ${COLOR_YELLOW}
    elif [ "${COLOR}" == "red" ]; then
       echo ${COLOR_RED}
    elif [ "${COLOR}" == "aborted" ]; then
       echo ${COLOR_ABORTED}
    elif [ "${COLOR}" == "blue_anime" ]; then
       echo ${COLOR_BLUE_BUILDING}
    elif [ "${COLOR}" == "yellow_anime" ]; then
       echo ${COLOR_YELLOW_BUILDING}
    elif [ "${COLOR}" == "red_anime" ]; then
       echo ${COLOR_RED_BUILDING}
    elif [ "${COLOR}" == "aborted_anime" ]; then
       echo ${COLOR_ABORTED_BUILDING}
    else
       echo ${COLOR_ERROR}
    fi
}

# Used with trap to shut off the Blink(1) when we get a SIGINT or SIGTERM.
function cleanup
{
    # Turn the Blink(1) off
    $BLINK1_TOOL --off > /dev/null 2>&1
    exit $?
}


# Show usage instructions
function show_usage
{
    echo " Usage: `basename ${0}` [OPTIONS] <project> [project2]"
    echo ""
    echo " Options:"
    echo "    -h              Displays this help"
    echo "    -t <seconds>    Polling interval in seconds (default: ${POLL_FREQUENCY} s.)"
    echo ""
    echo " <project> should be in the form job[/label=<build>] (default: ${PROJECT})"
    echo " Two projects can be specified, each controlling a different LED. "
    echo ""
}


### SETUP ###
# Get command line options
while getopts "ht:b:" OPTION
do
    case $OPTION in
        h)
            show_usage
            exit 0
            ;;
        t)
            POLL_FREQUENCY=$OPTARG
            ;;
        ?)
            show_usage
            exit 1
            ;;
    esac
done

# Get project
shift $(($OPTIND - 1))
if [ $1 ]; then
    PROJECT=$1
fi

if [ $2 ]; then
    PROJECT2=$2
fi
if [ $PROJECT2 ]; then
    TWO=true
fi

# Turn off the Blink(1) on SIGINT or SIGTERM
trap cleanup SIGINT SIGTERM

### MAIN ###
# In an infinite loop, poll the project and update the Blink(1) color.
if [ $TWO ]; then
    echo "Monitoring ${PROJECT} and ${PROJECT2}. CTRL-C to exit."
else
    echo "Monitoring ${PROJECT}. CTRL-C to exit."
fi
while true; do
    STATUS=$(curl -f -s "${URL}${PROJECT}/api/xml?xpath=/*/color")
    STATUS=$(echo $STATUS | sed 's,<color>\|</color>,,g')
    if [ $TWO ]; then 
       STATUS2=$(curl -f -s "${URL}${PROJECT2}/api/xml?xpath=/*/color")
       STATUS2=$(echo $STATUS2 | sed 's,<color>\|</color>,,g')
       LED1=1
       LED2=2
    else
       LED1=0
    fi
    if [ $TWO -a $BLINK2_TOOL ]; then
        blink=$(get_blink ${STATUS} ${STATUS2})
        $BLINK2_TOOL $blink rgb=$(get_color ${STATUS}) rgb=$(get_color ${STATUS2})
        if [ -z "$blink" ]; then
            sleep ${POLL_FREQUENCY}
        fi
    else
        set_blink1_color $(get_color ${STATUS}) $LED1
        if [ $TWO ]; then set_blink1_color $(get_color ${STATUS2}) $LED2; fi
        sleep ${POLL_FREQUENCY}
    fi
done
