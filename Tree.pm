package Sprout::Tree;

use Moose;
use Sprout::Branch;
use Sprout::Branch::Point;

## Attributes ##

has 'stem_length'   => ( is => 'ro', isa => 'Int' );   # Length of stem
has 'tree_width'    => ( is => 'ro', isa => 'Int' );   # Width of stem
has 'stem_curve'    => ( is => 'ro', isa => 'Int' );   # Curvature and complexity of stem
has 'branch_length' => ( is => 'ro', isa => 'Int' );   # Average (non-stem) branch length
has 'branch_stdev'  => ( is => 'ro', isa => 'Int' );   # Plus-minus range around the average
has 'complexity'    => ( is => 'ro', isa => 'Int' );   # Branching modifier: max number of
                                                       # branches sprouting from a node
has 'branch_curve'  => ( is => 'ro', isa => 'Num' );   # Average curvature of (non-stem) 
                                                       # branches

# Nodulation: determins the number of levels of sub-branching
has 'nodulation'    => ( is => 'ro', isa => 'Int' );
# Ebbing Factor: Determins how quickly the nodulation decreases along the tree
has 'ebbing_factor' => ( is => 'ro', isa => 'Int', default => 2 );

# Creation algorithm: can be either linear or recursive
# Linear gives more control but looks slightly less natural
has 'creation_algorithm' => ( is => 'ro', isa => 'Str', default => 'recursive' );

has 'branches' => ( 
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    default => sub { [ ] },
    handles => {
        add_branch      => 'push',
        count_branches  => 'count',
        filter_branches => 'grep',
    },
);   

# These two determin the amount of change in branch length and angle
# between branches, and along the whole shape of the tree
has 'dx_range' => ( is => 'ro', isa => 'Int'  );
has 'dy_range' => ( is => 'ro', isa => 'Int'  );

has 'verbose'  => ( is => 'ro', isa => 'Bool' );

# Determins whether the tree's shape is more dominated by a single stem with
# shorter and less developed sub-branches, or is highly complex and branching.
# An apically dominant tree will have one dominant stem with many branches
# sprouting out of it, throughout it's length. Not yet implemented (I still 
# need to think how to do this).
# The easier model is the non-apically-dominant tree, with modular branches.
has 'apical_dominance' => ( is => 'ro', isa => 'Int' );

# This is the width of the image on which the tree will be rendered, in pixels
has 'image_width' => ( is => 'ro', isa => 'Int' );


## Methods ##

sub create_tree {
    my $self = shift;

    my $verb = $self->verbose;
    
    $verb && print "[create_tree] Starting\n";
    $verb && print "[create_tree] algorithm is $self->creation_algorithm\n";

    if ( $self->creation_algorithm eq 'recursive' ) {
        # Create main stem
        my $stem = $self->create_stem;
        
        $verb && print "[create_tree] creating primary branches\n";
        
        # Create primary branches and recurse all sub-branches
        foreach my $branch ( 1 .. $self->complexity ) {
            $verb && print "[create_tree] \t creating primary branch $branch\n";
            
            $self->create_branches_recursive( $stem );
        }

    } else {
        
       # Set number of branching levels
        my $levels = $self->nodulation;
        
        $verb && print "[create_tree] creating $levels levels\n";
        
        foreach my $level ( 0 .. $levels ) {
            $verb && print "[create_tree] \t creating level $level\n";
            $self->create_branches( $level );
        }        
    }
}

# Create Branches: Linear branch creating function
sub create_branches {
    my ( $self, $level ) = @_;

    my $verb = $self->verbose;
    $verb && print "[create_branches] Starting\n";
    
    my $branch_num;

    # If it's the first level, the stem and primary branches need to be created
    if ( $level == 1 ) {
        my $stem    = $self->create_stem;
        $branch_num = $self->complexity;

        # Create primary branches
        foreach my $branch ( 1 .. $branch_num ) {
            $self->create_branch( $stem, $level );
        }

    } else {

        # Get the current level's parent branches
        # ( i.e. the previous level's branches )
        my @parent_branches = $self->filter_branches( 
            sub { $_->level == ( $level - 1 ) } 
        );

        foreach my $parent ( @parent_branches ) {
            # Number of sub branches 
            my $sub_branches = int( rand( $self->complexity ) );
            
            # Create sub-branches for the current parent branch
            foreach my $idx ( 1 .. $sub_branches ) {
                $self->create_branch( $parent, $level );
            }
        }
    }
}

