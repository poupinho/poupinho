# Baixa uma imagem pública (a foto do Google, por exemplo) para anexar como avatar.
# Segue até 3 redirecionamentos, só aceita https e imagens de até User::AVATAR_MAX_BYTES.
# Retorna { io:, content_type: } ou nil quando não deu para baixar.
module Avatars
  class Download
    MAX_REDIRECTS = 3
    TIMEOUT = 10

    def self.call(url)
      new(url).call
    end

    def initialize(url)
      @url = url.to_s
    end

    def call
      uri = URI.parse(@url)
      MAX_REDIRECTS.times do
        return unless uri.is_a?(URI::HTTPS)
        response = get(uri)
        case response
        when Net::HTTPSuccess
          return accept(response)
        when Net::HTTPRedirection
          uri = URI.join(uri, response["location"])
        else
          return
        end
      end
      nil
    rescue URI::Error, SocketError, IOError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
      nil
    end

    private

    def get(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
    end

    def accept(response)
      content_type = response["content-type"].to_s.split(";").first.to_s.strip
      body = response.body.to_s
      return unless content_type.in?(User::AVATAR_CONTENT_TYPES) && body.bytesize.between?(1, User::AVATAR_MAX_BYTES)
      { io: StringIO.new(body), content_type: content_type }
    end
  end
end
