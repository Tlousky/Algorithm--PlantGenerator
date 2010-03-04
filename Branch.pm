package Sprout::Branch;

use Moose;
use Sprout::Branch::Point;

has 'name' => ( is => 'ro', isa => 'Str' );

has [ 'start_point', 'end_point'  ] => ( is => 'ro', isa => 'Sprout::Branch::Point' );

# Deltas: the difference between start and end x and y coordinates
# reflecting the slope of the branch
has [ 'dx', 'dy' ] => ( is => 'ro', isa => 'Int' );

# Level in which this branch stands in a linearly created tree
has 'level' => ( is => 'ro', isa => 'Int' );

# Line thickness
has 'width' => ( is => 'ro', isa => 'Int' );

# Contains a reference to the parent branch
has 'parent' => ( is => 'ro', isa => 'Ref' );

# Nodulation: is the attribute which determins whether this branch will
#             continue to create sub-branches
# Complexity: is the number of sub-branches this branch has if nodulation
#             is > 0 (otherwise, no new branches will be created on this 
#             branch, even if it's complexity is > 0
has [ 'nodulation', 'complexity' ] => ( is => 'ro', isa => 'Int' );

# The string representaiton of the params required to create a curved path which will
# represent the branch
has 'path_string' => ( is => 'ro', isa => 'Str' );

1;