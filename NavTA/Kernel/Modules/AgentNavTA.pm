# --
# Copyright (C) 2026 netatvision
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see https://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentNavTA;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # placeholder: list config item classes to prove CMDB access works
    my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    ) || {};

    for my $ClassID ( sort { $ClassList->{$a} cmp $ClassList->{$b} } keys %{$ClassList} ) {
        $LayoutObject->Block(
            Name => 'Class',
            Data => {
                ClassID => $ClassID,
                Name    => $ClassList->{$ClassID},
            },
        );
    }

    my $Output = $LayoutObject->Header( Title => 'Provisioning' );
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentNavTA',
        Data         => \%Param,
    );
    $Output .= $LayoutObject->Footer();

    return $Output;
}

1;
