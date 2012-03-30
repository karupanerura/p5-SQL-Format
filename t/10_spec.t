use strict;
use warnings;
use t::Util;
use Test::More;
use SQL::Format;

my @specs = glob('t/spec/*');
for my $spec (@specs) {
    open my $fh, '<', $spec or die $!;
    while (defined(my $line = <$fh>)) {
        chomp $line;
        next if $line =~ /^\s*$/;
        next unless $line =~ s/^# //;

        my $desc           = $line;
        my $input          = <$fh>;
        my $param          = _eval(scalar <$fh>);
        my $expected       = <$fh>;
        my $expected_binds = _eval(scalar <$fh>);

        subtest "$spec: $desc" => sub {
            my ($stmt, @bind) = sqlf $input, $param;
            is $stmt, $expected;
            is_deeply \@bind, $expected_binds;
        };
    };
}

sub _eval {
    my $line = shift;
    my $data = eval "$line";
    if ($@) {
        fail "syntax error at line $.";
        exit;
    }
    $data;
}

done_testing;
