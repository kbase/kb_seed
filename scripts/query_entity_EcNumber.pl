use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 query_entity_EcNumber

Query the entity EcNumber.

EC numbers are assigned by the Enzyme Commission, and consist
of four numbers separated by periods, each indicating a successively
smaller cateogry of enzymes.

Example:

    query_entity_EcNumber -a 

=head2 Related entities

The EcNumber entity has the following relationship links:

=over 4
    
=item IsConsistentWith Role


=back


=head2 Command-Line Options

=over 4

=item -is field,value

Limit the results to entities where the given field has the given value.

=item -like field,value

Limit the results to entities where the given field is LIKE (in the sql sense) the given value.

=item -op operator,field,value

Limit the results to entities where the given field is related to the given value based on the given operator.

The operators supported are as follows. We provide text base alternatives to the comparison
operators so that extra quoting is not required to keep the command-line shell from 
confusing them with shell I/O redirection operators.

=over 4

=item < or lt

=item > or gt

=item <=  or le

=item >= or ge

=item =

=item LIKE

=back

=item -a

Return all fields.

=item -h

Display a list of the fields available for use.

=item -fields field-list

Choose a set of fields to return. Field-list is a comma-separated list of 
strings. The following fields are available:

=over 4

=item obsolete

=item replacedby

=back    
   
=back

=head2 Output Format

The standard output is a tab-delimited file containing a column
for each requested field.

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'obsolete', 'replacedby' );
my %all_fields = map { $_ => 1 } @all_fields, 'id';

my $usage = "usage: query_entity_EcNumber [-is field,value] [-like field,value] [-op operator,field,value] [-show-fields] [-a | -f field list] > entity.data";

my $a;
my $f;
my @fields;
my $show_fields;
my @query_is;
my @query_like;
my @query_op;

my %op_map = ('>', '>',
	      'gt', '>',
	      '<', '<',
	      'lt', '<',
	      '>=', '>=',
	      'ge', '>=',
	      '<=', '<=',
	      'le', '<=',
	      'like', 'LIKE',
	      );

my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script("a" 		=> \$a,
								  "show-fields" => \$show_fields,
								  "h" 		=> \$show_fields,
								  "is=s"	=> \@query_is,
								  "like=s"	=> \@query_like,
								  "op=s"	=> \@query_op,
								  "fields=s"    => \$f);

if ($show_fields)
{
    print STDERR "Available fields: @all_fields\n";
    exit 0;
}

if (@ARGV != 0 || ($a && $f))
{
    print STDERR $usage, "\n";
    exit 1;
}

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
	print STDERR "all_entities_EcNumber: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my @qry;

for my $ent (@query_is)
{
    my($field,$value) = split(/,/, $ent, 2);
    if (!$all_fields{$field})
    {
	die "$field is not a valid field\n";
    }
    
    push(@qry, [$field, '=', $value]);
}

for my $ent (@query_like)
{
    my($field,$value) = split(/,/, $ent, 2);
    if (!$all_fields{$field})
    {
	die "$field is not a valid field\n";
    }
    
    push(@qry, [$field, 'LIKE', $value]);
}

for my $ent (@query_op)
{
    my($op,$field,$value) = split(/,/, $ent, 3);

    if (!$all_fields{$field})
    {
	die "$field is not a valid field\n";
    }
    my $mapped_op = $op_map{lc($op)};
    if (!$mapped_op)
    {
	die "$op is not a valid operator\n";
    }
    
    push(@qry, [$field, $mapped_op, $value]);
}

my $h = $geO->query_entity_EcNumber(\@qry, \@fields );

while (my($k, $v) = each %$h)
{
    print join("\t", $k, @$v{@fields}), "\n";
}

