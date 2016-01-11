# Sidekiq Job Monitor

This gem allows you to easily monitor your jobs progression from your client.

This is often useful when the user has to wait for a specific job to complete
to access some produced data.

The original use case was to allow users to see a "work in progress" modal
while a big document was being generated, and then redirect them to download
it when the job has completed.

The gem plugs into Sidekiq's job processor as a middleware to track the
job progress and make it available through an JSON endpoint.

There's also a simple javascript client that allows you to hook into the
complete and failed events.

## Installation

Add to your Gemfile and `bundle install`:

```ruby
gem 'sidekiq-job_monitor'
```

Mount the engine in your routes.rb :

```ruby
mount Sidekiq::JobMonitor::Engine => '/job-monitor', as: :job_monitor
```

## Usage

The supported workflow for the gem is the following :

1. The user requests a document that need time to be processed
2. The server enqueues a sidekiq job in high priority queue and returns a waiting message in the form of a modal (for instance)
3. The client polls the server to know when the job is done
4. When the job is done, the server returns data to the client so that it can take some action to deliver the document

### 1. Requesting the document

Add a link to the job starting endpoint as a remote link :

```erb
<%= link_to 'Download report', build_report_path(@report), remote: true, data: { :'job-monitor-link' => true }
```

Initialize the javascript client and make it handle the main events :

```javascript
$(function() {
  $('[data-job-monitor-link]').each(function(i, el) {
    $(el).sidekiqJobMonitor({
      onStart: function($el) {
        // If you return a modal box from the server, initialize it
        $el.appendTo('body').modal();
        // Handle the "complete" event and redirect the user to a target
        // URL where it will be able to download the document
        $el.on('complete', function(e, monitor, data) {
          window.location.href = data.url;
        });
        // You can also stop monitoring the progress, for instance when the
        // modal is closed :
        $el.on('hide', function() {
          $el.trigger('stop');
        });
      }
    });
  });
});
```

### 2. The server enqueues a sidekiq job in high priority queue and returns a waiting message

Enqueue a job with a worker as usual, and store the Job ID in the controller

```ruby
class ReportsController
  def build
    @job_id = MyReportWorker.perform_async(params[:id])
    render layout: false
  end
end
```

Render a modal and return the monitoring URL as the main returned node's
`[data-monitor-url]` attribute, with the URL returned by `job_monitor.job_progress_path(job_id)` :

```erb
<div class="modal" data-monitor-url="<%= job_monitor.job_progress_path(@job_id) %>">
  <!-- Snip -->
  Please wait ...
  <!-- Snip -->
</div>
```

### 3. The client polls the server to know when the job is done

This part is already covered by the javascript code we wrote in step 1.

All you need is the correct plugin initialization and returning the
`data-monitor-url` attribute on the main returned node.

### 4. The client polls the server to know when the job is done

When the job is done, a javascript `complete` event is triggered on the modal.
We already handled that in step 1.

All we need now is to provide the `url` field in the data object returned by
the server upon job completion.

To do so, we add the `#monitoring_data` method to our worker class.
This method takes the exact same arguments as the `#perform` method, plus
the current job state (pending, processing, complete or failed) as the last
argument.

```ruby
class MyReportWorker
  include Sidekiq::Worker

  def perform(report_id)
    # Your worker logic here as usual ...
  end

  def monitoring_data(report_id, state)
    # Pseudo logic to get the desired URL
    { url: Report.find(report_id).document_url } if state == 'complete'
  end
end
```

Those fields will be added to the data hash returned by the server as JSON
and passed to the `complete` event callback as the last argument.

## Licence

This project rocks and uses MIT-LICENSE.
