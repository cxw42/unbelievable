# NAME

App::unbelievable - Yet another site generator (can you believe it?)

# SYNOPSIS

    use App::unbelievable;  # Pulls in Dancer2
    # your routes here
    unbelievable;           # At EOF, fills in the rest of the routes.

# DESCRIPTION

App::unbelievable makes a Dancer2 application into a static site generator.
Inputs are in `content/`.  Output goes to `_built/`.

# THANKS

Thanks to [Getopt::Long::Subcommand](https://metacpan.org/pod/Getopt::Long::Subcommand) --- I used some code from its Synopsis.

# LICENSE

Copyright (C) 2020 Chris White.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Chris White <cxwembedded@gmail.com>
