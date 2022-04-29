#  eth2 validators by using beaconcha.in API

Receive notifications on Telegram if your node misses attestations or block proposals


In Telegram, create a new bot by sending the ```/newbot``` command to @BotFather. Provide a name and username to your bot, and you'll receive a token to access the http API

Send a message to your bot, and run this on a terminal: ```curl "https://api.telegram.org/botYOUR_KEY_GOES_HERE/getUpdates"```. Extract the chat ```id```

Edit lines 3-5 in monitor.nim and set the validators you want to monitor (up to 100), the chat id and telegram token

Compile ```monitor.nim```. If you have nimbus, you can use the following command: ```the/path/to/nimbus-eth2/env.sh nim -d:ssl c monitor.nim```. This will generate the file ```monitor```

Set up a cronjob by running crontab -e. Add this job:
```*/6 * * * * /home/status/utils/monitor >> monitor-error.log ```

The free tier of beaconcha.in API has a limit of 30K request per month. The monitor will execute 3 API requests every 6 minutes for a total of ~21600 requests per month so we should be okay.
