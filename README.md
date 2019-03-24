Welcome to Glitch
=================

A haskell and cabal API boilerplate project that runs on glitch.me.
The package cache is set to /tmp/.cache/packages in the config 
file (/app/.cabal/config) to avoid running out of disk space when 
running `cabal install`.

Click `Show` in the header to see your app live. Updates to your code will instantly deploy and update live.

**Glitch** is the friendly community where you'll build the app of your dreams. Glitch lets you instantly create, remix, edit, and host an app, bot or site, and you can invite collaborators or helpers to simultaneously edit code with you.

Find out more [about Glitch](https://glitch.com/about).


Your Project
------------

For this server,
- the app starts at `src/Main.hs`
- add package dependencies in `webapp.cabal`
- safely store app secrets in `.env` (nobody can see this but you and people you invite)
  - then lookup those values with `Environment.lookupEnv "SECRET_KEY"`


Made on [Glitch](https://glitch.com/)
-------------------

\ ゜o゜)ノ
