class HealthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  skip_before_action :verify_authenticity_token, only: [:show]

  def show
    begin
      # Check database connection
      ActiveRecord::Base.connection.execute('SELECT 1')
      
      # Check Redis connection
      Redis.new(url: ENV['REDIS_URL']).ping
      
      render json: {
        status: 'healthy',
        timestamp: Time.current,
        database: 'connected',
        redis: 'connected',
        version: '1.0.0'
      }, status: :ok
    rescue => e
      render json: {
        status: 'unhealthy',
        timestamp: Time.current,
        error: e.message
      }, status: :service_unavailable
    end
  end
end
