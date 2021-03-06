codex-blackboard
================

Meteor app for coordating solving for our MIT Mystery Hunt team.  To run:

    $ cd codex-blackboard
    $ meteor
    <browse to localhost:3000>

Note that you'll code is pushed live to the server as you make changes, so
you can just leave meteor running.  Occassionally we make changes to the
database schema -- add new sample data, change how things are organized, etc.
In those cases:

    $ meteor reset
    $ meteor

will wipe the old database and start afresh.

At the moment the two ways to install Meteor are:

* just make a git clone of the meteor repo and put it in $PATH, or
* use the package downloaded by their install shell script

The first option is something like:

    $ cd ~/3rdParty ; git clone git://github.com/meteor/meteor.git ; cd ~/bin ; ln -s ~/3rdParty/meteor/meteor .

Note that meteor can run directly from its checkout, and figure out where to
find the rest of its files itself.

The second option is "easier" but gives me the willies:

    $ curl https://install.meteor.com | /bin/sh

You should probably watch the screencast at http://meteor.com to get a sense
of the framework; you might also want to check out the examples they've
posted, too.

The following links should give you a sense of the functionality we're
attempting to reimplement (talk to us if you need a reminder of the
login and password for these):

* http://codex.hopto.org/codex/wiki/All_Puzzles11
* http://codex.hopto.org/codex/wiki/2011_R1P1
* http://codex.hopto.org/show.asp?roomname=r10meta
* http://codex.hopto.org/codex/wiki/Chat_System#Chat_Bot
