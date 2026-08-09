module Api
  class ChatRoomsController < BaseController
    def index
      rooms = @user.chat_rooms.order(last_message_at: :desc).map { |room| room.info_for(@user) }
      render json: { rooms: rooms }
    end

    def create
      if room_limit_reached?
        return render json: { error: room_limit_error }, status: :unprocessable_entity
      end

      room = ChatRoom.new(name: params[:name].to_s.strip, host_user: @user, last_message_at: Time.current)

      if room.save
        room.chat_memberships.create!(user: @user, host: true)
        room.post_system_message("Room created. Share the invite link to add people.")
        render json: { room: room.info_for(@user) }, status: :created
      else
        render json: { error: room.errors.full_messages.first }, status: :unprocessable_entity
      end
    end

    def join
      room = ChatRoom.find_by(invite_token: params[:token].to_s.strip)
      unless room
        return render json: { error: "This invite link is no longer valid." }, status: :not_found
      end

      unless room.chat_memberships.exists?(user: @user)
        if room_limit_reached?
          return render json: { error: room_limit_error }, status: :unprocessable_entity
        end

        if room.chat_memberships.count >= ChatRoom::MEMBER_LIMIT
          return render json: { error: "This room is full." }, status: :unprocessable_entity
        end

        room.chat_memberships.create!(user: @user)
        room.post_system_message("#{@user.name} joined.")
      end

      render json: { room: room.info_for(@user) }
    end

    def leave
      membership = @user.chat_memberships.find_by(chat_room_id: params[:room_id])
      unless membership
        return render json: { error: "You are not in this room." }, status: :not_found
      end

      room = membership.chat_room
      membership.destroy!

      if room.chat_memberships.none?
        room.destroy!
      else
        room.post_system_message("#{@user.name} left.")
      end

      render json: { ok: true }
    end

    private

    def room_limit_reached?
      @user.chat_memberships.count >= ChatRoom::PER_USER_LIMIT
    end

    def room_limit_error
      "You're already in #{ChatRoom::PER_USER_LIMIT} rooms. Leave one first."
    end
  end
end
