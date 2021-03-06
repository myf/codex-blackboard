Meteor.publish 'all-roundgroups', -> RoundGroups.find()
Meteor.publish 'all-rounds', -> Rounds.find()
Meteor.publish 'all-puzzles', -> Puzzles.find()
Meteor.publish 'all-nicks', -> Nicks.find()
Meteor.publish 'all-presence', ->
  # strip out unnecessary fields from presence (esp timestamp) to avoid wasted
  # updates to clients
  Presence.find {present: true}, fields:
    timestamp: 0
    foreground_uuid: 0
    present: 0
Meteor.publish 'presence-for-room', (room_name) ->
  Presence.find {present: true, room_name: room_name}, fields:
    timestamp: 0
    foreground_uuid: 0
    present: 0

# this is for the "that was easy" sound effect
# everyone is subscribed to this all the time
Meteor.publish 'last-answered-puzzle', ->
  collection = 'last-answer'
  self = this
  uuid = Meteor.uuid()
  recent = null
  started = false
  max = (doc) ->
    if doc.solved?
      if (not recent?) or (doc.solved > recent)
        recent = doc.solved
        return true
    return false
  publishIfMax = (doc) ->
    return unless max(doc)
    self.set collection, uuid, {solved:recent, puzzle:doc._id}
    self.flush() if started
  handle = Puzzles.find({
    $and: [ {answer: $ne: null}, {answer: $exists: true} ]
  }).observe
    added: (doc,idx) -> publishIfMax(doc)
    changed: (doc, atIndex, oldDoc) -> publishIfMax(doc)
  # observe only returns after initial added callbacks.
  # if we still don't have a 'recent' (possibly because no puzzles have
  # been answered), set it to current time
  publishIfMax(solved:UTCNow()) unless recent?
  # okay, mark the subscription as ready.
  self.complete()
  self.flush()
  started = true
  self.onStop -> handle.stop()

# limit site traffic by only pushing out changes relevant to a certain
# roundgroup, round, or puzzle
Meteor.publish 'puzzle-by-id', (id) -> Puzzles.find _id: id
Meteor.publish 'round-by-id', (id) -> Rounds.find _id: id
Meteor.publish 'round-for-puzzle', (id) -> Rounds.find puzzles: id
Meteor.publish 'roundgroup-for-round', (id) -> RoundGroups.find rounds: id

Meteor.publish 'my-nick', (nick) -> Nicks.find canon: canonical(nick)

# only publish last page of messages
Meteor.publish 'recent-messages', (nick, room_name) ->
  nick = canonical(nick or '') or null
  Messages.find {
    room_name: room_name
    $or: [ { nick: nick }, { to: $in: [null, nick] } ]
  },
    sort:[["timestamp","desc"]]
    limit: MESSAGE_PAGE

# paged version: specify page boundary by timestamp, so we can display
# 'more' messages by passing in the timestamp of the first message
# on the current page we're looking at
Meteor.publish 'paged-messages', (nick, room_name, timestamp) ->
  nick = canonical(nick or '') or null
  Messages.find {
    room_name: room_name
    timestamp: $lt: +timestamp
    $or: [ { nick: nick }, { to: $in: [null, nick] } ]
  },
     sort: [['timestamp','desc']]
     limit: MESSAGE_PAGE

# same thing for operation log
Meteor.publish 'recent-oplogs', ->
  OpLogs.find {}, {sort: [["timestamp","desc"]], limit: 20}

Meteor.publish 'paged-oplogs', (timestamp) ->
  OpLogs.find {timestamp: $lt: +timestamp},
     sort: [['timestamp','desc']]
     limit: OPLOG_PAGE

# synthetic 'all-names' collection which maps ids to type/name/canon
Meteor.publish 'all-names', ->
  self = this
  handles = [ 'roundgroups', 'rounds', 'puzzles' ].map (type) ->
    collection(type).find({}).observe
      added: (doc, idx) ->
        self.set 'names', doc._id,
          type: type
          name: doc.name
          canon: canonical(doc.name)
        self.flush()
      removed: (doc,idx) ->
        self.unset 'names', doc._id, ['_id','type','name','canon']
        self.flush()
      changed: (doc,idx,olddoc) ->
        return unless doc.name isnt olddoc.name
        self.set 'names', doc._id,
          name: doc.name
          canon: canonical(doc.name)
        self.flush()
  # observe only returns after initial added callbacks have run.  So now
  # mark the subscription as ready
  self.complete()
  self.flush()
  # stop observing the various cursors when client unsubs
  self.onStop ->
    handles.map (h) -> h.stop()
