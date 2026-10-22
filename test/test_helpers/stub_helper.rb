# Substitui temporariamente um método de classe/módulo por um bloco, sem depender do minitest-mock.
#
#   stubbing(WebPush, :payload_send, ->(**args) { sent << args; true }) do
#     ...
#   end
module StubHelper
  def stubbing(target, method, impl)
    singleton = target.singleton_class
    backup = :"__stub_original_#{method}"
    singleton.alias_method(backup, method)
    singleton.define_method(method, &impl)
    yield
  ensure
    singleton.alias_method(method, backup)
    singleton.remove_method(backup)
  end
end

class ActiveSupport::TestCase
  include StubHelper
end
