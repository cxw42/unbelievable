# NAME

App::unbelievable - Yet another site generator (can you believe it?)

# SYNOPSIS

    use App::unbelievable;  # Pulls in Dancer2
    # your routes here
    unbelievable;           # At EOF, fills in the rest of the routes.

App::unbelievable makes a Dancer2 application into a static site generator.
App::unbelievable adds routes for `/` and `/**` that will render Markdown
files in `content/`.  The [unbelievable](https://metacpan.org/pod/unbelievable) script generates static HTML
and other assets into `_built/`.

# FUNCTIONS

## import

Imports [Dancer2](https://metacpan.org/pod/Dancer2), among others, into the caller's namespace.

## unbelievable

Make default routes to render Markdown files in `content/` into HTML.
Usage: `unbelievable;`.  Returns a truthy value, so can be used as the
last line in a module.

# THANKS

- Thanks to [Getopt::Long::Subcommand](https://metacpan.org/pod/Getopt::Long::Subcommand) --- I used some code from its Synopsis.
- Thanks to [Dancer2](https://metacpan.org/pod/Dancer2) and [App::Wallflower](https://metacpan.org/pod/App::Wallflower) for doing the heavy lifting!

# LICENSE

Copyright (C) 2020 Chris White.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Chris White <cxwembedded@gmail.com>
