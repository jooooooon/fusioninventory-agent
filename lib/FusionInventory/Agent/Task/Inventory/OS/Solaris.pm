package FusionInventory::Agent::Task::Inventory::OS::Solaris;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

our $runAfter = ["FusionInventory::Agent::Task::Inventory::OS::Generic"];

sub isInventoryEnabled {
    return $OSNAME eq 'solaris';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Operating system informations
    my $OSName = getFirstLine(command => 'uname -s');
    my $OSLevel = getFirstLine(command => 'uname -r');
    my $OSComment = getFirstLine(command => 'uname -v');

    my $OSVersion = getFirstLine(file => '/etc/release', logger => $logger);
    $OSVersion =~ s/^\s+//;

    if (!$OSVersion) {
        $OSVersion = $OSComment;
    }

    # Hardware informations
    my $karch = getFirstLine(command => 'arch -k');
    my $hostid = getFirstLine(command => 'hostid');
    my $proct = getFirstLine(command => 'uname -p');
    my $platform = getFirstLine(command => 'uname -i');
    my $HWDescription = "$platform($karch)/$proct HostID=$hostid";

    $inventory->setHardware({
        OSNAME      => "$OSName $OSLevel",
        OSCOMMENTS  => $OSComment,
        OSVERSION   => $OSVersion,
        DESCRIPTION => $HWDescription
    });
}

1;
