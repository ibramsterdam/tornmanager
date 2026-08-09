module Api
  class ChatRoomsController < BaseController
    def index
      mine = @user.chat_rooms.order(last_message_at: :desc).map { |room| room.info_for(@user) }
      public_rooms = ChatRoom.public_rooms.order(:name).map { |room| room.info_for(@user) }

      render json: { rooms: mine, public_rooms: public_rooms }
    end

    def create
      if room_limit_reached?
        return render json: { error: room_limit_error }, status: :unprocessable_entity
      end

      room = ChatRoom.new(name: params[:name].to_s.strip, host_user: @user, kind: "private", last_message_at: Time.current)

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

      join_room(room)
    end

    # Public rooms have no invite token — anyone may join them by id.
    def join_public
      room = ChatRoom.public_rooms.find_by(id: params[:room_id])
      unless room
        return render json: { error: "Room not found." }, status: :not_found
      end

      join_room(room)
    end

    def leave
      membership = @user.chat_memberships.find_by(chat_room_id: params[:room_id])
      unless membership
        return render json: { error: "You are not in this room." }, status: :not_found
      end

      room = membership.chat_room
      membership.destroy!

      # Public rooms are permanent; private rooms disappear with their last member.
      if !room.public? && room.chat_memberships.none?
        room.destroy!
      elsif !room.public?
        room.post_system_message("#{@user.name} left.")
      end

      render json: { ok: true }
    end

    private

    def join_room(room)
      unless room.chat_memberships.exists?(user: @user)
        if !room.public? && room_limit_reached?
          return render json: { error: room_limit_error }, status: :unprocessable_entity
        end

        if !room.public? && room.chat_memberships.count >= ChatRoom::MEMBER_LIMIT
          return render json: { error: "This room is full." }, status: :unprocessable_entity
        end

        room.chat_memberships.create!(user: @user)

        if room.public?
          @user.chat_anon_name!
        else
          room.post_system_message("#{@user.name} joined.")
        end
      end

      render json: { room: room.info_for(@user) }
    end

    # Public-room memberships don't count toward the per-user cap.
    def room_limit_reached?
      @user.chat_memberships.joins(:chat_room).where(chat_rooms: { kind: "private" }).count >= ChatRoom::PER_USER_LIMIT
    end

    def room_limit_error
      "You're already in #{ChatRoom::PER_USER_LIMIT} rooms. Leave one first."
    end
  end
end
