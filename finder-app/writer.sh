ArgWriteFileOk=0
ArgWriteDirectoryOk=0
ArgCountOk=0
fileExists=0
fileIsDirectory=0

if [ $# -ge 1 ]
then
    writeFileName=$1
    if [ -f $writeFileName ]
    then
        # File exists, is not a directory    
        fileExists=1
        fileIsDirectory=0
        writeFileDirectory="$(dirname $writeFileName)"
    else
        if [ -d $writeFileName ]
        then
            # File is a directory
            fileExists=0
            fileIsDirectory=1
            writeFileDirectory=$writeFileName
            
        else
            # File and directory don't exist
            fileExists=0
            fileIsDirectory=0
            writeFileDirectory="$(dirname $writeFileName)"
        fi
    fi

    if [ $# -eq 2 ]
    then
        ArgCountOk=1
        inputText=$2
    fi

    if [ $fileIsDirectory -eq 0 ]
    then
        if ! [ -d $writeFileDirectory ]
        then 
            # directory not exist, try to create it
            mkdir -p $writeFileDirectory
        fi
        if [ -d $writeFileDirectory ]
        then
            echo directory $writeFileDirectory is ok
            ArgWriteDirectoryOk=1
        fi
    
        if [ $ArgWriteDirectoryOk -eq 1 ]
        then
            # Try to access/create the file
            touch $writeFileName
            if [ $? -eq 0 ]
            then
                ArgWriteFileOk=1
            fi
        fi
    fi    
fi

if [ $ArgWriteFileOk -eq 1 ] && [ $ArgWriteDirectoryOk -eq 1 ] && [ $ArgCountOk -eq 1 ]
then
    # Write to the file
    echo $2 > $writeFileName 
else
    echo "Error(s):"
    if [ $ArgCountOk -ne 1 ]
    then
        echo "  Missing argument(s)"
    fi
    if [ $# -ge 1 ]
    then
        if [ $fileIsDirectory -eq 1 ]
        then
            echo "  $writeFileName is a directory - it must be a file"	
        else
            if [ $ArgWriteDirectoryOk -ne 1 ]
            then
                echo "  Unable to create directory"
            fi
            if [ $ArgWriteFileOk -ne 1 ]
            then
                echo "  Unable to create file"
            fi
        fi
    fi        
    echo "  Usage: $0 <write file name> <write string>"        
    exit 1
fi
