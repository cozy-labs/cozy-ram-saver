# [Cozy](http://cozy.io) RAM Saver

Save some RAM by putting node modules in common.
Tested with 6 apps (calendar, contacts, files, notes, photos, todos), and saved ~100MB RAM.

**DO NOT USE IN PRODUCTION**

## Usage

From the command line you can type:

    git clone https://github.com/cozy-labs/cozy-ram-saver
    cd cozy-ram-saver
    npm run /path/to/my/app

    # Or this also works for official apps
    npm run calendar # Works for official apps

    # Or if you want to reset node_modules for the calendar app
    npm run calendar --rebuild

By default it will save modules used multiple times under the `/usr/local/lib/node_shared_modules` path.

## Known issues

* Running the RAM saver 2 times on the same app breaks the app
* cozy-files, cozy-home and cozy-proxy do not work with shared modules at the moment.

## Hack

Hacking this app requires you [setup a dev environment](http://cozy.io/hack/getting-started/).

## License

Cozy Ram Saver is developed by Cozy Cloud and distributed under the AGPL v3 license.

## What is Cozy?

![Cozy Logo](https://raw.github.com/mycozycloud/cozy-setup/gh-pages/assets/images/happycloud.png)

[Cozy](http://cozy.io) is a platform that brings all your web services in the
same private space.  With it, your web apps and your devices can share data
easily, providing you
with a new experience. You can install Cozy on your own hardware where no one
profiles you.

## Community

You can reach the Cozy Community by:

* Chatting with us on IRC #cozycloud on irc.freenode.net
* Posting on our [Forum](https://forum.cozy.io/)
* Posting issues on the [Github repos](https://github.com/cozy/)
* Mentioning us on [Twitter](http://twitter.com/mycozycloud)
