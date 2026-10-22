# Baixa a foto de perfil do Google e anexa como avatar (só se o usuário ainda não tiver uma).
# O Google entrega a URL em 96px ("=s96-c"); pedimos 256px para o avatar não ficar borrado.
class GoogleAvatarJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(user, url)
    return if user.avatar.attached?
    image = Avatars::Download.call(larger(url))
    return unless image

    extension = Rack::Mime::MIME_TYPES.key(image[:content_type]).to_s
    user.avatar.attach(io: image[:io], filename: "google#{extension}", content_type: image[:content_type])
  end

  private

  def larger(url)
    url.to_s.sub(/=s\d+(-c)?\z/, "=s256-c")
  end
end
