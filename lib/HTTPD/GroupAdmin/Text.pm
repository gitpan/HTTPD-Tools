# $Id: Text.pm,v 1.11 1996/03/10 23:59:06 dougm Exp $
package HTTPD::GroupAdmin::Text;
@ISA = qw(HTTPD::GroupAdmin);
require Carp;

my %Default = (PATH => ".", 
	       DB => ".htgroup", 
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    #load the DBM methods
    $self->load("HTTPD::GroupAdmin::DBM");
    $self->db($self->{DB}); 
    return $self;
}

package HTTPD::GroupAdmin::Text::_generic;
@ISA = qw(HTTPD::GroupAdmin::Text
	  HTTPD::GroupAdmin::DBM::_generic);

$DLM = ": ";

sub _parseline {
    local($self,$fh,$_) = @_;
    chomp; s/^\s+//; s/\s+$//;
    my($key, $val) = split($DLM, $_, 2);
    $val =~ s/\s*,\s*/ /g;
    return ($key,$val);
}

sub _formatline {
    my($self,$key,$val) = @_;
    $val =~ s/(\w) /$1, /g;
    join($DLM, $key,$val) . "\n";
}

sub _tie {
    my($self) = @_;
    my($fh,$db) = ($self->gensym(), $self->{DB});
    my($key,$val);
    printf STDERR "%s->_tie($db)\n", $self->class if $self->debug;

    $db =~ /^[^<>;|]+$/ or Carp::croak("Bad file name '$file'"); $db = $&; #untaint	
    open($fh, $db) or return; #must be new

    while(<$fh>) {
	($key,$val) = $self->_parseline($fh, $_);
	next unless $key =~ /\S/;
	$self->{_HASH}{$key} = $val; 
    }
    close $fh;
}

sub _untie {
    my($self) = @_;
    return unless exists $self->{_HASH};
    my($fh,$db) = ($self->gensym(), $self->{DB});
    my($key,$val);

    $db =~ /^[^<>;|]+$/ or Carp::croak("Bad file name '$file'"); $db = $&; #untaint
    open($fh, ">$db") || Carp::croak("open: '$db' $!");

    while(($key,$val) = each %{$self->{_HASH}}) {
	print $fh $self->_formatline($key,$val);
    }
    delete $self->{_HASH};
    close $fh;
}

1;
__END__
