# -*- perl -*-
use ExtUtils::MakeMaker;

$VERSION = "0.53";
    
WriteMakefile(
	      VERSION   => $VERSION,
	      NAME  => 'HTTPD-Tools',
	      'dist'    => {COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
			     POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../'
			     },
	      'linkext' => {LINKTYPE => '' }, 
	      'clean'   => {FILES => "*% *.html *~ www-* .htp* .htg*"},
             );

