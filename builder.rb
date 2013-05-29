require './rndc.rb'

# node container for tool chain builder
class NodePool
  @nodes = []

  def add(nodelist)
    nodelist.each do |node| @nodes << node end
  end

  def start()
    @nodes.each do |node| node.start end
  end

  def stop()
    @nodes.each do |node| node.stop end
  end
end

def between(str, l, r)
  il = str.index l
  return nil if il.nil?
  ir = str.index r, il
  return nil if ir.nil?
  return str[il+1..ir-1]
end

:nopas
:toall
:toany
:paser
def pass_dict()
  passh = {'>'=>:toall,'?'=>:toany,nil=>:nopas}
  passh.default = :paser
  return passh
end

class NodeDescription
  @tag = ''                # reference name for this node
  @nodetype = ''           # performed operation
  @inverted = false        # would filter decision be inverted
  @param = ''              # node operation parameter (if is)
  @count = 1               # count of actors in node
  @passtype = :nopas       # how to pass operation result (to all, to any, not pass)
  @receivers = []          # list of nodes that receive operation result
  @valid = false
  @error = ''

  attr_accessor :tag
  attr_accessor :nodetype
  attr_accessor :inverted
  attr_accessor :param
  attr_accessor :count
  attr_accessor :passtype
  attr_accessor :receivers
  attr_accessor :valid
  attr_accessor :error

  def parse(descr)
    # string preparation
    descr.chomp!
    descr.gsub! ' ',''
    descr.gsub! "\t",''
    puts descr

    # tag
    ilpar = descr.index '('
    ilpar ||= 0
    @tag = descr[0, ilpar]
    puts "tag #{tag}"

    # operation
    irpar = descr.index ')'
    oper = between descr,'(',')'
    puts "oper #{oper}        #{ilpar} #{irpar}"
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
    puts "pass #{passtype}"

    #receivers
    rclist = descr[irpar+2..-1]
    rclist ||= ''
    @receivers = rclist.split ','
    @receivers.delete ''
    puts "receivers #{receivers}"

=begin
    # parsing operation
    @param = between oper,'{','}'
    puts "param #{param}"
    @count = between(oper,'[',']').to_i
    puts "count #{count}"
    @nodetype = oper[/\w*/]
    puts "nodetype #{nodetype}"
    @inverted = (oper[-1] == '-')
    puts "inverted #{inverted}"
=end

    @valid = true
    @error = 'no error'
    puts error
    return true
  end

  def initialize(descr)
    parse(descr)
  end
end

class TCBuilder
  @@n = [HostsUpSrc, PrintFlt, PortCheckFlt, TextFilter, PageCodeTextFilter, RespCodeFlt, PageTitleFlt, IpFileSaverFlt, ConditionalFlt, PageGraber]

  @nodemap = {}

  def initialize()
    @@n.each do |node| @nodemap[node.name] = node end
  end

  def exec(cmdlist)
    
  end
end




node = NodeDescription.new 'prt(print[4]{45}-)?dsf'
if not node.valid
  puts node.error
end


