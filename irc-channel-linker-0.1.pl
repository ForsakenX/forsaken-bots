#!/usr/bin/perl -w
#
# vim:set sw=4 ts=4:
#
# A simple Perl script to transmit messages between IRC channels
#
# Copyright (c) 2007 The Lion
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote
#    products derived from this software without specific prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

use Dumpvalue;
use IO::Socket::INET;
use IO::Select;
use strict;

my %option_defaults = (
	 config         => "$ENV{HOME}/.irc-channel-linker-rc"
	,dumptraffic	=> 0
	,globalnickname => 'link'
	,globalusername => 'chanlink'
);

sub irc_send
{
	my ($server, $data) = @_;
	chomp $data;
	{ local $/ = "\r"; chomp $data; }
	$data .= "\r\n";
	my $sn = $server->{'name'};
	my $maxlen = ${$server->{'servername_maxlen'}};
	printf "[%"."$maxlen"."s] << %s", $sn, $data if $server->{'dumptraffic'};
	my $sock = $server->{'sock'};
	print $sock $data;
}

sub irc_recv
{
	my ($server) = @_;
	my $sock = $server->{'sock'};
	my $data = <$sock>;
	return undef if !defined($data) || $data eq '';
	my $sn = $server->{'name'};
	my $maxlen = ${$server->{'servername_maxlen'}};
	printf "[%"."$maxlen"."s] >> %s", $sn, $data if $server->{'dumptraffic'};
	return $data;
}

sub irc_handshake
{
	my ($session, $server) = @_;
	my ($handshake_complete);
	my $nickname = $server->{'nickname'} || $session->{'globalnickname'};
	my $username = $server->{'username'} || $session->{'globalusername'};
	irc_send($server, "NICK $nickname");
	irc_send($server, "USER $username $username $username :IRC channel linker bot");
	until ($handshake_complete)
	{
		my $req = irc_recv($server);
		die 'IRC connection broken, stopped' unless defined($req);
		foreach (split(/\r?\n/, $req))
		{
			next if /^$/;
			if (/^:([^ ]*) 376 /)
			{
				irc_send($server, 'JOIN :'.join(',', keys %{$server->{'channels'}}));
				$server->{'servername'} = $1;
				$handshake_complete = 1;
			}
			elsif (/^PING (.*)$/i)
			{
				irc_send($server, "PONG $1");
			}
		}
	}
}

sub do_connect
{
	my ($session) = @_;
	#while (my ($servername, $server) = each %{$session->{'servers'}})
	foreach my $server (grep !$_->{'connected'}, values %{$session->{'servers'}})
	{
		my $host = $server->{'host'};
		$host .= ':6667' unless $host =~ /:/;
		my $sock = IO::Socket::INET->new($host)
			or die "connect: $!, stopped";
		# Set autoflush, IO::Socket before version 1.18 did not do
		# this automatically.
		if ($sock) { $| = 1, select $_ for select $sock; }
		$server->{'sock'} = $sock;
		irc_handshake($session, $server);
		$server->{'connected'} = 1;
	}
}

sub send_to_all_except
{
	my ($session, $server, $chan, $msg) = @_;
	unless ($session->{'quiet'})
	{
		foreach my $s (values %{$session->{'servers'}})
		{
			foreach my $c (keys %{$s->{'channels'}})
			{
				next if $s == $server && lc($c) eq lc($chan);
				privmsg($s, $c, $msg);
			}
		}
	}
}