# Create Stem: creates the primary branch (stem) for in both recursive and
# linear tree creating algorithms
sub create_stem {
    my $self = shift;
    
    my $verb = $self->verbose;
    $verb && print "[create_stem] Starting\n";
    
    my $d = $self->stem_length;
    
    # Set stem slope ( currently it's stragight up - slope = 0 )
    my $m = 0;
    # To set the slope to a random number between -/+0.5:
    # my $m = -0.5 + rand(1);

    # Set starting coordinates for the Tree's stem

    # Stem's X position is in the middle of the image
    my $x_start = int( $self->image_width / 2 );
    # Y position is of 1st point is on the ground.
    my $y_start = 0;

    # Mathematically speaking:
    # Stem length = distance between it's start and end points:
    #   d = sqrt[ (x2-x1)**2 + (y2-y1)**2 ] = sqrt( dx**2 + dy**2 )
    # Slope: 
    #   m = dy / dx = (y2-y1) / (x2-x1)

    # After development and a applying the square-root:
    #   y = sqrt[ d**2 / ( m**2 + 1 ) ] + y1
    #   x = m * (y1 - y) + x1
    
    my $y_end = int(
        sqrt( $d ** 2 / ( ( $m ** 2 ) + 1 ) + $y_start )
    );
    
    my $x_end = int(
        $m * ( $y_end - $y_start ) + $x_start
    );
    

    # Create stem coordinates
    my $start_point = Sprout::Branch::Point->new(
        x => $x_start, y => $y_start,
    );
    my $end_point = Sprout::Branch::Point->new(
        x => $x_end, y => $y_end,
    );

    $verb && print "[create_stem] \tcreating stem\n";

    my $stem = Sprout::Branch->new(
        name        => 1,
        start_point => $start_point,
        end_point   => $end_point,
        dx          => $x_end - $x_start,
        dy          => $y_end - $y_start,
        level       => 0,
        nodulation  => $self->nodulation,
        complexity  => $self->complexity,
        width       => $self->tree_width,
    );

    # Add stem to branches collection
    $self->add_branch( $stem );

    return $stem;
}

# Linear algorithm's branch creation sub
sub create_branch {
    my ( $self, $parent, $level ) = @_;
    my $start_point = $parent->end_point;

    my $verb = $self->verbose;

    my ( $dx, $dy )       = $self->calc_new_deltas( $parent );
    my ( $x_end, $y_end ) = $self->calc_new_endpoints(
        $start_point, $dx, $dy
    );

    my $end_point = Sprout::Branch::Point->new(
        x => $x_end, y => $y_end 
    );
    my $number = $self->count_branches + 1;  # New branch's num (name)

    my $newbranch = Sprout::Branch->new(
        name        => $number,
        start_point => $start_point,
        end_point   => $end_point,
        dx          => $dx,
        dy          => $dy,
        level       => $level,
        parent      => $parent,
#       nodulation  => ,
#       complexity  => ,
    );

    $self->add_branch( $newbranch );
}


# Calculate New Deltas: uses the parent branch's attributes and random factors
# to modify a new branche's dx and dy values, who determin the angle and length
# of the new branch.
sub calc_new_deltas {
    my ( $self, $parent ) = @_;

    my $verb = $self->verbose;

    # Get parent branch's deltas
    my $old_dx = $parent->dx;
    my $old_dy = $parent->dy;
    
    # Calculate modifiers:
    # These slightly change the dx and dy to create variation and randomness
    # in branches lengths and angles.
    # Modifiers range from -range_value to +range_value
    my $dx_modifier = (
        int( rand( $self->dx_range ) * -1 ) + 
        int( rand( $self->dx_range ) )
    );

    my $dy_modifier = (
        int( rand( $self->dy_range ) * -1 ) + 
        int( rand( $self->dy_range ) )
    );
    
    # If the level is 0, it's the stem's children, so the falloff should be 1.5
    # (so that they would still be a bit shorter than the stem).
    # otherwise, it should be the level + 1
    my $falloff = ( $parent->level == 0 ) ? 1.5 : $parent->level + 1;
    
    # Apply modifiers
    my $new_dx = int ( ( $old_dx + $dx_modifier ) / $falloff );
    my $new_dy = int ( ( $old_dy + $dy_modifier ) / $falloff );
        
    return( $new_dx, $new_dy );
}

