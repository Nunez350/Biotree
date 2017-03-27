#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';
use v5.10;
use Bio::BPWrapper;
use Bio::BPWrapper::TreeManipulations;
use Data::Dumper;
use Getopt::Long qw( :config bundling permute no_getopt_compat );
use Pod::Usage;

use constant PROGRAM => File::Basename::basename(__FILE__);

####################### Option parsing ######################
pod2usage(1) if scalar(@ARGV) < 1;
my %opts;
GetOptions(\%opts,
	   "help|h",
	   "man",
	   "version|V",
	   "as-text|t",
	   "ci|c=s", # attach binary trait table
	   "clean-br|b",
	   "clean-boot|B",
	   "del-otus|d=s",
	   "del-low-boot|D=f",
	   "depth=s",
	   "dist=s",
	   "dist-all",
	   "ead", # edge-length abundance distribution; ODwyer et al. PNAS (2015)
	   "input|i=s",
	   "label-nodes",
	   "lca=s",
	   "length|l",
	   "length-all|L",
	   "ltt=s",
	   "mid-point|m",
	   "multi2bi",
	   "otus-all|u",
	   "otus-desc|U:s",
	   "otus-num|n",
	   "output|o=s",
	   "random=i",
	   "reroot|r=s",
	   "sis-pairs", # pairwise OTU togetherness
	   "subset|s=s",
	   "swap-otus=s", # output trees with each possible pairs (with the designated one) swapped
	   "tree-shape", # for apTreeshape package
	   "walk|w=s",
#	   "rmbl|R",
#          "bootclean|b:f",
#          "collapse|c=s@",
#          "getroot|g",
#          "prune|p=s@",
#          "compnames|x",
#	   "collabel|C:s",
#	   "tree2tableid|I:s",
#	   "joindata|J=s@",
#	   "rename|N",
#	   "tree2table|T",
#          "comptrees|X",
	  ) or pod2usage(2);

Bio::BPWrapper::print_version(PROGRAM) if $opts{"version"};

# Create a new BioTree object and initialize that.
unshift @ARGV, \%opts;
initialize(@ARGV);
write_out(\%opts);

################# POD Documentation ##################
__END__
=encoding utf8

=head1 NAME

biotree - Tree manipulations based on L<BioPerl>

=head1 SYNOPSIS

B<biotree> [options] <tree file>

B<biotree> [-h | --help | -V | --version | --man]

 biotree -l tree.newick              # total tree [l]ength
 biotree -m tree.newick              # [m]id-point rooting
 biotree -u tree.newick              # list all OT[u]s
 biotree -d 'otu1,out2' tree.newick  # [d]elete these OTUs
 biotree -s 'otu1,otu2' tree.newick  # [s]ubset these OTUs
 biotree -D '0.9' tree.newick        # [D]elete low-support (< 0.9) branches
 biotree -r 'otu1' tree.newick       # [r]eroot with a OTU as outgroup
 biotree -o 'tabtree' tree.newick    # [o]utput tree in text format
 biotree --ci 'binary-trait' tree    # consistency indices at informative sites

=head1 DESCRIPTION

Designed as a UNIX-like utility, B<biotree> reads a tree file and reformats branches and nodes based on these BioPerl moduels: L<Bio::TreeIO>, L<Bio::Tree::Tree>, L<Bio::Tree::Node>, and L<Bio::Tree::TreeFunctionsI>. 

Trees can be in any format supported by L<Bio::TreeIO> in L<BioPerl>. However, biotree has not been tested on all possible formats, so behavior may be unexpected with some. Currently, biotree does not support multiple trees per file.

B<biotree> supports reading from STDIN, so that multiple tree manipulations could be chained using pipe ("|").

=head1 OPTIONS

=over 4

=item --ci, -c 'binary-trait-file' 

Attach a file containing binary trait values and prints consistency index for informative sites (not verified)

=item --clean-br, -b

Remove branch lengths from all nodes.

=item --clean-boot, -B

Remove all branch support values.

=item --del-otus, -d 'otu1,out2,etc'

Get a subtree by removing specified OTUs

=item --del-low-boot, -D 'cutoff'

Remove branches supported by less than specified cutoff value, creating a multi-furcating tree.

