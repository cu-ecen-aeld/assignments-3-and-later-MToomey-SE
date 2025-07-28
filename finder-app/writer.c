#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <syslog.h>


int main(int argc, char**argv)
{
    int current_errno;
    
    openlog(NULL, 0, LOG_USER);
    
//    printf("argc == %d\n", argc);
    if (argc != 3)
    {
        printf("Error - missing arguments\n");
        printf("Usage: %s <write file name> <write string>\n", argv[0]);        
        syslog(LOG_ERR, "Error - 2 arguments required. Argument count is %d\n", argc);
        exit(1);
    }
    const char *writeFileName = &(argv[1][0]);
    const char *writeFileData = &(argv[2][0]);
//    call fopen(), handle return value
//    send to log if required

//    printf("File name argument is %s\n",  writeFileName);
//    printf("File data argument is %s\n",  writeFileData);
//    printf("Sizeof write data %s is %ld\n", writeFileData, strlen(writeFileData));
    
    FILE *file = fopen(writeFileName, "w");  // Open file for writing
    current_errno = errno;    
//    perror("Error opening file");
//    printf("errno = %d\n", current_errno);
    if (file == NULL)
    {
//        perror("Error opening file");
        syslog(LOG_ERR, "Error - could not open file to write, error is : %s\n", strerror(current_errno));
        printf("Error - could not open file to write, error is : %s\n", strerror(current_errno));
        exit(1);
    }

    int numBytesWritten = fprintf(file, "%s", writeFileData);
    current_errno = errno;    
 //   printf("numBytesWritten = %d\n", numBytesWritten);
    if (numBytesWritten == 0)
    {
        syslog(LOG_ERR, "Error - could write to file, error is : %s\n", strerror(current_errno));    
        printf("Error - number of bytes written to file is 0, error is : %s\n", strerror(current_errno));    
    }
    else
    {
        syslog(LOG_DEBUG, "Writing %s to %s\n", writeFileData, writeFileName);
    }
    
}
