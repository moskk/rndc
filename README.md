# DESCRIPTION
well, **rndc** is a tool for serching of web-pages. currenly it can discover 
network hosts, scan ports, download pages, filter server responces by some 
properties (server responce code, page code/text content, page title), 
and give away host info into text file or into browser. 

you can't rob the caravans yet but this option is on develop. so you can 
try to search some caravans, lol.

# USAGE
## Basic
**rndc** provides you a set of tools which can be linked into chains. every 
node of this chain may have one of those types:
  * *source* that generates some job
  * *filter* that pass (or not) the job for enother node depending on some condition
  * *transformer* that transforms the job into something enother (actualy job too)

to use **rndc** you can:
  * manualy use classes defined in *rndcbase.rb* to create tool chains **OR**
  * use special building tool. just write a script and pass it to TCBuilder.

## TCBuilder scripting
TCBuilder (tool chain builder) script consists of node descriptions. every node performing some operation 
on jobs and have a list of nodes that will receive (or not) this job after operation 
is done. this descriptions are looks like this:
`tag (operation|parameter|[quantity]) passtype receiver1,receiver2,...,receiverN`

*tag* is a name of node. it is used for node referencing from another nodes to 
pass jobs for it. tag may be ommited in source descriptions or in case of nodes that 
would not be referenced.
*operation* is an exact kind of work that performed by node. some operations require 
*parameters*. operations and parameters will be described belowe.
every node can contain some *quantity* of similar actors that will operate simultaneously. 
1 is default value if no quantity block performed.
successfully operated job would be passed to receivers using some *passtype*:
  * **>** result will be passed to every actor *that is not busy* in all receiving nodes.
  this type of passing is unreliable as far as it can cause loosing of job in case 
  when all receivers are busy.
  * **?** result will be passed to only one randomly choosen receiver. node will attempt
  to pass the job untill it find a free consumer, so this pass type is reliable.

description concludes with a list of consumers. it consists of tags of some another 
nodes (except sources, that cant receive jobs) separated by commas. *passtype* and 
receiver list may be ommited, and then jobs will be suppressed after processing.
script lines that begins from **#** are comments.