module MockPebbleHelper

  def mock_pebble
    @@mock_pebble ||= start_mock_pebble
  end

  def mock_pebble_url
    "http://localhost:8666/api/mock/v1/echo"
  end

  private

    def start_mock_pebble
      pebble = MockPebble.new
      pebble.start
      pebble
    end

end