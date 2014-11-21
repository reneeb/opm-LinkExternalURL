# --
# Kernel/Output/HTML/LinkObjectURL.pm - layout backend module
# Copyright (C) 2011 - 2014 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::LinkObjectURL;

use strict;
use warnings;

our $VERSION = 0.02;

our @ObjectDependencies = qw(
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

=head1 NAME

Kernel::Output::HTML::LinkObjectURL - layout backend module

=head1 SYNOPSIS

All layout functions of link object (URL)

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::LinkObjectTicket->new(
        UserLanguage => 'en',
        UserID       => 1,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw(UserLanguage UserID)) {
        $Self->{$Needed} = $Param{$Needed} || die "Got no $Needed!";
    }

    # We need our own LayoutObject instance to avoid blockdata collisions
    #   with the main page.
    $Self->{LayoutObject} = Kernel::Output::HTML::Layout->new( %{$Self} );

    # define needed variables
    $Self->{ObjectData} = {
        Object   => 'URL',
        Realname => 'URL',
    };

    return $Self;
}

=item TableCreateComplex()

return an array with the block data

Return

    %BlockData = (
        {
            Object    => 'URL',
            Blockname => 'URL',
            Headline  => [
                {
                    Content => 'Title',
                },
            ],
            ItemList => [
                [
                    {
                        Type    => 'Link',
                        Key     => $URLID,
                        Content => '123123123',
                        Css     => 'style="text-decoration: line-through"',
                    },
                ],
            ],
        },
    );

    @BlockData = $LinkObject->TableCreateComplex(
        ObjectLinkListWithData => $ObjectLinkListRef,
    );

=cut

sub TableCreateComplex {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    if ( !$Param{ObjectLinkListWithData} || ref $Param{ObjectLinkListWithData} ne 'HASH' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ObjectLinkListWithData!',
        );
        return;
    }

    # convert the list
    my %LinkList;
    for my $LinkType ( sort keys %{ $Param{ObjectLinkListWithData} } ) {

        # extract link type List
        my $LinkTypeList = $Param{ObjectLinkListWithData}->{$LinkType};

        for my $Direction ( sort keys %{$LinkTypeList} ) {

            # extract direction list
            my $DirectionList = $Param{ObjectLinkListWithData}->{$LinkType}->{$Direction};

            for my $URLID ( sort keys %{$DirectionList} ) {

                $LinkList{$URLID}->{Data} = $DirectionList->{$URLID};
            }
        }
    }

    # create the item list
    my @ItemList;
    for my $URLID ( sort { $a <=> $b } keys %LinkList ) {

        # extract ticket data
        my $URL = $LinkList{$URLID}{Data};

        my @ItemColumns = (
            {
                Type    => 'Link',
                Key     => $URLID,
                Content => $URL->{Title},
                Link    => $URL->{URL},
            },
        );

        push @ItemList, \@ItemColumns;
    }

    return if !@ItemList;

    # define the block data
    my %Block      = (
        Object    => $Self->{ObjectData}->{Object},
        Blockname => $Self->{ObjectData}->{Realname},
        Headline  => [
            {
                Content => 'Title',
            },
        ],
        ItemList => \@ItemList,
    );

    return ( \%Block );
}

=item TableCreateSimple()

return a hash with the link output data

Return

    %LinkOutputData = (
        ExternalLink::Source => {
            URL => [
                {
                    Type    => 'Link',
                    Content => 'T:22222',
                    Title   => 'URL#22222: Title of ticket 22222',
                },
            ],
        },
        ExternalLink::Target => {
            URL => [
                {
                    Type    => 'Link',
                    Content => 'T:77777',
                    Title   => 'URL#77777: URL title',
                },
            ],
        },
    );

    %LinkOutputData = $LinkObject->TableCreateSimple(
        ObjectLinkListWithData => $ObjectLinkListRef,
    );

=cut