sub process_irc
{
	my ($session, $server) = @_;
	my $sock = $server->{'sock'};
	my $sn = $server->{'servername'};
	my $nick = $server->{'nickname'};
	my $data = irc_recv($server);
	return 0 unless defined($data);
	my @lines = split(/\r?\n/, $data, -1);
	$lines[0] = $server->{'temp_data'} . $lines[0]
		if $server->{'temp_data'};
	$server->{'temp_data'} = pop @lines;
	foreach (@lines)
	{
		chomp;
		{ local $/ = "\r"; chomp; }
		if (/^:([^ ]+) PRIVMSG $nick :?(.*)$/i)
		{
			# $1 = nickname, $2 = command
			do_command($session, $server, $1, $2);
		}
		elsif (/^:([^ !]+)[^ ]* PRIVMSG (#[^ ]+) :?(.*)$/i)
		{
			my ($from_nick, $chan, $msg) = ($1, $2, $3);
			send_to_all_except($session, $server, $chan, "<$from_nick> $msg")
				unless exists($server->{'ignores'}->{$from_nick});
		}
		elsif (/^:$nick(?:![^ ]*) JOIN :?(#[^ ]+)$/i)
		{
			# $1 = channel
			send_to_all_except($session, $server, '', "*** Joined $server->{'name'}:$1");
			$server->{'channels'}->{$1} = undef;
		}
		elsif (/^:$nick(?:![^ ]*) PART :?(#[^ ]+)$/i)
		{
			# $1 = channel
			send_to_all_except($session, $server, '', "*** Left $server->{'name'}:$1");
			delete $server->{'channels'}->{$1};
		}
		elsif (/^:([^ !]+)(?:![^ ]*)? KICK (#[^ ]+) $nick\b(?: :)?(.*)$/i)
		{
			# $1 = kicker, $2 = channel, $3 = reason (maybe)
			my $msg = "*** Got kicked from $server->{'name'}:$2 by $1";
			$msg .= " ($3)" if $3;
			send_to_all_except($session, $server, '', $msg);
			delete $server->{'channels'}->{$2};
		}
		elsif (/^(?::$sn )?PING (.*)$/i)
		{
			irc_send($server, "PONG $1");
		}
	}
	return 1;
}

sub privmsg
{
	my ($server, $target, $msg) = @_;
	irc_send($server, "PRIVMSG $target :$msg");
}

sub notice
{
	my ($server, $target, $msg) = @_;
	irc_send($server, "NOTICE $target :$msg");
}

sub do_command
{
	my ($session, $server, $nickuserhost, $cmdline) = @_;
	my ($cmd, @params) = split(/ +/, $cmdline);
	my @tmp = split(/!/, $nickuserhost, 2);
	my $opname = $tmp[0];
	if (exists($session->{'operators'}->{$nickuserhost}))
	{
		# Operator only commands
		if ($cmd =~ /^(?:QUIT|SHUTDOWN)$/i)
		{
			foreach my $s (values %{$session->{'servers'}})
			{
				irc_send($s, 'QUIT :Disconnecting');
			}
		}
		elsif ($cmd =~ /^(?:SHUTUP|SILENCE|SILENT|QUIET|MUTE)$/i)
		{
			send_to_all_except($session, $server, '', "*** Muted by $opname");
			$session->{'quiet'} = 1;
			notice($server, $opname, 'Muted.');
		}
		elsif ($cmd =~ /^UNMUTE$/i)
		{
			$session->{'quiet'} = 0;
			send_to_all_except($session, $server, '', "*** Unmuted by $opname");
			notice($server, $opname, 'Unmuted.');
		}
		elsif ($cmd =~ /^JOIN$/i)
		{
			irc_send($server, 'JOIN :'.join(',', (map { s/^#*/#/; $_; } @params)));
		}
		elsif ($cmd =~ /^PART$/i)
		{
			irc_send($server, 'PART :'.join(',', (map { s/^#*/#/; $_; } @params)));
		}
		elsif ($cmd =~ /^PARTALL$/i)
		{
			irc_send($server, 'JOIN 0');
		}
		elsif ($cmd =~ /^IGNORE$/i)
		{
			foreach (@params)
			{
				$server->{'ignores'}->{$_} = undef;
			}
			notice($server, $opname, 'Now ignoring '.join(', ', @params));
		}
		elsif ($cmd =~ /^UNIGNORE$/i)
		{
			my @unignored;
			foreach (@params)
			{
				if ($server->{'ignores'}->{$_})
				{
					delete $server->{'ignores'}->{$_};
					push @unignored, $_;
				}
			}
			if (@unignored)
			{
				notice($server, $opname, 'No longer ignoring '.join(', ', @unignored));
			}
			else
			{
				notice($server, $opname, 'None of those nicks were on ignore.');
			}
		}
		elsif ($cmd =~ /^LISTIGNORES$/i)
		{
			notice($server, $opname, 'Ignored: '.join(', ', keys %{$server->{'ignores'}}));
		}
		elsif ($cmd =~ /^DUMP$/i)
		{
			my $d = new Dumpvalue;
			$d->dumpValue($session);
		}
		else
		{
			notice($server, $opname, "Unrecognized command \"$cmd\"");
		}
	}
}

sub mainloop
{
	my ($session) = @_;
	my @servers = values %{$session->{'servers'}};
	my @socks = map $_->{'sock'}, @servers;
	while (grep $_->{'connected'}, @servers)
	{
		my @to_read = IO::Select->new(@socks)->can_read();
		last unless @to_read;
		foreach my $sock (@to_read)
		{
			my $server = (grep { $_->{'sock'} == $sock; } @servers)[0];
			$server->{'connected'} = process_irc($session, $server);
		}
	}
}

sub write_pidfile
{
	my ($pidfile) = @_;
	warn '$pidfile is set to 1, are you sure you want this? ... '
	  if $pidfile == 1;
	open(PIDFILE, '>', $pidfile) or die "open: $!, stopped";
	print PIDFILE $$ . "\n";
	close(PIDFILE);
}

sub create_new_opts_file_and_die
{
	my ($optsfile) = @_;
	die "$optsfile exists but can't be read, stopped" if (-e $optsfile);
	open(F, '>', $optsfile) or die "open: $!, stopped";
	print F
	    "# Example .irc-channel-linker-rc file, edit this to match your info\n"
	   ."# NOTE: set arguments such as 'channels' and 'operators' must\n"
	   ."# contain at least one comma.\n"
	   ."dumptraffic=0\n"
	   ."globalnickname=link\n"
	   ."globalusername=link\n"
	   ."#operators=yournick!user@"."host,othernick!user@"."host,...\n"
	   ."\n"
	   ."[server1]\n"
	   ."host=irc.server1.net\n"
	   ."channels=#chan1,\n"
	   ."\n"
	   ."[server2]\n"
	   ."host=irc.server2.net\n"
	   ."channels=#chan2,#chan3\n";
	close(F);
	chmod 0600, $optsfile;
	die "$optsfile created, edit it then run gsirc again. Stopped";
}

sub read_opts_from_file
{
	my ($fn) = @_;
	my %session = %option_defaults;
	open(OPTS, '<', $fn) or create_new_opts_file_and_die($fn);
	my $server = '';
	my $servername_maxlen = 0;
	$session{'servername_maxlen'} = \$servername_maxlen;
	while (<OPTS>)
	{
		next if /^#/ || /^\s*$/;
		my $s = \%session;
		$s = $session{'servers'}->{$server} if $server;
		if (/^\[(.*)\]$/)
		{
			$server = $1;
			unless ($session{'servers'}->{$1})
			{
				$session{'servers'}->{$1} = {
				     dumptraffic => $session{'dumptraffic'}
				    ,nickname    => $session{'globalnickname'}
				    ,username    => $session{'globalusername'}
				};
			}
			$s = $session{'servers'}->{$1};
			$s->{'name'} = $1;
			if (length($1) > ${$session{'servername_maxlen'}})
			{
				${$session{'servername_maxlen'}} = length($1);
			}
			$s->{'servername_maxlen'} = $session{'servername_maxlen'};
		}
		elsif (/^([^=]*)=(.*)$/)
		{
			my ($key, $value) = ($1, $2);
			if ($value =~ /,/)
			{
				# key=val1,val2,...,valn
				# This creates a list...
				#$s->{$key} = [];
				#foreach (split(/,/, $value))
				#{
				#	push @{$s->{$key}}, $_;
				#}
				# ...but what we really want is a set.
				$s->{$key} = {};
				foreach (split(/,/, $value))
				{
					$s->{$key}->{$_} = undef;
				}
			}
			else
			{
				# key=value
				$s->{$key} = $value;
			}
		}
		else
		{
			$s->{$_} = 1;
		}
	}
	close(OPTS);
	return \%session;
}

sub parse_args
{
	my ($opts) = @_;
	foreach (@ARGV)
	{
		if (/^(?:--)?([^=]*)=(.*)$/)
		{
			# --arg=value or arg=value
			$opts->{$1} = $2;
		}
		elsif (/^(?:--?)?(.*)$/)
		{
			# --arg or arg
			$opts->{$1} = 1;
		}
		else
		{
			die "Logically impossible argument encountered, "
			   ."please wait for universe to explode... ";
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
	$| = 1;
	my $session = read_opts_from_file(get_config_file());
	parse_args($session);
	write_pidfile($session->{'pidfile'}) if defined($session->{'pidfile'});
	(new Dumpvalue)->dumpValue($session);
	do_connect($session);
	mainloop($session);
}

run();
