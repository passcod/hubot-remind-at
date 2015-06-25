process.env.TZ = 'UTC'

assert = require 'power-assert'
Helper = require 'hubot-test-helper'
helper = new Helper('../scripts')

describe 'Reminder formats', ->
  room = null
  beforeEach ->
    room = helper.createRoom()

  it 'chrono formats specified with "at" are parsed', ->
    # Example taken from http://wanasit.github.io/pages/chrono/
    room.user.say 'user', 'hubot remind test at Saturday, 17 August 2513 to do task'
    assert.deepEqual room.messages[1], [
      "hubot", "I'll remind test to do task at Thu Aug 17 2513 12:00:00 GMT+0000 (UTC)"
    ]
