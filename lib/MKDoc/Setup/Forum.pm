=head1 NAME

MKDoc::Setup::Forum - Install MKDoc::Forum on an MKDoc::Core site.


=head1 REQUIREMENTS


=head2 MKDoc::Core

Make sure you have installed L<MKDoc::Core> on your system with at least one
L<MKDoc::Core> site. Please refer to L<MKDoc::Core::Article::Install> for
details on how to do this.


=head2 A Courrier IMAP server

You need access to a courrier IMAP server.


=head1 INSTALLING

Once you know the connection parameters of your Courier IMAP server (server
name, user name, password, port) installation should be very easy:

  source /path/to/site/mksetenv.sh
  perl -MMKDoc::Setup -e install_forum

That's it! The install script will prompt you for the server connection
parameters, test that it can connect to the server and finally write that
connection information in your site directory.

=cut
package MKDoc::Setup::Forum;
use strict;
use warnings;
use File::Spec;
use File::Touch;
use MKDoc::SQL;
use base qw /MKDoc::Setup/;


sub main::install_forum
{
    $::SITE_DIR = shift (@ARGV);
    __PACKAGE__->new()->process();
}


sub title { "MKDoc::Forum - IMAP setup" }


sub keys { qw /SITE_DIR HOST USER PASS PORT/ }


sub label
{
    my $self = shift;
    $_ = shift;
    /SITE_DIR/    and return "Site Directory";
    /HOST/        and return "IMAP Host";
    /USER/        and return "IMAP User";
    /PASS/        and return "IMAP Password";
    /PORT/        and return "IMAP Port";
    return;
}


sub initialize
{
    my $self = shift;
    my $SITE_DIR  = File::Spec->rel2abs ( $::SITE_DIR || $ENV{SITE_DIR} || '.' );
    $SITE_DIR     =~ s/\/$//;

    $self->{SITE_DIR} = $SITE_DIR;

    my $name = $SITE_DIR;
    $name    =~ s/^\///;
    $name    =~ s/\/$//;
    my @name = split /\//, $name;
    $name    = pop (@name);
    $name    = lc ($name);
    $name    =~ s/[^a-z0-9]/_/gi;
}


sub validate
{
    my $self = shift;
    return $self->validate_site_dir() &&
           $self->validate_db_connect();
}


sub validate_site_dir
{
    my $self = shift;
    my $SITE_DIR = $self->{SITE_DIR};

    $SITE_DIR || do {
        print $self->label ('SITE_DIR') . " cannot be undefined\n";
        return 0;
    };

    -d $SITE_DIR or do {
        print $self->label ('SITE_DIR') . " must exist\n";
        return 0;
    };

    -d "$SITE_DIR/su" or mkdir "$SITE_DIR/su" or do {
        print "$SITE_DIR/su must exist\n";
        return 0;
    };

    return 1;
}


sub validate_db_connect
{
    my $self = shift;
    eval {
        # do stuff here
        1;
    };

    $@ and do {
        print $@;
        return 0;
    };

    return 1;
}


sub install
{
    my $self = shift;
    my $dir  = $self->{SITE_DIR};
    my @args = ();

    defined $self->{HOST} and push @args, host     => $self->{HOST};
    defined $self->{USER} and push @args, user     => $self->{USER};
    defined $self->{PASS} and push @args, password => $self->{PASS};
    defined $self->{PORT} and push @args, port     => $self->{PORT};

    open  FP, ">$dir/imap.pl" or die "Cannot write $dir/imap.pl";
    print FP <<EOF;
#!/usr/bin/perl

# -----------------------------------------------------------------------------
# imap.pl
# -----------------------------------------------------------------------------
#    Description: Automatically generated MKDoc Site imap driver.
#    Note       : ANY CHANGES TO THIS FILE WILL BE LOST!
# -----------------------------------------------------------------------------

use MKDoc::Forum::IMAP::Connection;

\$::MKD_IMAP = MKDoc::Forum::IMAP::Connection->new (
EOF

    print FP join ', ', map { "'$_'" } @args;
    print FP <<EOF;

);


1;

EOF

    close FP;
    print "Wrote $dir/imap.pl\n";

    File::Touch::touch ("$dir/init/10000_MKDoc::Forum::IMAP::Init");
    print "Added $dir/init/10000_MKDoc::Forum::IMAP::Init\n";

    File::Touch::touch ("$dir/plugin/50000_MKDoc::Forum::Plugin::MBoxes");
    print "Added $dir/plugin/50000_MKDoc::Forum::Plugin::MBoxes\n";

    File::Touch::touch ("$dir/plugin/50000_MKDoc::Forum::Plugin::List");
    print "Added $dir/plugin/50000_MKDoc::Forum::Plugin::List\n";

    File::Touch::touch ("$dir/plugin/50000_MKDoc::Forum::Plugin::Post");
    print "Added $dir/plugin/50000_MKDoc::Forum::Plugin::Post\n";

    File::Touch::touch ("$dir/plugin/50000_MKDoc::Forum::Plugin::View");
    print "Added $dir/plugin/50000_MKDoc::Forum::Plugin::View\n";

    exit (0);
}


1;
