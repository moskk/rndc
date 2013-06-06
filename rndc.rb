#!/usr/bin/env ruby
require './tcbuilder.rb'
require 'optparse'

def man_hash()
  cmdman = {}
  cmdman['-n'] = "\tdry run, just check script for syntax"
  cmdman['-t'] = "\tprint time stamps in tracing lines"
  cmdman['-f'] = " <script file> "
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
args = parse_args
if args['hhh']
  print_man
  puts "\ntool chain builder alloved actions:"
  $n.each do |node|
    puts "= #{node.opname} - #{node.descr}"
  end
  exit
elsif args['hh']
  print_man
  puts "\ntool chain builder alloved actions:"
  $n.each_value do |node|
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

tcb = TCBuilder.new file, run
puts tcb.log

if args['-t']
  module Kernel
    def puts (*params)
      print Time.now.to_s.split(' ')[1], ' '
      params.each do |param| print param end
      print "\n"
    end
  end
end

tcb.join












