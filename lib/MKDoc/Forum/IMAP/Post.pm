package MKDoc::Forum::IMAP::Post;
use MKDoc::Forum::Message;
use warnings;
use strict;
use Encode; 


=head2 $class->process ($hashref);

$hashref is a message as follows:

  {
      realname    => <user real name> 
      email       => <user email>
      subject     => <user subject>
      message     => <user message>
      language    => <language iso code>
      in_reply_to => <reply_id>
      references  => <references_id>
  }

=cut
sub post
{
    my $class = shift;
    my $hash = shift;
    my $mail = $class->_post_construct_mail ($hash);
    return $::MKD_IMAP->append ($::MKD_IMAP->mbox_prefixed(), $mail);
}


sub _post_clean_header
{
    my $class = shift;
    my $res  = shift || '';
    $res =~ s/(\n|\r)+/ /gsm;
    $res =~ s/[\x00-\x08]//g;
    $res =~ s/[\x0B-\x0C]//g;
    $res =~ s/[\x0E-\x1F]//g;
    $res =~ s/^\s+//;
    $res =~ s/\s+$//;
    return $res;
}


sub _post_clean_body
{
    my $class = shift;
    my $res  = shift;
    my @data = split /\n/sm, $res;
    
    my @result  = ();
    my @current = ();
    for (@data)
    {
	chomp();
	chomp();
	/^\s*\>/ and do {
	    if (@current)
	    {
		my $current = Text::Wrap::wrap ('', '', @current);
		push @result, split /\n/sm, $current;
		@current = ();
	    }
	    push @result, $_;
	    next;
	};
	
	/^\s*$/ and do {
	    if (@current)
	    {
		my $current = Text::Wrap::wrap ('', '', @current);
		push @result, split /\n/sm, $current;
		@current = ();
	    }
	    push @result, $_;
	    next;
	};
	
	push @current, $_;
    }
    
    if (@current)
    {
	my $current = Text::Wrap::wrap ('', '', @current);
	push @result, split /\n/sm, $current;
	@current = ();
    }
    
    return join "\n", @result;
}


sub _post_construct_mail
{
    my $class   = shift;
    my $message = shift;
    my $mbox    = $::MKD_IMAP->mbox;
    
    my $realname    = $class->_post_clean_header ($message->{realname});
    my $email       = $class->_post_clean_header ($message->{email});
    my $subject     = $class->_post_clean_header ($message->{subject});
    my $body        = $message->{message}; #$class->_post_clean_body   ($message->{message});
    my $language    = $class->_post_clean_header ($message->{language});
    my $in_reply_to = $message->{in_reply_to};
    my $references  = $message->{references};
    my $now         = $::MKD_IMAP->Rfc822_date (time);
    
    my $to = $::MKD_IMAP->{'.connect'}->{'user'} . '+' . $mbox . '@' . $ENV{SERVER_NAME};
    
    my $from_encoded    = Encode::encode ('MIME-Header', "$realname <$email>");
    my $to_encoded      = Encode::encode ('MIME-Header', $to);
    my $subject_encoded = Encode::encode ('MIME-Header', $subject);
    
    my $rand1  = join '', map { chr (ord ('A') + int (rand (26))) } 1..8;
    my $rand2  = join '', map { chr (ord ('A') + int (rand (26))) } 1..8;
    my $msg_id = $email;
    $msg_id =~ s/.*\@//;
    $msg_id = "$rand1.$rand2\@$msg_id";
    
    my $rhost = $ENV{REMOTE_HOST} || $ENV{REMOTE_ADDR};
    my $mail = <<EOF;
Return-Path: <$email>
Received: from $rhost [$ENV{REMOTE_ADDR}]
        by $ENV{SERVER_NAME} with MKDoc-Forum;
        $now
Delivered-To: $to
From: $from_encoded
To: $to_encoded
Subject: $subject_encoded
Message-ID: <$msg_id>
EOF

    if ($references)
    {
	$mail .= <<EOF;
References: $references
EOF
    }

    $mail .= <<EOF;
Mime-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Content-Disposition: inline
Content-Language: $language
EOF

    if ($in_reply_to)
    {
	$mail .= <<EOF;
In-Reply-To: $in_reply_to
EOF
    }
    
    $mail .= <<EOF;
User-Agent: $ENV{HTTP_USER_AGENT}
Sender: $email
Date: $now
EOF

    $mail =~ s/^(\r|\n)+//sm;
    $mail .= "\n$body";
    # Encode::_utf8_off ($mail);
    return $mail;
}


1;


__END__
