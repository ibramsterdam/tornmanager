class WarChannel < ApplicationCable::Channel
  def subscribed
    faction = current_user.faction

    if faction
      stream_from "war:faction:#{faction.id}"
    else
      reject
    end
  end

  def unsubscribed
  end
end
