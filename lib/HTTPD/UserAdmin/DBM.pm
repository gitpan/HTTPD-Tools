# $Id: DBM.pm,v 1.11 1996/03/11 00:01:23 dougm Exp $
package HTTPD::UserAdmin::DBM;
@ISA = qw(HTTPD::UserAdmin);
require HTTPD::UserAdmin;
require Carp;

my %Default = (PATH => ".",
	       DB => ".htpasswd",
	       DBMF => "NDBM", 
	       FLAGS => "rwc",
	       MODE => 0644, 
	    );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    $self->_dbm_init;
    $self->db($self->{DB}); 
    return $self;
}

sub DESTROY {
    $_[0]->_untie('_HASH');
    $_[0]->unlock;
}

package HTTPD::UserAdmin::DBM::_generic;
@ISA = qw(HTTPD::UserAdmin::DBM);

sub add {
    my($self, $user, $passwd, $noenc, @rest) = @_;
    return(0, "add_user: no user name!") unless $user;
    return(0, "add_user: no password!") unless $passwd;
    return(0, "user '$user' exists in $self->{DB}") 
	if $self->exists($user);
    $noenc ||= 0;
    local($^W) = 0; #shutup uninit warnings

    my $dlm = ":";
    $dlm = $self->{DLM} if defined $self->{DLM};
    my $pass = ($noenc ? $passwd : $self->encrypt($passwd));
    $self->{_HASH}{$user} = $pass . (@rest ? ($dlm . join($dlm,@rest)) : "");
    1;
}

sub exists {
    my($self, $name) = @_;
    return 0 unless defined $self->{_HASH}{$name};
    return $self->{_HASH}{$name};
}

sub delete {
    my($self, $user) = @_;
    my $rc = 1; 
    delete($self->{_HASH}{$user});
    $self->{_HASH}{$user} and $rc = 0;
    $rc;
}

sub db {
    my($self, $file) = @_;
    my $old = $self->{DB};
    return $old unless $file;
    if($self->{_HASH}) {
	$self->DESTROY;
    }
    $file = $file =~ m,^\.*/, ? $file : "$self->{PATH}/$file";
    $file =~ /^[^<>;|]+$/ or Carp::croak("Bad file name '$file'"); $file = $&; #untaint

    $self->{DB} = $file;

    #return unless $self->{NAME};	
    $self->lock || Carp::croak();
    $self->_tie('_HASH', $self->{DB});
    $old;
}

sub list {
    keys %{$_[0]->{_HASH}};
}

1;

__END__


