use ExtUtils::MakeMaker;
use lib 'lib';
use warnings;
use strict;
use MKDoc::Setup::Forum;
use File::Spec;

print <<'EOF';
I am going to launch a setup utility. If you do not have a test courier IMAP
server, you can cancel the setup - but the extended test suite will be skipped.

Press any key to continue...
EOF

<STDIN>;

unless (fork())
{
    -d 'test' or mkdir 'test' or die "Cannot create test directory";
    -d 'test/init' or mkdir 'test/init' or die "Cannot create test directory";
    $::SITE_DIR = File::Spec->rel2abs ('test');
    MKDoc::Setup::Forum->new()->process();
}
else
{
    wait;
}



# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MKDoc::Forum',
    'VERSION_FROM'	=> 'lib/MKDoc/Forum.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	'Test::Harness'	          => '2.00',
	'Scalar::Util'            => '1.07',
	'MKDoc::Core'	          => '0.3',
        'MKDoc::Text::Structured' => '0.1',
        'MKDoc::XML'              => '0.70',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/MKDoc/Forum.pm', # retrieve abstract from module
       AUTHOR     => 'Jean-Michel Hiver <jhiver@mkdoc.com>') : ()),
);


1;


package MY;


sub postamble {
    return <<EOF;
cover ::
	\$(RM_RF) cover_db
	PERL5OPT=-MDevel::Cover \$(MAKE) test || true
	cover -report html cover_db > /dev/null

EOF

}


1;
