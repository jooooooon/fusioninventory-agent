package FusionInventory::LoggerBackend::File;
use strict;

sub new {
  my ($class, $params) = @_;

  my $self = {};
  $self->{config} = $params->{config};
  $self->{logfile} = $self->{config}->{logdir}."/".$self->{config}->{logfile};

  bless $self, $class;
  return $self;
}

sub addMsg {

  my ($self, $args) = @_;

  my $level = $args->{level};
  my $message = $args->{message};

  return if $message =~ /^$/;

  open FILE, ">>".$self->{config}->{logfile} or warn "Can't open ".
  "`".$self->{config}->{logfile}."'\n";
  print FILE "[".localtime()."][$level] $message\n";
  close FILE;

}

1;
