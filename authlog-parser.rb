#!/usr/bin/ruby

#  
#  name: authlog-parser 1.2
#  author: Giuseppe Pagano <giuseppe.pagano.p@gmail.com>
#  
#  The MIT License (MIT)
#
#  Copyright (c) 2014 Giuseppe Pagano
#  
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#  
#  The above copyright notice and this permission notice shall be included in all
#  copies or substantial portions of the Software.
#  
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.
#

# Opening String class to add colors for console output
class String
def red;            "\033[31m#{self}\033[0m" end
def green;          "\033[32m#{self}\033[0m" end
def cyan;           "\033[36m#{self}\033[0m" end
def bold;           "\033[1m#{self}\033[22m" end
end

require 'optparse' # OptionParse class is required to parse options

# Mode constnts
ALL = 0
ACCEPTED = 1
FAILED = 2

# Options hash
options = {fileOut: nil, append: false, mode: ALL}

# Default auth.log file
defaultPath = "/var/log/auth.log"

# Sandwich method used for file handling
def use_file(filename, mode)
	open(filename, mode) do |file|
		yield(file)
	end
end

parser = OptionParser.new do|opts|
	opts.banner = "Utility to parse authentication linux logs"
	opts.banner += " to have a better viev of accesses.\nUsage: authlog-parser [options] sourcefile"
	opts.banner += "\nNOTE: if no file is given /var/log/auth.log is used.\nOptions:"

	opts.on('-o', '--output filename', 'Name of the output file') do |name|
		options[:fileOut] = name;
	end

	opts.on('-a', '--append', 'Appends the results to the file') do
		options[:append] = true;
	end

	opts.on('-m', '--mode [all|accepted|failed]', 'Show all (default), only accepted or only failed requests') do |mode|
		case mode
		when "all"
			options[:mode] = ALL
		when "accepted"
			options[:mode] = ACCEPTED
		when "failed"
			options[:mode] = FAILED
		else
			puts "Mode #{mode} not valid. Selecting all the entries."
		end
	end

	opts.on('-v', '--version', 'Show version') do
		puts "authlog-parser v 1.2"
		exit
	end

	opts.on('-h', '--help', 'Displays Help') do
		puts opts
		exit
	end
end

begin
	parser.parse!
rescue
	# Rescue if there is an unknown option, prints and error message then exits
	puts "unknown option!".red
	puts parser.help
	exit
end

fileIn = ARGV[0]
if fileIn == nil
	if File.exist?(defaultPath) 
		puts "Using default path at #{defaultPath}"
		fileIn = defaultPath
	else
		puts "No input file given. Exiting.".red
		exit
	end
end

# This regex captures the date, the state, the username used and the ip
# from wich the request has been made.
# For instance, from this string:
# Sep  8 18:05:58 giuse sshd[8494]: Accepted password for giuse from 127.0.0.1 port 49776 ssh2
#
# These groups are capured:
# 1. Sep  8 18:05:58
# 2. Accepted
# 3. giuse
# 4. 127.0.0.1
#
# Wich are arranged in this way:
# On: Sep  8 18:05:58   state: Accepted   with: giuse   from:  127.0.0.1
#
REGEX = /([\w]{3}\ ?\ \d{1,2}\ \d{2}:\d{2}:\d{2}) .+\: (Failed|Accepted|refused).*( [\w-]+) from( [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/
newlog = Array.new
use_file(fileIn, 'r') do |file|
	while line = file.gets
		match = line.match(REGEX)
		if( match == nil)
			next
		end
		groups = match.captures
		if(options[:mode] == ACCEPTED && groups[1] == "Accepted")
			newlog.push "On: "+groups[0]+"  state: "+groups[1].green.bold+"   with: "+groups[2].cyan.bold+"   from: "+groups[3]
		elsif(options[:mode] == FAILED && (groups[1] == "Failed" || groups[1] == "refused"))
			if groups[1] == "Failed"
				newlog.push "On: "+groups[0]+"  state: "+groups[1].red.bold+"   with: "+groups[2].cyan.bold+"   from: "+groups[3]
			else
				newlog.push "On: "+groups[0]+"  state: "+groups[1].red.bold+"  from: "+groups[3]
			end
		elsif(options[:mode] == ALL)
			if(groups[1] == "Accepted")
				newlog.push "On: "+groups[0]+"  state: "+groups[1].green.bold+"   with: "+groups[2].cyan.bold+"   from: "+groups[3]
			elsif groups[1] == "refused"
				newlog.push "On: "+groups[0]+"  state: "+groups[1].red.bold+"  from: "+groups[3]
			else
				newlog.push "On: "+groups[0]+"  state: "+groups[1].red.bold+"   with: "+groups[2].cyan.bold+"   from: "+groups[3]
			end
		end
		
	end
end

if options[:fileOut] == nil
	# If no file is given for output
	# prints the output on screen
	newlog.each do |elem|
		puts elem
	end
else
	mode = options[:append] ? 'a' : 'w'
	use_file(options[:fileOut], mode) do |file|
		newlog.each do |elem|
			file.write("#{elem}\n")
		end
	end
end
