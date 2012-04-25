#!/usr/bin/perl

my $inputfile = "../input/2b_tested.lst";
my %roles, %masters, %slaves, %cc_has_broker;
$ENV{'EUCALYPTUS'} = "/opt/eucalyptus";

open(FH, "$inputfile") or die "failed to open $inputfile";
while(<FH>) {
    chomp;
    my $line = $_;
    my ($ip, $distro, $version, $arch, $source, @component_str) = split(/\s+/, $line);
    if ($ip =~ /\d+\.\d+\.\d+\.\d+/ && $distro && $version && ($arch eq "32" || $arch eq "64") && $source && @component_str) {
	foreach $component (@component_str) {
	    $component =~ s/\[//g;
	    $component =~ s/\]//g;
	    print "C: $component\n";
	    if ($masters{"$component"}) {
		$slaves{"$component"} = $masters{"$component"};
	    }
	    $masters{"$component"} = "$ip";
	    $roles{"$component"} = 1;
	    if ($distro =~ /VMWARE/ && $component =~ /NC(\d+)/) {
		$cc_has_broker{"CC$1"} = 1;
	    }
	}
    }
}
close(FH);
foreach $component (keys(%roles)) {
    # switch the master/slaves for all but the CLC
    if (($masters{$component} && $slaves{$component}) && (! ($component =~ /CLC/))) {
	print "SWITCHIN\n";
	$s = $slaves{$component};
	$slaves{$component} = $masters{$component};
	$masters{$component} = $s;
    }
    print "Component: $component Master: $masters{$component} Slave: $slaves{$component}\n";
}

# these need to be specified on a per test basis (configuration of test option)
$component_to_switch = shift @ARGV;
$rank_to_switch = shift @ARGV;
if (!$component_to_switch || !$rank_to_switch) {
    print "usage: $0 <component> <rank>\n";
    exit 1;
}

if ($component_to_switch =~ /CC\d+/) {
    $kill_cmd = "/tmp/cleannet.pl /tmp/2b_tested.lst";
    if ($cc_has_broker{$component_to_switch}) {
	$second_kill_cmd = "echo hello";
    }
} elsif ($component_to_switch =~ /VMWARE\d+/) {
    $kill_cmd = "echo hello";
    $component_to_switch =~ s/VMWARE/CC/;
} elsif ($component_to_switch =~ /NC\d+/) {
    $kill_cmd = "/tmp/cleannet.pl /tmp/2b_tested.lst";
} else {
    $kill_cmd = "echo hello";
}

if ($rank_to_switch eq "MASTER") {
    $ip_to_switch = $masters{"$component_to_switch"};
} else {
    $ip_to_switch = $slaves{"$component_to_switch"};
}

$cmd = "scp -o StrictHostKeyChecking=no ../input/2b_tested.lst root\@$ip_to_switch:/tmp/";
print "CMD TO RUN '$cmd'\n";
$rc = system($cmd);
$cmd = "scp -o StrictHostKeyChecking=no cleannet.pl root\@$ip_to_switch:/tmp/";
print "CMD TO RUN '$cmd'\n";
$rc = system($cmd);

if ($ip_to_switch && $kill_cmd) {
    print "DOIT: '$component_to_switch' located at '$ip_to_switch' with cmd '$kill_cmd'\n";
    $cmd = "ssh -o StrictHostKeyChecking=no root\@$ip_to_switch \"$kill_cmd\"";
    print "CMD TO RUN '$cmd'\n";
    $rc = system($cmd);
} else {
    print "usage: $0 <component> <rank>\n";
    exit 1;
}

# second kill command may be needed for VMware Broker
if ($rc==0 && $ip_to_switch && $second_kill_cmd) {
    $cmd = "ssh -o StrictHostKeyChecking=no root\@$ip_to_switch \"$second_kill_cmd\"";
    print "CMD TO RUN '$cmd'\n";
    $rc = system($cmd);
}

exit ($rc);
