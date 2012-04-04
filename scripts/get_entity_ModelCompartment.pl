use strict;
use Data::Dumper;
use Bio::KBase::Utilities::ScriptThing;
use Carp;

#
# This is a SAS Component
#


=head1 get_entity_ModelCompartment

The Model Compartment represents a section of a cell
(e.g. cell wall, cytoplasm) as it appears in a specific
model.

Example:

    get_entity_ModelCompartment -a < ids > table.with.fields.added

would read in a file of ids and add a column for each filed in the entity.

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the id. If some other column contains the id,
use

    -c N

where N is the column (from 1) that contains the id.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Related entities

The ModelCompartment entity has the following relationship links:

=over 4
    
=item IsDivisionOf Model

=item IsInstanceOf Compartment

=item IsRealLocationOf Requirement

=item IsTargetOf BiomassCompound


=back

=head2 Command-Line Options

=over 4

=item -c Column

Use the specified column to define the id of the entity to retrieve.

=item -h

Display a list of the fields available for use.

=item -fields field-list

Choose a set of fields to return. Field-list is a comma-separated list of 
strings. The following fields are available:

=over 4

=item compartment_index

=item label

=item pH

=item potential

=back    

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added for each requested field.  Input lines that cannot
be extended are written to stderr.  

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'compartment_index', 'label', 'pH', 'potential' );
my %all_fields = map { $_ => 1 } @all_fields;

my $usage = "usage: get_entity_ModelCompartment [-h] [-c column] [-a | -f field list] < ids > extended.by.a.column(s)";

my $column;
my $a;
my $f;
my $i = "-";
my @fields;
my $show_fields;
my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script('c=i'	   	=> \$column,
								  "a"	   	=> \$a,
								  "h"	   	=> \$show_fields,
								  "show-fields"	=> \$show_fields,
								  "fields=s" 	=> \$f,
								  'i=s'	   	=> \$i);
if ($show_fields)
{
    print STDERR "Available fields: @all_fields\n";
    exit 0;
}
if ($a && $f) { print STDERR $usage; exit 1 }
if ($a)
{
    @fields = @all_fields;
}
elsif ($f) {
    my @err;
    for my $field (split(",", $f))
    {
	if (!$all_fields{$field})
	{
	    push(@err, $field);
	}
	else
	{
	    push(@fields, $field);
	}
    }
    if (@err)
    {
	print STDERR "get_entity_ModelCompartment: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
} else {
    print STDERR $usage;
    exit 1;
}

open my $ih, "<$i";
while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $geO->get_entity_ModelCompartment(\@h, \@fields);
    for my $tuple (@tuples) {
        my @values;
        my ($id, $line) = @$tuple;
        my $v = $h->{$id};
	if (! defined($v))
	{
	    #nothing found for this id
	    print STDERR $line,"\n";
     	} else {
	    foreach $_ (@fields) {
		push (@values, $v->{$_});
	    }
	    my $tail = join("\t", @values);
	    print "$line\t$tail\n";
        }
    }
}
