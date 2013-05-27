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

:toall
:toany
class NodeDescription
  @tag = ''
  @nodetype = ''
  @param = ''
  @passtype = :toall
  @receivers = []
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
