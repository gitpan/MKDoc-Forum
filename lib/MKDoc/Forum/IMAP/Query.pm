package MKDoc::Forum::IMAP::Query;
use MKDoc::Forum::Message;
use strict;
use warnings;

our %Threads = ();
our $Current = undef;
our @Stack   = ();


=head2 uid_most_recent_first();

Returns all the UIDs from the current $::MKD_IMAP object,
most recent first.

=cut
sub uid_most_recent_first
{
    my @res  = $::MKD_IMAP->sort ('REVERSE DATE', 'US-ASCII', 'ALL');
    return (wantarray) ? @res : \@res;
}


=head2 slicing_structure ($per_page, $current, $uid_array);

Splits $uid_array into a list of 'slices' containing $per_page message each.

Each element of the resulting array looks like this:

  {
      number    => <index in the array + 1>,
      thickness => $per_page,
      uids      => <array refs of UIDs for this slice>
      current   => <TRUE if 'number' is the same as $current>
  }

=cut
sub slicing_structure
{
    my $thickness = shift;
    my $slice_num = shift;
    my $uid_array = shift;
    
    my $number_of_slices = scalar @{$uid_array} / $thickness;
    $number_of_slices = int ($number_of_slices) + 1
        if (int ($number_of_slices) != $number_of_slices);
    
    my @struct = ();
    for (1..$number_of_slices)
    {
	my $slice = slice_info ($thickness, $_, $uid_array);
	$slice->{current} = ($slice_num == $_) ? 1 : 0;
	push @struct, $slice;
    }
    
    unless (scalar @struct)
    {
	push @struct, {
	    number    => 1,
	    thickness => $thickness,
	    uids      => [],
	};
    }
    
    return (wantarray) ? @struct : \@struct;
}


sub slice_info
{
    my $thickness = shift;
    my $slice_num = shift;
    my $uid_array = shift;
    
    my $first_slice_num = 1;
    my $last_slice_num  = scalar @{$uid_array} / $thickness;
    $last_slice_num = int ($last_slice_num) + 1
        unless ($last_slice_num == int ($last_slice_num));
    
    my $lower_bound;
    my $upper_bound;
    
    # if there is only one slice, then things are easy enough
    if ($first_slice_num == $last_slice_num)
    {
	$lower_bound = 0;
	$upper_bound = $#{$uid_array};
    }
    
    # if there is more than one slice, but we're on the first slice
    elsif ($slice_num == $first_slice_num)
    {
	$lower_bound = 0;
	$upper_bound = $slice_num * $thickness - 1;
    }
    
    # if there is more than one slice, but we're on the last slice
    elsif ($slice_num == $last_slice_num)
    {
	$lower_bound = ($slice_num - 1) * $thickness;
	$upper_bound = $#{$uid_array};
    }
    
    # we're somewhere in the middle
    else
    {
	$lower_bound = ($slice_num - 1) * $thickness;
	$upper_bound = $slice_num * $thickness - 1;
    }
    
    my @slice = @{$uid_array}[$lower_bound .. $upper_bound];
    return {
	number     => $slice_num,
	thickness  => $thickness,
	uids       => \@slice,
    };
}


=head2 slice_threaded ($slice);

Using the UIDs defined whitin this particular slice, loads all the
corresponding messages and threads them properly. Returns the top thread
messages.

=cut
sub slice_threaded
{
    my $slice = shift;
    my $uids = [ @{$slice->{uids}} ];

    return new MKDoc::Forum::Message ( children => [] ) unless (defined $uids);
    return new MKDoc::Forum::Message ( children => [] ) unless (scalar @{$uids});
    
    if (scalar @{$uids} == 1) { return select_threaded_messages ("UID $uids->[0]") }
    if (scalar @{$uids} == 2) { return select_threaded_messages ("OR UID $uids->[0] UID $uids->[1]") }
    
    my $condition = '';
    while (@{$uids} != 2)
    {
	my $uid = shift (@{$uids});
	$condition .= "OR UID $uid ";
    }
    $condition .= "OR UID $uids->[0] UID $uids->[1]";
    
    return select_threaded_messages ($condition);
}


sub select_threaded_messages
{
    my $condition = shift || 'ALL';
    
    # bulk-load message headers to avoid loading them one by
    # one later on. It's a bit of a kludge but it increases
    # performance greatly.
    $::MKD_MESSAGES_HEADERS_TEMP = select_headers (
	$condition,
        qw/Message-ID From To Date Subject In-Reply-To References Content-Language/
       );
 
    my ($res_string) = grep /\*\s+THREAD/, $::MKD_IMAP->tag_and_run ("UID THREAD REFERENCES US-ASCII $condition");
    my $res = _messages_threaded ($res_string);
    _messages_parentify ($res);
    
    return $res;
}


sub select_headers
{
    my $condition = shift || 'ALL';
    my @headers   = @_;
    @headers = ('ALL') unless (scalar @headers);
    
    return $::MKD_IMAP->parse_headers (scalar ($::MKD_IMAP->search ($condition)) , @headers)
}


sub _messages_threaded
{
    my $thread_info_string = shift;
    my @tokens = map { (defined $_) ? $_ : () } $thread_info_string =~ /(\()|(\))|(\d+)/g;
    
    # a bit of initialization...
    local %Threads = ();
    local $Current = new MKDoc::Forum::Message ( children => [] );
    local @Stack = ($Current);
    
    # builds the tree using the tokens
    my $first = $Current;
    foreach (@tokens)
    {
	if (/\(/)    { _messages_threaded_open_parenthesis()  }
	elsif (/\)/) { _messages_threaded_close_parenthesis() }
	else         { _messages_threaded_number ($_)         }
    }
    
    _messages_threaded_collapse_empty_threads ($first);
    return $first;
}


sub _messages_threaded_open_parenthesis
{
    my $message = new MKDoc::Forum::Message;
    $Current->{children} ||= [];
    push @{$Current->{children}}, $message;
    $Current = $message;
    push @Stack, $message;
}


sub _messages_threaded_close_parenthesis
{
    pop (@Stack);
    $Current = $Stack[$#Stack];
}


sub _messages_threaded_number
{
    my $number = shift;
    if (not defined $Current->uid)
    {
	$Current->{uid} = $number;
    }
    else
    {
	my $message = new MKDoc::Forum::Message ($number);
	$Current->{children} ||= [];
	push @{$Current->{children}}, $message;
	$Current = $message;
    }
}


sub _messages_threaded_collapse_empty_threads
{
   my $thread = shift;

   return ($thread) unless (defined $thread->{children});
   
   my @new_children = ();
   push @new_children, _messages_threaded_collapse_empty_threads ($_) for (@{$thread->{children}});
   $thread->{children} = \@new_children;
   
   (defined $thread->{uid}) ? return ($thread) : return @{$thread->{children}};
}


sub _messages_parentify
{
    my $message = shift;
    my $parent  = shift;
    
    if (defined $parent) { $message->{parent} = "$parent" }
    foreach (@{$message->{children}}) { _messages_parentify ($_, $message) }
}


=head2 message_header ($uid);

Returns the parsed headers for the message $uid.

=cut
sub message_header
{
    my $uid  = shift || die "\$uid not specified";
    return $::MKD_IMAP->parse_headers ($uid, 'ALL')
}


1;


__END__
