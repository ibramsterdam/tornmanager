module Api
  class ChatMessagesController < BaseController
    SEND_COOLDOWN = 1.second
    PAGE_LIMIT = 100

    before_action :set_room

    def index
      messages = @room.chat_messages
        .with_attached_image
        .where("id > ?", params[:since_id].to_i)
        .order(:id)
        .limit(PAGE_LIMIT)

      render json: { messages: messages.map { |m| present(m) } }
    end

    def create
      return if rate_limited!

      message = @room.chat_messages.new(sender_attrs.merge(body: params[:body].to_s.strip))
      save_message(message)
    end

    def create_image
      return if rate_limited!

      unless params[:image].respond_to?(:read)
        return render json: { error: "No image provided." }, status: :bad_request
      end

      message = @room.chat_messages.new(sender_attrs.merge(body: params[:body].to_s.strip))
      message.image.attach(params[:image])
      save_message(message)
    end

    private

    def save_message(message)
      if message.save
        Rails.cache.write(cooldown_key, true, expires_in: SEND_COOLDOWN)
        render json: { message: present(message) }, status: :created
      else
        render json: { error: message.errors.full_messages.first }, status: :unprocessable_entity
      end
    end

    def sender_attrs
      if @room.public?
        { user: @user, sender_name: @user.chat_anon_name!, sender_torn_id: nil }
      else
        { user: @user, sender_name: @user.name, sender_torn_id: @user.torn_id }
      end
    end

    def set_room
      @room = @user.chat_rooms.find_by(id: params[:room_id])
      return render json: { error: "Room not found." }, status: :not_found unless @room

      if @room.suspended?(@user)
        render json: { error: "You have been suspended from this chat." }, status: :forbidden
      end
    end

    def present(message)
      message.as_api_json.merge(own: message.user_id == @user.id)
    end

    def rate_limited!
      return false unless Rails.cache.exist?(cooldown_key)

      render json: { error: "You're sending messages too fast." }, status: :too_many_requests
      true
    end

    def cooldown_key
      "chat:cooldown:#{@user.id}"
    end
  end
end
