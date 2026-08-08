module Api
  class ChatMessagesController < BaseController
    SEND_COOLDOWN = 1.second
    PAGE_LIMIT = 100

    before_action :set_room

    def index
      messages = @room.chat_messages
        .where("id > ?", params[:since_id].to_i)
        .order(:id)
        .limit(PAGE_LIMIT)

      render json: { messages: messages.map(&:as_api_json) }
    end

    def create
      if rate_limited?
        return render json: { error: "You're sending messages too fast." }, status: :too_many_requests
      end

      message = @room.chat_messages.new(
        user: @user,
        body: params[:body].to_s.strip,
        sender_name: @user.name,
        sender_torn_id: @user.torn_id
      )

      if message.save
        Rails.cache.write(cooldown_key, true, expires_in: SEND_COOLDOWN)
        render json: { message: message.as_api_json }, status: :created
      else
        render json: { error: message.errors.full_messages.first }, status: :unprocessable_entity
      end
    end

    private

    def set_room
      @room = @user.chat_rooms.find_by(id: params[:room_id])
      render json: { error: "Room not found." }, status: :not_found unless @room
    end

    def rate_limited?
      Rails.cache.exist?(cooldown_key)
    end

    def cooldown_key
      "chat:cooldown:#{@user.id}"
    end
  end
end
