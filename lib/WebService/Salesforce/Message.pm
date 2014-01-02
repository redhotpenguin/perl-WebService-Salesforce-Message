package WebService::Salesforce::Message;

use strict;
use warnings;

our $VERSION = '0.02';

use Moo;
use XML::LibXML;

has 'xml' => ( is => 'ro', required => 1 );

has 'dom' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        XML::LibXML->load_xml( string => $self->xml );
    }
);

has 'notifications' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my ($node) = $self->dom->findnodes('/soapenv:Envelope/soapenv:Body');
        my ($notifications) = $node->getChildrenByTagName('notifications');
        return $notifications;
    }
);

has 'organization_id' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications->getChildrenByTagName('OrganizationId')->[0]
          ->textContent;
    }
);

has 'action_id' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications->getChildrenByTagName('ActionId')->[0]
          ->textContent;
    }
);

has 'session_id' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications->getChildrenByTagName('SessionId')->[0]
          ->textContent;
    }
);

has 'enterprise_url' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications->getChildrenByTagName('EnterpriseUrl')->[0]
          ->textContent;
    }
);

has 'partner_url' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications->getChildrenByTagName('PartnerUrl')->[0]
          ->textContent;
    }
);

has 'notification' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notifications->getChildrenByTagName('Notification')->[0];
    }
);

has 'notification_id' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notification->getChildrenByTagName('Id')->[0]
          ->textContent;
    }
);

has 'sobject' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->notification->getChildrenByTagName('sObject')->[0];
    }
);

has 'object_type' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my ( $ns, $type ) =
          split( ':', $self->sobject->getAttribute('xsi:type') );
        return $type;
    }
);

has 'attrs' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self       = shift;
        my @childnodes = $self->sobject->childNodes();
        return [
            map  { $_->localname }
            grep { $_->isa('XML::LibXML::Element') } @childnodes
        ];
    }
);

has 'ack' => (
    is      => 'ro',
    default => sub {
        return <<ACK;
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body>
        <notificationsResponse xmlns="http://soap.sforce.com/2005/09/outbound">
            <Ack>true</Ack>
        </notificationsResponse>
    </soapenv:Body>
</soapenv:Envelope>
ACK
    }
);

sub get {
    my ( $self, $attr ) = @_;
    return $self->sobject->findnodes("./sf:$attr")->[0]->textContent;
}

1;

__END__


=head1 NAME

WebService::Salesforce::Message - Perl extension for Salesforce outbound messages

=head1 SYNOPSIS

  use WebService::Salesforce::Message;

  my $xml = read_in_salesforce_soap_message();
  my $message = WebService::Salesforce::Message->new( xml => $xml );

  my $attrs = $message->attrs; # Id, other attributes of the object in the message
  my $object_id = $message->get('Id');
  my $organization_id = $message->organization_id;

=head1 DESCRIPTION

Salesforce.com can send outbound SOAP messages on status changes. Use this
module to parse those message and inspect the object attributes.

See the source for available methods. Documentation will be added in 0.02, or 
as patches are provided.

=head1 SEE ALSO

L<WWW::Salesforce>
L<SOAP::Lite>

=head1 AUTHOR

Fred Moyer<lt>fred@redhotpenguin.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by iParadigms LLC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
