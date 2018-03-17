check_traceroute_pingplot
==========================

This plugin does a traceroute with the given OS's traceroute command (currently supported: Linux and Windows)
and creates a nice graph via rrdgraph.

So now, when a machine you are trying to access has bad ping times every now and then, you can find out where
it actually starts (if you are running a two-way traceroute). The only thing missing (which won't ever be added
though) is checking for packetloss (like eg. the nicely done default plugin check_icmp does).


INSTALLATION

To install this plugin, simply install it into your nagios/icinga plugins directory and link to it in your nagios/icinga configuration.

Also, if you want to use ping types deemed root-only by the kernel, you need to run this plugin via sudo
and set up /etc/sudoers accordingly:

    Defaults: nagios !requiretty
    nagios   ALL=(root) /usr/bin/traceroute*

In case you are using Fedora or RHEL / CentOS with SElinux enabled, you might need to either write
an SElinux policy module or have to turn off SElinux for nrpe/nagios/the server itself completely.

For the whole server:

  setenforce 0

A few websites on SElinux:
* On disabling: https://www.alfresco.com/blogs/devops/2015/11/19/the-10-commandments-to-avoid-disabling-selinux/
* On writing policy modules:  https://www.digitalocean.com/community/tutorials/an-introduction-to-selinux-on-centos-7-part-1-basic-concepts


PNP4Nagios

In case you are using PNP4Nagios, you can install the pnp4nagios template from the archive as follows:

    a. Copy the pnp4nagios-template-*.php file to eg. /usr/share/pnp/templates/check_traceroute_pingplot.php (php!)
    b. Copy the pnp4nagios-check_commands-*.cfg file to /etc/pnp/check_commands/check_traceroute_pingplot.cfg (cfg!)


Debugging

When the traceroute command does not return any hopinfo in the debug-output, make sure sudoers is set up correctly.


SUPPORT AND DOCUMENTATION

I can be reached via mail under the following address:

  fkrueger-dev-checktraceroutepingplot@holics.at

You can find the newest version of this plugin and pnp4nagios template on:

    * http://dev.techno.holics.at/check_traceroute_pingplot/
    * https://github.com/fkrueger-2/check_traceroute_pingplot
    * https://exchange.nagios.org/directory/Plugins/Network-Connections%2C-Stats-and-Bandwidth/check_traceroute_pingplot/


LICENSE AND COPYRIGHT

Copyright (C) 2014,2017 by Frederic Krueger / fkrueger-dev-checktraceroutepingplot@holics.at


Licensed under the Apache License, Version 2.0

