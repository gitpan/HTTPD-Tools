# -*- perl -*-
use ExtUtils::MakeMaker;

$VERSION = "0.52";
    
WriteMakefile(
	      VERSION   => $VERSION,
	      DISTNAME  => 'HTTPD-Tools',
	      SKIP      => [qw(static dynamic)],
	      'dist'    => {COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
			     POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../'
			     },
	      'linkext' => {LINKTYPE => '' }, 
	      'clean'   => {FILES => "*% *.html *~ www-* .htp* .htg*"},
             );

#__END__

#You shouldn't need this junk with the latest version of MakeMaker

sub MY::test {
    my $self = shift;
    $_ = $self->MM::test;
    s/(TEST_TYPE=).*/$1test_dynamic/;
    $_;
}

BEGIN {
$SIG{__WARN__} = sub {
    $_[0] =~ /^Use of uninitialized value/ && return;
    $_[0] =~ /used only once/ && return;
    $_[0] =~ /^Subroutine\s+[\w:]+\s+redefined/ && return;
    warn @_;
};
}
