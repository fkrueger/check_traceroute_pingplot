<?php

/*
 *   PNP4NAGIOS template for check_traceroute_pingplot from 2016-07-27
 *   (c) 2014,2017 by Frederic Krueger / fkrueger-dev-checktraceroutepingplot@holics.at
 *
 *   Licensed under the Apache License, Version 2.0
 *   There is no warranty of any kind, explicit or implied, for anything this software does or does not do.
 *
 *   Updates for this piece of software could be available under the following URL:
 *     GIT:   https://github.com/fkrueger-2/check_traceroute_pingplot
 *     Home:  http://dev.techno.holics.at/check_traceroute_pingplot/
 *
 *   This is coming with check_traceroute_pingplot v0.1.3
 *
 *   Requires: pnp4nagios
 *
 */

## options
$graphtype = "nice";		# nice, boring
$coloring = "rainbow-small";	# nice, boring, rainbow, rainbow-small
$coloringoffset = 2;		# start coloring at offset x in the chosen coloring scheme

$DEBUG = 0;


## a few color schemes
$oldschoolcolors = array (				# enough for 28 hops		name: oldschool
 'dark' => array(
  'cc3118', 'cc7016', 'c9b215',  # red orange yellow
  '24bc14', '1598c3', 'b415c7',  # green blue pink
  '4d18e4',                      # purple
  'cc3118', 'cc7016', 'c9b215',  # red orange yellow
  '24bc14', '1598c3', 'b415c7',  # green blue pink
  '4d18e4',                      # purple
  'cc3118', 'cc7016', 'c9b215',  # red orange yellow
  '24bc14', '1598c3', 'b415c7',  # green blue pink
  '4d18e4',                      # purple
  'cc3118', 'cc7016', 'c9b215',  # red orange yellow
  '24bc14', '1598c3', 'b415c7',  # green blue pink
  '4d18e4'                       # purple
 ),
 'light' => array(
  'ea644a', 'ec9d48', 'ecd748',  # red orange yellow
  '54ec48', '48c4ec', 'de48ec',  # green blue pink
  '7648ec',                      # purple
  'ea644a', 'ec9d48', 'ecd748',  # red orange yellow
  '54ec48', '48c4ec', 'de48ec',  # green blue pink
  '7648ec',                      # purple
  'ea644a', 'ec9d48', 'ecd748',  # red orange yellow
  '54ec48', '48c4ec', 'de48ec',  # green blue pink
  '7648ec',                      # purple
  'ea644a', 'ec9d48', 'ecd748',  # red orange yellow
  '54ec48', '48c4ec', 'de48ec',  # green blue pink
  '7648ec'                       # purple
 )
);

$rainbowcolors = array(				# enough for 51 hops		name: rainbow
 'dark' => array(
  "000000", "0009f3", "011bdb", "022dc3", "033fab", "045193", "04627b", "057463",
  "06864b", "079833", "08aa1b", "14b70e", "2dbe0d", "46c60b", "5ece0a", "77d508",
  "90dd07", "a9e405", "c1ec04", "daf402", "f3fb01", "fffa00", "fff100", "ffe800",
  "ffdf00", "ffd500", "ffcc00", "ffc300", "ffba00", "ffb100", "ffa700", "ff9900",
  "ff8800", "ff7800", "ff6700", "ff5700", "ff4600", "ff3600", "ff2500", "ff1500",
  "ff0400", "f2000a", "e20018", "d10025", "c00033", "af0041", "9e004e", "8e005c",
  "7d0069", "6c0077", "5b0085"
 ),
 'light' => array(	# TODO we need to make this lighter than the above
  "000000", "0009f3", "011bdb", "022dc3", "033fab", "045193", "04627b", "057463",
  "06864b", "079833", "08aa1b", "14b70e", "2dbe0d", "46c60b", "5ece0a", "77d508",
  "90dd07", "a9e405", "c1ec04", "daf402", "f3fb01", "fffa00", "fff100", "ffe800",
  "ffdf00", "ffd500", "ffcc00", "ffc300", "ffba00", "ffb100", "ffa700", "ff9900",
  "ff8800", "ff7800", "ff6700", "ff5700", "ff4600", "ff3600", "ff2500", "ff1500",
  "ff0400", "f2000a", "e20018", "d10025", "c00033", "af0041", "9e004e", "8e005c",
  "7d0069", "6c0077", "5b0085"
 )
);

$rainbowsmallcolors = array(			# enough for 25 hops		name: rainbow-small
 'dark' => array(
  "000000", "011bdb", "033fab", "04627b",
  "06864b", "08aa1b", "2dbe0d", "5ece0a",
  "90dd07", "c1ec04", "f3fb01", "fff100",
  "ffdf00", "ffcc00", "ffba00", "ffa700",
  "ff8800", "ff6700", "ff4600", "ff2500",
  "ff0400", "e20018", "c00033", "9e004e",
  "7d0069"
 ),
 'light' => array(
  "0009f3", "022dc3", "045193", "057463",
  "079833", "14b70e", "46c60b", "77d508",
  "a9e405", "daf402", "fffa00", "ffe800",
  "ffd500", "ffc300", "ffb100", "ff9900",
  "ff7800", "ff5700", "ff3600", "ff1500",
  "f2000a", "d10025", "af0041", "8e005c",
  "6c0077"
 )
);

