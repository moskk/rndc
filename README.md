## DESCRIPTION
well, **rndc** is a multipurpose web-tool. currenly it can discover 
network hosts, scan ports, download pages, filter server responces by some 
properties (server responce code, page code/text content, page title), perform 
reverse DNS lookup and give away host info into text file or into browser. 
it also provides to you a convinient interface to build pipelines for processing 
results and thus allows you to create branchy logics for hosts and pages exploration.

you can't rob the caravans yet but this option is on develop. so you can 
try to search some caravans, lol.

## DEPENDENCIES
**rndc** depends of following gems:
  * nokogiri
  * net-ping
  * [mail](https://github.com/mikel/mail)

## USAGE
### Basic
**rndc** provides you a set of tools which can be linked into chains (pipelines). every 
node of this chain may have one of those types:
  * *source* that generates some job. this job contains some data
  that will used by other nodes (it is usually an IP address or a domain name).
  * *filter* that pass (or not) the job for enother node depending on some condition
  * *transformer* that transforms the job into something enother (actualy job too). 
  for example, it can download page or perform DNS query.

to use **rndc** you can:
  * manualy use classes defined in *engine/rndcbase.rb* to create tool chains **OR**
  * use special building tool (TCBuilder). just write a script file and pass it to **rndc.rb** after **-f** key. 

### Tool chain builder scripting
TCBuilder (tool chain builder) script consists of node descriptions. in fact 
it is definition of directed graph that's every vertex (node) 
performing some operation on jobs and have a list of nodes that will receive 
(or not) this job after operation is done. this descriptions are looks like this:
`tag (operation|parameter|[quantity]inverter) passtype receiver1,...,receiverN : nreceiver1,...,nreceiverM`

looks terrible, but it's pretty simple. just read on.
*tag* is a name of node. it is used for node referencing from another nodes to 
pass jobs for it. tag may be ommited in source descriptions or in case of nodes that 
would not be referenced.

*operation* is an exact kind of work that performed by node. some operations require 
*parameters*. run *rndc.rb -hhh* to get info about operations and parameters.

every node can contain some *quantity* of similar actors that will operate simultaneously. 
1 is default value if no quantity block performed. if actor's (node's) operation is long or 
is not always ends successfully, it is might be usefull to parallelize it.

if node is filter, it can be *inverted* by adding **-** sign after operation description. 
this mean that job which will be normally passed by usual filter, will be suppressed 
by inverted one, so behavior of the filter is reversed. filter also might be 
marked by **+** sign (usual filter) just for clarity.

successfully operated job would be passed to *receivers* using some *passtype*:
  * **>** result will be passed to every actor *that is not busy* in all receiving nodes.
  this type of passing is unreliable as far as it can cause loosing of job in case 
  when all receivers are busy.
  * **?** result will be passed to only one randomly choosen receiver. node will attempt
  to pass the job untill it find a free consumer, so this pass type is reliable.

description concludes with a list of consumers. it consists of tags of some another 
nodes (except sources, that cant receive jobs) separated by commas. *passtype* and 
receiver list may be ommited, and then jobs will be suppressed after processing. 

also if receiver list contains a **:** then receivers specified after it will receive 
an unsuccessfully operated job (it is something like *else* operator). in this case the 
same passtype used.
if you wish to pass the job to the next node, you may specify a **#** symbol instead 
of exact node name. if your script is linear (i.e. it is consist of nodes each of which passes only 
[un]succesfully processed jobs to next node only), you may not entitle your nodes at all.

script lines that begins from **#** are comments.

if script line begins with **#>** then its trail will be printed on script parsing. 
this feature is allows you to describe script logics in code and print its summary on launching.

look at file *code/discover.script*, it is an example script.

## COMMAND LINE OPTIONS
**-f**	 *script file* specifying script file

**-n**		dry run, just check script for syntax

**-t**		print time stamps in tracing lines

**-c**		print squized script code

**-h**		**this manual**

**-hh**		this manual and script function list

**-hhh**		this manual and script function list with descriptions


## TODO LIST
- [x] some convinient command line interface
- [x] built-in documentation by script functions
- [ ] extending of filter functionality (reverse DNS and others)
- [x] use domain names in HTTP-requests (it imay be usefull sometimes)
- [x] merging command line keys (like netstat -nat)
- [x] passing multiple parameters to nodes
- [x] mail delivery engine
- [x] branching filters
- [ ] command aliases (short names or more understandable, for user's choise)
- [x] actualize description
- [x] passing jobs to next node without exact node name specification
- [ ] triggers (sending user defined commands to engine by network)
- [ ] job processing logging