#!/usr/bin/env ruby
=begin
puts code_squize("1 1  1   1    't\t2  2  \"1 3   3   1 1 \"3   4    1 6       3   t\t4    5     '1    \"3   '||2  3   5     t\t0'\"")
exit
=end

require 'optparse'

def usage()
  "#{__FILE__} [OPTIONS] <filename>"
end

def man_hash()
  cmdman = {}
  #cmdman['-f'] = " <script file> specifying script file"
  cmdman['-n'] = "\tdry run, just check script for syntax"
  cmdman['-t'] = "\tprint time stamps in tracing lines"
  cmdman['-c'] = "\tprint squized script code on start"
  cmdman['-r'] = "\trestart script on critical runtime error or on finish"
  cmdman['-l'] = "\tenable job trace logging"
  #cmdman['-h'] = "\tthis manual"
  cmdman['-h'] = "\tthis manual and script function list"
  cmdman['-hh'] = "\tthis manual and script function list with descriptions"
  return cmdman
end

def print_man()
  puts "basic usage: #{usage}"
  puts "command line OPTIONS:"
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

require './engine/tcbuilder.rb'
load_node_classes

args = parse_args

$logging = false

opts = "\ntool chain builder alloved actions:"
if args['hh']
  print_man
  puts opts
  $node_classes.each do |node|
    puts "= #{node.opname} - #{node.descr}"
  end
  exit
elsif args['h']
  print_man
  puts opts
  $node_classes.each do |node|
    puts "= #{node.opname}"
  end
  exit
elsif ARGV.empty?
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

restart = false
if args['r']
  restart = true
end

file = ARGV.last
if ARGV.size == 0
  puts "ERROR: script file not specified, use #{usage}"
  exit
elsif not File.exists? file
  puts "ERROR: script file \"#{file}\" does not exist"
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
  if not run
    break
  elsif restart
    puts "SCRIPT RESTART"
  else
    puts "script #{file} successfully finished"
    break
  end
end


