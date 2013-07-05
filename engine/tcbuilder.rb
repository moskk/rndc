require './engine/rndcbase.rb'

def between(str, l, r)
  il = str.index l
  return nil if il.nil?
  ir = str.index r, il+1
  return nil if ir.nil?
  return str[il+1..ir-1]
end

:nopas
:toall
:toany
:paser
def pass_dict()
  passh = {'>'=>:toall,'?'=>:toany, nil=>:nopas}
  passh.default = :paser
  return passh
end

# squize empty spaces in code lines except ones in string values
def code_squize(str)
  s1 = str.split ''
  s2 = ''
  sqflag, dqflag, spaceflag = false, false, false
  s1.each do |c|
    case c
    when ' ', "\t"
      if not spaceflag
        spaceflag = true
      elsif not (sqflag or dqflag)
        next
      end
    when "\'"
      sqflag = (not sqflag) if not dqflag
    when "\""
      dqflag = (not dqflag) if not sqflag
    else
      spaceflag = false
    end
    
    s2 << c
  end
  return s2
end

class NodeDescription
  attr_reader :source
  attr_accessor :tag
  attr_accessor :order_num
  attr_reader :nodetype
  attr_reader :inverted
  attr_reader :param
  attr_reader :count
  attr_reader :passtype
  attr_reader :receivers
  attr_reader :nreceivers
  attr_reader :valid
  attr_reader :error

  def parse(descr, print = false)
    @source = descr.clone

    if descr[0] == '#'
      if descr.length > 1 and descr[1] == '>'
        puts descr[2..-1]
      end
      @nodetype = nil
      @valid = true
      return true
    end

    # string preparation
    descr.chomp!
=begin
    descr.gsub! ' ',''
    descr.gsub! "\t",''
=end
    descr = code_squize descr
    puts " >> #{descr}" if print 

   # tag
    ilpar = descr.index '('
    ilpar ||= 0
    @tag = descr[0, ilpar]
    #puts "tag #{tag}"

    # operation
    irpar = descr.rindex ')'
    oper = between descr,'(',')'
    #puts "oper #{oper}        #{ilpar} #{irpar}"
    if oper.nil?
      @error = "no operation performed: #{oper}"
      return false
    end

    # passtype
    pass = descr[irpar+1]
    @passtype = pass_dict[pass]
    if @passtype == :paser
      @error = "unrecognized passing type #{pass}"
      return false
    end
    #puts "pass #{passtype}"

    #receivers
    rclist = descr[irpar+2..-1]
    rclist ||= ''
    rc_clust = rclist.split ':'
    rc_clust ||= []
    #puts "rc_clust #{rc_clust.inspect}"
    if rc_clust.empty?
      #no receivers
    elsif rc_clust.size <= 2
      @receivers = rc_clust.fetch(0, '').split(',')
      @receivers.delete ''
      @nreceivers = rc_clust.fetch(1, '').split(',')
      @nreceivers.delete ''
      #puts " r#{@receivers}"
      @receivers.each do |rec|
        if rec =~ /\W/ and rec != "#"
          @error = "invalid tag name #{rec}. allowed symbols: a-zA-Z0-9_ or '#'"
          return false
        end
      end
      #puts "nr#{@nreceivers}"
      @nreceivers.each do |rec|
        if rec =~ /\W/ and rec != "#"
          @error = "invalid tag name #{rec}. allowed symbols: a-zA-Z0-9_ or '#'"
          return false
        end
      end
    else
      @error = "invalid receivers list \"#{rclist}\""
      return false
    end
    #puts "receivers #{receivers}"
    while not ( oper.nil? or oper.empty?)
      #puts "--------#{oper[0]}"
      case oper[0]
      when /\w/
        @nodetype = oper.slice!(/\w*/)
        #puts "nodetype #{nodetype} => #{oper}"
      when '|'
        t = oper.slice!(/\|.*\|/)
        @param = between t,'|','|'
        #print "param ", param, " => ", oper, "\n"
      when '['
        t = oper.slice!(/\[.*\]/)
        t = between(t,'[',']')
        if not t =~ /\d+/
          @error = "count must be an integer, but '#{t}' is not looking such"
          return false
        end
        @count = t.to_i
        #puts "count #{count} => #{oper}"
      when '+'
        oper.slice!(/./)
        @inverted = false
        #puts "inverted #{inverted} => #{oper}"
      when '-'
        oper.slice!(/./)
        @inverted = true
        #puts "inverted #{inverted} => #{oper}"
      else
        @error = "unexpected symbol in operation definition: #{oper[0]}"
        return false
      end
    end
    @valid = true
    @error = 'no error'
    return true
  end

  def initialize(descr, print)
    @source = ''             # source script line
    @tag = ''                # reference name for this node
    @nodetype = ''           # performed operation
    @inverted = false        # would filter decision be inverted
    @param = ''              # node operation parameter (if is)
    @count = 1               # count of actors in node
    @passtype = :nopas       # how to pass operation result (to all, to any, not pass)
    @receivers = []          # list of nodes that receive successfull operation result
    @nreceivers = []         # list of nodes that receive failed operation result
    @valid = false
    @error = ''
    @order_num = -1

    parse(descr, print)
  end
end

