#!/usr/bin/perl -w

# Nagios plugin for a decent pingplotter-style traceroute (and rrdgraph)
#
# (c) 2014,2017 by Frederic Krueger / fkrueger-dev-checktraceroutepingplot@holics.at
#
# Licensed under the Apache License, Version 2.0
# There is no warranty of any kind, explicit or implied, for anything this software does or does not do.
#
# Updates for this piece of software could be available under the following URL:
#   GIT:   https://github.com/fkrueger-2/check_traceroute_pingplot
#   Home:  http://dev.techno.holics.at/check_traceroute_pingplot/
#

# TODO:
# Obviously this plugin is probably a horror scenario with enforcing SElinux. Someone should change that and write a working policy ;-)

## Credits go to the following people:
#  * George Hansper for providing a patch that adds overall ping statistics to the status output
#  * George Hansper for providing the idea (and a patch) for supporting different types of traceroutes
#  * Michele Nicosia for providing the idea to include the hopcount in our data structures after all
#  * Fixed a booboo in the pnp4nagios template resulting in a nonshow on a traceroute longer than the coloring scheme (thanks Jen Carroll)
#  * Fixed another booboo in the pnp4nagios templates that caused things to go awry with rrdtool > 1.5, when the area-tag had a : but no info after it (thanks Ed Stout)
## More people may follow ;-)


use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case);
use POSIX;
## you may need to install the next module via apt-get, yum, emerge, ppm or perl's CPAN-shell mechanism.
use File::Which;

# our nagios "lib" directories
if (-d "/usr/lib/nagios/plugins") { use lib "/usr/lib/nagios/plugins"; }
if (-d "/usr/lib64/nagios/plugins") { use lib "/usr/lib64/nagios/plugins"; }
if (-d "/srv/nagios/libexec") { use lib "/srv/nagios/libexec"; }

use utils qw (%ERRORS);

# if utils.pm doesn't exist on your system, comment out the "use utils" statement and uncomment the below "our %ERRORS" statement.
#our %ERRORS = ( 'UNKNOWN' => -1, 'OK' => 0, 'WARNING' => 1, 'CRITICAL' => 2 );


## globals

# used lateron. insert full path to your OS traceroute tool to override automatic detection.
my $bin_traceroute = "";



##
## dont end below here unless you know what you are doing
##

# program info
$PROG_NAME     = 'check_traceroute_pingplot';
$PROG_VERSION  = '0.1.3';
$PROG_EMAIL    = 'fkrueger-dev-checktraceroutepingplot@holics.at';
$PROG_URL      = 'http://dev.techno.holics.at/check_traceroute_pingplot/';

# these are our default values
our $DEBUG = (0==1);
my $dflt_warnping = 250;    # ms
my $dflt_warnpl = 25;       # %
my $dflt_critping = 500;    # ms
my $dflt_critpl = 50;       # %
my $dflt_maxhops = 20;      # max. number of hops
my $dflt_waittime = 2;      # seconds (between hops)
my $dflt_tracetype = "";		# default tracetype, can be '', icmp, tcpsync
my $dflt_usesudo = (0==1);	# default: don't use sudo

# options for later usage
my ($opt_ip, $opt_warn, $opt_crit, $opt_waittime, $opt_maxhops, $opt_perfdata, $opt_verbose, $opt_debug, $opt_dontaccumulateping, $opt_tracetype, $opt_usesudo) = ("", "", "", 0, 0, 0, 0, 0, 0, "", 0);

# our work variables
my ($do_perfdata, $verbose, $dontaccumulateping, $ip, $waittime, $maxhops, $warnping, $warnpl, $critping, $critpl, $tracetype, $usesudo) = (0, 0, 0, "", $dflt_waittime, $dflt_maxhops, $dflt_warnping, $dflt_warnpl, $dflt_critping, $dflt_critpl, $dflt_tracetype, $dflt_usesudo);


