# frozen_string_literal: true

# an example consumer class
class Consumer < Racecar::Consumer
  subscribes_to 'racecar-example-topic'

  def process(message)
    puts 'consuming message'
  end
end
