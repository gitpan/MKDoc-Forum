package MKDoc::Forum::Plugin::List;
use MKDoc::Forum::IMAP::Query;
use strict;
use warnings;

use base qw /MKDoc::Core::Plugin/;


sub uri
{
    my $self = shift;
    my %args = @_;
    my $mbox = delete $args{'mbox'} || $self->mbox();
    my $hint = $self->uri_hint();

    local *location;
    *location = sub { "/.$hint/$mbox.html" };
    return $self->SUPER::uri (%args);
}


sub activate
{
    my $self = shift;
    my $mbox = $self->mbox()   || return;

    $::MKD_IMAP && $::MKD_IMAP->connect() or return;
    $::MKD_IMAP->set_mbox ($mbox);
    $::MKD_IMAP->mbox_exists() || return;

    return $self->SUPER::activate (@_);
}


sub uri_hint
{
    return $ENV{MKD__FORUM_LIST_URI_HINT} || 'forums';
}


sub mbox
{
    my $self = shift;
    my $req  = $self->request();
    my $path = $req->path_info();
    my $hint = $self->uri_hint();
    my ($mbox) = $path =~ /^\/.$hint\/(.*)\.html$/;

    return $mbox;
}


sub run
{
    my $self = shift;
    $self->_prefetch();
    return $self->SUPER::run (@_);
}


# $imap->uid_most_recent_first;
sub _prefetch
{
    my $self = shift;
    $self->{'.precached'} && return;
    
    $self->{uids} = MKDoc::Forum::IMAP::Query::uid_most_recent_first();
    my $thickness = $self->slice_thickness();
    my $number    = $self->slice_number();
    $self->{slices} = MKDoc::Forum::IMAP::Query::slicing_structure ( $thickness, $number, $self->{uids} );
    
    $self->{top_thread} = do {
	my $slice  = $self->current_slice;
        my $thread = MKDoc::Forum::IMAP::Query::slice_threaded ($slice);
	
	# we want the messages most recent first...
	$thread->{children} = [reverse @{$thread->{children}}]
	    if (defined $thread->{children});
	
	$thread;
    };

    $self->{'.precached'} = 1;
}


##
# $self->slice_thickness;
# -----------------------
#   Returns the thickness of each page, i.e. the number
#   of message subjects which are displayed on each page
##
sub slice_thickness
{
    my $self = shift;
    my $req  = shift;
    return $ENV{MKD__FORUM_LIST_PER_PAGE} || '50';
}


##
# $self->slice_number;
# --------------------
#   Returns current page that we're viewing
##
sub slice_number
{
    my $self = shift;
    my $req  = $self->request();
    return $req->param ('page') || 1;
}


##
# $self->current_slice;
# ---------------------
#   Returns the current slice that we're onto
##
sub current_slice
{
    my $self = shift;
    return unless (defined $self->{slices});
    foreach (@{$self->{slices}})
    {
	return $_ if ($_->{current});
    }
    
    return $self->{slices}->[0];
}


##
# $self->top_thread;
# ------------------
#   Returns the top thread, which holds all the messages for the
#   current page in a tree-shaped structure
##
sub top_thread
{
    my $self = shift;
    return $self->{top_thread};
}


##
# $self->has_many_slices;
# -----------------------
#   Returns TRUE if this mailbox is split into multiple pages,
#   FALSE otherwise
##
sub has_many_slices
{
    my $self = shift;
    return @{$self->{slices}} > 1;
}


1;