# tool chain builder
$n = [HostsUpSrc, PrintFlt, OperaOpener, PortCheckFlt, TextFilter, 
    PageCodeTextFilter, RespCodeFlt, PageTitleFlt, IpFileSaverFlt, 
    ConditionalFlt, PageGraber, ReverseDnsFlt, Delayer, DebugSource, 
    MailerFlt, IceweaselOpener]

# script executing engine
class TCBuilder

  @nodemap = {}
  @nodes_descr = {}
  @nodes_queue = {}
  @nodes = {}
  @valid = false
  @log = []

  attr_reader :valid
  attr_reader :log

  def initialize(script_file, run = true, print_code = false)
    @nodemap = {}
    @nodes_descr = {}
    @nodes_queue = {}
    @nodes = {}
    @valid = false
    @log = []
    @threads = []
    @print_code = print_code
    $n.each do |node|
      @nodemap[node.opname] = node
    end

    @log << "loading script file \"#{script_file}\"..."
    if load_script script_file
      @log << "script \"#{script_file}\" loaded"
    else
      @log << "script \"#{script_file}\" NOT loaded due some errors"
      return false
    end

    if not run
      @log << "dry run completed"
      return true
    end
    
    if start_script
      @log << "script \"#{script_file}\" started"
    else
      @log << "script \"#{script_file}\" NOT started due some errors"
      return false
    end

    return true
  end

  def load_script(script_file)
    # parsing script
    script = file_lines script_file
    fail = false
    #puts script
    def_tag = 'unnamed_node:aaaa'
    script.each do |line|
      node = NodeDescription.new line, @print_code
      if not node.valid
        err = "syntax error in line \"#{line}\": #{node.error}"
        @log << err
        fail = true
        next
      end

      if not node.nodetype.nil?
        if node.tag.empty? or node.tag.nil?
          node.tag = def_tag.succ!
        end
        if @nodes_descr.include? node.tag
          err = "node named \"#{node.tag}\" allredy defined before. redefinition in line \"#{node.source}\""
          @log << err
          fail = true
          next
        end
        @nodes_descr[node.tag] = node
        node.order_num = @nodes_queue.size
        @nodes_queue[node.order_num] = node.tag
      end
    end

    return false if fail
    
    #p @nodes_queue

    # checking for valid node action names and tags
    @nodes_descr.each_value do |node|
      if not @nodemap.include? node.nodetype
        err = "undefined action type \"#{node.nodetype}\" referenced in line \"#{node.source}\""
        @log << err
        fail = true
      end
      
      node.receivers.each_index do |i|
        if node.receivers[i] == '#'
          node.receivers[i] = @nodes_queue.fetch(node.order_num+1, nil)
        end
      end
      
      node.nreceivers.each_index do |i|
        if node.nreceivers[i] == '#'
          node.nreceivers[i] = @nodes_queue.fetch(node.order_num+1, nil)
        end
      end

      node.receivers.delete nil
      node.nreceivers.delete nil
      
      #puts "#{node.order_num}\t+#{node.receivers}-#{node.nreceivers}"

      reflist = []
      reflist.push *node.receivers
      reflist.push *node.nreceivers
      reflist.each do |totag|
        if not @nodes_descr.include? totag
          err = "no nodes tagged as \"#{totag}\" found in script, but one is referenced in line: \"#{node.source}\""
          @log << err
          fail = true
        end
      end
    end

    return false if fail
    return true
  end

  def start_script()
    # creating node actors
    @nodes_descr.each_pair do |tag, node|
      #param = eval node.param
      param = eval "[#{node.param}]"
      #p param
      @nodes[tag] ||= []
      1.upto node.count do
        newnode = @nodemap[node.nodetype].new([], [], (node.passtype == :toall), param)
        newnode.invert = node.inverted
        @nodes[tag] << newnode
      end
    end

    # adding node receivers
    @nodes_descr.each_pair do |tag, node_descr|
      #puts "---#{node_descr.receivers.inspect}-#{node_descr.nreceivers.inspect}"
      node_descr.receivers.each do |receiver|
        @nodes[tag].each do |node|
          node.add_rcv @nodes[receiver]
        end
      end
      node_descr.nreceivers.each do |nreceiver|
        @nodes[tag].each do |node|
          node.add_nrcv @nodes[nreceiver]
        end
      end
    end
    
    # checking for chain integrity
    @nodes.each_pair do |tag, nodelist|
      if nodelist.empty?
        @log << "WARNING: node \"#{tag}\" has no actors. is it ok?"
        next
      end
      if nodelist[0].cust_list.empty?
        @log << "WARNING: node \"#{tag}\" has no consumers, so its all jobs will be suppressed. is it ok?"
      end
    end
    
    # starting nodes
    @nodes.each_value do |nodelist|
      nodelist.each do |node|
        node.start
        @threads << node.thread
      end
    end
    
    @log << ''
    @valid = true

    return true
  end

  def stop_script()
    @nodes.each_value do |nodelist|
      nodelist.each do node
        node.stop
      end
    end
  end
  
  def join()
    return if @threads.empty?
    while true
      @threads.each do |th|
        if th.alive?
          sleep 0.5
          next
        end
        return true
      end
    end
  end
end

















