package Morry;
use Moses;
use POE::Component::IRC::Plugin::TinyURL;

use Module::Pluggable (
    search_path => ['Morry::Plugin'],
    sub_name    => 'plugin_classes',
);

owner    'go|dfish!goldfish@Redbrick.dcu.ie';
nickname 'morry';
server   'irc.redbrick.dcu.ie';
channels '#redbrick';

sub custom_plugins {
    return { 
        'tinyurl' => POE::Component::IRC::Plugin::TinyURL->new(), 
        map { $_ => $_ } $_[0]->plugin_classes 
    }
}

no Moses;
1;
__END__