# Calculate New End-points: ( by adding the deltas to the start-points )
sub calc_new_endpoints {
    my ( $self, $start_point, $dx, $dy ) = @_;

    my $x_end = $dx + $start_point->x;
    my $y_end = $dy + $start_point->y;

    return( $x_end, $y_end );
}

# The recursive algorithm for creating all non-stem branches
sub create_branches_recursive {
    my ( $self, $parent ) = @_;

    my $verb = $self->verbose;

    my $name = $parent->name;
    $verb && print "[create_branches_recursive] on parent: $name\n";
    
    # Create a new branch connected to parent
    my $branch = $self->make_branch( $parent );
    
    # Create this branche's sub-branches
    if ( $branch->nodulation ) {
        foreach my $idx ( 1 .. $branch->complexity ) {
            $verb && print qq{
                [create_branches_recursive] \tcreating $name 's branches\n
            };
            $self->create_branches_recursive( $branch );
        }
    }
}

# Sub for creating single branches used by the recursive algorithm
sub make_branch {
    my ( $self, $parent ) = @_;
    my $start_point = $parent->end_point;

    my $verb = $self->verbose;

    my $name = $parent->name;
    $verb && print "[make_branche] on parent: $name\n";

    my ( $dx, $dy )       = $self->calc_new_deltas( $parent );
    my ( $x_end, $y_end ) = $self->calc_new_endpoints(
        $start_point, $dx, $dy
    );

    my $end_point  = Sprout::Branch::Point->new(
        x => $x_end, y => $y_end
    );

    my $number     = $self->count_branches + 1;        # New branch's num (name)
    my $nodulation = $self->calc_new_nodulation( $parent );

    my $complexity = int( rand( $self->complexity ) ); # Calculate new complexity
    
    # Calculate new width, and prevent a less than 1 width
    my $falloff   = ( $parent->level == 0 ) ? 1.5 : $parent->level + 1;
    my $new_width = int ( $self->tree_width / $falloff );
    my $width     = $new_width ? $new_width : 1;
    
    my $path_str  = $self->create_path( $start_point, $end_point, $dx, $dy );
    
    my $newbranch = Sprout::Branch->new(
        name        => $number,
        start_point => $start_point,
        end_point   => $end_point,
        dx          => $dx,
        dy          => $dy,
        level       => $parent->level + 1,
        parent      => $parent,
        nodulation  => $nodulation,
        complexity  => $complexity,
        width       => $width,
        path_string => $path_str,
    );

    $verb && print "[make_branche] \tmaking branch $number\n";

    $self->add_branch( $newbranch );

    return $newbranch;
}

sub calc_new_nodulation {
    my ( $self, $parent ) = @_;

    my $verb = $self->verbose;

    my $old = $parent->nodulation;
    
    # Reduce ebbing factor from the parent's nodulation
    my $new = $old - $self->ebbing_factor;
    
    return $new;
}

sub create_path {
    my ( $self, $start, $end, $dx, $dy ) = @_;
    
    my $x1 = $start->x;
    my $y1 = $start->y;
    my $x2 = $end->x;
    my $y2 = $end->y;
    
    
    my $length  = sqrt( $dx ** 2 + $dy ** 2 );
    my $phandle = $self->branch_curve * $length;
    
    # X / Y values of control point 1 (curving the start point)
    my $c1_x = $x1 - rand($phandle) + rand($phandle);
    my $c1_y = $y1 - rand($phandle) + rand($phandle);

    # X / Y values of control point 2 (curving the end point)
    my $c2_x = $x2 - rand($phandle) + rand($phandle);
    my $c2_y = $y2 - rand($phandle) + rand($phandle);
    
    my $d_str = "M $x1 $y1 C $c1_x $c1_y $c2_x $c2_y $x2 $y2";

    return $d_str;
}


1;

__END__

# After much thought, I have decided that it will be much simpler to ditch the length
# And use dX and dY ranges instead.
# This way it will be much easier to calculate the endpoint, and it will be possible
# to simply determin the direction of the branch:
# dX < 0 => left
# dX > 0 => right
# dY > 0 => up   ( ascending  )
# dY < 0 => down ( descending )