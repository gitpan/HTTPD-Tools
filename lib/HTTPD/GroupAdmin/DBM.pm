# $Id: DBM.pm,v 1.12 1996/03/18 15:50:47 dougm Exp $
package HTTPD::GroupAdmin::DBM;
@ISA = qw(HTTPD::GroupAdmin);
require Carp;

my %Default = (PATH => ".",
	       DB => ".htgroup",
	       DBMF => "NDBM", 
               NAME => "",
               FLAGS => "rwc",
	       MODE => 0644, 
	    );

sub new {
    my($class) = shift;
    my $self = bless {%Default, @_}, $class;
    $self->_dbm_init;
    $self->db($self->{DB}); 
    return $self;
}

DESTROY {
    $_[0]->_untie('_HASH');
    $_[0]->unlock;
}

sub db {
    my($self, $file) = @_;
    my $old = $self->{'DB'};
    return $old unless $file;
    if($self->{_HASH}) {
	$self->DESTROY;
    }
    $file = $file =~ m,^\.*/, ? $file : "$self->{PATH}/$file";
    $self->{'DB'} = $file;

    #return unless $self->{NAME};	
    $self->lock || Carp::croak();
    $self->_tie('_HASH', $self->{DB});
    $old;
}

package HTTPD::GroupAdmin::DBM::_generic;
@ISA = qw(HTTPD::GroupAdmin::DBM);
require Carp;

$DLM = " ";

sub add {
    my($self, $username, $group) = @_;
    $group = $self->{NAME} unless defined $group;
    return(0, "No group name!") unless defined $group;

    unless ($self->{_HASH}{$group}) {
	$self->_tie('_HASH', $self->{DB});
    }
    if ($self->{_HASH}{$group}) {
	return (0, "'$username' already in '$group'") if
	    $self->{_HASH}{$group} =~ /(^|[$DLM]+)$username([$DLM]+|$)/;
    }
    #for that old .= bug, should be fixed now
    my $val = "";	
    if(defined $self->{_HASH}{$group}) {
	$val = $self->{_HASH}{$group} . $DLM;
    }
    $val .= $username;
    $self->{_HASH}{$group} = $val;
}

sub delete {
    my($self,$username,$group) = @_;
    $group = $self->{NAME} unless defined $group;
    $self->{_HASH}->{$group} =~ s/(^|$DLM)$username($DLM|$)/$1$2/;
}

sub remove { 
    my($self,$group) = @_;
    $group = $self->{NAME} unless defined $group;
    delete $self->{_HASH}{$group};
    if($self->{NAME} eq $group) {
	delete $self->{NAME};
    }
    1;
}

sub create {
    my($self,$group) = @_;
    return unless $group;
    Carp::croak("group '$group' exists") if $self->exists($group);
    $self->{_HASH}{$group} = "";
    1;
}

sub exists {
    my($self, $name) = @_;
    return 0 unless defined $self->{_HASH}{$name};
    return $self->{_HASH}{$name};
}

sub list {
    return split(/[$DLM]+/, $_[0]->{_HASH}{$_[1]}) if $_[1];
    keys %{$_[0]->{_HASH}};
}

1;


