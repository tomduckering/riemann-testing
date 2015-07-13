# Riemann Testing
A tool to test Riemann (the event stream processor) from the outside.

##Why did you build this?

Partly because I struggled with testing index search based logic using the built in testing functionality. And partly because my ruby foo is stronger so I hit it with my preferred hammer.

## How do I use it?

1. Make sure riemann is on your PATH. `export PATH:$PATH:/path/to/riemann/bin`

2. Make sure you've got ruby at the right version with the appropriate gems installed.

3. Run `rspec --format doc riemann_spec.rb`


## What does it do?

Just some helper code to make testing Riemann as a black box easier.

This includes:

1. Some helper code that's called in the `@before` block it will start up riemann with your config. This is all contained in 'riemann_runner.rb'

2. Some code to pretend to be a logstash server (since this is what I'll be sending some events to). This too is started in the `@before` block. The code for this is in `fake_logstash.rb`. It starts a multithreaded socket server and parses all lines to it as JSON and pops them in an array. Before each test case we reset that array to make sure the tests are as isolated as possible.

Tests do one of two things:

1. Send events to Riemann and then check the index to see if the index is in the expected state.

2. Send events to Riemann and then check the events received by the fake logstash server to see if Riemann emitted the events we expected.

## What's wrong with it?

* Liberal use of `sleep(x)`
* Tests don't reset the index so you have to be careful since the state of Riemann's index may impact later tests.

##What next?

Dunno. Shout if you have ideas. Make PRs if you have written code that would help make this better. Tell me why this is a terrible way of doing it. All input welcome.
