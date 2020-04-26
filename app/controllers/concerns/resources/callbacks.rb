module Resources
  module Callbacks
    extend ActiveSupport::Concern

    module ClassMethods

      attr_accessor :callbacks

      protected

      def new_action
        @callbacks ||= {}
        @callbacks[:new_action] ||= ::Resources::ActionCallbacks.new
      end

      def create
        @callbacks ||= {}
        @callbacks[:create] ||= ::Resources::ActionCallbacks.new
      end

      def update
        @callbacks ||= {}
        @callbacks[:update] ||= ::Resources::ActionCallbacks.new
      end

      def destroy
        @callbacks ||= {}
        @callbacks[:destroy] ||= ::Resources::ActionCallbacks.new
      end

      def custom_callback(action)
        @callbacks ||= {}
        @callbacks[action] ||= ::Resources::ActionCallbacks.new
      end
    end

    protected

    def invoke_callbacks(action, callback_type)
      callbacks = self.class.callbacks || {}
      return if callbacks[action].nil?
      case callback_type.to_sym
        when :before then callbacks[action].before_methods.each {|method| send method }
        when :after  then callbacks[action].after_methods.each  {|method| send method }
        when :fails  then callbacks[action].fails_methods.each  {|method| send method }
      end
    end
  end
end
class Resources::ActionCallbacks
  attr_reader :before_methods
  attr_reader :after_methods
  attr_reader :fails_methods

  def initialize
    @before_methods = []
    @after_methods = []
    @fails_methods = []
  end

  def before(method)
    @before_methods << method
  end

  def after(method)
    @after_methods << method
  end

  def fails(method)
    @fails_methods << method
  end

end
