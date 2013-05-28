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

def pass_dict()
  passh = {'>'=>:toall,'?'=>:toany}
  passh.default = :nopas
  return passh
end

:nopas
:toall
:toany
class NodeDescription
  @tag = ''
  @nodetype = ''
  @param = ''
  @count = 1
  @passtype = :nopas
  @receivers = []

  attr_accessor :tag
  attr_accessor :nodetype
  attr_accessor :param
  attr_accessor :passtype
  attr_accessor :receivers

  def parse(descr)
    # string preparation
    descr.chomp!
    descr.gsub! ' ',''
    descr.gsub! '\t',''
    puts descr

    # tag
    ilpar = descr.index '('
    ilpar ||= 0
    @tag = descr[0, ilpar]
    puts "tag #{@tag}"

    # operation
    irpar = descr.index ')'
    #oper = descr[ilpar+1, irpar-2]
    oper = between descr,'(',')'
    #puts "oper #{oper}        #{ilpar} #{irpar}"

    # passtype
    @passtype = pass_dict[descr[irpar+1]]
    puts "pass #{@passtype}"

    #receivers
    rclist = descr[irpar+2..-1]
    rclist ||= ''
    @receivers = rclist.split ','
    puts "receivers #{@receivers}"

    # parsing operation
    @param = between oper,'{','}'
    puts "param #{@param}"
    @count = between(oper,'[',']').to_i
    puts "count #{@count}"
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




NodeDescription.new 'ddgdfgfd(print{45}[4]-)'




