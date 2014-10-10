hubot-ga-rt-alert
=================

A hubot script to notify when the number of real time users exceeds or goes down threshold you set by using Google Analytics API.

## Installation
Run

```sh
$ npm install --save git://github.com/en30/hubot-ga-rt-alert
```

Add `hubot-ga-rt-alert` to `external-scripts.json`

## Configuration
This script depends on `hubot-googleapi`. Setup as the instruction on [en30/hubot-googleapi](https://github.com/en30/hubot-googleapi). Don't forget to add `analytics` or `analytics.readonly` to `GOOGLE_API_SCOPES`.

The Real Time Reporting API is limited beta, and you need to request access as the instruction on [What Is The Real Time Reporting API - Overview](https://developers.google.com/analytics/devguides/reporting/realtime/v3/?hl=ja)

This script checks the number of realtime users every `5` minutes. You can change its interval by setting an environment variable, `GA_ALERT_PER_MINUTES`.

## Commands

```
hubot analytics list views - Returns all of analytics views with these id.
hubot analytics list alerts - Returns all of set alerts.
hubot analytics set alert on <view id> with threshold <threshold> - Sets an alert on a view specified by <view id> which will be triggered when the number of realtime users goes over <threshold>.
hubot analytics remove alert on <view id> - Removes an alert on a view specified by <view id>
```
