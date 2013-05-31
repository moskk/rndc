#!/usr/bin/env ruby
require './tcbuilder.rb'
require 'optparse'

def print_man()
  cmdman = {}
  cmdman['-n'] = "\tdry run, just check script for syntax"
  cmdman['-f <filename>'] = "script file"
  cmdman['-h'] = "\tthis manual"
  cmdman['-hh'] = "\tthis manual and script function list"
  cmdman['-hhh'] = "\tthis manual and script function list with descriptions"

  puts "command line options:"
  cmdman.each_pair do |key, value|
    puts "#{key}\t#{value}"
  end
end

if ARGV.include? '-h' or ARGV.empty?
  print_man
  exit
elsif ARGV.include? '-hh'
  print_man
  puts "\nTCBuilder alloved actions:"
  $n.each do |node|
    puts "= #{node.opname}"
  end
  exit
elsif ARGV.include? '-hhh'
  print_man
  puts "\nTCBuilder alloved actions:"
  $n.each do |node|
    puts "= #{node.opname} - #{node.descr}"
  end
  exit
end

run = true
if ARGV.include? '-n'
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

tcb = TCBuilder.new './discover.script', run
puts tcb.log
tcb.join












