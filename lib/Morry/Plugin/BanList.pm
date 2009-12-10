package Morry::Plugin::BanList;

use Moses::Plugin;
use YAML::Any qw(DumpFile LoadFile);
use List::MoreUtils qw(natatime);

use namespace::autoclean;

sub S_bot_addressed {
    my ($self, $irc, $nickstr, $channels, $message) = @_;

    return PCI_EAT_NONE unless $$message =~ /^(load|save)_bans$/;
    return PCI_EAT_PLUGIN unless $$nickstr eq $self->bot->default_owner; 
    
    my $channel = $$channels->[0] || '';
    return PCI_EAT_PLUGIN unless $channel;

    my $banfile = 
        '/home/associat/g/goldfish/.morry/bans-' . $channel . '.yml';
 
    if ($$message =~ /save/) {
        my $ban_ref = $self->bot->irc->channel_ban_list($channel);
        return PCI_EAT_PLUGIN unless $ban_ref;

        DumpFile($banfile, [keys %$ban_ref]); 
    } else {
       my @bans = @{ LoadFile($banfile) };
        if (@bans) {
# limit seems to be 4 bans at a time
# TODO: Update: I'm guessing the limit is not 4, but it's
# actually a limit on message length being sent
# research/confirm and alter accordingly if needed
            my $iter = natatime 4, @bans;
            while (my @banlines = $iter->()) {
                my $modestr = '+b' x scalar @banlines;
                $self->irc->yield('mode' => $channel => $modestr => @banlines)
            }
        }
    }

    return PCI_EAT_PLUGIN;
}

1;
__END__
