# Define variáveis de ambiente só durante o bloco.
module EnvHelper
  def with_env(vars)
    old = vars.keys.to_h { |k| [ k, ENV[k] ] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    old.each { |k, v| ENV[k] = v }
  end
end

class ActiveSupport::TestCase
  include EnvHelper
end
