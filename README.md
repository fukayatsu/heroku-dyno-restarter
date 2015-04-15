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
TODO

## Heroku Button
## Redis Cloud addon
## Environment variable
- `HEROKU_API_KEY`
- `APP_API_TOKEN`

## Papertrail alert and webhook
## uptimerobot
- https://uptimerobot.com/