## func
sub usage
{
  my $msg = shift;
  $msg = "" if (!defined($msg));
  my $detailledhelp = shift;
  $detailledhelp = ((defined($detailledhelp)) and ($detailledhelp eq "detailledhelp")) ? 1 : 0;

  print "\nusage: $0 <-H <ip|hostname> [-w <maxping>] [-c <maxping>] [-T <tracetype>] [-S]\n";
  print "                         [-m <max-ttl-in-hops>] [-t <waittime-between-hops-in-seconds>] [-a] [-p] [-v] [-d] [-h]\n";
  print "\n";
  print "This plugin does a traceroute with the given OS'S traceroute command (currently supported: Linux and Windows)\n";
  print "and creates a nice graph via rrdgraph.\n";
  print "\n";
  print "So now, when a machine you are trying to access has bad ping times every now and then, you can find out where\n";
  print "it actually starts (if you are running a two-way traceroute). The only thing missing (which won't ever be added\n";
  print "though) is checking for packetloss (like eg. the nicely done default plugin check_icmp does).\n";
  print "\n";

  print "\n";
  print "    Defaults:\n";
  print "    -w    warning        ${dflt_warnping} (in ms)\n";
  print "    -c    critical       ${dflt_critping} (in ms)\n";
  print "    -m    max-hops       ${dflt_maxhops} (ttl in hops)\n";
  print "    -t    wait-time      ${dflt_waittime} (seconds)\n";
  print "\n";
  print "    -a    dont accumulate ping times (ie. hop3 value = hop3-hop2)\n";
	print "    -S    try using sudo, where appropriate (Non-Windows only)\n";
	print "    -T    type of traceroute to do; can be icmp, tcpsyn or '' (default: '${dflt_tracetype}')\n";
  print "    -p    print performance data\n";
  print "    -v    verbose output\n";
  print "    -d    debug mode\n";
  print "    -h    a more detailled help\n";
  print "\n";
  if ($detailledhelp)
  {
    print "### NAGIOS COMMANDS DEFINITION
define command{
  command_name  check_traceroute_pingplot
  command_line  \$USER1\$/contrib/check_traceroute_pingplot.pl -H \$ARG1\$ -w \$ARG2\$ -c \$ARG3\$ \$ARG4\$ \$ARG5\$ \$ARG6\$ \$ARG7\$ \$ARG8\$ \$ARG9\$
}

### NAGIOS SERVICECHECK DEFINITION
define service{
  use                             local-service
  host_name                       yourhost
  service_description             Traceroute Nicely www.google.com
  # use warnping 250ms, critping 500ms, timeout-per-proberound=1s
  check_command                   check_traceroute_pingplot!www.google.com!250!500!-t!1
}

### NRPE CHECK DEFINITION
command[check_traceroute_pingplot]=/usr/lib/nagios/plugins/contrib/check_traceroute_pingplot.pl -H \$ARG1\$ -p -v -w \$ARG2\$ -c \$ARG3\$   \$ARG4\$ \$ARG5\$ \$ARG6\$ \$ARG7\$ \$ARG8\$ \$ARG9\$

### Possible sudo setup (/etc/sudoers or /etc/sudoers.d/traceroute)
nagios	ALL=(root) NOPASSWD: /usr/sbin/traceroute *

";
  } # end if detailled help
  if ($msg ne "")
  {
    print "Error: $msg\n\n";
  }
  else
  {
    print "$PROG_NAME v$PROG_VERSION is licensed under the Apache License, Version 2.0 .
There is no warranty of any kind, explicit or implied, for anything this software does or does not do.

The main page for this plugin can be found at: $PROG_URL

(c) 2014,2016 by Frederic Krueger / $PROG_EMAIL
  
";
  } # end if no error occurred => print license
} # end sub usage


sub dbgprint
{
  my $msg = shift;
  $msg = "" if (!defined($msg));

  if ($msg ne "")
  {
    if ($DEBUG)
    {
      print "DBG> $msg\n";
    }
  } # end if got msg
} # end sub dbgprint


