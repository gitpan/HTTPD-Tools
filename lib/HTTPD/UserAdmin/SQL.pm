# $Id: SQL.pm,v 1.12 1997/02/03 02:42:36 dougm Exp $
package HTTPD::UserAdmin::SQL;
use DBI;
use Carp ();
use strict;
use vars qw(@ISA);
@ISA = qw(HTTPD::UserAdmin);

my %Default = (HOST => "",                  #server hostname
	       DB => "",                    #database name
	       USER => "", 	            #database login name	    
	       AUTH => "",                  #database login password
	       DRIVER => "mSQL",            #driver for DBI
	       USERTABLE => "",             #table with field names below
	       NAMEFIELD => "user",         #field for the name
	       PASSWORDFIELD => "password", #field for the password
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    $self->_check(qw(DRIVER DB USERTABLE)); 
    $self->db($self->{DB});	
    return $self;
}

sub db {
    my($self,$db) = @_;
    my $old = $self->{DB};
    return $old unless $db;
    $self->{DB} = $db; 

    if(defined $self->{'_DBH'}) {
	$self->{'_DBH'}->disconnect;
    }

    #we should just be able to say this:
    #$self->{_DBH} = DBI->connect( @{$self}{ qw(DB  USER  PASSWORD  DRIVER) } );
    #this needs to be fixed in a big way

    #so we do this hack for now for mSQL, 
    #I'm ignoring the Informix driver problem for now
    my(@args) = qw(DB  USER  PASSWORD  DRIVER);
    if($self->{DRIVER} eq 'mSQL') {
	@args = ('HOST', 'DB', '', 'DRIVER');
    }
    $self->{'_DBH'} = DBI->connect( @{$self}{ @args } );

    return $old;
}

sub DESTROY {}

package HTTPD::UserAdmin::SQL::_generic;
use vars qw(@ISA);
@ISA = qw(HTTPD::UserAdmin::SQL);

sub add {
    my($self, $username, $passwd, $noenc) = @_;
    return(0, "add_user: no user name!") unless $username;
    return(0, "add_user: no password!") unless $passwd;
    return(0, "user '$username' already exists!") 
	if $self->exists($username);

    my $statement = 
	sprintf("INSERT into %s (%s, %s)\n VALUES ('%s', '%s')\n",
		@{$self}{qw(USERTABLE NAMEFIELD PASSWORDFIELD)}, $username, 
		$noenc ? $passwd : $self->encrypt($passwd));

    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
    1;
}

sub exists {
    my($self, $username) = @_;
    my $statement = 
	sprintf("SELECT %s from %s WHERE %s='%s'\n",
		@{$self}{qw(PASSWORDFIELD USERTABLE NAMEFIELD)}, $username);
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement);
    Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	unless $sth;
    $sth->execute || Carp::croak($DBI::err);
    my(@row) = $sth->fetchrow;
    $sth->finish;
    return $row[0];
}

sub delete {
    my($self, $username) = @_;
    my $statement = 
	sprintf("DELETE from %s where %s='%s'\n",
		@{$self}{qw(USERTABLE NAMEFIELD)}, $username);
    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
}

sub update {
    my($self, $username, $passwd) = @_;
    return 0 unless $self->exists($username);
    my $statement = 
	sprintf("UPDATE %s SET %s='%s'\n WHERE %s = '%s'\n",
		@{$self}{qw(USERTABLE PASSWORDFIELD)}, $self->encrypt($passwd),
		$self->{NAMEFIELD}, $username);
    print STDERR $statement if $self->debug;
    $self->{'_DBH'}->do($statement) || Carp::croak($DBI::errstr);
}

sub list {
    my($self) = @_;
    my $statement = 
	sprintf("SELECT %s from %s\n",
		@{$self}{qw(NAMEFIELD USERTABLE)});
    print STDERR $statement if $self->debug;
    my $sth = $self->{'_DBH'}->prepare($statement);
    Carp::carp("Cannot prepare sth ($DBI::err): $DBI::errstr")
	unless $sth;
    $sth->execute || Carp::croak($DBI::err);
    my($user,@list);
    while($user = $sth->fetchrow) {
	push(@list, $user);
    }
    $sth->finish;
    return @list;
}

1;

__END__

CREATE table auth_users (
    user char(40),
    password char(20)
)
   