sub TableCreateSimple {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    if ( !$Param{ObjectLinkListWithData} || ref $Param{ObjectLinkListWithData} ne 'HASH' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ObjectLinkListWithData!',
        );
        return;
    }

    my %LinkOutputData;
    for my $LinkType ( sort keys %{ $Param{ObjectLinkListWithData} } ) {

        # extract link type List
        my $LinkTypeList = $Param{ObjectLinkListWithData}->{$LinkType};

        for my $Direction ( sort keys %{$LinkTypeList} ) {

            # extract direction list
            my $DirectionList = $Param{ObjectLinkListWithData}->{$LinkType}->{$Direction};

            my @ItemList;
            for my $URLID ( sort { $a <=> $b } keys %{$DirectionList} ) {

                # extract ticket data
                my $URL = $DirectionList->{$URLID};

                my $ShortTitle = $URL->{Title};
                if ( length $ShortTitle > 30 ) {
                    $ShortTitle = substr( $ShortTitle, 0, 30 ) . '[...]';
                }

                # define item data
                my %Item = (
                    Type    => 'Link',
                    Content => $ShortTitle,
                    Title   => $URL->{Title},
                    Link    => $URL->{URL},
                );

                push @ItemList, \%Item;
            }

            # add item list to link output data
            $LinkOutputData{ $LinkType . '::' . $Direction }->{URL} = \@ItemList;
        }
    }

    return %LinkOutputData;
}

=item ContentStringCreate()

return a output string

    my $String = $LayoutObject->ContentStringCreate(
        ContentData => $HashRef,
    );

=cut

sub ContentStringCreate {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    if ( !$Param{ContentData} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ContentData!',
        );
        return;
    }

    return;
}

=item SelectableObjectList()

return an array hash with selectable objects

Return

    @SelectableObjectList = (
        {
            Key   => 'URL',
            Value => 'URL',
        },
    );

    @SelectableObjectList = $BackendObject->SelectableObjectList(
        Selected => $Identifier,  # (optional)
    );

=cut

sub SelectableObjectList {
    my ( $Self, %Param ) = @_;

    my $Selected;
    if ( $Param{Selected} && $Param{Selected} eq $Self->{ObjectData}->{Object} ) {
        $Selected = 1;
    }

    # object select list
    my @ObjectSelectList = (
        {
            Key      => $Self->{ObjectData}->{Object},
            Value    => $Self->{ObjectData}->{Realname},
            Selected => $Selected,
        },
    );

    return @ObjectSelectList;
}

=item SearchOptionList()

return an array hash with search options

Return

    @SearchOptionList = (
        {
            Key       => 'URL',
            Name      => 'URL',
            InputStrg => $FormString,
            FormData  => '1234',
        },
        {
            Key       => 'Title',
            Name      => 'Title',
            InputStrg => $FormString,
            FormData  => 'BlaBla',
        },
    );

    @SearchOptionList = $BackendObject->SearchOptionList(
        SubObject => 'Bla',  # (optional)
    );

=cut

sub SearchOptionList {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    # search option list
    my @SearchOptionList = (
        {
            Key  => 'URL',
            Name => 'URL',
            Type => 'Text',
        },
        {
            Key  => 'Title',
            Name => 'Title',
            Type => 'Text',
        },
    );

    # add formkey
    for my $Row (@SearchOptionList) {
        $Row->{FormKey} = 'SEARCH::' . $Row->{Key};
    }

    # add form data and input string
    ROW:
    for my $Row (@SearchOptionList) {

        # prepare text input fields
        if ( $Row->{Type} eq 'Text' ) {

            # get form data
            $Row->{FormData} = $ParamObject->GetParam( Param => $Row->{FormKey} );

            # parse the input text block
            $Self->{LayoutObject}->Block(
                Name => 'InputText',
                Data => {
                    Key   => $Row->{FormKey},
                    Value => $Row->{FormData} || '',
                },
            );

            # add the input string
            $Row->{InputStrg} = $Self->{LayoutObject}->Output(
                TemplateFile => 'LinkObject',
            );

            next ROW;
        }

        # prepare list boxes
        if ( $Row->{Type} eq 'List' ) {

            # get form data
            my @FormData = $ParamObject->GetArray( Param => $Row->{FormKey} );
            $Row->{FormData} = \@FormData;

            my %ListData;

            # add the input string
            $Row->{InputStrg} = $Self->{LayoutObject}->BuildSelection(
                Data       => \%ListData,
                Name       => $Row->{FormKey},
                SelectedID => $Row->{FormData},
                Size       => 3,
                Multiple   => 1,
            );

            next ROW;
        }
    }

    return @SearchOptionList;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
