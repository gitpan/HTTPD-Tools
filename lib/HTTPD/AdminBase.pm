# $Id: AdminBase.pm,v 1.11 1996/03/10 23:55:52 dougm Exp $
package HTTPD::AdminBase;
require Carp;
require Fcntl;
use File::Basename;

$VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

#generic contructor stuff

my $Debug = 0;
my %Default = (DBTYPE => "DBM",
	       SERVER => "_generic",
	       DEBUG  => $Debug,
	       LOCKING => 1,
	       );

my %ImplementedBy = ();

sub new {
    my($class) = shift;
    my $attrib = { %Default, @_ };
    for (keys %$attrib) { $attrib->{"\U$_"} = delete $attrib->{$_}; }
    $Debug = $attrib->{DEBUG} if defined $attrib->{DEBUG};

    #who's gonna do all the work?
    my $impclass = $class->implementor(@{$attrib}{qw(DBTYPE SERVER)});
    unless ($impclass) {
	Carp::croak(sprintf "%s not implemented for Server '%s' and DBType '%s'",
	               $self->class, @{$self}{qw(SERVER DBTYPE)});
    }

    #the final product
    return new $impclass ( %{$attrib} );
}

sub close { $_[0] = undef }

sub dbtype {
    my($self,$dbtype) = @_;
    my $old = $self->{DBTYPE};
    return $old unless $dbtype;
    Carp::croak("Can't modify DBType attribute");
    #I think it makes more sense 
    #just to create a new instance in your script
    my $base = $self->baseclass(3); #snag HTTPD::(UserAdmin|GroupAdmin)::(DBM|Text|SQL)
    $self->close;
    $self = $base->new( %{$self}, DBType => $dbtype );
    return $old;
}

#implementor code derived from URI::URL
sub implementor {
    my($self,$dbtype,$server,$impclass) = @_;
    my $class = $self->class;
    my $ic;
    if($self->is_instance) {
	($server,$dbtype) = @{$self}{qw(SERVER DBTYPE)};
    }

    $server = (defined $server) ? lc($server) : '_generic';
    $dbtype = (defined $dbtype) ? $dbtype     : 'DBM';
    $modclass = join('::', $class,$dbtype,$server);
    if ($impclass) {
        $ImplementedBy{$modclass} = $impclass;
    }

    return $ic if $ic = $ImplementedBy{$modclass};

    #first load the database class
    $ic = $self->load($class, $dbtype);

    # now look for a server subclass
    $ic = $self->load($ic, $server);

    if ($ic) {
        $ImplementedBy{$ic} = $ic;
    }
    $ic;
}

sub load {
    my($self) = shift;
    my($ic,$module);
    if(@_ > 1) { $ic = join('::', @_) }
    else       { $ic = $_[0] }

    unless (defined @{"${ic}::ISA"}) {
	# Try to load it
	($module = $ic) =~ s,::,/,g;
	$module =~ /^[^<>|;]+$/; $module = $&; #untaint
	eval { require "$module.pm"; };
	print STDERR "loading $ic $@\n" if $Debug;
	$ic = '' unless defined @{"${ic}::ISA"};
    }
    $ic;
}

sub support {
    my($self,%support) = @_;
    my $class = $self->class;
    my($code,$db,$srv);
    foreach $srv (keys %support) {
	foreach $db (@{$support{$srv}}) {
	    @{"${class}::${db}::${srv}::ISA"} = qq(${class}::${db}::_generic);
	}
    }
}

sub _check {
    my($self) = shift;
    foreach (@_) {
	next if defined $self->{$_};
	Carp::croak(sprintf "cannot construct new %s object without '%s'", $self->class, $_);
    }
}

sub _elem {
    my($self, $element, $val) = @_;
    my $old = $self->{$element};
    return $old unless $val;
    $self->{$element} = $val; 
    return $old;
}

#DBM stuff
sub _tie {
    my($self, $key, $file) = @_;
    printf STDERR "%s->_tie($file)\n", $self->class if $Debug;
    tie(%{$self->{$key}}, $self->{_DBMPACK}, 
	$file, @{$self}{qw(_FLAGS MODE)}) || Carp::croak("tie '$file' $!");    
}

sub _untie {
    my($self, $key) = @_;
    untie %{$self->{$key}};
}

%DBMFiles = ();
%DBMFlags = (
	     GDBM => { 
		 rwc => sub { GDBM_File::GDBM_WRCREAT() },
		 rw  => sub { GDBM_File::GDBM_READER()|GDBM_File::GDBM_WRITER() },
		 w   => sub { GDBM_File::GDBM_WRITER() },
		 r   => sub { GDBM_File::GDBM_READER() },
	     },
	     DEFAULT => { 
		 rwc => sub { Fcntl::O_RDWR()|Fcntl::O_CREAT() },
		 rw  => sub { Fcntl::O_RDWR() },
		 w   => sub { Fcntl::O_WRONLY() },
		 r   => sub { Fcntl::O_RDONLY() },
	     },
);

