requires 'App::Wallflower';
requires 'Dancer2';
requires 'File::Find::Rule';
requires 'File::Slurp';
requires 'File::Temp';
requires 'Getopt::Long::Subcommand';
requires 'Import::Into';
requires 'JSON';
requires 'Plack::Builder';
requires 'Plack::Runner';
requires 'Pod::Usage';
requires 'Test::More';
requires 'Text::FrontMatter::YAML';
requires 'Text::MultiMarkdown';
requires 'autodie';
requires 'feature';
requires 'parent';
requires 'perl', '5.010001';
requires 'vars::i';
requires 'version', '0.77';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
};
