package FusionInventory::Agent::Task;

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Find;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    die 'no target parameter' unless $params{target};

    my $self = {
        logger       => $params{logger} ||
                        FusionInventory::Agent::Logger->new(),
        config       => $params{config},
        confdir      => $params{confdir},
        datadir      => $params{datadir},
        target       => $params{target},
        token        => $params{token},
        deviceid     => $params{deviceid},
        user         => $params{user},
        password     => $params{password},
        proxy        => $params{proxy},
        ca_cert_file => $params{ca_cert_file},
        ca_cert_dir  => $params{ca_cert_dir},
        no_ssl_check => $params{no_ssl_check},
    };
    bless $self, $class;

    return $self;
}

sub getPrologResponse {
    my ($self) = @_;

    my $prolog = FusionInventory::Agent::XML::Query::Prolog->new(
        token    => $self->{token},
        deviceid => $self->{deviceid},
    );

    my $response = $self->{client}->send(
        url     => $self->{target}->getUrl(),
        message => $prolog
    );

    return unless $response;

    # update target
    my $content = $response->getContent();
    if (defined($content->{PROLOG_FREQ})) {
        $self->{target}->setMaxDelay($content->{PROLOG_FREQ} * 3600);
    }

    return $response;
}

sub getModules {
    my ($class, $prefix) = @_;

    # allow to be called as an instance method
    $class = ref $class ? ref $class : $class;

    # use %INC to retrieve the root directory for this task
    my $file = module2file($class);
    my $rootdir = $INC{$file};
    $rootdir =~ s/.pm$//;
    return unless -d $rootdir;

    # find a list of modules from files in this directory
    my $root = $file;
    $root =~ s/.pm$//;
    $root .= "/$prefix" if $prefix;
    my @modules;
    my $wanted = sub {
        return unless -f $_;
        return unless $File::Find::name =~ m{($root/\S+\.pm)$};
        my $module = file2module($1);
        push(@modules, $module);
    };
    File::Find::find($wanted, $rootdir);
    return @modules
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Task - Base class for agent task

=head1 DESCRIPTION

This is an abstract class for all task performed by the agent.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<config>

=item I<target>

=item I<storage>

=item I<prologresp>

=item I<client>

=item I<deviceid>

=back

=head2 run()

This is the method to be implemented by each subclass.

=head2 getModules($prefix)

Return a list of modules for this task. All modules installed at the same
location than this package, belonging to __PACKAGE__ namespace, will be
returned. If optional $prefix is given, base search namespace will be
__PACKAGE__/$prefix instead.