$boringcolors = array(				# enough for 34 hops		name: boring
  'dark' => array(
    '000000', '101010', '202020', '303030', '404040', '505050', '606060', '707070', '808080', '909090', 'a0a0a0', 'b0b0b0', 'c0c0c0', 'd0d0d0', 'e0e0e0', 'f0f0f0', 'ffffff',
    '000000', '101010', '202020', '303030', '404040', '505050', '606060', '707070', '808080', '909090', 'a0a0a0', 'b0b0b0', 'c0c0c0', 'd0d0d0', 'e0e0e0', 'f0f0f0', 'ffffff'
  ),
  'light' => array(
    '080808', '181818', '282828', '383838', '484848', '585858', '686868', '787878', '888888', '989898', 'a8a8a8', 'b8b8b8', 'c8c8c8', 'd8d8d8', 'e8e8e8', 'f8f8f8', 'ffffff',
    '080808', '181818', '282828', '383838', '484848', '585858', '686868', '787878', '888888', '989898', 'a8a8a8', 'b8b8b8', 'c8c8c8', 'd8d8d8', 'e8e8e8', 'f8f8f8', 'ffffff'
  )
);



## main
$opt[1] =  " --title \"Accu Ping for " . $this->MACRO['DISP_HOSTNAME'] . ' / ' . $this->MACRO['DISP_SERVICEDESC'] . "\" ";
$opt[1] .= " --font DEFAULT:7: --lower-limit 0 --slope-mode ";
$def[1] = "";

$opt[2] =  " --title \"Diff Ping for " . $this->MACRO['DISP_HOSTNAME'] . ' / ' . $this->MACRO['DISP_SERVICEDESC'] . "\" ";
$opt[2] .= " --font DEFAULT:7: --lower-limit 0 --slope-mode ";
$def[2] = "";

$usedcolors = $oldschoolcolors;
if ($coloring == "boring") $usedcolors = $boringcolors;
if ($coloring == "rainbow") $usedcolors = $rainbowcolors;
if ($coloring == "rainbow-small") $usedcolors = $rainbowsmallcolors;

$tmpdef = create_graph ($this->DS, $graphtype, "hop", $usedcolors, $coloringoffset);
if ($DEBUG > 0) $tmpdef = " DEBUG OUTPUT\n $tmpdef ";
if ($tmpdef == "")
{
  $opt[1] = "";
  $def[1] = "";
}
else
{
  $def[1] = $tmpdef;
}

$tmpdef = create_graph ($this->DS, $graphtype, "dhop", $usedcolors, $coloringoffset);
if ($DEBUG > 0) $tmpdef = " DEBUG OUTPUT\n $tmpdef ";
if ($tmpdef == "")
{
  $opt[2] = "";
  $def[2] = "";
}
else
{
  $def[2] = $tmpdef;
}














