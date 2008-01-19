#!/usr/bin/perl -w
#
# vim:set ts=4 sw=4:
#
# A gamespy peerchat <-> IRC tunnel

use Digest::MD5 qw(md5_hex);
use IO::Socket::INET;
use IO::Select;
use bytes;
use strict;

# Code derived from gs_peerchat.h by Luigi Auriemma
sub peerchat_init
{
	my ($context, $challenge, $gamekey) = @_;
	$context->{'num1'} = $context->{'num2'} = 0;
	my @gk = map(ord, split(//, $gamekey));
	my @s = ();
	my $p = 0;
	foreach my $c (map(ord, split(//, $challenge)))
	{
		push @s, ($c ^ $gk[$p]);
		$p++;
		$p = 0 if $p >= @gk;
	}
	my @crypt = reverse(0..255);
	my $t1 = 0;
	$p = 0;
	die join(', ', @gk) unless scalar @gk == 6;
	die join(', ', @s) unless scalar @s == 16;
	for (my $n = 0; $n < 256; $n++)
	{
		$t1 = ($t1 + ($s[$p] + $crypt[$n]) % 256) % 256;
		my $temp = $crypt[$t1];
		$crypt[$t1] = $crypt[$n];
		$crypt[$n] = $temp;
		$p++;
		$p = 0 if $p >= @s;
	}
	$context->{'crypt'} = \@crypt;
}

# Code derived from gs_peerchat.h by Luigi Auriemma
sub peerchat_crypt
{
	my ($context, $data) = @_;
	my $num1 = $context->{'num1'};
	my $num2 = $context->{'num2'};
	my $crypt = $context->{'crypt'};
	my $s = '';
	my $t;
	foreach my $c (map(ord, split(//, $data)))
	{
		$num1 = ($num1 + 1) % 256;
		$t = $crypt->[$num1];
		$num2 = ($num2 + $t) % 256;
		$crypt->[$num1] = $crypt->[$num2];
		$crypt->[$num2] = $t;
		$t = ($t + $crypt->[$num1]) % 256;
		$s .= chr($c ^ $crypt->[$t]);
	}
	$context->{'num1'} = $num1;
	$context->{'num2'} = $num2;
	return $s;
}

# Code derived from peerchat_ip.h by Luigi Auriemma
sub ip_enc
{
	my $addr = inet_aton($_[0]);
	return undef unless defined($addr);
	my $ip = unpack('I', $addr);
	$ip ^= 0xc3801dc7;
	my @dec = split(//, 'aFl4uOD9sfWq1vGp');
	my $data = 'X';
	for (my $sh = 28; $sh >= 0; $sh -= 4)
	{
		$data .= $dec[($ip >> $sh) & 15];
	}
	return $data . 'X';
}

# Code derived from peerchat_ip.h by Luigi Auriemma
sub ip_dec
{
	my ($str) = @_;
	my @data = split(//, $str);
	my %enc = (
		 'a' => 0        ,'s' =>  8
		,'F' => 1        ,'f' =>  9
		,'l' => 2        ,'W' => 10
		,'4' => 3        ,'q' => 11
		,'u' => 4        ,'1' => 12
		,'O' => 5        ,'v' => 13
		,'D' => 6        ,'G' => 14
		,'9' => 7        ,'p' => 15
	);
	my $ip = 0;
	for (my ($sh, $i) = (28, 1); $sh >= 0; $sh -= 4, $i++)
	{
		return $str unless exists($enc{$data[$i]});
		$ip |= $enc{$data[$i]} << $sh;
	}
	return inet_ntoa(pack('I', $ip ^ 0xc3801dc7));
}

our %option_help = (
	 clientcontext   => 'Context handle for encryption of client data'
	,config          => 'The configuration file read during startup'
	,dumptraffic     => 'If true, all traffic is written to stdout'
	,email           => 'Email address to be passed during login'
	,gamekey         => 'Gamekey to be used for crypt initialization'
	,gamename        => 'Gamename to be used for crypt initialization'
	# countrycode,?,?,?,birthday,month,year,?,?,?,?
	,gs_pinfo        => 'GS peerchat playerinfo string to be sent after login'
	,gsirc           => 'Toggle for #gsirc channel auto-join/messages'
	,gsirc_botname   => 'gsirc control bot name'
	,gsirc_channel   => 'gsirc control channel name'
	,gsock           => 'GS peerchat connection socket'
	,gsock_temp_data => 'Unfinished line from last peerchat packet'
	,inetd           => "Don't listen on socket but read from standard input"
	,isock           => 'IRC client connection socket'
	,isock_temp_data => 'Unfinished line from last IRC packet'
	,localport       => 'The port to listen on for the IRC connection'
	,my_ip           => 'Our WAN IP as returned by peerchat server'
	,nickname        => 'Preferred nickname (for login) / actual nickname'
	,password        => 'Password (or its MD5 hash) to be used during login'
	,pidfile         => 'File to write PID to during startup'
	,primarynickname => 'Primary gamespy nickname to be sent during login'
	,queries         => 'GETCKEY/GETKEY query tracking hash'
	,querycounter    => 'GETCKEY/GETKEY query ID counter'
	,servercontext   => 'Context handle for encryption of server data'
	,servername      => 'Server name used by peerchat server'
	,showbcasts      => 'If true, shows BCAST messages in #gsirc channel'
	,uid             => 'UID returned by peerchat server during login'
	,unknown1        => 'Some other value returned by peerchat during login'
);

our %option_defaults = (
	 config          => "$ENV{HOME}/.gsirc"
	,dumptraffic     => 0
	,email           => '<the email you provided gamespy during registration>'
	,gamekey         => 'Xn221z'
	,gamename        => 'gslive'
	,gs_pinfo        => 'US,,0,1280,1,4,1980,0.000000,0.000000,0,'
	,gsirc           => 1
	,gsirc_botname   => 'gsirc'
	,gsirc_channel   => 'gsirc'
	,inetd           => 0
	,localport       => 6667
	,password        => '<your gamespy password or its MD5 hash>'
	,pidfile         => ''
	,primarynickname => '<your primary gamespy nickname>'
	,showbcasts      => 1
);

sub gs_send
{
	my ($context, $data) = @_;
	chomp $data;
	{ local $/ = "\r"; chomp $data; }
	$data .= "\r\n";
	print "[GS]  << $data" if $context->{'dumptraffic'};
	$context->{'gsock'}->send(peerchat_crypt($context->{'clientcontext'},
		$data));
}

sub gs_recv
{
	my ($context) = @_;
	my $data = '';
	$context->{'gsock'}->recv($data, 8192);
	return undef if $data eq '';
	$data = peerchat_crypt($context->{'servercontext'}, $data);
	print "[GS]  >> $data" if $context->{'dumptraffic'};
	return $data;
}

sub irc_send
{
	my ($context, $data) = @_;
	chomp $data;
	{ local $/ = "\r"; chomp $data; }
	$data .= "\r\n";
	print "[IRC] << $data" if $context->{'dumptraffic'};
	my $isock = $context->{'isock'};
	if ($isock) { print $isock $data; }
	else        { print        $data; }
}

sub irc_recv
{
	my ($context) = @_;
	my $isock = $context->{'isock'};
	my $data;
	if ($isock) { $data = <$isock>; }
	else        { $data = <STDIN>;  }
	return undef if !defined($data) || $data eq '';
	print "[IRC] >> $data" if $context->{'dumptraffic'};
	return $data;
}

sub peerchat_handshake
{
	my ($context) = @_;
	my $gsock = $context->{'gsock'} or die 'no gsock, stopped';
	my $gamename = $context->{'gamename'} or die 'no gamename, stopped';
	my $gamekey = $context->{'gamekey'} or die 'no gamekey, stopped';
	my $nickname = $context->{'primarynickname'}
		or die 'no primarynickname, stopped';
	my $email = $context->{'email'} or die 'no email, stopped';
	my $password = $context->{'password'} or die 'no password, stopped';
	irc_send($context, 'NOTICE AUTH :*** Start peerchat handshake');
	irc_send($context, 'NOTICE AUTH :*** Sending CRYPT');
	my $data = "CRYPT des 139 $gamename\n";
	print "[GS]  << $data" if $context->{'dumptraffic'};
	$gsock->send($data);
	my $response = '';
	irc_send($context, 'NOTICE AUTH :*** Waiting for challenge strings');
	$gsock->recv($response, 4096);
	chomp $response;
	{ local $/ = "\r"; chomp $response; }
	print "[GS]  >> $response\n" if $context->{'dumptraffic'};
	die 'invalid challenge sent by server, stopped'
		unless $response =~ /^:([^ ]*) [^ ]* [^ ]* ([^ ]*) ([^ ]*)$/;
	my ($servername, $clientchallenge, $serverchallenge) = ($1, $2, $3);
	$context->{'servername'} = $servername;
	my (%clientcontext, %servercontext);
	irc_send($context, 'NOTICE AUTH :*** Preparing client encryption context');
	peerchat_init(\%clientcontext, $clientchallenge, $gamekey);
	irc_send($context, 'NOTICE AUTH :*** Preparing server encryption context');
	peerchat_init(\%servercontext, $serverchallenge, $gamekey);
	$context->{'clientcontext'} = \%clientcontext;
	$context->{'servercontext'} = \%servercontext;
	irc_send($context, 'NOTICE AUTH :*** Sending LOGIN');
	$password = md5_hex($password) unless $password =~ /^[0-9a-z]{32}$/i;
	gs_send($context, 'LOGIN 1 * '.$password.' :'. $nickname.'@'.$email);
	irc_send($context, 'NOTICE AUTH :*** Awaiting LOGIN response');
	$response = gs_recv($context);
	chomp $response;
	{ local $/ = "\r"; chomp $response; }
	die "invalid LOGIN response ($response) received from server, stopped"
		unless $response =~ /^:$servername [^ ]* [^ ]* ([^ ]*) ([^ ]*)$/;
	my ($unknown1, $uid) = ($1, $2);
	$context->{'unknown1'} = $unknown1;
	$context->{'uid'} = $uid;
	irc_send($context, 'NOTICE AUTH :*** Sending USRIP');
	gs_send($context, "USRIP");
	irc_send($context, 'NOTICE AUTH :*** Awaiting USRIP response');
	$response = gs_recv($context);
	chomp $response;
	{ local $/ = "\r"; chomp $response; }
	die 'invalid USRIP response received from server, stopped'
		unless $response =~ /^:$servername .*@(\d+\.\d+\.\d+\.\d+)$/;
	my $ip = $1;
	$context->{'my_ip'} = $ip;
	irc_send($context, 'NOTICE AUTH :*** Sending USER and NICK');
	gs_send($context, 'USER '.ip_enc($ip).'|'.$uid." 127.0.0.1 peerchat.gamespy.com :336d5ebc5436534e61d16e63ddfca327");
	gs_send($context, "NICK *");
	irc_send($context, 'NOTICE AUTH :*** Peerchat handshake and login complete');
}

sub irc_handshake
{
	my ($context) = @_;
	my ($nick_sent, $user_sent);
	irc_send($context, 'NOTICE AUTH :*** Waiting for nickname and username to be sent');
	until ($nick_sent && $user_sent)
	{
		my $req = irc_recv($context);
		die 'IRC connection broken, stopped' unless defined($req);
		foreach (split(/\r?\n/, $req))
		{
			next if /^$/;
			if (/^NICK ([^ ]*)$/i)
			{
				$context->{'nickname'} = $1;
				$nick_sent = 1;
			}
			elsif (/^USER/i)
			{
				$user_sent = 1;
			}
			elsif (/^PING (.*)$/i)
			{
				irc_send($context, "PONG $1");
			}
		}
	}
	irc_send($context, 'NOTICE AUTH :*** Nickname and username received');
}

sub getconn
{
	my ($lsock) = @_;
	my $isock;
	if ($lsock) { $isock = $lsock->accept() or die "accept: $!, stopped"; }
	my $gsock = IO::Socket::INET->new('peerchat.gamespy.com:6667')
		or die "connect: $!, stopped";
	# Set autoflush, IO::Socket before version 1.18 did not do this automatically
	if ($isock) { $| = 1, select $_ for select $isock; }
	if ($gsock) { $| = 1, select $_ for select $gsock; }
	my %context = (
		 isock => $isock
		,gsock => $gsock
	);
	return \%context;
}

sub parse_key_reply
{
	my ($queries, $replies) = @_;
	warn 'queries '.scalar @$queries.' and replies '.scalar @$replies
		.' differ in size! ... ' if scalar @$queries != scalar @$replies;
	my @frepl = ();
	for (my $i = 0; $i < @$queries; $i++)
	{
		if ($queries->[$i] eq 'b_flags')
		{
			my @flags;
			foreach (split(//, $replies->[$i]))
			{
				if    (/a/) { push @flags, 'away'; }
				elsif (/s/) { push @flags, 'hosting'; }
				else        { push @flags, "($_)"; }
			}
			push @frepl, 'flags = '.join(', ', @flags);
		}
		elsif ($queries->[$i] eq 'b_pinfo')
		{
			if ($replies->[$i] =~ /^([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),(.*)$/)
			{
				# $1 = country code, $4,$5,$6 = birth d/m/y, rest = unknown
				push @frepl, "pinfo: country = $1, birth date = $7/$6/$5, unknowns = $2,$3,$4,$8";
			}
			else
			{
				push @frepl, "pinfo: unknown format: $replies->[$i]";
			}
		}
		elsif ($queries->[$i] eq 'instsvc')
		{
			push @frepl, "games = $replies->[$i]";
		}
		elsif ($queries->[$i] eq 'username')
		{
			if ($replies->[$i] =~ /^([XaFl4uOD9sfWq1vGp]*)\|(.*)$/)
			{
				# $1 = peerchat encoded IP, $2 = UID
				push @frepl, "user = $2@".ip_dec($1);
			}
			else
			{
				push @frepl, "user = $replies->[$i]";
			}
		}
		else
		{
			push @frepl, $queries->[$i].' = '.$replies->[$i];
		}
	}
	return join(' || ', @frepl);
}

sub handle_getckey_reply
{
	my ($context, $chan, $subj, $queryid, $msg) = @_;
	my @repl = split(/\\/, $msg, -1);
	shift @repl; # Always starts with \
	if ($queryid =~ /^BCAST$/i)
	{
		# Ignore if showbcasts is not set
		if ($context->{'showbcasts'})
		{
			# BCAST uses key\value pairs
			my @queries = ();
			my @replies = ();
			my $flipflop = 0;
			foreach (@repl)
			{
				if ($flipflop) { push @replies, $_; $flipflop--; }
				else           { push @queries, $_; $flipflop++; }
			}
			gsirc_say($context, "<$chan:$subj> ".parse_key_reply(\@queries, \@replies));
		}
	}
	else
	{
		unless (defined($context->{'queries'}->{$queryid}))
		{
			gsirc_say($context, "GETCKEY reply with unknown ID $queryid: <$chan:$subj> $msg");
			return;
		}
		gsirc_say($context, "<$chan:$subj> ".parse_key_reply($context->{'queries'}->{$queryid}, \@repl));
	}
}

sub handle_getkey_reply
{
	my ($context, $subj, $queryid, $msg) = @_;
	my @repl = split(/\\/, $msg, -1);
	shift @repl; # Always starts with \
	unless (defined($context->{'queries'}->{$queryid}))
	{
		gsirc_say($context, "GETKEY reply with unknown ID $queryid: <$subj> $msg");
		return;
	}
	gsirc_say($context, "<$subj> ".parse_key_reply($context->{'queries'}->{$queryid}, \@repl));
	delete $context->{'queries'}->{$queryid};
}

sub process_peerchat
{
	my ($context) = @_;
	my $sn = $context->{'servername'};
	my $data = gs_recv($context);
	unless (defined($data))
	{
		# Peerchat connection broken
		irc_send($context, 'ERROR :Closing link: peerchat connection broken');
		$context->{'isock'}->shutdown(2);
		$context->{'isock'}->close();
		return 0;
	}
	my @lines = split(/\r?\n/, $data, -1);
	$lines[0] = $context->{'gsock_temp_data'} . $lines[0]
		if $context->{'gsock_temp_data'};
	$context->{'gsock_temp_data'} = pop @lines;
	foreach (@lines)
	{
		chomp;
		{ local $/ = "\r"; chomp; }
		if (/^:$sn 709 /)
		{
			# "No unique nickname registered"
			if ($context->{'nickname'})
			{
				my $nickname = $context->{'nickname'};
				irc_send($context, ":$sn NOTICE $nickname :No unique nickname registered");
				irc_send($context, ":$sn NOTICE $nickname :Sending REGISTERNICK 1 $nickname");
				gs_send($context, "REGISTERNICK 1 $nickname");
			}
			else
			{
				irc_send($context, ":$sn NOTICE AUTH :No unique nickname registered");
				irc_send($context, ":$sn NOTICE AUTH :Send REGISTERNICK 1 <nickname>");
			}
		}
		elsif (/^:$sn 001 ([^ ]*)-gs (.*)$/)
		{
			$context->{'nickname'} = $1;
			irc_send($context, ":$sn 001 $1 $2");
			gs_send($context, "SETKEY :\\instsvc\\$context->{'gamename'}");
			gs_send($context, "SETKEY :\\b_pinfo\\$context->{'gs_pinfo'}");
		}
		elsif (/^:$sn 376 ([^ ]*)-gs (.*)$/)
		{
			# End of MOTD
			irc_send($context, ":$sn 376 $1 $2");
			join_gsirc_channel($context) if $context->{'gsirc'};
		}
		elsif (/^PING (.*)$/i)
		{
			gs_send($context, "PONG $1");
		}
		elsif (/^:($context->{'nickname'}|$context->{'gsirc_botname'}(?:-gs)?)!(.*)$/i)
		{
			# Someone's using our or the gsirc bot's name!
			gsirc_say($context, "\002\003"."4Name conflict\003\002: \"$1!$2\"");
		}
		elsif (/^:([^ ]*) NICK (:?$context->{'nickname'}|$context->{'gsirc_botname'}(?:-gs)?)\b(.*)$/i)
		{
			# Someone's using our or the gsirc bot's name!
			gsirc_say($context, "\002\003"."4Name conflict\003\002: \":$1 NICK $2$3\"");
		}
		elsif (/^:([^ !]*)-gs!([XaFl4uOD9sfWq1vGp]*)\|([^ @]*)@\* ([^ ]*) ([^ ]*)-gs( .*)?$/)
		{
			# $1 = nickname, $2 = peerchat encoded IP, $3 = UID, $4 = event
			# type, $5 = our nick(?), $6 = msg
			my $ip = ip_dec($2);
			irc_send($context, ":$1!$3@"."$ip $4 $5$6");
		}
		elsif (/^:([^ !]*)-gs!([XaFl4uOD9sfWq1vGp]*)\|([^ @]*)@\* (.*)$/)
		{
			# $1 = nickname, $2 = peerchat encoded IP, $3 = UID, $4 = msg
			my $ip = ip_dec($2);
			irc_send($context, ":$1!$3@"."$ip $4");
		}
		elsif (/^:([^ !]*)-gs!\*@\* (.*)$/)
		{
			# $1 = nickname, $2 - msg
			irc_send($context, ":$1!*@* $2");
		}
		elsif (/^:$sn 702 [^ ]* ([^ ]*) ([^ ]*)-gs ([^ ]*) :?(.*)$/)
		{
			# GETCKEY reply or BCAST
			# $1 = channel, $2 = subject, $3 = query ID, $4 = reply
			handle_getckey_reply($context, $1, $2, $3, $4);
		}
		elsif (/^:$sn 703 [^ ]* [^ ]* ([^ ]*)/)
		{
			# End of GETCKEY reply
			# $1 = query ID
			delete $context->{'queries'}->{$1};
		}
		elsif (/^:$sn 700 [^ ]* ([^ ]*)-gs ([^ ]*) :?(.*)$/)
		{
			# GETKEY reply
			# $1 = subject, $2 = query ID, $3 = reply
			handle_getkey_reply($context, $1, $2, $3);
		}
		elsif (/^:$sn 311 ([^ ]*)-gs ([^ ]*)-gs ([XaFl4uOD9sfWq1vGp]*)\|([^ ]*) (.*)$/)
		{
			# WHOIS nick, user, host, realname reply
			# $1 = our nick, $2 = queried nick, $3 = peerchat encoded IP
			# $4 = queried nick's UID, $5 = the rest
			irc_send($context, ":$sn 311 $1 $2 $4 ".ip_dec($3)." $5");
		}
		elsif (/^:$sn (31[2-8]) ([^ ]*)-gs ([^ ]*)-gs (.*)$/)
		{
			# WHOIS additional info
			# $1 = reply code, $2 = our nick, $3 = queried nick, $4 = the rest
			irc_send($context, ":$sn $1 $2 $3 $4");
		}
		elsif (/^:$sn 352 ([^ ]*)-gs ([^ ]*) ([XaFl4uOD9sfWq1vGp]*)\|([^ ]*) [^ ]* ([^ ]*) ([^ ]*)-gs ([^ ]*) ([^ ]*) (.*)$/)
		{
			# WHO reply
			# $1 = our nick, $2 = channel name, $3 = peerchat encoded IP
			# $4 = target nick's UID, $5 = s, $6 = target nickname
			# $7 = flags, $8 = :0, $9 = target nick's realname
			my $ip = ip_dec($3);
			irc_send($context, ":$sn 352 $1 $2 $4 $ip $5 $6 $7 $8 $9");
		}
		elsif (/^:$sn 353 ([^ ]*)-gs ([^ ]*) ([^ ]*) (.*)$/)
		{
			# NAMES reply
			# $1 = our nick, $2 = *, $3 = channel name, $4 = names list
			my @names = split(' ', $4);
			for (my $i = 0; $i < @names; $i++)
			{
				$names[$i] =~ s/-gs$//;
			}
			irc_send($context, ":$sn 353 $1 $2 $3 ".join(' ', @names));
		}
		elsif (/^:$sn 367 [^ ]* [^ ]* [^ ]* [^ ]*@ [0-9]*$/)
		{
			# Leave out those long ban lists
		}
		elsif (/^:$sn ([^ ]*) ([^ ]*)-gs (.*)$/)
		{
			# $1 = message type code, $2 = nickname, $3 = message
			irc_send($context, ":$sn $1 $2 $3");
		}
		else
		{
			my $text = $_;
			$text =~ s/\b($context->{'nickname'})\b/$1-gs/g;
			irc_send($context, $_);
		}
	}
	return 1;
}

sub process_irc
{
	my ($context) = @_;
	my $sn = $context->{'servername'};
	my $nick = $context->{'nickname'};
	my $gsirc = $context->{'gsirc_botname'};
	my $gsirc_chan = $context->{'gsirc_channel'};
	#my $userhost = $context->{'uid'}.'@'.$context->{'my_ip'};
	my $data = irc_recv($context);
	unless (defined($data))
	{
		# IRC client broke connection
		gs_send($context, "QUIT :Later!");
		return 0;
	}
	my @lines = split(/\r?\n/, $data, -1);
	$lines[0] = $context->{'isock_temp_data'} . $lines[0]
		if $context->{'isock_temp_data'};
	$context->{'isock_temp_data'} = pop @lines;
	foreach (@lines)
	{
		chomp;
		{ local $/ = "\r"; chomp; }
		if (/^([^ ]*) #$gsirc_chan ?(.*)/i)
		{
			# Special case, the gsirc control channel
			my ($cmd, $params) = ($1, $2);
			if ($cmd =~ /^JOIN$/i)
			{
				join_gsirc_channel($context);
			}
			elsif ($cmd =~ /^PART$/i)
			{
				part_gsirc_channel($context);
			}
			elsif ($cmd =~ /^MODE$/i and not $params)
			{
				irc_send($context, ":$sn 324 $nick #$gsirc_chan +");
			}
			elsif ($cmd =~ /^MODE$/i and $params =~ /^\+?b/)
			{
				irc_send($context, ":$sn 368 $nick #$gsirc_chan :End of Channel Ban List");
			}
			elsif ($cmd =~ /^NAMES$/i)
			{
				irc_send($context, ":$sn 353 $nick = #$gsirc_chan :$nick @"."$gsirc");
				irc_send($context, ":$sn 366 $nick #$gsirc_chan :End of /NAMES list.");
			}
			elsif ($cmd =~ /^WHO$/i)
			{
				irc_send($context, ":$sn 329 $nick #$gsirc_chan ".time());
				irc_send($context, ":$sn 352 $nick #$gsirc_chan $context->{'uid'} $context->{'my_ip'} $sn $nick H :0 -");
				irc_send($context, ":$sn 352 $nick #$gsirc_chan gsirc gsirc $sn $gsirc H*@ :0 GS-IRC tunnel info bot");
				irc_send($context, ":$sn 315 $nick #$gsirc_chan :End of /WHO list.");
			}
			elsif ($cmd =~ /^TOPIC$/i and not $params)
			{
				irc_send($context, ":$sn 332 $nick #$gsirc_chan :gsirc control channel");
				irc_send($context, ":$sn 333 $nick #$gsirc_chan $gsirc ".time());
			}
			elsif ($cmd =~ /^PRIVMSG$/i)
			{
				# gsirc command
				do_gsirc($context, $params);
			}
			else
			{
				irc_send($context, ":$sn 482 $nick #$gsirc_chan :Permission denied");
			}
		}
		elsif (/^AWAY :(.+)$/)
		{
			gs_send($context, "AWAY :$1");
			irc_send($context, ":$sn 306 $nick :You have been marked as being away");
		}
		elsif (/^AWAY(?: :)?$/)
		{
			gs_send($context, "AWAY :");
			irc_send($context, ":$sn 305 $nick :You are no longer marked as being away");
		}
		else
		{
			if (/^([^ ]*) $gsirc(?: :?(.*))?$/)
			{
				# Special case, the gsirc control channel bot
				my ($cmd, $params) = ($1, $2);
				if ($cmd =~ /^INVITE$/i and $params =~ /^#([^ ]*)$/)
				{
					# Move user and gsirc bot to given channel
					irc_send($context, ":$gsirc!gsirc@"."gsirc PART #$gsirc_chan :Moved over to #$1");
					part_gsirc_channel($context);
					$context->{'gsirc_channel'} = $1;
					join_gsirc_channel($context);
				}
				elsif ($cmd =~ /^WHOIS$/i)
				{
					irc_send($context, ":$sn 311 $nick $gsirc gsirc gsirc * :GS-IRC tunnel info bot");
					irc_send($context, ":$sn 319 $nick $gsirc :@"."$gsirc_chan");
					irc_send($context, ":$sn 312 $nick $gsirc localhost :gsirc tunnel");
					irc_send($context, ":$sn 318 $nick $gsirc :End of /WHOIS reply");
				}
				elsif ($cmd =~ /^USERHOST$/i)
				{
					irc_send($context, ":$sn 302 $nick :$gsirc=+gsirc@"."gsirc");
				}
				elsif ($cmd =~ /^PRIVMSG$/i)
				{
					do_gsirc($context, $params);
				}
			}
			else
			{
				# Add -gs to nicknames if appropriate
				if (/^(INVITE|ISON|MODE|NICK|NOTICE|PRIVMSG|USERHOST|WHOIS|WHOWAS) ([^#][^ ]*)(.*)$/)
				{
					# Direct nickname related
					gs_send($context, "$1 $2-gs$3");
				}
				elsif (/^KICK (#[^ ]*) ([^ ]*)(.*)/)
				{
					gs_send($context, "KICK $1 $2-gs$3");
				}
				elsif (/^MODE (#[^ ]*) ((?:\+|-)[^ ]*) (.*)/)
				{
					my @modenicks = split(' ', $3);
					for (my $i = 0; $i < @modenicks; $i++)
					{
						$modenicks[$i] .= '-gs';
					}
					gs_send($context, "MODE $1 $2 ".join(' ', @modenicks));
				}
				else
				{
					gs_send($context, $_);
				}
			}
		}
	}
	return 1;
}

sub gsirc_say
{
	my ($context, $text) = @_;
	my $gsirc = $context->{'gsirc_botname'};
	my $gsirc_chan = $context->{'gsirc_channel'};
	irc_send($context, ":$gsirc!gsirc@"."gsirc PRIVMSG #$gsirc_chan :" . $text)
		if $context->{'gsirc'};
}

sub join_gsirc_channel
{
	my ($context) = @_;
	my $sn = $context->{'servername'};
	my $nick = $context->{'nickname'};
	my $gsirc = $context->{'gsirc_botname'};
	my $gsirc_chan = $context->{'gsirc_channel'};
	my $nickhost =
		 $nick.'!'
		.$context->{'uid'}.'@'
		.$context->{'my_ip'};
	irc_send($context, ":$nickhost JOIN #$gsirc_chan");
	irc_send($context, ":$sn 332 $nick #$gsirc_chan :gsirc control channel");
	irc_send($context, ":$sn 333 $nick #$gsirc_chan $gsirc ".time());
	irc_send($context, ":$sn 353 $nick = #$gsirc_chan :$nick @"."$gsirc");
	irc_send($context, ":$sn 366 $nick #$gsirc_chan :End of /NAMES list.");
	$context->{'gsirc'} = 1;
}

sub part_gsirc_channel
{
	my ($context) = @_;
	my $nick = $context->{'nickname'};
	my $nickhost =
		 $nick.'!'
		.$context->{'uid'}.'@'
		.$context->{'my_ip'};
	irc_send($context, ":$nickhost PART #$context->{'gsirc_channel'}");
	$context->{'gsirc'} = 0;
}

sub do_gsirc
{
	my ($context, $cmdline) = @_;
	if ($cmdline =~ /^:?([^ ]+) ?(.*)$/)
	{
		my $cmd = $1;
		my @args = split(' ', $2);
		if ($cmd =~ /^HELP$/i)
		{
			foreach (
				 "help"
				,"    Prints this information."
				,"get <user|#chan> <key1> [<key2>]..."
				,"    Request information about a user or channel."
				,"    Example keys: b_flags, b_pinfo, instsvc, username."
				,"set [<#chan>] <key> [<value>]"
				,"    Set information about yourself or broadcast it"
				,"    to a channel. If <value> is unspecified it is sent"
				,"    as the empty value."
				,"explain [<key>]..."
				,"    Prints help for the given context hash keys"
				,"    (options). If none are specified, prints help for"
				,"    all of them. Note that some of them (like inetd)"
				,"    only have an effect during initialization."
				,"print [<key>]..."
				,"    Prints the values for the given context hash keys."
				,"    If no keys are specified, lists everything."
				,"printdef [<key>]..."
				,"    Prints the default values for the given context hash"
				,"    keys. If no keys are specified, lists all defaults."
				,"setopt <key> [<value>]"
				,"    Adds or modifies an option in the context hash."
				,"    If <value> is unspecified then the key is deleted"
				,"    from the hash. \002Use carefully!\002"
				,"ipenc [<hostname or IP address>]..."
				,"    Prints the gamespy peerchat encoded representations"
				,"    of the given IP addresses. If a hostname is given it"
				,"    is first resolved to an IP address. If no argument"
				,"    is given your own IP address is used."
				,"ipdec <encoded IP> [<encoded IP>]..."
				,"    Decrypts and prints the given peerchat encoded IP"
				,"    addresses."
				,"md5 <text>"
				,"    Prints the MD5 digest for the given text."
				,"quote <text>"
				,"    Sends <text> to the peerchat server, unfiltered"
				,"    (except for the encryption)."
				,"quoteirc <text>"
				,"    Sends <text> to your IRC client, unfiltered."
				,"renamebot <newname>"
				,"    Renames the $context->{'gsirc_botname'} bot. (To rename the"
				,"    channel, invite the bot to it.)"
			) { gsirc_say($context, $_); }
		}
		elsif ($cmd =~ /^GET$/i)
		{
			if (@args < 2)
			{
				gsirc_say($context, 'Insufficient arguments. Try "help".');
				return;
			}
			my @queries = @args[1..$#args];
			my $queryid = sprintf('%03d', $context->{'querycounter'}++);
			$context->{'queries'}->{$queryid} = \@queries;
			if ($args[0] =~ /^#/)
			{
				# Channel - GETCKEY
				gs_send($context, "GETCKEY $args[0] * $queryid 0 :\\"
					.join('\\', @queries));
			}
			else
			{
				# User - GETKEY
				gs_send($context, "GETKEY $args[0]-gs $queryid 0 :\\"
					.join('\\', @queries));
			}
		}
		elsif ($cmd =~ /^SET$/i)
		{
			if (@args < 1)
			{
				gsirc_say($context, 'Insufficient arguments. Try "help".');
				return;
			}
			if ($args[0] =~ /^#/)
			{
				# Channel broadcast - SETCKEY
				if (@args < 2)
				{
					gsirc_say($context, 'Insufficient arguments. Try "help".');
					return;
				}
				$args[2] = '' unless defined($args[2]);
				gs_send($context, "SETCKEY $args[0] $context->{'nickname'}-gs "
				    .':\\'.$args[1].'\\'.$args[2]);
			}
			else
			{
				# Set user info - SETKEY
				$args[1] = '' unless defined($args[1]);
				gs_send($context, "SETKEY :\\".$args[0].'\\'.$args[1]);
			}
		}
		elsif ($cmd =~ /^PRINT$/i)
		{
			if (@args < 1)
			{
				@args = sort keys %$context;
			}
			foreach my $key (@args)
			{
				if (exists($context->{$key}))
				{
					gsirc_say($context, "\002$key\002: $context->{$key}");
				}
				else
				{
					gsirc_say($context, "Unknown key \"$key\". Try \"explain\".");
				}
			}
		}
		elsif ($cmd =~ /^PRINTDEF$/i)
		{
			if (@args < 1)
			{
				@args = sort keys %option_defaults;
			}
			foreach my $key (@args)
			{
				if (exists($option_defaults{$key}))
				{
					gsirc_say($context, "\002$key\002: $option_defaults{$key}");
				}
				else
				{
					gsirc_say($context, "No default value for option \"$key\". Try \"printdef\" without arguments.");
				}
			}
		}
		elsif ($cmd =~ /^SETOPT$/i)
		{
			if (@args < 1)
			{
				gsirc_say($context, 'Insufficient arguments. Try "help".');
				return;
			}
			if (@args < 2)
			{
				delete $context->{$args[0]};
				gsirc_say($context, "\002$args[0]\002 deleted from context hash");
			}
			else
			{
				my $key = shift @args;
				my $value = join(' ', @args);
				$context->{$key} = $value;
				gsirc_say($context, "\002$key\002 set to \"$value\"");
			}
		}
		elsif ($cmd =~ /^IPENC$/i)
		{
			if (@args < 1)
			{
				$args[0] = $context->{'my_ip'}
			}
			foreach (@args)
			{
				my $encip = ip_enc($_);
				if (defined($encip))
				{
					gsirc_say($context, "\002$_\002: $encip");
				}
				else
				{
					gsirc_say($context, "Unable to resolve \"\002$_\002\"");
				}
			}
		}
		elsif ($cmd =~ /^IPDEC$/i)
		{
			if (@args < 1)
			{
				gsirc_say($context, 'Insufficient arguments. Try "help".');
				return;
			}
			foreach (@args)
			{
				if (/^X[XaFl4uOD9sfWq1vGp]{8}X$/)
				{
					gsirc_say($context, "\002$_\002: ".ip_dec($_));
				}
				else
				{
					gsirc_say($context, "\002$_\002 is not a valid encoded IP");
				}
			}
		}
		elsif ($cmd =~ /^EXPLAIN$/i)
		{
			if (@args < 1)
			{
				@args = sort keys %option_help;
			}
			foreach my $key (@args)
			{
				if (exists($option_help{$key}))
				{
					gsirc_say($context, "\002$key\002: $option_help{$key}");
				}
				else
				{
					gsirc_say($context, "Unknown key \"$key\". Try \"explain\".");
				}
			}
		}
		elsif ($cmd =~ /^MD5$/i)
		{
			if (@args < 1)
			{
				gsirc_say($context, 'Insufficient arguments. Try "help".');
				return;
			}
			gsirc_say($context, md5_hex(join(' ', @args)));
		}
		elsif ($cmd =~ /^QUOTE$/i)
		{
			if (@args < 1)
			{
				gsirc_say($context, 'Insufficient arguments. Try "help".');
				return;
			}
			gs_send($context, join(' ', @args));
		}
		elsif ($cmd =~ /^QUOTEIRC$/i)
		{
			if (@args < 1)
			{
				gsirc_say($context, 'Insufficient arguments. Try "help".');
				return;
			}
			irc_send($context, join(' ', @args));
		}
		elsif ($cmd =~ /^RENAMEBOT$/i)
		{
			if (@args < 1)
			{
				gsirc_say($context, 'Insufficient arguments. Try "help".');
				return;
			}
			irc_send($context, ":$context->{'gsirc_botname'}!gsirc@"."gsirc NICK :$args[0]");
			$context->{'gsirc_botname'} = $args[0];
		}
		else
		{
			gsirc_say($context, "Command \"$cmd\" not recognized. Try \"help\".");
		}
	}
}

sub mainloop
{
	my ($context) = @_;
	my $peerchat_connected = 1;
	my $irc_connected = 1;
	while ($peerchat_connected and $irc_connected)
	{
		my @to_read = IO::Select->new(@{$context}{qw/gsock isock/})->can_read();
		last unless @to_read;
		foreach my $sock (@to_read)
		{
			if ($sock == $context->{'gsock'})
			{
				$peerchat_connected = process_peerchat($context);
			}
			elsif ($sock == $context->{'isock'})
			{
				$irc_connected = process_irc($context);
			}
			else
			{
				warn "WTF.. unknown socket ready for reading! ... ";
			}
		}
	}
}

sub write_pidfile
{
	my ($pidfile) = @_;
	warn '$pidfile is set to 1, are you sure you want this? ... '
	  if $pidfile eq 1;
	open(PIDFILE, '>', $pidfile) or die "open: $!, stopped";
	print PIDFILE $$ . "\n";
	close(PIDFILE);
}

sub create_new_opts_file_and_die
{
	my ($optsfile) = @_;
	die "$optsfile exists but can't be read, stopped" if (-e $optsfile);
	open(F, '>', $optsfile) or die "open: $!, stopped";
	print F "# Example .gsirc file, edit this to match your info\n";
	foreach my $key (sort keys %option_defaults)
	{
		print F "#$key=$option_defaults{$key}\n";
	}
	close(F);
	chmod 0600, $optsfile;
	die "$optsfile created, edit it then run gsirc again. Stopped";
}

sub read_opts_from_file
{
	my ($configfile) = @_;
	my %opts = %option_defaults;
	$opts{'config'} = $configfile;
	if (not open(F, '<', $configfile))
	{
		print STDERR "error: open: $!\n";
		create_new_opts_file_and_die($configfile);
	}
	while (<F>)
	{
		chomp;
		{ local $/ = "\r"; chomp; }
		# Ignore # comments and blank lines
		next if /^#/;
		next if /^\s*$/;
		if (/^([^=]*)=(.*)$/)
		{
			# opt=value
			die "Unrecognized option $1, stopped"
			  unless exists($option_defaults{$1});
			$opts{$1} = $2;
		}
		else
		{
			# opt
			die "Unrecognized option $_, stopped"
			  unless exists($option_defaults{$_});
			$opts{$_} = 1;
		}
	}
	close(F);
	return \%opts;
}

sub parse_args
{
	my ($opts) = @_;
	foreach (@ARGV)
	{
		if (/^(?:--)?([^=]*)=(.*)$/)
		{
			# --arg=value or arg=value
			die "Unrecognized option $1, stopped"
			  unless exists($option_defaults{$1});
			$opts->{$1} = $2;
		}
		elsif (/^(?:--?)?(.*)$/)
		{
			die "Unrecognized option $1, stopped"
			  unless exists($option_defaults{$1});
			$opts->{$1} = 1;
		}
		else
		{
			die "FIXME: invalid arg $_, shouldn't happen!";
		}
	}
}

sub get_config_file
{
	if (my ($configfile) = grep(/^(?:--)?config=/, @ARGV))
	{
		$configfile =~ s/^(?:--)?config=//;
		return $configfile;
	}
	else
	{
		return $option_defaults{'config'};
	}
}

sub run
{
	# Set autoflush on stdout in case it's redirected.
	$| = 1;
	my $opts = read_opts_from_file(get_config_file());
	parse_args($opts);
	write_pidfile($opts->{'pidfile'}) if $opts->{'pidfile'};
	my $listensock;
	unless ($opts->{'inetd'})
	{
		$listensock = IO::Socket::INET->new(
			 Listen => 1
			,LocalPort => $opts->{'localport'}
			,Proto => 'tcp'
			,ReuseAddr => 1
		) or die "can't create listen socket: $!, stopped";
		print 'Tunnel initialized, connect your IRC client to localhost:'
		    . "$opts->{'localport'}\n";
	}
	my $context = getconn($listensock);
	# Merge opts into context hash
	while (my ($key, $value) = each %$opts)
	{
		$context->{$key} = $value;
	}
	irc_handshake($context);
	peerchat_handshake($context);
	mainloop($context);
}

run();
