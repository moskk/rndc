#!/usr/bin/env ruby
require './tcbuilder.rb'
require 'optparse'

if ARGV.include? '-h' or ARGV.empty?
  cmdman = {}
  cmdman['-n'] = "\tdry run, just check script for syntax"
  cmdman['-f <filename>'] = "script file"
  cmdman['-h'] = "\tthis manual"

  puts "command line options:"
  cmdman.each_pair do |key, value|
    puts "\t#{key}\t#{value}"
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
  puts "ERROR: script file not specified"
  exit
elsif not File.exists? ARGV[fi+1]
  puts "ERROR: script file \"#{ARGV[fi+1]}\" does not exist"
else
  file = ARGV[fi+1]
end

tcb = TCBuilder.new './discover.script', run
puts tcb.log
tcb.join












