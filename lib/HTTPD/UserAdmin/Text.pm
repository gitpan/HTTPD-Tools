# $Id: Text.pm,v 1.11 1996/03/11 00:01:23 dougm Exp $
package HTTPD::UserAdmin::Text;
require HTTPD::UserAdmin;
require Carp;
@ISA = qw(HTTPD::UserAdmin);

my %Default = (PATH => ".", 
	       DB => ".htpasswd", 
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ }, $class;

    #load the DBM methods
    $self->load("HTTPD::UserAdmin::DBM");

    $self->db($self->{DB}); 
    return $self;
}

#do this so we can borrow from the DBM class

sub _tie {
    my($self) = @_;
    my($fh,$db) = ($self->gensym(), $self->{DB});
    printf STDERR "%s->_tie($db)\n", $self->class if $self->debug;

    $db =~ /^[^<>;|]+$/ or Carp::croak("Bad file name '$file'"); $db = $&; #untaint
    open($fh, $db) or return;
    my($key,$val);
    
    while(<$fh>) { #slurp! need a better method here.
	($key,$val) = $self->_parseline($fh, $_);
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
    open($fh, ">$db") or Carp::croak("open: '$db' $!");

    while(($key,$val) = each %{$self->{_HASH}}) {
	print $fh $self->_formatline($key,$val);
    }
    delete $self->{_HASH};
}

package HTTPD::UserAdmin::Text::_generic;
@ISA = qw(HTTPD::UserAdmin::Text
	  HTTPD::UserAdmin::DBM::_generic);

$DLM = ":";

sub _parseline {
    local($self,$fh,$_) = @_;
    chomp;
    my($key, $val) = split($DLM, $_, 2);
    return ($key,$val);
}

sub _formatline {
    my($self,$key,$val) = @_;
    join($DLM, $key,$val) . "\n";
}

1;
