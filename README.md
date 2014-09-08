#Authlog-parser

The fastes way to read your authentication log files.
Distributed under the MIT license

Usage: authlog-parser [options] sourcefile  
NOTE: if no file is given /var/log/auth.log is used.  
Options:  
    -o, --output filename            Name of the output file  
    -a, --append                     Appends the results to the file  
    -m, --mode [all|accepted|failed] Show all (default), only accepted or only failed requests  
    -v, --version                    Show version  
    -h, --help                       Displays Help  
