package Morry::Plugin::AdminList;

use Moses::Plugin;

use feature qw(switch);
use namespace::autoclean;

sub S_bot_addressed {
    my ($self, $irc, $nickstr, $channels, $message) = @_;

    return PCI_EAT_NONE unless $$message =~ /^(add|del|dump)/;
    return PCI_EAT_PLUGIN unless $$nickstr eq $self->bot->default_owner; 

    my $channel = $$channels->[0] || '';
    return PCI_EAT_PLUGIN unless $channel;

    my $nick = parse_user($$nickstr);
    my ($cmd, @args) = split ' ', $$message;
    given ($cmd) {
        when (/^(add|del)$/) {
            foreach my $arg (@args) {
# bot cannot be in admins hash
                next if $arg eq $self->bot->default_nickname;
                my $key = $self->bot->irc->nick_long_form($arg);
                next unless $key;
                $cmd eq 'add'
                    ? $self->bot->set_admin($key => 1)
                    : $self->bot->del_admin($key);
            }
        }
        when ($_ eq 'dump') {
            $self->bot->privmsg($channel => "$nick: " . $self->bot->dump_admins)
        }
    }
    return PCI_EAT_PLUGIN
}

1;
__END__
