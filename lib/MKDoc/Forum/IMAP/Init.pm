package MKDoc::Forum::IMAP::Init;
use MKDoc::Core;
use warnings;
use strict;

sub init
{
    my $file = $ENV{SITE_DIR} . '/imap.pl';
    $file and do {
        open FP, "<$file" or die "Cannot read $file. Reason: $!";
        my $data = join '', <FP>;
        close FP;

        eval "$data";
        $@ && die $@;
    };
}


1;