=item --depth 'node' 

Prints depth to root. Accepts node names and/or IDs.

=item --distance 'node1,node2'

Prints the distance between a pair of nodes or leaves.

=item --dist-all

Prints half-matrix list of distances between ALL leaves.

=item --ead

Edge-length abundance distribution, a statistics of tree balance (ODwyer et al. PNAS 2015)

=item --input, -i 'format'

Input file format. Accepts newick and nhx.

=item --labelnodes

Prepends ID to each leaf/node label. Useful when identifying unlabled nodes, such as when using --otus-desc or --subset.

=item --lca 'node1,node2,node3,etc'

Returns ID of most recent common ancestor across provided nodes. Returns direct ancestor if single leaf/node provided.

=item --length, -l

Print total branch length.

=item --lengthall, -L

Prints all nodes and branch lengths.

=item --ltt 'number_of_bins'

For making lineage-through-time plot: Divides tree into number of specified segments and counts branches up to height the segment. Returns: bin_number, branch_count, bin_floor, bin_ceiling.

=item --mid-point, -m

Reroot tree at mid-point

=item --multi2bi

Force a multi-furcating tree into a bifurcating tree (by randomly resolve nodes with multiple descendants)

=item --otus-all, -u

Print leaf nodes with branch lengths.

=item --otus-desc, -U 'internal_node_id' | 'all'

Prints all OTU's that are descended from the given internal node (identifiable by running --label-nodes). If 'all', a complete list of all internal nodes and their descendents is returned instead (given in the order of "walking" through the tree from the root node).

=item --otus-num, -n

Print total number of OTUs (leaves).

=item --output, -o 'format'

Output file format. Accepts newick, nhx, and tabtree.

=item --random [sample_size]

Builds a tree of a random subset of the original tree's OTUs. 

=item --reroot, -r 'newroot'

Reroot tree to specified node by creating new branch.

=item --sis-pairs

For each pair of OTUs, print 1/0 if they are (or not) sister OTUs.

=item --subset, -s 'node1,node2,node3,etc'

Creates a tree of only the specified leaves/nodes and their descendants. Specifying a single internal node produces a subtree from that node.

=item --swap-otus 'OTU'

Output tree with each possible pairs swapped (can't remember why this method was written, please ignore)

=item --tree-shape

Print a matrix of tree shapes (input file for R Package apTreeshape)

=item --walk, -w 'otu'

Walks along the tree starting from the specified OTU and prints the total distance traveled while reaching each other OTU. Does not count any segment more than once. Useful when calculating evolutionary distance from a reference OTU.

=back

=head2 Options common to all BpWrappers utilities

=over 4

=item --help, -h

Print a brief help message and exit.

=item --man (but not "-m")

Print the manual page and exit.

=item --version, -V

Print current release version of this command and exit.

=back

=head1 SEE ALSO

=over 4

=item *

L<Bio::BPWrapper::TreeManipulations>, the underlying Perl Module

=item *

L<Qiu Lab wiki page|http://diverge.hunter.cuny.edu/labwiki/Bioutils>

=item *

L<Github project wiki page|https://github.com/bioperl/p5-bpwrapper/wiki>

=item *

L<Newick utilities by Junier & Zdobnov (Bioinformatics, 2010, 26:1669)|http://cegg.unige.ch/newick_utils>

=back

=head1 CONTRIBUTORS

=over 4

=item *
Rocky Bernstein (testing & release)

=item  *
Yözen Hernández yzhernand at gmail dot com (initial design of implementation)

=item *
Pedro Pegan (developer)

=item  *
Weigang Qiu <weigang@genectr.hunter.cuny.edu> (maintainer)

=back

=head1 TO DO

=over 4

=item *
consistency index for DNA/protein alignments

=item *
text-format tree display needs improvement or re-implementation (as in newick utilities)

=back

=head1 TO CITE

=over 4

=item *
Hernandez, Bernstein, Qiu, et al (2017). "BpWrappers: Command-line utilities for manipulation of sequences, alignments, and phylogenetic trees based on BioPerl". (In prep).

=item *
Stajich et al (2002). "The BioPerl Toolkit: Perl Modules for the Life Sciences". Genome Research 12(10):1611-1618.

=back

=cut
