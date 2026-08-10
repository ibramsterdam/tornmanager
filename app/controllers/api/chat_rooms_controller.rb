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

      room = ChatRoom.new(
        name: params[:name].to_s.strip,
        host_user: @user,
        kind: "private",
        encrypted: params[:encrypted] ? true : false,
        last_message_at: Time.current
      )

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

      # Public rooms are permanent. A private room that just lost its last
      # member starts a 7-day self-destruct clock (see ChatRoom.abandoned) —
      # it survives so people can rejoin via the invite link in the meantime.
      if !room.public? && room.chat_memberships.none?
        room.update!(emptied_at: Time.current)
      elsif !room.public?
        room.post_system_message("#{@user.name} left.")
      end

      render json: { ok: true }
    end

    # Host-only: the roster with each member's suspended state, for the manage panel.
    def members
      room = member_private_room
      return unless room

      members = room.chat_memberships.includes(:user).map do |m|
        {
          torn_id: m.user.torn_id,
          name: m.user.name,
          host: room.host_user_id == m.user_id,
          suspended: room.chat_suspensions.exists?(user_id: m.user_id)
        }
      end

      render json: { members: members }
    end

    def suspend
      room = host_room
      return unless room

      target = target_user(room)
      return unless target

      if target.id == @user.id
        return render json: { error: "You can't suspend yourself." }, status: :unprocessable_entity
      end

      unless room.chat_suspensions.exists?(user: target)
        room.chat_suspensions.create!(user: target)
        room.post_system_message("#{@user.name} has suspended #{target.name}.")
      end

      render json: { ok: true }
    end

    def unsuspend
      room = host_room
      return unless room

      target = target_user(room)
      return unless target

      if room.chat_suspensions.where(user: target).delete_all.positive?
        room.post_system_message("#{@user.name} has unsuspended #{target.name}.")
      end

      render json: { ok: true }
    end

    private

    # Resolves the room only when the current user hosts it; renders an error
    # and returns nil otherwise, so kick controls can't be driven by non-hosts.
    def host_room
      room = ChatRoom.private_rooms.find_by(id: params[:room_id])
      unless room&.host?(@user)
        render json: { error: "Only the room host can do that." }, status: :forbidden
        return nil
      end
      room
    end

    def target_user(room)
      user = room.users.find_by(torn_id: params[:torn_id].to_i)
      render json: { error: "That player isn't in this room." }, status: :not_found unless user
      user
    end

    # A private room the current user belongs to. Public rooms are excluded so
    # their roster can never deanonymize members.
    def member_private_room
      room = @user.chat_rooms.private_rooms.find_by(id: params[:room_id])
      render json: { error: "Room not found." }, status: :not_found unless room
      room
    end

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
          room.update!(emptied_at: nil) if room.emptied_at
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
