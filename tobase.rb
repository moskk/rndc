#!/usr/bin/env ruby
path = ARGV[0]
if not File.exist? path
  print "file not found: #{path}"
  exit
end

all_cites = []
how_much = 10

file = File.open(path, "r"){ |file|
    file.each do |line|
        all_cites << line
    end
}
if all_cites.size == 0
	puts "no addreses left :("
	exit 
end

how_much = all_cites.size if how_much > all_cites.size

1.upto(how_much) do
    system("opera -newtab #{all_cites.shift}")
    sleep 0.1
end

file = File.open(path, "w"){ |file|
    all_cites.each do |line|
        file.puts line
    end
}

puts "#{all_cites.size} addreses left"

