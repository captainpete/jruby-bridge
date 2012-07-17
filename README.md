jruby-bridge
============

A simple class for bridging between Ruby and JRuby instances via DRb

This is used when a Ruby application needs to call some Java code, but the
entire appliction cannot be written in JRuby. This will be the case when a
required module (e.g. Qt) will not compile for JRuby, or when the Java code
is an optional part of the application (e.g. part of a plugin) and the absence
of JRuby should not break the application.

See http://entrenchant.blogspot.com/2012/07/drb-jruby-bridge.html for full
discussion.
