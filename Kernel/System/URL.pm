# --
# Copyright (C) 2011 - 2023 Perl-Services.de, https://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::URL;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Ticket
    Kernel::System::DB
);

=head1 NAME

Kernel::System::URL - backend for URLs (used to link with tickets)

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item URLAdd()

to add a news 

    my $ID = $URLObject->URLAdd(
        URL   => 'http://perl-magazin.de',
        Title => 'Perl-Magazin',
    );

=cut

sub URLAdd {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    for my $Needed (qw(URL UserID Title)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # insert new news
    return if !$DBObject->Do(
        SQL => 'INSERT INTO ps_urls (title, url) VALUES (?, ?)',
        Bind => [
            \$Param{Title},
            \$Param{URL},
        ],
    );

    # get new url id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT MAX(id) FROM ps_urls WHERE url = ? AND title = ?',
        Bind  => [ \$Param{URL}, \$Param{Title} ],
        Limit => 1,
    );

    my $URLID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $URLID = $Row[0];
    }

    # log notice
    $LogObject->Log(
        Priority => 'notice',
        Message  => "URL '$URLID' created successfully ($Param{UserID})!",
    );

    return $URLID;
}

=item URLGet()

returns a hash with news data

    my %URLData = $URLObject->URLGet( ID => 2 );

This returns something like:

    %URLData = (
        ID    => 2,
        Title => 'Perl-Magazin',
        URL   => 'http://perl-magazin.de',
    );

=cut

sub URLGet {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{ID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );

        return;
    }

    # sql
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, title, url FROM ps_urls WHERE id = ?',
        Bind  => [ \$Param{ID} ],
        Limit => 1,
    );

    my %URL;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %URL = (
            ID    => $Data[0],
            Title => $Data[1],
            URL   => $Data[2],
        );
    }

    return %URL;
}

=item URLDelete()

deletes a news entry. Returns 1 if it was successful, undef otherwise.

    my $Success = $URLObject->URLDelete(
        ID => 123,
    );

=cut

sub URLDelete {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{ID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );

        return;
    }

    return $DBObject->Do(
        SQL  => 'DELETE FROM ps_urls WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );
}

=item URLSearch()

=cut

sub URLSearch {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check for needed params
    if ( !$Param{URL} && !$Param{Title} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need URL or Title!",
        );

        return;
    }

    my $SQL = 'SELECT id FROM ps_urls WHERE ';

    my @Where;
    my @Bind;

    if ( $Param{Title} ) {
        $Param{Title} =~ s{\*}{%}g;
        $Param{Title} = '%' . $Param{Title} . '%';
        push @Where, 'title LIKE ?';
        push @Bind, \$Param{Title};
    }

    if ( $Param{URL} ) {
        $Param{URL} =~ s{\*}{%}g;
        $Param{URL} = '%' . $Param{URL} . '%';
        push @Where, 'url LIKE ?';
        push @Bind, \$Param{URL};
    }

    my $Where = join ' OR ', @Where;
    $SQL     .= $Where;

    return if !$DBObject->Prepare(
       SQL   => $SQL,
       Bind  => \@Bind,
       Limit => $Param{Limit}, 
    );

    my @UrlIDs;

    while ( my ($ID) = $DBObject->FetchrowArray() ) {
        push @UrlIDs, $ID;
    }

    return @UrlIDs;
}


=item URLList()

returns a hash of all news

    my %URLs = $URLObject->URLList();

the result looks like

    %URLs = (
        '1' => 'URL 1',
        '2' => 'Test URL',
    );

=cut

sub URLList {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL  => "SELECT id, url FROM ps_urls",
    );

    my %URL;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $URL{ $Data[0] } = $Data[1];
    }

    return %URL;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

