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

      render json: { messages: messages.map { |m| present(m) } }
    end

    def create
      if rate_limited?
        return render json: { error: "You're sending messages too fast." }, status: :too_many_requests
      end

      # In public rooms the sender's Torn identity is never stored — only their
      # stable per-room pseudonym is persisted, so a message can't be traced
      # back to a player through the data.
      attrs = { user: @user, body: params[:body].to_s.strip }
      if @room.public?
        attrs[:sender_name] = @user.chat_anon_name!
        attrs[:sender_torn_id] = nil
      else
        attrs[:sender_name] = @user.name
        attrs[:sender_torn_id] = @user.torn_id
      end

      message = @room.chat_messages.new(attrs)

      if message.save
        Rails.cache.write(cooldown_key, true, expires_in: SEND_COOLDOWN)
        render json: { message: present(message) }, status: :created
      else
        render json: { error: message.errors.full_messages.first }, status: :unprocessable_entity
      end
    end

    private

    def set_room
      @room = @user.chat_rooms.find_by(id: params[:room_id])
      return render json: { error: "Room not found." }, status: :not_found unless @room

      # A suspended member keeps their membership (and the room in their list)
      # but the server serves them no messages and accepts none — a hard block
      # that holding the encryption key can't bypass.
      if @room.suspended?(@user)
        render json: { error: "You have been suspended from this chat." }, status: :forbidden
      end
    end

    # `own` lets the client highlight your own messages without exposing a Torn
    # id in public rooms; anonymous messages carry no torn_id at all.
    def present(message)
      message.as_api_json.merge(own: message.user_id == @user.id)
    end

    def rate_limited?
      Rails.cache.exist?(cooldown_key)
    end

    def cooldown_key
      "chat:cooldown:#{@user.id}"
    end
  end
end
