# heroku-dyno-restarter
Restart heroku dyno on Error

There are [schneems/puma_auto_tune](https://github.com/schneems/puma_auto_tune) or [schneems/puma_worker_killer](https://github.com/schneems/puma_worker_killer), but they does not work as intended on Heroku. (See https://github.com/schneems/get_process_mem/issues/7.)

So, We need another approach (for now).

# Concept
[Heroku: R14 Error - Memory quota exceeded](https://devcenter.heroku.com/articles/error-codes#r14-memory-quota-exceeded) log

↓

[Papertrail | Add-ons | Heroku](https://addons.heroku.com/papertrail) and send alert via webhook

↓

[heroku-dyno-restarter](https://github.com/fukayatsu/heroku-dyno-restarter) (this repo)

↓

Restart web dyno via api (`heroku ps:restart web.x`)

# Usage

## Heroku Button

Press this button to deploy this app using your heroku account:

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

You will be asked to fill in a name for the app. Something like "my-company-dyno-restarter".

You will also be asked for your heroku api key.
You can get this key here: https://dashboard.heroku.com/account#api-key

## Papertrail alert and webhook

After deploy by Heroku button above, fetch your heroku-dyno-restarter app's token.

```
heroku config:get APP_API_TOKEN -a <your heroku-dyno-restarter app name>
```

1. Remember the token.
2. Set your papertrail's alert for your target app.
3. Set webhook URL: https://<your heroku-dyno-restarter app name>.herokuapp.com/webhook?token=<APP_API_TOKEN>

![papertrail's webhook](https://user-images.githubusercontent.com/536118/29061708-e495b9d0-7c59-11e7-96a6-13c73d04abb6.png)

## Configuration

Heroku Dyno Restarter will try to guess your app's name based on the papertrail alert. To override this guess,
you can set `SOURCE_APP_NAME`:

```
heroku config:set SOURCE_APP_NAME=my-company-app -a <your heroku-dyno-restarter app name>
```

