package FusionInventory::Agent::Task::Inventory::Input::Win32::Printers;

use strict;
use warnings;

use English qw(-no_match_vars);
use Win32::TieRegistry (
    Delimiter   => '/',
    ArrayValues => 0,
    qw/KEY_READ/
);

use FusionInventory::Agent::Tools::Win32;

my @status = (
    'Unknown', # 0 is not defined
    'Other',
    'Unknown',
    'Idle',
    'Printing',
    'Warming Up',
    'Stopped printing',
    'Offline',
);

my @errStatus = (
    'Unknown',
    'Other',
    'No Error',
    'Low Paper',
    'No Paper',
    'Low Toner',
    'No Toner',
    'Door Open',
    'Jammed',
    'Service Requested',
    'Output Bin Full',
    'Paper Problem',
    'Cannot Print Page',
    'User Intervention Required',
    'Out of Memory',
    'Server Unknown',
);

sub isEnabled {
    my (%params) = @_;
    return !$params{no_printer};
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $object (getWmiObjects(
        class      => 'Win32_Printer',
        properties => [ qw/
            ExtendedDetectedErrorState HorizontalResolution VerticalResolution Name
            Comment DescriptionDriverName DriverName PortName Network Shared 
            PrinterStatus ServerName ShareName PrintProcessor
        / ]
    )) {

        my $errStatus;
        if ($object->{ExtendedDetectedErrorState}) {
            $errStatus = $errStatus[$object->{ExtendedDetectedErrorState}];
        }

        my $resolution;

        if ($object->{HorizontalResolution}) {
            $resolution =
                $object->{HorizontalResolution} .
                "x"                             .
                $object->{VerticalResolution};
        }

        $object->{Serial} = _getUSBPrinterSerial($object->{PortName})
            if $object->{PortName} && $object->{PortName} =~ /USB/;

        $inventory->addEntry(
            section => 'PRINTERS',
            entry   => {
                NAME           => $object->{Name},
                COMMENT        => $object->{Comment},
                DESCRIPTION    => $object->{Description},
                DRIVER         => $object->{DriverName},
                PORT           => $object->{PortName},
                RESOLUTION     => $resolution,
                NETWORK        => $object->{Network},
                SHARED         => $object->{Shared},
                STATUS         => $status[$object->{PrinterStatus}],
                ERRSTATUS      => $errStatus,
                SERVERNAME     => $object->{ServerName},
                SHARENAME      => $object->{ShareName},
                PRINTPROCESSOR => $object->{PrintProcessor},
                SERIAL         => $object->{Serial}
            }
        );

    }    
}

sub _getUSBPrinterSerial {
    my ($portName) = @_;

    my $machKey = $Registry->Open('LMachine', { 
        Access => KEY_READ | KEY_WOW64_64 ## no critic (ProhibitBitwise)
    }) or die "Can't open HKEY_LOCAL_MACHINE key: $EXTENDED_OS_ERROR";

    # first, find the USB container ID for this printer
    my $prefix = _getUSBPrefix(
        $machKey->{"SYSTEM/CurrentControlSet/Enum/USBPRINT"},
        $portName
    );
    return unless $prefix;

    # second, get the serial number from the ID container entry
    my $serial = _getUSBSerial(
        $machKey->{"SYSTEM/CurrentControlSet/Enum/USB"},
        $prefix
    );

    return $serial;
}

sub _getUSBPrefix {
    my ($printKey, $portName) = @_;

    # find the printer entry matching given portname
    foreach my $printerKey (values %$printKey) {
        # look for a subkey with expected content
        foreach my $subKeyName (keys %$printerKey) {
            my $subKey = $printerKey->{$subKeyName};
            next unless 
                $subKey->{'Device Parameters/'}                &&
                $subKey->{'Device Parameters/'}->{'/PortName'} &&
                $subKey->{'Device Parameters/'}->{'/PortName'} eq $portName;
            # got it
            my $prefix = $subKeyName;
            $prefix =~ s{&$portName/$}{};
            return $prefix;
        };
    }

    return;
}

sub _getUSBSerial {
    my ($usbKey, $prefix) = @_;

    # find the device entry matching given container Id
    foreach my $deviceKey (values %$usbKey) {
        # look for a subkey with expected content
        foreach my $subKeyName (keys %$deviceKey) {
            my $subKey = $deviceKey->{$subKeyName};
            next unless
                $subKey->{'/ParentIdPrefix'} &&
                $subKey->{'/ParentIdPrefix'} eq $prefix;
            # got it
            my $serial = $subKeyName;
            $serial =~ s{/$}{};
            return $serial;
        }
    }

    return;
}

1;