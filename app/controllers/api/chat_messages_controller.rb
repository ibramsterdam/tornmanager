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

      bytes = uploaded_image_bytes
      return render json: { error: "No image provided." }, status: :bad_request unless bytes

      message = @room.chat_messages.new(sender_attrs.merge(body: params[:body].to_s.strip))
      message.image.attach(
        io: StringIO.new(bytes),
        filename: @room.public? ? "image.jpg" : "image.enc",
        content_type: @room.public? ? "image/jpeg" : "application/octet-stream"
      )
      save_message(message)
    end

    def image
      message = @room.chat_messages.with_attached_image.find_by(id: params[:message_id])
      return render json: { error: "Image not found." }, status: :not_found unless message&.image&.attached?

      render json: { data: Base64.strict_encode64(message.image.download) }
    end

    private

    def uploaded_image_bytes
      if params[:image_base64].present?
        Base64.strict_decode64(params[:image_base64].to_s)
      elsif params[:image].respond_to?(:read)
        params[:image].read
      end
    rescue ArgumentError
      nil
    end

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
