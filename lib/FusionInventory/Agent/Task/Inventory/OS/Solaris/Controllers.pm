package FusionInventory::Agent::Task::Inventory::OS::Solaris::Controllers;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return can_run('cfgadm');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $handle = getFileHandle(
        command => 'cfgadm -s cols=ap_id:type:info',
        logger  => $logger,
    );

    return unless $handle;

    while (my $line =~ <$handle>) {
        next if $line =~  /^Ap_Id/;
        next unless $line =~ /^(\S+)\s+(\S+)\s+(\S+)/;
        my $name = $1;
        my $type = $2;
        my $manufacturer = $3;
        $inventory->addEntry({
            section => 'CONTROLLERS',
            entry => {
                NAME         => $name,
                MANUFACTURER => $manufacturer,
                TYPE         => $type,
            }
        });
    }
    close $handle;
}

1;