## more func
function create_graph ($cur_ds, $graphtype = "nice", $dsprefix = "Hop", $usedcolors = array(), $coloringoffset = 0)
{
  global $DEBUG;

  $dsprefixlc = strtolower($dsprefix);

  $found_dsprefix = false;

  $ds_data = array();      # assoc
  $ds_keynames = array();  # 0..99
  $ds_names = array();

  $tmpdef = "";   # which we return once we re done here

  $numcolors = sizeof($usedcolors['dark']);
  # make sure coloringoffset is a positive number and is within the color-array range
  $coloringoffset = abs($coloringoffset);
  $coloringoffset = $coloringoffset % ($numcolors-1);
  
  # 1. collect names and values
  $linecnt = 1;
  reset ($cur_ds);
  foreach ($cur_ds as $key => $val)
  {
    if (! isset($ds_data[ $val['NAME'] ]))  # key = number (0..99), without leading zeroes
    {
      if ((strpos(strtolower($val['NAME']), $dsprefixlc) !== false) and (strpos(strtolower($val['NAME']), $dsprefixlc) == 0))
      {
        $ds_data[ sprintf("%015d###%s", $val['MAX'], $val['NAME']) ] = array( 'key' => $key, 'val' => $val );
      }
    } # end if new key gotten
    else
    {
      $tmpdef .= "DupKey$key: " .$val['NAME']. "  ";
    } # end if dupe key gotten

    $linecnt++;
  } # end foreach name/value collector

  # 2. sort data in reverse alphabetical order
  reset ($ds_data); krsort ($ds_data);

  # 3. get keynames at current position for later referencing
  $linecnt = 1;
  foreach ($ds_data as $k => $v)   # go from back to front because of the nature of traceroute and pings
  {
    $ds_keynames["DP$linecnt"] = $k;
    $ds_names[$v['val']['NAME']] = "DP$linecnt";
    $linecnt++;
  } # end foreach key in order

  $curstart = 1; $curend = sizeof($ds_keynames);
  for ($xx = $curstart; $xx <= $curend; $xx++)
  {
    $curk = $ds_keynames["DP${xx}"];  $v = $ds_data [$curk];
    $tmpdef .= "DEF:DP${xx}=" .$v['val']['RRDFILE']. ":" .$v['val']['DS']. ":AVERAGE ";
  } # end for all dp of image - def


  # use cdef to have other than bytes values (ie. 1073741824 => GB, 1024768 => MB)
  for ($xx = $curstart; $xx <= $curend; $xx++)
  {
    $curk = $ds_keynames["DP${xx}"];  $v = $ds_data [$curk];
    $s = "DP$xx,";
## The following comment is simply adding up all datapoint values on a given x-position
##    $s = $v['key'] .",";
#    for ($i=1; $i <= $xx; $i++)
#      { $curk = $ds_keynames["DP$i"]; $s .= "DP$i" .","; }
##      { $curk = $ds_keynames["Hop$i"]; $s .= $v['key'] .","; }
#    for ($i=1; $i <= ($xx-1); $i++)
#      { $s .= "+,"; }
#
#    $s .= "UNKN,IF";
##
    $tmpdef .= sprintf ("CDEF:%s%s=%s", $v['val']['NAME'], "", "DP$xx"). " ";
    if ($graphtype == "nice")
    {
      $tmpdef .= sprintf ("CDEF:%s%s=%s", $v['val']['NAME'], (($DEBUG > 0)?"--".$ds_keynames["DP$xx"]:"area"), "DP${xx},0,GT,DP${xx},UNKN,IF"). " ";
    }
  } # end for all dp of image - cdef

  # 4. draw stacking lines
  for ($xx = $curstart; $xx <= $curend; $xx++)
  {
    $curk = $ds_keynames["DP${xx}"];  $v = $ds_data [$curk];

    $s = "";
    if ($dsprefixlc == "dhop")
    {
      $s = (($xx > 1) ? ":STACK" : "");
    }

    # print it
    if ($graphtype == "nice")     # 25-1 = 0 bis 24 ; d.h. 24 + offset - (1 bis 16) 
    {
      $tmpoffset = $coloringoffset+$xx;
      if ($tmpoffset >= $numcolors-1) $tmpoffset -= $numcolors -1;
      if ($tmpoffset < 0) $tmpoffset += $numcolors-1;
      $tmpdef .= sprintf ("AREA:%sarea#%s#000000:\"\"%s", $v['val']['NAME'], $usedcolors['light'][$tmpoffset], $s). "  ";
    }
  }

  # then overlay with lines of darker colors
  for ($xx = $curstart; $xx <= $curend; $xx++)
  {
    $curk = $ds_keynames["DP${xx}"];  $v = $ds_data [$curk];

    # get a fine label
    $prtname = $ds_data[$curk]['val']['NAME'];
    $prtname = trim(preg_replace ("/_/", " ", $prtname));

    $tmpoffset = $coloringoffset+$xx;
    if ($tmpoffset >= $numcolors-1) $tmpoffset -= $numcolors -1;
    if ($tmpoffset < 0) $tmpoffset += $numcolors-1;
    $tmpdef .= sprintf ("LINE1:%s%s#%s:\"%s\"", $v['val']['NAME'], "", $usedcolors['dark'][$tmpoffset], $prtname). " ";
    $tmpdef .= sprintf ("GPRINT:%s:%s:\"%s\"", $v['val']['NAME'], "LAST", "Current %6.2lf ms   Min Avg Max "). " ";
    $tmpdef .= sprintf ("GPRINT:%s:%s:\"%s\"", $v['val']['NAME'], "MIN", "%6.2lf"). " ";
    $tmpdef .= sprintf ("GPRINT:%s:%s:\"%s\"", $v['val']['NAME'], "AVERAGE", "%6.2lf"). " ";
    $tmpdef .= sprintf ("GPRINT:%s:%s:\"%s\\c\"", $v['val']['NAME'], "MAX", "%6.2lf ms"). " ";

    $found_dsprefix = true;
  }

  $tmpdef .= "COMMENT:\"\\c\"  ";
  $tmpdef .= "COMMENT:\"check_traceroute_pingplot graph template\\r\"  ";
  $tmpdef .= "COMMENT:\"Command " . $val['TEMPLATE'] . " (template\: nice)\\r\"  ";

  # dont return half-finished template, if we didnt get datapoints from the rrd
  if ($found_dsprefix != true) { $tmpdef = ""; }

  return ($tmpdef);
} # end func nice_graph



?>
