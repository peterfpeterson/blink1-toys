#!/bin/bash
### VARIABLES ###
POLL_FREQUENCY=1.5 # can be specified on command line
MAX_BRIGHT=127 # 255 is the absolute top

### CONSTANTS - DON'T CHANGE THESE ###
BLINK1_TOOL="`which blink1-tool`"
for ((i=0; i<12; i++)) ; do
  last_colors[$i]="00,00,00"
done

### FUNCTIONS ###

# Set the Blink(1) to a color in "R,G,B" format, which must be supplied
# as an argument.
function set_blink1_color
{
    $BLINK1_TOOL --rgb ${1} --led ${2} > /dev/null 2>&1
}

function set_leds
{
    local colors=("${@}")
    for ((i=0; i<12; i++)) ; do
        led=$(echo $i+3 | bc)
        echo "$led ${last_colors[$i]} -> ${colors[$i]}" # DEBUG
        if [ ${colors[$i]} != ${last_colors[$i]} ]; then
            set_blink1_color ${colors[$i]} $led
        fi
        last_colors[$i]=${colors[$i]}
    done
}

function show_time_spot
{
    # hours
    led_full=$(echo ${1}-1 | bc)
    for ((i=0; i<12; i++)) ; do
        if [ $i -eq $led_full ]; then
            colors[$i]=$MAX_BRIGHT
        else
            colors[$i]=0
        fi
    done

    # minutes
    led_full=$(echo ${2}/5 | bc) # number of fully lit
    led_partial=$(echo ${2}-$led_full*5 | bc) # minutes since last 5
    led_partial=$(echo $led_partial*60+${3} | bc) # seconds since last 5
    led_partial=$(echo $led_partial*$MAX_BRIGHT/300 | bc) # convert to intensity
    for ((i=0; i<12; i++)) ; do
        if [ $i -eq $(echo $led_full-1 | bc) ]; then
            colors[$i]="${colors[$i]},$MAX_BRIGHT"
        elif [ $led_full -eq 0 -a $i -eq 11 ]; then
            colors[$i]="${colors[$i]},$MAX_BRIGHT"
        elif [ $i -eq $led_full ]; then
            colors[$i]="${colors[$i]},$led_partial"
        else
            colors[$i]="${colors[$i]},0"
        fi
    done

    # seconds
    led_full=$(echo ${3}/5 | bc) # number of fully lit
    led_partial=$(echo ${3}-$led_full*5 | bc) # seconds since last 5
    led_partial=$(echo $led_partial*$MAX_BRIGHT/5 | bc) # convert to intensity
    for ((i=0; i<12; i++)) ; do
        if [ $i -eq $(echo $led_full-1 | bc) ]; then
            colors[$i]="${colors[$i]},$MAX_BRIGHT"
        elif [ $led_full -eq 0 -a $i -eq 11 ]; then
            colors[$i]="${colors[$i]},$MAX_BRIGHT"
        elif [ $i -eq $led_full ]; then
            colors[$i]="${colors[$i]},$led_partial"
        else
            colors[$i]="${colors[$i]},0"
        fi
    done

    set_leds ${colors[@]}
}

function show_time_sweep
{
    # hours
    led_full=$(echo ${1}-1 | bc)
    for ((i=0; i<12; i++)) ; do
        if [ $i -le $led_full ]; then
            colors[$i]=$MAX_BRIGHT
        else
            colors[$i]=0
        fi
    done

    # minutes
    led_full=$(echo ${2}/5 | bc) # number of fully lit
    led_partial=$(echo ${2}-$led_full*5 | bc) # minutes since last 5
    led_partial=$(echo $led_partial*60+${3} | bc) # seconds since last 5
    led_partial=$(echo $led_partial*$MAX_BRIGHT/300 | bc) # convert to intensity
    for ((i=0; i<12; i++)) ; do
        led_max=$(echo $i*5 | bc)
        if [ $i -lt $led_full ]; then
            colors[$i]="${colors[$i]},$MAX_BRIGHT"
        elif [ $i -eq $led_full ]; then
            colors[$i]="${colors[$i]},$led_partial"
        else
            colors[$i]="${colors[$i]},0"
        fi
    done

    # seconds
    led_full=$(echo ${3}/5 | bc) # number of fully lit
    led_partial=$(echo ${3}-$led_full*5 | bc) # seconds since last 5
    led_partial=$(echo $led_partial*$MAX_BRIGHT/5 | bc) # convert to intensity
    for ((i=0; i<12; i++)) ; do
        led_max=$(echo $i*5 | bc)
        if [ $i -lt $led_full ]; then
            colors[$i]="${colors[$i]},$MAX_BRIGHT"
        elif [ $i -eq $led_full ]; then
            colors[$i]="${colors[$i]},$led_partial"
        else
            colors[$i]="${colors[$i]},0"
        fi
    done

    set_leds ${colors[@]}
}

function show_now
{
    echo "***** $(date "+%I %M %S")" # DEBUG
    show_time_sweep `date "+%I %M %S"`
    # show_time_spot `date "+%I %M %S"`
}

# Used with trap to shut off the Blink(1) when we get a SIGINT or SIGTERM.
function cleanup
{
    # Turn the Blink(1) off
    for ((i=0; i<12; i++)) ; do
        led=$(echo 14-$i | bc)
        $BLINK1_TOOL --led $led --off > /dev/null 2>&1
    done
    exit $?
}

# Show usage instructions
function show_usage
{
    echo " Usage: `basename ${0}` [OPTIONS]"
    echo ""
    echo " Options:"
    echo "    -h              Displays this help"
    echo "    -f <seconds>    Polling interval in seconds (default: ${POLL_FREQUENCY} s.)"
}


### SETUP ###
# Get command line options
while getopts "hf:" OPTION
do
    case $OPTION in
        h)
            show_usage
            exit 0
            ;;
        f)
            POLL_FREQUENCY=$OPTARG
            ;;
        ?)
            show_usage
            exit 1
            ;;
    esac
done

shift $(($OPTIND - 1))
if [ $3 ]; then
    show_time_sweep $1 $2 $3
    # show_time_spot $1 $2 $3
    exit 0
fi

# Turn off the Blink(1) on SIGINT or SIGTERM
trap cleanup SIGINT SIGTERM

while true; do
    show_now
    sleep ${POLL_FREQUENCY}
done
