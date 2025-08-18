#!/bin/sh
ArgDirectoryOk=0
ArgCountOk=0

if [ $# -ge 1 ]
then
    if [ -d $1 ]
    then
    ArgDirectoryOk=1
    fi
fi


if [ $# -eq 2 ]
then
    ArgCountOk=1
fi

if [ $ArgCountOk -eq 1 ] && [ $ArgDirectoryOk -eq 1 ] 
then
    filesdir=$1
    searchstr=$2
    filescount=$(find "$filesdir" -type f | wc -l)

    searchall="${filesdir}/*"
    match_count=$(grep -r $searchstr $searchall  | wc -l)            
    echo The number of files are $filescount and the number of matching lines are $match_count
else
    echo "Error(s):"
    if [ $ArgCountOk -ne 1 ]
    then
        echo "  Missing argument(s)"
    fi
    
    if [ $ArgDirectoryOk -ne 1 ]
    then
        if [ $# -ge 1 ]
        then
            echo "  Search path not found: $1"
        fi    
    fi

    echo "Usage: $0 <search path> <search string>"        
    exit 1
fi
    

