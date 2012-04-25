#!/usr/bin/perl

require "ec2ops.pl";

$start_or_stop = shift @ARGV || "START";
$component_to_switch = shift @ARGV || "CLC";
$rank_to_switch = shift @ARGV || "MASTER";
$failure_mode = shift @ARGV || "script";

parse_input();
print "SUCCESS: parsed input\n";

setlibsleep(0);
print "SUCCESS: set sleep time for each lib call\n";

setremote($masters{"CLC"});
print "SUCCESS: set remote CLC: masterclc=$masters{CLC}\n";

setfailuretype($failure_mode);
print "SUCCESS: set failure mode to: $failure_mode\n";

if ($component_to_switch eq "ALL") {
    foreach $component (keys(%masters)) {
	if ($rank_to_switch eq "BOTH") {
	    control_component($start_or_stop, $component, "MASTER");
	    control_component($start_or_stop, $component, "SLAVE");
	} else {
	    control_component($start_or_stop, $component, $rank_to_switch);
	}
    }
} else {
    if ($rank_to_switch eq "BOTH") {
	control_component($start_or_stop, $component_to_switch, "MASTER");
	control_component($start_or_stop, $component_to_switch, "SLAVE");
    } else {
	control_component($start_or_stop, $component_to_switch, $rank_to_switch);
    }
}
print "SUCCESS: controlled component: $start_or_stop, $component_to_switch ($current_artifacts{controlip}), $rank_to_switch\n";

doexit(0, "EXITING SUCCESS\n");

create_volume(1);
print "SUCCESS: created volume: vol=$current_artifacts{volume}\n";

wait_for_volume();
print "SUCCESS: volume became available: vol=$current_artifacts{volume}, volstate=$current_artifacts{volumestate}\n";

attach_volume();
print "SUCCESS: attached volume: volstate=$current_artifacts{volumestate}\n";

wait_for_volume_attach();
print "SUCCESS: volume became attached: volstate=$current_artifacts{volumestate}\n";

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";

run_instance_command("echo y | mkfs.ext3 $idev");
run_instance_command("mkdir -p /tmp/testmount");
run_instance_command("mount $idev /tmp/testmount");
run_instance_command("dd if=/dev/zero of=/tmp/testmount/file bs=1M count=10");
run_instance_command("umount /tmp/testmount");
print "SUCCESS: formatted, mounted, copied data to, and unmounted volume\n";

detach_volume();
print "SUCCESS: detached volume\n";
wait_for_volume_detach();
print "SUCCESS: volume became detached: volstate=$current_artifacts{volumestate}\n";

attach_volume();
print "SUCCESS: attached volume: volstate=$current_artifacts{volumestate}\n";
wait_for_volume_attach();
print "SUCCESS: volume became attached: volstate=$current_artifacts{volumestate}\n";

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";

run_instance_command("mount $idev /tmp/testmount");
run_instance_command("ls /tmp/testmount/file");
run_instance_command("umount /tmp/testmount");
print "SUCCESS: re-mounted, verified data, and unmounted volume\n";

detach_volume();
print "SUCCESS: detached volume\n";

wait_for_volume_detach();
print "SUCCESS: volume became detached: volstate=$current_artifacts{volumestate}\n";

create_snapshot();
print "SUCCESS: created snapshot: snap=$current_artifacts{snapshot}\n";

wait_for_snapshot();
print "SUCCESS: snapshot became available: snap=$current_artifacts{snapshotstate}\n";

delete_volume();
print "SUCCESS: volume deleted: vol=$current_artifacts{volume} state=$current_artifacts{volumestate}\n";

create_snapshot_volume();
print "SUCCESS: volume created from snapshot: vol=$current_artifacts{volume}\n";

wait_for_volume();
print "SUCCESS: volume became available: vol=$current_artifacts{volume}, volstate=$current_artifacts{volumestate}\n";

attach_volume();
print "SUCCESS: attached volume: volstate=$current_artifacts{volumestate}\n";

wait_for_volume_attach();
print "SUCCESS: volume became attached: volstate=$current_artifacts{volumestate}\n";

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";

run_instance_command("echo y | mkfs.ext3 $idev");
run_instance_command("mkdir -p /tmp/testmount");
run_instance_command("mount $idev /tmp/testmount");
run_instance_command("dd if=/dev/zero of=/tmp/testmount/file bs=1M count=10");
run_instance_command("umount /tmp/testmount");
print "SUCCESS: formatted, mounted, copied data to, and unmounted volume\n";

detach_volume();
print "SUCCESS: detached volume\n";
wait_for_volume_detach();
print "SUCCESS: volume became detached: volstate=$current_artifacts{volumestate}\n";

attach_volume();
print "SUCCESS: attached volume: volstate=$current_artifacts{volumestate}\n";
wait_for_volume_attach();
print "SUCCESS: volume became attached: volstate=$current_artifacts{volumestate}\n";

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";

run_instance_command("mount $idev /tmp/testmount");
run_instance_command("ls /tmp/testmount/file");
run_instance_command("umount /tmp/testmount");
print "SUCCESS: re-mounted, verified data, and unmounted volume\n";

detach_volume();
print "SUCCESS: detached volume\n";

wait_for_volume_detach();
print "SUCCESS: volume became detached: volstate=$current_artifacts{volumestate}\n";

delete_volume();
print "SUCCESS: volume deleted: vol=$current_artifacts{volume} state=$current_artifacts{volumestate}\n";

delete_snapshot();
print "SUCCESS: snapshot deleted: snap=$current_artifacts{snapshot}, snapstate=$current_artifacts{snapshotstate}\n";

doexit(0, "EXITING SUCCESS\n");
