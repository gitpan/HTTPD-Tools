# $Id: DBM.pm,v 1.12 1997/02/03 02:42:36 dougm Exp $
package HTTPD::UserAdmin::DBM;
use HTTPD::UserAdmin ();
use Carp ();
use strict;
use vars qw(@ISA);
@ISA = qw(HTTPD::UserAdmin);

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
    $self->{'_HASH'}{$user} = $pass . (@rest ? ($dlm . join($dlm,@rest)) : "");
    1;
}

package HTTPD::UserAdmin::DBM::_generic;
use vars qw(@ISA);
@ISA = qw(HTTPD::UserAdmin::DBM HTTPD::UserAdmin);

1;

__END__



