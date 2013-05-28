require './rndc.rb'

##########################################
#        E N T R Y   P O I N T
#       definition of toolchain
##########################################

oo = OperaOpener.new []

# fsflt = IpFileSaverFlt.new [], './result.list'

tctd = PageCodeTextFilter.new [oo], './denied.words'

condflt = ConditionalFlt.new [tctd], '.text.length > 0'

ptflt = PageTitleFlt.new [condflt], './denied.titles'

cflt = RespCodeFlt.new [ptflt], [200]

pg = PageGraber.new [cflt]
printer = PrintFlt.new [], 'p80 ok: '

hups_list = []
1.upto 100 do
  hups_list.push PortCheckFlt.new [printer, pg], [80]
end

1.upto 50 do
  HostsUpSrc.new hups_list, false
end

puts '-------------S T A R T E D----------------'

gets 
