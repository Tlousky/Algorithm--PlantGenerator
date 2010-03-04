package Sprout::Branch::Point;

use Moose;

has [ 'x', 'y' ] => ( is => 'ro', isa => 'Int' );

1;