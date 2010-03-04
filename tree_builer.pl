#!perl

# Tester for tree builder
use strict;
use warnings;

use Sprout::Tree;
use SVG;

my $dimention = 400;

sub draw_svg {
    my $tree = shift;

    # create an SVG object
    my $svg = SVG->new( 
        id         => 'tree',
        width      => $dimention,
        height     => $dimention,
    );
    
    # use explicit element constructor to generate a group element
    my $main = $svg->group(
        id        => 'main',
        # The transformation is necessary, because the origial y axis goes down,
        # istead of up. This flips the image.
        transform => 'translate($dimention, $dimention) rotate(180)',
    );
    
    my $stem = $tree->branches->[0];

    my $start_point = $stem->start_point;
    my $end_point   = $stem->end_point;

    $main->line(
        id           => $stem->name,
        x1           => $start_point->x,
        y1           => $start_point->y, 
        x2           => $end_point->x,
        y2           => $end_point->y,
        stroke_width => $stem->width,
        style        => {
            stroke         => 'black',
            'stroke-width' => $stem->width,
        },        
    );
    
    my $points;
    foreach my $branch ( @{ $tree->branches } ) {
## For non-path branches:
#        my $start_point = $branch->start_point;
#        my $end_point   = $branch->end_point;
#        $main->line(
#            id           => $branch->name,
#            x1           => $start_point->x,
#            y1           => $start_point->y, 
#            x2           => $end_point->x,
#            y2           => $end_point->y,
#            stroke_width => $branch->width,
#            style        => {
#                stroke         => 'black',
#                'stroke-width' => $branch->width,
#            },
#        );

        next if $branch->name eq '1';

        $points = {
            d => $branch->path_string,
        };
        
        $main->path(
            %$points,
            id           => $branch->name,
            stroke_width => $branch->width,
            style => {
                'stroke'       => 'black',
                'fill-opacity' => 1,
    #           'fill-color'   => 'black',
                'stroke-color' => 'black',
                'fill'         => 'none',
                'stroke-width' => $branch->width,
            },
        );
    }    

    my $output = $svg->xmlify;
    
    return $output;

}

foreach (1..4) {
    my $rand = int rand 999;
    my $output_path = "tree_recur_$rand.svg";

    my $tree = Sprout::Tree->new(
        image_width        => $dimention,
        stem_length        => 100,
        tree_width         => 10,
        complexity         => 10,
        nodulation         => 6,
        ebbing_factor      => 2,
        creation_algorithm => 'recursive',
    #   level              => 10,           # Specify to test the linear algorithm
        dx_range           => 140,
        dy_range           => 100,
        verbose            => 1,
        branch_curve       => 0.25,
    );

    $tree->create_tree;

    my $output = draw_svg($tree);

    # File operations and rendering:
    open my $output_file, '>', $output_path;
    print $output_file $output;
    close $output_file;
}
