# $Id: UserAdmin.pm,v 1.14 1997/07/09 02:35:43 dougm Exp $
package HTTPD::UserAdmin;
use HTTPD::AdminBase ();
use Carp ();
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(HTTPD::AdminBase);
$VERSION = (qw$Revision: 1.14 $)[1];

sub delete {
    my($self, $user) = @_;
    my $rc = 1; 
    delete($self->{'_HASH'}{$user});
    $self->{'_HASH'}{$user} and $rc = 0;
    $rc;
}

sub list {
    keys %{$_[0]->{'_HASH'}};
}

sub exists {
    my($self, $name) = @_;
    return 0 unless defined $self->{'_HASH'}{$name};
    return $self->{'_HASH'}{$name};
}

sub db {
    my($self, $file) = @_;
    my $old = $self->{'DB'};
    return $old unless $file;
    if($self->{'_HASH'}) {
	$self->DESTROY;
    }

    $self->{'DB'} = $file;

    #return unless $self->{NAME};	
    $self->lock || Carp::croak();
    $self->_tie('_HASH', $self->{DB});
    $old;
}

sub group {
    my($self) = shift;
    $self->load('HTTPD::GroupAdmin');
    my %attr = %{$self};
    foreach(qw(DB _HASH)) {
	delete $attr{$_}; #just incase, everything else should be OK
    }
    return new HTTPD::GroupAdmin (%attr, @_);
}

sub update {
    my($self, $username, $passwd) = @_;
    return (0, "User '$username' does not exist") unless $self->exists($username);
    $self->delete($username);
    $self->add($username, $passwd);
    1;
} 

sub convert {
    my($self) = shift;
    my $class = $self->baseclass(2); #hmm
    my $new = $class->new(@_);
    foreach($self->list) {
	$new->add($_, $self->password($_), 1);
    }
    $new;
}

sub password { shift->exists(@_); }

# from Apache's dbmmanage:
# if $newstyle is 1, then use new style salt (starts with '_' and contains
# four bytes of iteration count and four bytes of salt).  Otherwise, just use
# the traditional two-byte salt.
# see the man page on your system to decide if you have a newer crypt() lib.
# I believe that 4.4BSD derived systems do (at least BSD/OS 2.0 does).
# The new style crypt() allows up to 20 characters of the password to be
# significant rather than only 8.

#my %NewStyle = map $_,1, qw(bsd/os-2.0);

sub encrypt {
    my($self) = shift; 
    my $newstyle = defined $_[1]; # || defined $NewStyle{ join("-",@Config{qw(osname osvers)}) };
    my($passwd) = "";
    my($scheme) = $self->{ENCRYPT} || "crypt";
    #not quite sure where we're at risk here...
    $_[0] =~ /^[^<>;|]+$/ or Carp::croak("Bad password name"); $_[0] = $&;
    if($scheme eq "crypt") {
	$passwd = crypt($_[0], salt($newstyle));
    }
    elsif ($scheme eq "MD5") {
	#I know, this isn't really "encryption", 
	#since you can't decrypt it, oh well...
	unless (defined $self->{'_MD5'}) {
	    require MD5;
	    $self->{'_MD5'} = new MD5;
	}
	my($username,$realm,$pass) = split(":", $_[0]);

	$self->{'_MD5'}->add(join(":", $username, $realm, $pass));
	$passwd = join(":", $realm, $self->{'_MD5'}->hexdigest());
	$self->{'_MD5'}->reset;
    }
    else {
	Carp::croak("unknown encryption method '$_'");
    }
    return $passwd;
}

sub salt {
    my($newstyle) = @_;
    return defined($newstyle) && $newstyle ? 
	join('', "_", randchar(1), "a..", randchar(4)) : randchar(2);
}

my(@saltset) = (qw(. /), 0..9, "A".."Z", "a".."z");
srand(time ^ $$);

sub randchar {
  local($^W) = 0; #we get a bogus warning here
  my($count) = @_;
  my $str = "";
  $str .= $saltset[int(rand(64))+1] while $count--;
  $str;
}

#These should work fine with the _generic classes
my %Support = (apache =>   [qw(DBM Text SQL)],
	       ncsa   =>   [qw(DBM Text)],
	       netscape => [qw(DBM)],
	       );

HTTPD::UserAdmin->support(%Support);

1;

__END__

=head1 NAME 

HTTPD::UserAdmin - Management of HTTP server user databases

=head1 SYNOPSIS

    use HTTPD::UserAdmin ();

=head1 DESCRIPTION

This software is meant to provide a generic interface that
hides the inconsistencies across HTTP server implementations 
of user and group databases.

=head1 METHODS

=over 4

=item new ()

Here's where we find out what's different about your server.

Some examples:


    @DBM = (DBType => 'DBM',
	    DB     => '.htpasswd',
	    Server => 'apache');

    $user = new HTTPD::UserAdmin @DBM;


This creates an object who's database is a DBM file named '.htpasswd', in a format that 
the Apache server understands.


    @Text = (DBType => 'Text',
	     DB     => '.htpasswd',
	     Server => 'ncsa');

    $user = new HTTPD::UserAdmin @Text;


