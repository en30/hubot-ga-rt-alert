# Description:
#   A hubot script to notify when the number of real time users exceeds or goes down threshold you set by using Google Analytics API.
#
# Dependencies:
#   "cron": "^1.0.5",
#   "hubot-googleapi": "^0.2.1",
#   "lodash": "^2.4.1"
#
# Configuration:
#   HEROKU_URL or HUBOT_URL
#   GOOGLE_API_CLIENT_ID
#   GOOGLE_API_CLIENT_SECRET
#   GOOGLE_API_SCOPES
#
# Commands:
#   hubot analytics list views - Returns all of analytics views with these id.
#   hubot analytics list alerts - Returns all of set alerts.
#   hubot analytics set alert on <view id> with threshold <threshold> - Sets an alert on a view specified by <view id> which will be triggered when the number of realtime users goes over <threshold>.
#   hubot analytics remove alert on <view id> - Removes an alert on a view specified by <view id>
#
# URLS:
#
# Author:
#   en30

{CronJob} = require('cron')
_ = require('lodash')
ALERT_PER_MINUTES = process.env.GA_ALERT_PER_MINUTES || 5
BRAIN_KEY = "ga-rt-alert:alerts"

collectionToString = (collection, props)->
  header = props.join(', ') + "\n"
  body = collection.map((item)->
    props.map((prop)-> item[prop]).join(', ')
  ).join("\n")
  header + body

module.exports  = (robot)->
  new CronJob
    cronTime: "0 */#{ALERT_PER_MINUTES} * * * *",
    start: true,
    onTick: ->
      alerts = robot.brain.get(BRAIN_KEY) || []
      alerts.forEach (alert)->
        robot.emit "googleapi:request",
          service: "analytics"
          version: "v3"
          endpoint: "data.realtime.get"
          params:
            ids: "ga:#{alert.id}",
            metrics: "rt:activeUsers"
          callback: (err, res)->
            return console.log(err) if err
            return unless res.rows
            if parseInt(res.rows[0], 10) > parseInt(alert.threshold)
              unless alert.running
                robot.messageRoom alert.room, """
                  The number of real time users of #{alert.name} has exceeded #{alert.threshold}!
                """
              alert.running = true
            else
              if alert.running
                robot.messageRoom alert.room, """
                  The number of real time users of #{alert.name} has gone below #{alert.threshold}.
                """
              alert.running = false
            robot.brain.set BRAIN_KEY, alerts

  robot.respond /analytics list views/, (msg)->
    robot.emit "googleapi:request",
      service: "analytics"
      version: "v3"
      endpoint: "management.profiles.list"
      params:
        accountId: "~all"
        webPropertyId: "~all"
      callback: (err, data)->
        return msg.send(err) if err
        msg.send collectionToString(data.items, ['id', 'name', 'websiteUrl'])

  robot.respond /analytics list alerts/, (msg)->
    alerts = robot.brain.get(BRAIN_KEY) || []
    if alerts.length == 0
      msg.send("There is no alert.")
    else
      msg.send collectionToString(alerts, ['id', 'name', 'threshold', 'room'])

  robot.respond /analytics set alert on (\d+) with threshold (\d+)/, (msg)->
    id = msg.match[1]
    threshold = msg.match[2]
    alerts = robot.brain.get(BRAIN_KEY) || []
    alert = _.find(alerts, id: id)
    if alert
      alert.threshold = threshold
      alert.room = msg.envelope.room
      alert.running = false
      robot.brain.set BRAIN_KEY, alerts
      msg.send("Changed the threshold of #{alert.name}'s alert to #{threshold}.")
      return

    robot.emit "googleapi:request",
      service: "analytics"
      version: "v3"
      endpoint: "management.profiles.list"
      params:
        accountId: "~all"
        webPropertyId: "~all"
      callback: (err, data)->
        return msg.send(err) if err
        view = _.find(data.items, (item)-> item.id == id)
        return msg.send("Threre is no view scpecified by the id") unless view
        alerts.push
          id: id,
          name: view.name,
          threshold: threshold,
          room: msg.envelope.room,
          running: false
        robot.brain.set BRAIN_KEY, alerts
        msg.send("Set an alert on #{view.name} which notifis #{msg.envelope.room} when the number of real time users exceeds #{threshold}.")

  robot.respond /analytics remove alert on (\d+)/, (msg)->
    id = msg.match[1]
    alerts = robot.brain.get(BRAIN_KEY) || []
    i = _.findIndex(alerts, id: id)
    return msg.send("Threre is no alert set on the view") if i == -1
    deleted = alerts.splice(i, 1)[0]
    robot.brain.set BRAIN_KEY, alerts
    msg.send("Removed the alert on #{deleted.name}")