sub getformattedip
{
  my $ip = shift;
  if ((!defined($ip)) or ($ip eq "")) { return ("NO.IP.GOT.TEN"); }
  return (sprintf ("%03s.%03s.%03s.%03s", split /\./, $ip));
} # end sub getoutputip


sub calc_minavgmax
{
  my $aref = shift;

  my @arr = ();
  foreach my $val (@{$aref})
    { push @arr, $val  if (($val ne "") and ($val > 0)); }

  my $min = 9999999; my $max = -9999999; my $avg = 0;
  for (my $i=0; $i <= $#arr; $i++)
  {
    $min = $arr[$i] if ($min > $arr[$i]);
    $max = $arr[$i] if ($max < $arr[$i]);
    $avg += $arr[$i];
  }
  $min = sprintf ("%.2f", $min);
  $avg = sprintf ("%.2f", $avg/($#arr+1));
  $max = sprintf ("%.2f", $max);
  return ($min, $avg, $max);
} # end sub calc_minavgmax


## args
my @origargv = @ARGV;		# save for (maybe) later debug output

GetOptions(
    "H|hostname=s"  => \$opt_ip,
    "w|warning=s"   => \$opt_warn,
    "c|critical=s"  => \$opt_crit,
    "m|maxhops=s"   => \$opt_maxhops,
    "t|waittime=s"  => \$opt_waittime,    # for each round of probes (in seconds)
    "a|dontaccumulateping"  => \$opt_dontaccumulateping,
	  "S|usesudo"     => \$opt_usesudo,
	  "T|tracetype=s" => \$opt_tracetype,
    "d|debug"       => \$opt_debug,
    "v|verbose"     => \$opt_verbose,
    "p|perfdata"    => \$opt_perfdata,
    "h|help"        => \$opt_help
);


## arg parsing
if (defined($opt_help))
{
  usage("", "detailledhelp");
  exit($ERRORS{'OK'});
} # end if opt_help given


if ((!defined($opt_ip)) or ($opt_ip eq ""))
{
  usage ("Need an IP/Hostname to traceroute to.");
  exit($ERRORS{'UNKNOWN'});
}
else
{
  $ip = $opt_ip;
} # end if got ip

if ((defined($opt_warn)) and ($opt_warn ne ""))
{
  my ($tmpping) = ($opt_warn =~ /^(\d+)$/);
  if ((defined($tmpping)) and ($tmpping > 0))
  {
    $warnping = $tmpping;
  }
  else
  {
    usage ("Must define --warning=<maxping> .");
    exit($ERRORS{'UNKNOWN'});
  }
} # end if opt_warn given

if ((defined($opt_crit)) and ($opt_crit ne ""))
{
  my ($tmpping, $tmppl) = ($opt_crit =~ /^(\d+)$/);
  if ((defined($tmpping)) and ($tmpping > 0))
  {
    $critping = $tmpping;
  }
  else
  {
    usage ("Must define --critical=<maxping> .");
    exit($ERRORS{'UNKNOWN'});
  }
} # end if opt_crit given

if ((defined($opt_waittime)) and ($opt_waittime ne "") and ($opt_waittime > 0))
{
  if ($opt_waittime =~ /^(\d+)$/)
  {
    $waittime = $1;
  }
} # end if opt_waittime given

if ((defined($opt_maxhops)) and ($opt_maxhops ne "") and ($opt_maxhops > 0))
{
  if ($opt_maxhops =~ /^(\d+)$/)
  {
    $maxhops = $1;
  }
} # end if opt_maxhops given

if ((defined($opt_dontaccumulateping)) and ($opt_dontaccumulateping ne ""))
{
  $dontaccumulateping = ($opt_dontaccumulateping) ? 1 : 0;
} # end if opt_dontaccumulateping given

if (defined($opt_tracetype))
{
  if ($opt_tracetype =~ /^(?:icmp|tcpsyn|)$/i)
	{
		$tracetype = lc($opt_tracetype);
	}
	else
	{
		usage ("Tracetype must be either 'icmp', 'tcpsyn' or ''.");
		exit (-1);
	}
} # end if opt_tracetype given

if ((defined($opt_perfdata)) and ($opt_perfdata ne ""))
{
  $do_perfdata = ($opt_perfdata) ? 1 : 0;
} # end if opt_perfdata given

if ((defined($opt_usesudo)) and ($opt_usesudo ne ""))
{
  $usesudo = ($opt_usesudo) ? 1 : 0;
} # end if opt_usesudo given

if ((defined($opt_debug)) and ($opt_debug ne ""))
{
  $DEBUG = ($opt_debug) ? 1 : 0;
} # end if opt_debug given

if ((defined($opt_verbose)) and ($opt_verbose ne ""))
{
  $verbose = ($opt_verbose) ? 1 : 0;
} # end if opt_verbose given



## main
dbgprint ("This is $PROG_NAME v$PROG_VERSION running (ts: " .strftime("%Y-%m-%d %H:%M:%S", localtime()). ")");

my $cmd = "";
my $os = $^O;
if ($bin_traceroute eq "")
{
  $os = $^O;
  dbgprint ("OS:   '$os'");
  dbgprint ("ARGV: " .join(",", @origargv));
  dbgprint ("#");
  if (($os eq "linux") or ($os eq "darwin") or ($os eq "freebsd") or ($os eq "vms") or ($os eq "hpux") or ($os eq "aix") or ($os eq "irix"))
  {
		my $sudosnippet = "";
		if ( (($tracetype eq "icmp") or ($tracetype eq "tcpsyn")) and ($< != 0) )
		{
			if (! $usesudo)
			{
			  warn "# Tracetype '$tracetype' probably needs root permissions (use sudo).\n";
			}
			else
			{
				$sudosnippet = "sudo -u root -n -- ";
			}
		}
    $bin_traceroute = which ("traceroute");
		$tracetype = ($tracetype eq "icmp" ? "-I " : ($tracetype eq "tcpsyn" ? "-T " : ""));
    $cmd = "$sudosnippet $bin_traceroute -w $waittime -m $maxhops $tracetype -n $ip";
  } # end if on unixy os
  elsif (($os eq "MSWin32") or ($os eq "MSWin64"))
  {
	  if ($tracetype ne "")
		  { warn "# Tracetype '$tracetype' is not supported for Windows.\n"; }
    $bin_traceroute = which ("tracert");
    $cmd = "$bin_traceroute -w $waittime -h $maxhops -d $ip";
  } # end if on windows
  else
  {
    usage ("Automatic detection for \$bin_traceroute failed to find a knonwn OS. Try manual overriding in the script.");
    exit ($ERRORS{'UNKNOWN'});
  } # end if autodetection failed

  if ((defined($bin_traceroute)) and (-e "$bin_traceroute") and (-x "$bin_traceroute"))
  {
    dbgprint ("Found workable traceroute command '$bin_traceroute'.");
  } # end if found bin_traceroute through automatic detection that exists and is executable
  else
  {
    usage ("Automatic detection for \$bin_traceroute failed to find a working executable. Try manual overriding in the script.");
    exit ($ERRORS{'UNKNOWN'});
  } # end if we didnt.
} # end if bin_traceroute needs autodetecting
else
{
  if ((! -e "$bin_traceroute") or (! -x "$bin_traceroute"))
  {
    usage ("Manual override of \$bin_traceroute '$bin_traceroute': File isn't there or isn't executable.");
    exit ($ERRORS{'UNKNOWN'});
  } # end if bin_traceroute doesnt exist
} # end if bin_traceroute set by manual override


my $errorsoccured = "";
my $biggesthostname = 4*3+3;	# ie. 000.000.000.000

our %hopinfos = ();      # format: ip => { 'hop' => [ hop-count, .. ], pingtimes => [ num1, .., numn ] }


# now the traceroute

## XXX the windows part is working, but wasn't tested with NSClient++ or NSCP yet. Feedback would be appreciated.

# command definition is done above in the os-detection part.
# our default: linux traceroute
if (open (TR, "$cmd |"))
{
  dbgprint ("\$ $cmd");

  while (defined(my $inp = <TR>))
  {
    chomp ($inp);
    dbgprint ("$inp");
    # skip empty and header lines (first is begin linux traceroute, second is begin mswin32 tracert, third is end mswin32 tracert)
    next if ($inp =~ /^(traceroute to.*|Tracing route to.*|Trace complete.*|)$/i);
    # trim
    $inp =~ s/^\s+//g;  # ..spaces
    $inp =~ s/ ms / /g; # .."ms"
    # get the fields (position, ip, min ping, avg ping, max ping)

    if (($os eq "MSWin32") or ($os eq "MSWin64"))
    {
      #windows:
      #$dbg1  = " 1      <1 ms   <1 ms    <1 ms  62.154.14.242";
      #$dbg10 = " 10     *      197 ms   136 ms  178.32.135.223";
      
      my @t = split /\s+/, $inp;
      dbgprint ("t: " .join(",", @t). "");

      if ((defined($t[0])) and ($t[0] ne "*") and ($t[0] > 0) and (defined($t[1])) and ($t[1] ne "") and (defined($t[2])) and ($t[2] ne "") and (defined($t[3])) and ($t[3] ne "") and (defined($t[4])) and ($t[4] =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/))
      {
        $t[1] = "0" if ($t[1] eq "*"); # turn * into 0 (ms)
        $t[2] = "0" if ($t[2] eq "*"); # turn * into 0 (ms)
        $t[3] = "0" if ($t[3] eq "*"); # turn * into 0 (ms)
        $t[1] = "1" if ($t[1] eq "<1"); # turn <1 ms into 1 (ms)
        $t[2] = "1" if ($t[2] eq "<1"); # turn <1 ms into 1 (ms)
        $t[3] = "1" if ($t[3] eq "<1"); # turn <1 ms into 1 (ms)

        $t[0] =~ s/[^0-9]//g;
        $t[1] =~ s/[^0-9\.\-\+]//g;
        $t[2] =~ s/[^0-9\.\-\+]//g;
        $t[3] =~ s/[^0-9\.\-\+]//g;

        # replace , with .  so perl can handle it as a float number
        $t[1] =~ s/,/./g;
        $t[2] =~ s/,/./g;
        $t[3] =~ s/,/./g;

        my $currentip = ((defined($t[4])) ? $t[4] : "");  my $currenthop = ((defined($t[0])) ? $t[0] : -1);
				my $currentlbl = "";

        if (($currentip ne "") and ($currenthop > 0))
        {
					$currentlbl = "${currentip}-${currenthop}";
          my @tmppt = (); my @tmphop = ();
          if (!defined($hopinfos{$currentlbl})) { $hopinfos{$currentlbl} = { 'hops' => [ @tmphop ], 'ip' => $currentip, 'pingtimes' => [ @tmppt ] }; }
          if (defined($hopinfos{$currentlbl}{'hops'})) { @tmphop = @{$hopinfos{$currentlbl}{'hops'}}; }
          if (defined($hopinfos{$currentlbl}{'pingtimes'})) { @tmppt = @{$hopinfos{$currentlbl}{'pingtimes'}}; }
          push @tmphop, $currenthop;
          push @tmppt, $t[1]  if ($t[1] > 0);
          push @tmppt, $t[2]  if ($t[2] > 0);
          push @tmppt, $t[3]  if ($t[3] > 0);
          $hopinfos{$currentlbl}{'hops'} = [ @tmphop ];
          $hopinfos{$currentlbl}{'pingtimes'} = [ @tmppt ];

          $biggesthostname = length($currentip)  if (length($currentip) > $biggesthostname);
        } # end if got valid ip and hopnum at the least
      } # end if got valid-looking infos
    } # end if is MSWin32 or other Win
    else  # the default: linux traceroute
    {

      ## the following is used for debugging:
      #my $dbg4 = " 4  176.57.248.141 (176.57.248.141)  10.979 ms 176.57.248.137 (176.57.248.137)";
      #my $dbg5 = " 5  72.14.233.54  0.861 ms  4.873 ms  0.822 ms";
      #my $dbg6 = " 6  66.249.94.6  1.064 ms  1.073 ms 66.249.94.22  1.393 ms";
      #my $dbg7 = " 7  64.233.175.15  0.999 ms 64.233.175.12  1.104 ms 209.85.248.57  1.075 ms";
      #$inp = $dbg5;
      ## /debugging

      # XXX any stuff in brackets, like in dbg4 below, can be safely disregarded, since it s just a "get_hostname"
      #     interpretation of the answering addr for a given probe.
      $inp =~ s/\s+\([0-9.]+\)//isg;

      # remove any trailing ips without pingtime information
      ## TODO (maybe, but I really don't want to introduce any other system tools): do separate icmp pings for such ips instead.
      $inp =~ s/\s+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\s*$//isg;

      # now prepend the currently answering ip before any pingtime
      my @x = split /\s+/, $inp;

      my $currenthop = -1;
      my $currentip = "";
			my $currentlbl = "";
      for (my $i=0; $i <= $#x; $i++)
      {
        if ((defined($x[$i])) and ($x[$i] ne ""))
        {
          my $dbgout = "x-$i is '$x[$i]' => ";
          if ($x[$i] =~ /^\d+$/)                         # found hop count
          {
            $dbgout .= "hop!";
            $currenthop = $x[$i];
          }
          elsif ($x[$i] =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) # found ip
          {
            $dbgout .= "IP!";
            $currentip = "$x[$i]";
            $currentlbl = "${currentip}-${currenthop}";
            $biggesthostname = length($currentip)  if (length($currentip) > $biggesthostname);
          }
          elsif ($x[$i] =~ /^[0-9]+\.[0-9]+$/)              # found pingtime
          {
            $dbgout .= "pingtime!";
            my @tmppt = (); my @tmphop = ();
            if (!defined($hopinfos{$currentlbl})) { $hopinfos{$currentlbl} = { 'hops' => [ @tmphop ], 'ip' => $currentip, 'pingtimes' => [ @tmppt ] }; }
            if (defined($hopinfos{$currentlbl}{'hops'})) { @tmphop = @{$hopinfos{$currentlbl}{'hops'}}; }
            if (defined($hopinfos{$currentlbl}{'pingtimes'})) { @tmppt = @{$hopinfos{$currentlbl}{'pingtimes'}}; }
            push @tmphop, $currenthop;
            push @tmppt, $x[$i];
            $hopinfos{$currentlbl}{'hops'} = [ @tmphop ];
            $hopinfos{$currentlbl}{'pingtimes'} = [ @tmppt ];
          }
          elsif ($x[$i] eq "ms")                            # discard the "ms" sign
            { $dbgout .= "ms-sign."; }
          elsif ($x[$i] eq "")                              # discard empty stuff
            { $dbgout .= "empty."; }
          elsif ($x[$i] eq "*")                             # discard * (ie. "timeout")
            { $dbgout .= "*."; }
          else                                              # and warn about other stuff
          {
            $dbgout .= "unknown-input.";
            warn "inp '$inp' contains unknown input '$x[$i]'\n";
          }
          dbgprint ($dbgout);
        } # end if x-i entry is at least defined
      } # end for content in @t

      ## the debug input should look like the following at this point:
      #my $dbgout4 = " 4  176.57.248.141  10.979 ms";
      #my $dbgout5 = " 5  72.14.233.54  0.861 ms  4.873 ms  0.822 ms";
      #my $dbgout6 = " 6  66.249.94.6  1.064 ms  1.073 ms 66.249.94.22  1.393 ms";
      #my $dbgout7 = " 7  64.233.175.15  0.999 ms 64.233.175.12  1.104 ms 209.85.248.57  1.075 ms";
      ## /debugging

    } # end if is default (ie. linux traceroute)
  } # end while reading traceroute output
  dbgprint ("\$ ");
  close (TR);
} # end if open worked
else
{
  usage ("Couldn't start traceroute command '$cmd'. Exitting");
  exit ($ERRORS{'UNKNOWN'});
} # end if open didnt work



# doing some precalculations for later output
my $highesthop = 0;
my @hop2ips = ();   # format: hopcount => { ip1 => 1, ip2 => 1, .., ipn => 1 }

my @ipqs = ();
foreach my $ip (sort keys %hopinfos)
{
  # calculate min-avg-max ping for output
  my ($pingmin, $pingavg, $pingmax) = calc_minavgmax (\@{$hopinfos{$ip}{'pingtimes'}});
  $hopinfos{$ip}{'pingmin'} = $pingmin;
  $hopinfos{$ip}{'pingavg'} = $pingavg;
  $hopinfos{$ip}{'pingmax'} = $pingmax;

  @ipqs = split /\./, $hopinfos{$ip}{'ip'}; # XXX
  $hopinfos{$ip}{'ip-sprintf'} = sprintf ("%03i_%03i_%03i_%03i", $ipqs[0], $ipqs[1], $ipqs[2], $ipqs[3]);

  # get highest hopnum in hopinfos{ip}, and record if higher than previous max.
  if (defined($hopinfos{$ip}{'hops'}))
  {
    my @tmphop = ( reverse sort @{$hopinfos{$ip}{'hops'}} );
    if ($highesthop < $tmphop[0]) { $highesthop = $tmphop[0]; }   # end this loop right after first entry (= highest num)
  }

  # sort ips by hopnum
  my @tmpx = ();
  foreach my $hopnum (sort @{$hopinfos{$ip}{'hops'}})
  {
    my %tmpips = ();
    if (!defined($hop2ips[$hopnum])) { $hop2ips[$hopnum] = { %tmpips }; }
    if (defined($hop2ips[$hopnum])) { %tmpips = %{$hop2ips[$hopnum]}; }
    if ((!defined($tmpips{$ip})) or ($tmpips{$ip} <= 0)) { $tmpips{$ip} = 1; }
    $hop2ips[$hopnum] = { %tmpips };
  }
}

dbgprint ("highesthop: $highesthop");
dbgprint ("hop2ips: " .Dumper(@hop2ips));
dbgprint ("hopinfos: " .Dumper(%hopinfos));


my $perfdata = "";
my $hopdata = "";

my %allhops = ( 'pingmin' => -99999, 'pingavg' => -99999, 'pingmax' => -99999 );

my $RC = "OK";

## TODO not sure how to create packetloss checking akin to check_icmp's doing without doing the pinging manually ourself.
if ($highesthop > 0)
{
  dbgprint ("got " .$highesthop. " hops from traceroute (at the most).");
  my $ping_last = 0;
  for (my $hopnum = 1; $hopnum <= $#hop2ips; $hopnum++)
  {
    my %tmpips = ();
    if (defined($hop2ips[$hopnum]))
    {
      %tmpips = %{$hop2ips[$hopnum]};
      
      foreach my $ip (sort keys %tmpips)
      {
        my %curhop = %{$hopinfos{$ip}};
        dbgprint ("# hop $hopnum (label '$ip'): ping-last = $ping_last");
        if ((defined($curhop{'ip'})) and ($curhop{'ip'} ne ""))
        {
	  # for outputting the min-avg-max for the whole ping in the status line
	  if ($curhop{'pingmin'} > $allhops{'pingmin'}) { $allhops{'pingmin'} = $curhop{'pingmin'}; }
	  if ($curhop{'pingavg'} > $allhops{'pingavg'}) { $allhops{'pingavg'} = $curhop{'pingavg'}; }
	  if ($curhop{'pingmax'} > $allhops{'pingmax'}) { $allhops{'pingmax'} = $curhop{'pingmax'}; }

          if ($curhop{'pingmax'} < $warnping)
          {
            $hopdata .= sprintf ("OK - Hop %" .($highesthop < 10 ? 1:2). "i, IP %" .($biggesthostname). "s, ping min-avg-max %06.2f-%06.2f-%06.2f ms\n", $hopnum, getformattedip($curhop{'ip'}), $curhop{'pingmin'}, $curhop{'pingavg'}, $curhop{'pingmax'});
          }
          elsif ($curhop{'pingmax'} < $critping)
          {
            $hopdata .= sprintf ("WARNING - Hop %" .($highesthop < 10 ? 1:2). "i, IP %" .($biggesthostname). "s, ping min-avg-max %06.2f-%06.2f-%06.2f ms >= warnping %5.2f ms\n", $hopnum, getformattedip($curhop{'ip'}), $curhop{'pingmin'}, $curhop{'pingavg'}, $curhop{'pingmax'}, $warnping);
            $RC = "WARNING" if ($RC eq "OK");
          }
          else
          {
            $hopdata .= sprintf ("CRITICAL - Hop %" .($highesthop < 10 ? 1:2). "i, IP %" .($biggesthostname). "s, ping min-avg-max %06.2f-%06.2f-%06.2f ms >= critping %5.2f ms\n", $hopnum, getformattedip($curhop{'ip'}), $curhop{'pingmin'}, $curhop{'pingavg'}, $curhop{'pingmax'}, $critping);
            $RC = "CRITICAL" if (($RC eq "WARNING") or ($RC eq "OK"));
          }
  
          # add up pingtimes to create a "nice" mountain graph lateron, maybe. use 0 if would be negative (it can happen)
          $ping_actual = (($curhop{'pingavg'} - $ping_last) < 0 ? 0 : $curhop{'pingavg'} - $ping_last);
          $ping_last = $curhop{'pingavg'};
  
          # and create perfdata
          my $tmpip = $curhop{'ip-sprintf'};
  
          # hop = accumulated pingtime, dhop = "diff hop", ie. the difference between hops
          $perfdata .= ($dontaccumulateping ? sprintf (" dhop_%02i-%s=%05.2f;;;;", $hopnum, $tmpip, $ping_actual) : "") .sprintf(" hop_%02i-%s=%05.2f;;;;", $hopnum, $tmpip, $curhop{'pingavg'});
        } # end if got valid-looking info
      } # end foreach ip at hopnum
    } # end if got ips for hop2ips[hopnum]
  } # end for each hop in array
} # end if hops got info
else
{
  print "UNKNOWN - No traceroute info gotten.\n";
  exit ($ERRORS{'UNKNOWN'});
} # end if no hops info gotten


if ($hopdata ne "")
{
  if ($allhops{'pingmin'} <= -99999)  { $allhops{'pingmin'} = $allhops{'pingavg'}; }
  if ($allhops{'pingmax'} <= -99999) { $allhops{'pingmax'} = $allhops{'pingavg'}; }

  print "$RC - Traceroute to IP $ip has $highesthop hops";
  printf (", ping min-avg-max %06.2f-%06.2f-%06.2f ms", $allhops{'pingmin'}, $allhops{'pingavg'}, $allhops{'pingmax'});
  print "" .((!$do_perfdata) ? "\n" : "");
  if (($do_perfdata) and ($perfdata ne ""))
  {
    print " |$perfdata\n";
  } # end if do_perfdata and have perfdata
  # and now the hopbyhop info
  if ($verbose) { print "$hopdata\n"; } 

  exit ($ERRORS{$RC});
}




1;
