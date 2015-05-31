# Description
#   remind by natural language date for hubot
# Commands
#   hubot remind <me|username> at <time> to <action> - Set a reminder at <time> to do an <action> <time> is natural language date which chrono-node can parse

chrono = require('chrono-node')
uuid   = require('node-uuid')

class Reminders
  constructor: (@robot) ->
    @robot.brain.data.reminder_at ?= {}
    @robot.brain.on 'loaded', =>
        reminder_at = @robot.brain.data.reminder_at
        for own id, o of reminder_at
          reminder = new ReminderAt o.envelope, o.mention, new Date(o.date), o.time, o.action
          if reminder.diff() > 0
            @queue(reminder, id)
          else
            @remove(id)

  queue: (reminder, id) ->

    if ! id?
      id = uuid.v4() while ! id? or @robot.brain.data.reminder_at[id]

    @robot.logger.debug("add id:#{id}")

    setTimeout =>
      target_user = if reminder.mention == 'me' then reminder.envelope.user.name else reminder.mention
      @robot.send reminder.envelope, "I were asked to remind @#{target_user} to #{reminder.action} at #{reminder.time}"
      @remove(id)
    , reminder.diff()

    @robot.brain.data.reminder_at[id] = reminder

  remove: (id) ->
    @robot.logger.debug("remove id:#{id}")
    delete @robot.brain.data.reminder_at[id]

class ReminderAt

  constructor: (@envelope, @mention, @date, @time, @action) ->

  diff: ->
    now = new Date().getTime()
    (@date.getTime()) - now

module.exports = (robot) ->
  reminders = new Reminders robot

  robot.respond /remind (.+) at (.+) to (.*)/i, (msg) ->
    mention = msg.match[1]
    time = msg.match[2]
    action = msg.match[3]

    results = chrono.parse(time)

    if results.length < 1
      msg.send "can't parse #{time}"
      return

    reminder = new ReminderAt msg.envelope, mention, results[0].start.date(), time, action

    @robot.logger.debug results[0].start.date()

    if reminder.diff() <= 0
      msg.send "#{time} is past. can't remind you"
      return

    reminders.queue reminder

    target_user = if mention == 'me' then 'you' else mention
    msg.send "I'll remind #{target_user} to #{action} at #{reminder.date.toLocaleString()}"
