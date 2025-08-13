#include "systemcalls.h"
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>
#include <fcntl.h>      // For open() and O_* constants
#include <sys/types.h>  // For mode_t and other types
#include <sys/stat.h>   // For file permission constants
#include <unistd.h>     // For close(), read(), write()
#include <errno.h>


/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

/*
 * TODO  add your code here
 *  Call the system() function with the command set in the cmd
 *   and return a boolean true if the system() call completed with success
 *   or false() if it returned a failure
*/
    bool ret_val = true;
    int system_return = system(cmd);
    if (system_return == -1)
    {
        ret_val = false;
    }

    return (ret_val);
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;

    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
//    command[count] = command[count];

/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/
//    fflush(stdout);
    pid_t pid = fork();

    if (pid ==  -1) 
    {
        return false;
    }
     
    if (pid == 0) 
    {
//        printf("This is the child process. PID: %d\n", getpid());
        int execv_status = execv(command[0], command);

        if (execv_status < 0)
        {
            perror("execv failed");	
            exit(errno);
        }
    }

    int status;
    pid_t child_pid = wait(&status);
    child_pid = child_pid;        
//        printf("After wait(), child_pid = %d, raw status = %d\n", child_pid, status);
    if (WIFEXITED(status)) 
    {
        int exit_status = WEXITSTATUS(status);
        if (exit_status != 0)
        {
            return false;
        }
            
    }
    else        
    {
        return false;
    }
    va_end(args);
    return true;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];


/*
 * TODO
 *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
 *   redirect standard out to a file specified by outputfile.
 *   The rest of the behaviour is same as do_exec()
 *
*/
    int fd = open(outputfile, O_WRONLY|O_TRUNC|O_CREAT, 0644);
    if (fd == -1) 
    {
//        printf("Open file failed: %s\n", outputfile);     
        perror("open"); 
        return false;
    }
//    fflush(stdout);
    pid_t pid = fork();

//    printf("Fork pid = %d\n", pid);
    if (pid == -1) 
    {
        return false;
    } 
    if (pid == 0) 
    {
        if (dup2(fd, 1) == -1) 
        { 
            perror("dup2");
            return false;
        }
            
        int execv_status = execv(command[0], command);

        // Only reached if execv fails
        execv_status = execv_status;
        if (execv_status == -1)
        {
            return false;
        }

    }

    int status;
    pid_t child_pid = wait(&status);
    if (child_pid == -1)
    {
        return false;
    }
    else
    {
        if (WIFEXITED(status)) 
        {
            int exit_status = WEXITSTATUS(status);
            if (exit_status != 0)
            {
                return WEXITSTATUS(status);
           }
        }
    }

    va_end(args);

    return true;
}


