#!/bin/sh
BLINK1_TOOL=`which blink1-tool`
SLEEP="sleep .5" # seconds
FADE="-m $(echo 10+\(300/12\) | bc)" # milliseconds

function led()
{
    num=`echo ${1}+${2} | bc`
    if [ ${num} -gt 14 ]; then
        num=`echo ${num}-12 | bc`
    fi
    echo ${num}
}

function set_half()
{
    ${BLINK1_TOOL} --red -l $(led ${1} 0) ${FADE}
    ${BLINK1_TOOL} --yellow -l $(led ${1} 1) ${FADE}
    ${BLINK1_TOOL} --green -l $(led ${1} 2) ${FADE}
    ${BLINK1_TOOL} --cyan -l $(led ${1} 3) ${FADE}
    ${BLINK1_TOOL} --blue -l $(led ${1} 4) ${FADE}
    ${BLINK1_TOOL} --magenta -l $(led ${1} 5) ${FADE}
}

function set_from()
{
    set_half ${1}
    set_half `echo ${1}+6 | bc`
}

for ((i=0; i<40; i++ )) ; do
    for ((j=3; j<14; j++ )) ; do
        set_from $j
        $SLEEP
    done
done
