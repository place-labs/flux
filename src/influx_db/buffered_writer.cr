require "tasker"
require "./client"
require "./point"

class InfluxDB::BufferedWriter
  private getter client : InfluxDB::Client

  private getter bucket : String

  private getter buffer : Channel(Point)

  private getter batch_size : Int32

  private getter flush_delay : Time::Span

  private getter schedule = Tasker.instance

  private getter mutex = Mutex.new

  private getter queue_length = 0

  private getter write_task : Tasker::Task?

  # Creates a new buffered writer for storing points in *bucket* via *client*.
  #
  # Writes to the underlying client are deferred until *batch_size* points are
  # cached or no additional write call is made for *flush_delay*.
  def initialize(@client, @bucket, @batch_size = 5000, @flush_delay = 1.seconds)
    @buffer = Channel(Point).new(batch_size * 2)
  end

  # Enqueue a *point* for writing.
  def enqueue(point : Point) : Nil
    buffer.send point
    mutex.synchronize { @queue_length += 1 }
    flush
  end

  # Flush any fully buffered writes, or schedules a task for partials.
  def flush : Nil
    while queue_length >= batch_size
      @write_task.try &.cancel
      @write_task = nil
      write batch_size
    end

    if queue_length > 0
      @write_task ||= schedule.in(flush_delay) do
        @write_task = nil
        write queue_length
      end
    end
  end

  # Dequeue up to *count* points.
  private def dequeue(count : Int)
    read = 0
    points = Array(Point).build(count) do |arr|
      while read < count && (point = buffer.receive?)
        arr[read] = point
        read += 1
      end
      read
    end
    mutex.synchronize { @queue_length -= read }
    points
  end

  # Asynchronously writes up to *count* Points from the buffer.
  def write(count : Int) : Nil
    points = dequeue count
    spawn do
      client.write bucket, points
    end
  end
end
