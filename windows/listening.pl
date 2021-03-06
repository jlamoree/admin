#!/usr/bin/perl -w

# Run this script to display the currently running applications listening on TCP ports
# 
# Joseph Lamoree
# joseph@lamoree.com
# 2009-10-09 14:43 PDT

my $WINDOWS_SYSTEM_PROCESS = "[Windows System Process]";
my $TERMINATED_PROCESS = "[Terminated Process - Socket Cleanup Pending]";

my @conns;
my %procs;
my $buffer = `/cygdrive/c/WINDOWS/system32/netstat -nao -p tcp`;
foreach $_ (split(/\n/, $buffer)) {
  s/^\s+//g;
  if (/^TCP/) { 
    push(@conns, [split(/\s+/)]);
  }
}

$buffer = `/bin/ps -W -a -s`;
foreach $_ (split(/\n/, $buffer)) {
  if (/ unknown /) {
    /^\w?\s+?(\d+)\s+/;
    $procs{$1} = $WINDOWS_SYSTEM_PROCESS;
  } elsif (/^\w?\s+\d+\s+/) {
    /^\w?\s+?(\d+)\s+([\w\?]+)\s+([\d:]{8})\s+(.*)/;
    $procs{$1} = $4;
  }
}

$num = @conns;
print "Connections: $num\n";
for (my $i=0; $i<$num; $i++) {
  my $pid = $conns[$i][4];
  my $proc = ($pid == 0) ? $TERMINATED_PROCESS : $procs{$pid};
  my($ipI, $portI) = split(':', $conns[$i][1]);
  my($ipO, $portO) = split(':', $conns[$i][2]);
  printf('%4d: %15s:%-5s %15s:%-5s %s', $pid, $ipI, $portI, $ipO, $portO, $proc);
  print "\n";
}

exit 0;
