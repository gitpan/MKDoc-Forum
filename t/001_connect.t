use MKDoc::Core::Init;
use Test::More qw /no_plan/;
use lib qw (lib ../lib);
use strict;
use warnings;

ok (1);
exit unless (-f 'test/imap.pl');

$ENV{SITE_DIR} = 'test';

MKDoc::Core::Init->init();
ok ( $::MKD_IMAP                       => 'IMAP Connection object exists');
ok ( $::MKD_IMAP->connect()            => 'IMAP Connection object connects');
ok ( $::MKD_IMAP->IsConnected()        => 'IMAP Connection object is connected');

1;
