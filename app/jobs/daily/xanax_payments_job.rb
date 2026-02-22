module Daily
  class XanaxPaymentsJob < OwnerApiJob
    PAYMENT_RECIPIENT_TORN_ID = 2728237

    def perform
      fetch_and_process_payments
    end

    private

    def fetch_and_process_payments
      log_entries = TornApi::User::Log.new(OwnerCredentials.api_key).fetch_xanax_payments(limit: 100)

      log_entries.each do |entry|
        process_payment(entry) unless XanaxPayment.exists?(log_id: entry.id)
      rescue ActiveRecord::RecordNotUnique
        Rails.logger.info "Payment #{entry.id} already processed, skipping"
        next
      end
    end

    def process_payment(entry)
      sender = find_or_create_sender(entry.sender_torn_id)
      recipient = User.find_by!(torn_id: PAYMENT_RECIPIENT_TORN_ID)

      XanaxPayment.create!(
        recipient: recipient,
        sender: sender,
        log_id: entry.id,
        xanax_amount: entry.xanax_quantity,
        weeks_granted: entry.xanax_quantity,
        processed_at: Time.at(entry.timestamp)
      )

      sender.extend_subscription!(entry.xanax_quantity)

      Rails.logger.info "Xanax payment processed: #{entry.xanax_quantity} from #{sender.name || sender.torn_id}"
    end

    def find_or_create_sender(torn_id)
      User.find_by(torn_id: torn_id) || create_sender(torn_id)
    end

    def create_sender(torn_id)
      profile = TornApi::User::Basic.new(OwnerCredentials.api_key, torn_id).fetch

      User.create!(
        torn_id: profile.id,
        name: profile.name,
        level: profile.level,
        api_key: nil
      )
    rescue TornApi::ApiError => e
      Rails.logger.warn "Could not fetch profile for #{torn_id}: #{e.message}. Creating minimal user record."
      User.create!(
        torn_id: torn_id,
        name: "User #{torn_id}",
        level: 1,
        api_key: nil
      )
    end
  end
end
