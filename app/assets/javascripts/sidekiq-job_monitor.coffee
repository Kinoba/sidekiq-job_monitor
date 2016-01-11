@Sidekiq ?= {}

class Sidekiq.JobMonitor
  constructor: (markup, options = {}) ->
    @$el = $(markup)
    @monitorURL = @$el.data('monitor-url')
    setTimeout(@monitorProgress, 1000)
    $('body').trigger('start', [this])
    options.onStart?(@$el)

  monitorProgress: =>
    $.getJSON(@monitorURL)
      .done(@onMonitorProgressData)
      .fail(@jobFailed)

  onMonitorProgressData: (data) =>
    if data.state is 'complete'
      @jobComplete(data)
    else
      setTimeout(@monitorProgress, 1000)

  jobComplete: (data) ->
    console.log "trigger completion : ", this, data
    @$el.trigger('complete', [this, data])

  jobFailed: =>
    @$el.trigger('failed', [this])

  trigger: (eventName, args...) ->
    args = [this].concat(args)
    @$el.trigger(eventName, args)

$.fn.sidekiqJobMonitor = (options = {}) ->
  @each (i, el) ->
    $(el).on 'ajax:success', (e, response) ->
      new Sidekiq.JobMonitor(response, options)
