use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 otus_to_representatives

We deine the notion of OTU loosely.  We try to keep genomes with 97% identical SSUrRNAs
within the same OTU.  We pick a representative genome for each OTU, and we try to
keep all genomes that have 97% identical SSU rRNAs in the same OTU.  

This command is intended to add a column containing the representative genome from the given OTU.

Example:

    otus_to_representatives [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain a genome identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call otu_members. It is documented as follows:

  $return = $obj->otus_to_representatives($otus)

=over 4

=item Parameter and return types

=begin html

<pre>
$otus is a reference to a list where each element is an int
$return is a reference to a hash where the key is an int and the value is a genome
genome is a string
</pre>

=end html

=begin text

$otus is a reference to a list where each element is an int
$return is a reference to a hash where the key is an int and the value is a genome
genome is a string

=end text

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing genome identifiers is not the last column.

=item -i InputFile    [ use InputFile, rather than stdin ]

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column (the representative genome from the OTU) added.  

Input lines that cannot be extended are written to stderr.

=cut

my $usage = "usage: otus_to_representatives [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
						       'i=s' => \$input_file);
if (! $kbO) { print STDERR $usage; exit }

my $ih;
if ($input_file)
{
    open $ih, "<", $input_file or die "Cannot open input file $input_file: $!";
}
else
{
    $ih = \*STDIN;
}

while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $kbO->otus_to_representatives(\@h);
    for my $tuple (@tuples) {
        #
        # Process output here and print.
        #
        my ($id, $line) = @$tuple;
        my $v = $h->{$id};

        if (! defined($v))
        {
            print STDERR $line,"\n";
        }
        elsif (ref($v) eq 'ARRAY')
        {
            foreach $_ (@$v)
            {
                print "$line\t$_\n";
            }
        }
        else
        {
            print "$line\t$v\n";
        }
    }
}
