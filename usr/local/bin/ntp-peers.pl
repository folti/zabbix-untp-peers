#!/usr/bin/perl

use strict;
#add path if needed into $smartctl_cmd
my $cmd = undef;
my $host = $ENV{"NTP_SERVER"} || "localhost";

foreach my $pth (split(":", $ENV{'PATH'})) {
    my $_cmd = "$pth/ntpq";
    if ( -x $_cmd ) {
        $cmd = $_cmd;
        last;
    }
}

if ( ! defined $cmd ) {
    print "\nntpq not found in \$PATH.";
    exit 1;
}

my $num_args = $#ARGV + 1;
my $command = $ARGV[0];
if (($num_args != 2)and(!($command eq "discovery" || $command eq "server-count"))) {
    print "\nUsage: ntp-peers.pl command [peer_ip]\n";
    exit;
}
my $dpeer = $ARGV[1];

my @pout = `$cmd -n -c peers $host | grep -v '.PEER.' | awk 'match(\$1, /[0-9\\.]+/) {print \$1,\$(NF-7),\$(NF-2),\$(NF-1),\$NF;}'`;

if ($command eq "discovery") {
  my $first = 1;
  print "{\"data\":[";
  foreach my $line (@pout) {
    chomp $line;
    my ($peer,$stratum,$delay,$offset,$jitter) = split(" ",$line);
    $peer=~s/(\d+\.\d+\.\d+\.\d+)/$1/g;
    $peer=$1;
    print "," if not $first;
    $first = 0;
    print "{";
    print "\"{#PEER}\":\"$peer\",";
    print "\"{#STRATUM}\":\"$stratum\"";
    print "}";
  }
  print "]}";
}
elsif ($command eq "stratum") {
  foreach my $line (@pout) {
    chomp $line;
    my ($peer,$stratum,$delay,$offset,$jitter) = split(" ",$line);
    $peer=~s/(\d+\.\d+\.\d+\.\d+)/$1/g;
    $peer=$1;
    if ($peer =~ /$dpeer/) { print "$stratum\n"; }
  }
}
elsif ($command eq "delay") {
  foreach my $line (@pout) {
    chomp $line;
    my ($peer,$stratum,$delay,$offset,$jitter) = split(" ",$line);
    $peer=~s/(\d+\.\d+\.\d+\.\d+)/$1/g;
    $peer=$1;
    if ($peer =~ /$dpeer/) { print "$delay\n"; }
  }
}
elsif ($command eq "offset") {
  foreach my $line (@pout) {
    chomp $line;
    my ($peer,$stratum,$delay,$offset,$jitter) = split(" ",$line);
    $peer=~s/(\d+\.\d+\.\d+\.\d+)/$1/g;
    $peer=$1;
    if ($peer =~ /$dpeer/) { print "$offset\n"; }
  }
}
elsif ($command eq "jitter") {
  foreach my $line (@pout) {
    chomp $line;
    my ($peer,$stratum,$delay,$offset,$jitter) = split(" ",$line);
    $peer=~s/(\d+\.\d+\.\d+\.\d+)/$1/g;
    $peer=$1;
    if ($peer =~ /$dpeer/) { print "$jitter\n"; }
  }
}
elsif ($command eq "above-limit-stratums" || $command eq "stratums-above-limit") {
  my $count = 0;
  foreach my $line (@pout) {
    my ($peer,$stratum,$delay,$offset,$jitter) = split(" ",$line);
    if ($stratum >= $dpeer) {
      $count++;
    }
  }
  print "$count\n";
}
elsif ($command eq "server-count") {
  print $#pout + 1, "\n";
}
else {
  print "$dpeer\n";
}