This creates an object who's database is a plain text file named '.htpasswd', in a format that 
the NCSA server understands.


    @SQL =  (DBType =>    "SQL",          
	     Host =>      "",             #server hostname 
	     DB =>        "www",          #database name
	     User =>      "", 	  	  #database login name	    
	     Auth =>      "",             #database login password
	     Driver =>    "mSQL",         #driver for DBI
	     Server =>    "apache",       #HTTP server type, not required
	     UserTable => "www-users",    #table with field names below
	     NameField => "user",         #field for the name
	     PasswordField => "password", #field for the password
	     );

    $user = new HTTPD::UserAdmin @SQL;


This creates an object who's mSQL database is named 'www', with a schema that
the Apache server (extention) understands.

Full list of constructor attributes:

Note: Attribute names are case-insensitive

B<DBType>  - The type of database, one of 'DBM', 'Text', or 'SQL' (Default is 'DBM')

B<DB>      - The database name (Default is '.htpasswd' for DBM & Text databases)

B<Server>  - HTTP server name (Default is the generic class, that works with NCSA, Apache and possibly others)

Note: run 'perl t/support.t matrix' to see what support is currently availible

B<Encrypt> - One of 'crypt' or 'MD5', defaults to 'crypt'

B<Locking> - Boolean, Lock Text and DBM files (Default is true)

B<Path>    - Relative DB files are resolved to this value  (Default is '.')

B<Debug>   - Boolean, Turn on debug mode

B<Flags>   - The read, write and create flags.  
There are four modes:
B<rwc> - the default, open for reading, writing and creating.
B<rw> - open for reading and writing.
B<r> - open for reading only.
B<w> - open for writing only.

Specific to DBM files:

B<DBMF>    - The DBM file implementation to use (Default is 'NDBM')

B<Mode>    - The file creation mode, defaults to '0644'

Specific to DBI:
We talk to an SQL server via Tim Bunce's DBI switch, for more info see:
http://www.hermetica.com/technologia/DBI/

B<Host>      - Server hostname

B<User>      - Database login name	    

B<Auth>      - Database login password

B<Driver>    - Driver for DBI  (Default is 'mSQL')            

B<UserTable> - Table with field names below

B<NameField> - Field for the name  (Default is 'user')

B<PasswordField> - Field for the password  (Default is 'password')


From here on out, things should look the same for everyone.


=item add($username,$password[,$noenc,@fields])

Add a user.

If $noenc is true, the password is not encrypted, useful for copying/converting, or
if you just prefer to store passwords in plain text.

Fails if $username exists in the database

    if($user->add('dougm', 'secret')) {
	print "You have the power!\n";
    }

You may need to pass additional fields, such as the user's real name.
This depends on your server of course.

    $user->add('JoeUser', 'try2guess', '', 'Joseph A. User');


=item delete($username)

Delete a user

    if($user->delete('dougm')) {
	print "He's gone\n";
    }

=item exists($username)

True if $username is found in the database

    if($user->exists('dougm')) {
	die "oh no!";
    }

=item password()

Returns the encrypted password for a user

    $passwd = $user->password("dougm");

Useful for copying users to another database.

=item list()

Returns a list of usernames in the current database

    @users = $user->list

=item update($username,$password)

Update $username with a new $password

    if($user->update('dougm', 'idunno')) {
	print "Updated\n";
    }

=item group()

Short cut for creating an HTTPD::GroupAdmin object.
All applicable attributes are inherited, but can be 
overridden.

    $group = $user->group(NAME => 'www-group');

(See HTTPD::GroupAdmin)

=item convert(@Attributes)

Convert a database. 

    $dbmuser = $user->convert(@Apache);

=item lock([$timeout])
=item unlock()

These methods give you control of the locking mechanism.

    $user = new HTTPD::UserAdmin (Locking => 0); #turn off auto-locking
    $user->lock; #lock the object's database
    $user->add($username,$passwd); #write while file is locked
    $user->unlock; release the lock


=item db($dbname);

Select a different database.

    $olddb = $user->db($newdb);
    print "Now we're reading and writing '$newdb', done with '$olddb'n\";

=item flags([$flags])

Get or set read, write, create flags.

=item commit

Commit changes to disk (for Text files).

=back

=head1 Message Digest User Databases

Currently, you can store user info in a format for servers who support
Message Digest Authentication.  Here's an example:

  $user = new HTTPD::UserAdmin (DB => '.htdigest', Encrypt => 'MD5');
  
  ($username,$realm,$password) = ('JoeUser', 'SomePlace', '14me');


  #The checksum contains more info that just a password
  $user->add($username, "$username:$realm:$password");
  $user->update($username, "$username:$realm:newone");


  $info = $user->password($username);
  ($realm, $checksum) = split(":", $info);

  $user->delete($username);                                

See <URL:http://hoohoo.ncsa.uiuc.edu/docs/howto/md5_auth.html> for NCSA's
implementation.

So, it's a little more work, but don't worry, a nicer interface is on the way.

=head1 SEE ALSO

HTTPD::GroupAdmin(3), HTTPD::Authen(3)

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

Copyright (c) 1996, Doug MacEachern

This library is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut

