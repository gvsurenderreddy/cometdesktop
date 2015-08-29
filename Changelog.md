v0.9.1 - Dec 22, 2008
  * first public release

v0.9.2 - Jan 02, 2009
  * added config command secure\_login
  * modified login.pl to use the secure\_login flag
  * fixed the db record for Sprocket Socket in qo\_files
    * execute this on your db: update qo\_files set path='lib/Sprocket/' where id=11;
  * fixed exception handling
  * added exception handling to the DB library
  * added methods to handle http output
  * overhauled the error handling in CometDesktop.pm
  * added files: Requires, Changelog
  * added 'if exists' to config command load\_config
  * moved the sound manger flash object to the bottom right, and changed its bgcolor to black
  * added looping load\_config detection
  * added constants true and false for use with json
  * added config command use\_exceptions, turning this on will capture errors and show a detailed dump to the viewer, instead of a simple 500 error
  * added config command tmpdir
  * js - replaced desktopConfig with app.config
  * js - removed any use of startupModules, use app.register(<string|object>)
  * js - the comet desktop version string is now in app.version