#!/usr/bin/perl

use URI;

$ec2timeout = 30;

sub failure {
  my($msg) = @_;
  print "[TEST_REPORT]\tFAILED: ", $msg, "\n";
  exit(1);
}

sub success {
  my($msg) = @_;
  print "[TEST_REPORT]\t", $msg, "\n";
}

$mode = shift @ARGV;


my @ips;

open(INPUT, "../input/2b_tested.lst") || die "Cannot open input/2b_tested.lst";

while(<INPUT>) {
    if ($_ =~ /(.*)\t(.*)\t(.*)\t(.*)\t(.*)\t(.*CLC.*)/) {
        push(@ips, $1);
    }
}

close(INPUT);

$count=20;
$done=0;
while(!$done && $count > 0) {
system("date");
$cmd = "runat $ec2timeout ec2-describe-instances";
$count=0;
open(RFH, "$cmd|");
while(<RFH>) {
    chomp;
    my $line = $_;
    print "DESCRIBE INSTANCES: $line\n";
    my ($type, $id, $emi, $ip0, $ip1, $status, @tmp) = split(/\s+/, $line);
    if ($type eq "INSTANCE" && $status eq "running" && !($ip0 =~ m/^(euca-0-0-0-0)/i)  ) {
	$done++;
    }
}
$count--;
close(RFH);
sleep(30);
}

#cleanup any terminated instances
system("date");
$cmd = "runat $ec2timeout ec2-describe-instances";
$count=0;
open(RFH, "$cmd|");
while(<RFH>) {
    chomp;
    my $line = $_;
    print "OUTPUT: $line\n";
    my ($type, $id, $emi, $ip0, $ip1, $status, @tmp) = split(/\s+/, $line);
    if ($type eq "INSTANCE" && $status eq "terminated") {
      $terminated_ids[$count] = $id;
      $count++;
    }
}
close(RFH);

for $id(@terminated_ids) {
  $cmd = "runat $ec2timeout ec2-terminate-instances $id";
  open(RFH, "$cmd|");
  while(<RFH>) {
    chomp;
    my $line = $_;
    print "OUTPUT: $line\n";
  }
}

sub get_ips{
    $cmd = "runat $ec2timeout ec2-describe-instances";
    open(RFH, "$cmd|");
    while(<RFH>) {
	chomp;
	my $line = $_;
	print "OUTPUT: $line\n";
	($type, $id, $emi, $publicip, $privateip, @tmp) = split(/\s+/, $line);
  }
  close(RFH);
  failure("Public IP not found") unless defined $publicip;
  failure("Private IP not found") unless defined $privateip;
  return ($publicip, $privateip);
}


sub resolve_hostname{
  my($ec2_host, $hostname) = @_;
  $cmd = "dig \@$ec2_host $hostname";
  open(RFH, "$cmd|");
  $found = 0;
  while(<RFH>) {
    chomp;
    my $line = $_;
    print $_;
    if ($line =~ /^$hostname\./) {
       success ($line);
       $found = 1;
    }
  }
  close(RFH);
  failure("Unable to resolve $hostname") if($found == 0);
}


#my $s3_url = URI->new($ENV{'S3_URL'});
#$s3_host = $s3_url->host();

#failure("Unable to get S3 host. Is S3_URL set?") unless defined $s3_host;

#my $ec2_url = URI->new($ENV{'EC2_URL'});
#$ec2_host = $ec2_url->host();

#failure("Unable to get EC2_URL host. Is EC2_URL set?") unless defined $ec2_host;


#$s3curl_home = $ENV{'S3_CURL_HOME'};
#$id = $ENV{'EC2_ACCESS_KEY'};
#$key = $ENV{'EC2_SECRET_KEY'};
#$s3_url = $ENV{'S3_URL'};

#failure("S3_CURL_HOME must be set.") unless defined $s3curl_home;
#failure("EC2_ACCESS_KEY must be set.") unless defined $id;
#failure("EC2_SECRET_KEY must be set.") unless defined $key;
#failure("S3_URL must be set.") unless defined $s3_url;

($public_ip, $private_ip) = get_ips();
resolve_hostname($ips[$mode], $public_ip);
resolve_hostname($ips[$mode], $private_ip);
exit(0);
