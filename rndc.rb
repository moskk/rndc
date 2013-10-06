#!/usr/bin/env ruby
require './engine/tcbuilder.rb'

=begin
puts code_squize("1 1  1   1    't\t2  2  \"1 3   3   1 1 \"3   4    1 6       3   t\t4    5     '1    \"3   '||2  3   5     t\t0'\"")
exit
=end

require 'optparse'

def man_hash()
  cmdman = {}
  cmdman['-f'] = " <script file> specifying script file"
  cmdman['-n'] = "\tdry run, just check script for syntax"
  cmdman['-t'] = "\tprint time stamps in tracing lines"
  cmdman['-c'] = "\tprint squized script code on start"
  cmdman['-r'] = "\trestart script on critical runtime error or on finish"
  cmdman['-l'] = "\tenable job trace logging"
  cmdman['-h'] = "\tthis manual"
  cmdman['-hh'] = "\tthis manual and script function list"
  cmdman['-hhh'] = "\tthis manual and script function list with descriptions"
  return cmdman
end

def print_man()
  puts "command line options:"
  cmdman = man_hash
  cmdman.each_pair do |key, value|
    puts "#{key}\t#{value}"
  end
end

def parse_args
  cmdman = man_hash
  args = ''
  ARGV.each do |arg|
    if arg[0] == '-' 
      args << arg[1..-1]
    end
  end
  return args
end

#####################################
#       E N T R Y   P O I N T
#####################################
puts "\nsee https://github.com/moskk/rndc for more information and newest versions\n\n"

load_node_classes

args = parse_args

$logging = false

if args['hhh']
  print_man
  puts "\ntool chain builder alloved actions:"
  $node_classes.each do |node|
    puts "= #{node.opname} - #{node.descr}"
  end
  exit
elsif args['hh']
  print_man
  puts "\ntool chain builder alloved actions:"
  $node_classes.each do |node|
    puts "= #{node.opname}"
  end
  exit
elsif args['h'] or args.empty?
  print_man
  exit
end

run = true
if args['n']
  run = false
end

print_code = false
if args['c']
  print_code = true
end

fi = ARGV.index '-f'
file = ''
if fi.nil? or ARGV[fi+1].nil?
  puts "ERROR: script file not specified, use -f <filename>"
  exit
elsif not File.exists? ARGV[fi+1]
  puts "ERROR: script file \"#{ARGV[fi+1]}\" does not exist"
else
  file = ARGV[fi+1]
end

if args['l']
  $logging = true
end


while true do
  begin
    tcb = TCBuilder.new file, run, print_code
    puts tcb.log
    
    if not tcb.valid
      break
    end

    if args['t']
      module Kernel
        def puts (*params)
          print Time.now.to_s.split(' ')[1], ' '
          params.each do |param| print param end
          print "\n"
        end
      end
    end
    tcb.join
  rescue Exception => e
      puts "CRITICAL ERROR"
      print_error e
  end
  #puts args
  tcb.stop
  if args['r'].nil?
   puts "script #{file} successfully finished"
  break
  else
     puts "SCRIPT RESTART"
  end
end


