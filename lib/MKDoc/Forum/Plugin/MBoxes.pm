package MKDoc::Forum::Plugin::MBoxes::Object;
use strict;
use warnings;

sub new
{
   my $class = shift || return;
   my $mbox  = shift || return;
   return bless \$mbox, $class;
}


sub mbox
{
    my $self = shift;
    return $$self;
}


sub title
{
    my $self = shift;
    my $mbox = $self->mbox();
    $::MKD_IMAP->set_mbox ($mbox);

    my $uids = MKDoc::Forum::IMAP::Query::uid_most_recent_first();
    my $uid  = pop (@{$uids});

    defined $uid or return $mbox;

    my $message = new MKDoc::Forum::Message ($uid) || return $mbox;
    my $ret = $message->subject() || $mbox;

    $::MKD_MESSAGES_HEADERS_TEMP = {};
    return $ret;
}


sub xhtml_description
{
    my $self = shift;
    my $mbox = $self->mbox();
    $::MKD_IMAP->set_mbox ($mbox);

    my $uids = MKDoc::Forum::IMAP::Query::uid_most_recent_first();
    my $uid  = pop (@{$uids});

    defined $uid or return;

    my $message = new MKDoc::Forum::Message ($uid) || return;
    my $ret =  $message->body_as_xhtml();

    $::MKD_MESSAGES_HEADERS_TEMP = {};
    return $ret;
}


package MKDoc::Forum::Plugin::MBoxes;
use strict;
use warnings;
use base qw /MKDoc::Core::Plugin/;


sub sillyness { $::MKD_IMAP }


sub uri_hint
{
    return $ENV{MKD__FORUM_MBOXES_URI_HINT} || 'forums.html';
}


sub location
{
    my $self = shift;
    return '/.' . $self->uri_hint();
}


sub list
{
    my $self = shift;
    $::MKD_IMAP->connect();
    
    my @folders = $::MKD_IMAP->folders_unprefixed;
    @folders    = grep (!/Trash/, @folders);
    @folders    = grep (!/^INBOX$/, @folders);
    @folders    = map { new MKDoc::Forum::Plugin::MBoxes::Object ($_) } @folders;
    return wantarray ? @folders : \@folders;
}


1;


__END__
