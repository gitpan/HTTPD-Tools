# $Id: GroupAdmin.pm,v 1.12 1996/03/18 15:32:51 dougm Exp $

package HTTPD::GroupAdmin;
@ISA = qw(HTTPD::AdminBase);
require HTTPD::AdminBase;

$VERSION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

sub user {
    my($self) = shift;
    $self->load('HTTPD::UserAdmin');
    my %attr = %{$self};
    delete $attr{DB}; #just incase, everything else should be OK
    return new HTTPD::UserAdmin (%attr, @_);
}

sub name { shift->_elem('NAME', @_) }

#These should work fine with the _generic classes
my %Support = (apache =>   [qw(Text)],
	       ncsa   =>   [qw(DBM Text)],
	       );

HTTPD::GroupAdmin->support(%Support);

1;

__END__

=head1 NAME 

HTTPD::GroupAdmin - Management of HTTP server group databases

=head1 SYNOPSIS

    require HTTPD::GroupAdmin

=head1 DESCRIPTION

This software is meant to provide a generic interface that
hides the inconsistencies across HTTP server implementations 
of user and group databases.

=head1 METHODS

=head2 new ()

Here's where we find out what's different about your server.

Some examples:


    @DBM = (DBType => 'DBM',
	    DB     => '.htgroup',
	    Server => 'apache');

    $group = new HTTPD::GroupAdmin @DBM;


This creates an object who's database is a DBM file named '.htgroup', in a format that 
the Apache server understands.


    @Text = (DBType => 'Text',
	     DB     => '.htgroup',
	     Server => 'ncsa');

    $group = new HTTPD::GroupAdmin @Text;


This creates an object who's database is a plain text file named '.htgroup', in a format that 
the NCSA server understands.

Note: Support is not yet availible for SQL servers

Full list of constructor attributes:

Note: Attribute names are case-insensitive

B<Name>    - Group name

B<DBType>  - The type of database, one of 'DBM', 'Text', or 'SQL' (Default is 'DBM')

B<DB>      - The database name (Default is '.htpasswd' for DBM & Text databases)

B<Server>  - HTTP server name (Default is the generic class, that works with NCSA, Apache and possibly others)

Note: run 'perl t/support.t matrix' to see what support is currently availible

B<Path>    - Relative DB files are resolved to this value  (Default is '.')

B<Locking> - Boolean, Lock Text and DBM files (Default is true)

B<Debug>   - Boolean, Turn on debug mode

Specific to DBM files:

B<DBMF>    - The DBM file implementation to use (Default is 'NDBM')

B<Flags>   - The read, write and create flags.  
There are four modes:
B<rwc> - the default, open for reading, writing and creating.
B<rw> - open for reading and writing.
B<r> - open for reading only.
B<w> - open for writing only.

B<Mode>    - The file creation mode, defaults to '0644'

From here on out, things should look the same for everyone.


=head2 add($username[,$groupname])

Add user $username to group $groupname, or whatever the 'Name' attribute is set to.

Fails if $username exists in the database

    if($group->add('dougm', 'www-group')) {
	print "Welcome!\n";
    }

=head2 delete($username[,$groupname])

Delete user $username from group $groupname, or whatever the 'Name' attribute is set to.

    if($group->delete('dougm')) {
	print "He's gone from the group\n";
    }

=head2 exists($groupname)

True if $groupname is found in the database

    if($group->exists('web-heads')) {
	die "oh no!";
    }

=head2 list([$groupname])

Returns a list of group names, or users in a group if '$name' is present.

@groups = $group->list;

@users = $group->list('web-heads');

=head2 user()

Short cut for creating an HTTPD::UserAdmin object.
All applicable attributes are inherited, but can be 
overridden.

    $user = $group->user();

(See HTTPD::UserAdmin)

=head2 convert(@Attributes)

Convert a database. 

    #not yet

=head2 remove($groupname)

Remove group $groupname from the database

=head2 name($groupname)

Change the value of 'Name' attribute.

    $group->name('bew-ediw-dlrow');

=head2 debug($boolean)

Turn debugging on or off

=head2 lock([$timeout])
=head2 unlock()

These methods give you control of the locking mechanism.

    $group = new HTTPD::GroupAdmin (Locking => 0); #turn off auto-locking
    $group->lock; #lock the object's database
    $group->add($username,$passwd); #write while database is locked
    $group->unlock; release the lock

=head2 db($dbname);

Select a different database.

    $olddb = $group->db($newdb);
    print "Now we're reading and writing '$newdb', done with '$olddb'n\";


=head1 SEE ALSO

HTTPD::UserAdmin

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

Copyright (c) 1996, Doug MacEachern, OSF Research Institute

This library is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
