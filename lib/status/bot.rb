require "status/bot/version"
require "ethereum"

class String
  def to_hex
    "0x#{unpack("H*").first}"
  end
end

Ethereum::Client.class_eval do
  EXTRA_RPC_COMMANDS = %w(shh_generateSymKeyFromPassword shh_newKeyPair shh_subscribe)
  EXTRA_RPC_COMMANDS.each do |cmd|
    method_name = cmd.underscore
    define_method method_name do |*args|
      send_command(cmd, args)
    end
  end
end

module Status
  class Bot
    def initialize(ipc_path="geth.ipc")
      @client = Ethereum::IpcClient.new(ipc_path, false)
      @key_pair_id = @client.shh_new_key_pair()["result"]
    end

    def join(chat_name)
      PublicChat.new(@client, chat_name, @key_pair_id)
    end
  end

  class PublicChat
    def initialize(client, name, key_pair_id)
      @client = client
      @name = name
      @key_pair_id = key_pair_id
      @sym_key_id = client.shh_generate_sym_key_from_password(name)["result"]
      @topic = generate_topic()
    end

    def generate_topic
      name_hex = @name.to_hex
      full_topic = @client.web3_sha3(name_hex)["result"]
      full_topic[0, 10]
    end

    def post(text)
      payload = generate_payload(text)
      msg = {
        symKeyID: @sym_key_id,
        sig: @key_pair_id,
        ttl: 10,
        topic: @topic,
        payload: payload.to_hex,
        powTime: 1,
        powTarget: 0.001
      }

      @client.shh_post(msg)
    end

    private

    def generate_payload(text)
      timestamp = Time.now.to_i * 1000
      %|["~#c4",["#{text}","text/plain","~:public-group-user-message",#{timestamp * 100},#{timestamp}]]|
    end
  end
end