sub _dbm_init {
    my($self,$dbmf) = @_;
    $self->{DBMF} = $dbmf if defined $dbmf;
    my($flags, $dbmpack);
    unless($dbmpack = $DBMFiles{$self->{DBMF}}) {
	$DBMFiles{$dbmpack} = $dbmpack = "$self->{DBMF}_File";
	$self->load($dbmpack) or Carp::croak("can't load '$dbmpack'");
    }

    my($key,$mode) = @{$self}{qw(DBMF FLAGS)};
    $key = "DEFAULT" unless defined $DBMFlags{$key};
    if(defined $DBMFlags{$key}->{$mode}) {
	$flags = &{$DBMFlags{$key}->{$mode}};
    }

    @{$self}{qw(_DBMPACK _FLAGS)} = ($dbmpack, $flags);
    1;
}

#stuff for Filehandles
#From Symbol.pm, not everyone has 5.002 yet :-(
#this dumps core with 5.001m
#my $genpkg = "Symbol::";
#my $genseq = 0;

#sub gensym {
#    my $name = "GEN" . $genseq++;
#    local *{$genpkg . $name};
#    \delete ${$genpkg}{$name};
#}

my $gensym = "DBSYM000";

sub gensym {
    #my $class = $_[0]->class;
    my $class = "HTTPD::AdminBase";
    *{"${class}::" . $gensym++};
}


sub ungensym {} #nah

#stuff for locking
#File::Lock would be nice to have standard

#use Fcntl qw(F_WRLCK F_SETLK F_UNLCK);
my $STRUCT = "sslll";

sub lock {
    my($self,$timeout,$file) = @_;
    return 1 unless $self->{LOCKING};
    $timeout = $timeout || 10;
    my $lock = pack($STRUCT,Fcntl::F_WRLCK(),0,0,0,0);
    my($FH) = $self->{_LOCKFH} = $self->gensym;

    unless($file = $file || "$self->{DB}.lock") {
	Carp::croak("can't set lock, no file specified!");
    }
    unless ( -w dirname($self->{_LOCKFILE} = $file)) {
	print STDERR "lock: can't write to '$file' ";
	#for writing lock files under CGI and such
	$self->{_LOCKFILE} = $file = 
	    sprintf "%s/%s-%s", $self->tmpdir(), "HTTPD", basename($file);
	print STDERR "trying '$file' instead\n";
    }

    $file =~ /^[^<>;|]+$/ or Carp::croak("Bad file name '$file'"); $file = $&; #untaint
    
    open($FH, ">>$file") || Carp::croak("can't open '$file' $!");
    while(! fcntl($FH, Fcntl::F_SETLK(), $lock)) {
	sleep 1;
	if(--$timeout < 0) {
	    print STDERR "lock: timeout, can't lock $file \n";
	    return 0;
	}
    }
    print STDERR "lock-> $file\n" if $Debug;
    1;
}

sub unlock { 
    my($self) = @_;
    return 1 unless $self->{LOCKING};
    my $FH = $self->{_LOCKFH};
    fcntl($FH, Fcntl::F_SETLK(), pack($STRUCT,Fcntl::F_UNLCK(),0,0,0,0));   
    close $FH;
    unlink $self->{_LOCKFILE};
    print STDERR "unlock-> $self->{_LOCKFILE}\n" if $Debug;
    1;
}

#hmm, this doesn't seem right
sub tmpdir {
    my($self) = @_;
    return $self->{TMPDIR} if defined $self->{TMPDIR};
    my $dir;
    foreach ( qw(/tmp /usr/tmp /var/tmp) ) {
	last if -d ($dir = $_);
    }
    $self->{TMPDIR} = $dir;
}

sub debug   { shift->_elem('DEBUG',   @_) }
sub path    { shift->_elem('PATH',    @_) }
sub locking { shift->_elem('LOCKING', @_) }

#AUTOLOAD {
#    my ($package, $method) = $AUTOLOAD =~ /(.*)::(.+)$/g;
#    my $elem = uc $method;
#    if(exists $_[0]->{$elem}) {
#	eval "sub $AUTOLOAD { shift->_elem($elem, \@_); }";
#	#*{$AUTOLOAD} = sub { shift->_elem($elem, @_); };
#	print STDERR "AUTOLOAD: sub $AUTOLOAD {}\n" if $Debug;
#	goto &$AUTOLOAD;
#    }
#    else {
#	croak qq(Can't locate object method "$method" via package "$package");
#    }
#}

#grumble, need $obj->isa();
sub baseclass {
    my($self, $n) = @_;
    join '::', (split(/::/, $self->class))[0 .. $n - 1];
}

#from UNIVERSAL.pm - [JACKS  Jack Shirazi <JackS@slc.com>]
#someday we'll just say
#require UNIVERSAL;

package UNIVERSAL;

sub FileHandle::is_instance {$_[0] ne 'FileHandle'}
sub FileHandle::class {'FileHandle'}

sub is_instance {ref($_[0]) ? 1 : ''}
sub class {ref($_[0]) || $_[0]}

1;

