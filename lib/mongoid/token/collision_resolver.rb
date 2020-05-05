require 'mongoid/token/collisions'

module Mongoid
  module Token
    class CollisionResolver
      attr_accessor :create_new_token
      attr_reader :klass
      attr_reader :field_name
      attr_reader :retry_count

      def initialize(klass, field_name, retry_count)
        @create_new_token = Proc.new {|doc|}
        @klass = klass
        @field_name = field_name
        @retry_count = retry_count
        klass.send(:include, Mongoid::Token::Collisions)
        alias_method_with_collision_resolution(:insert)
        alias_method_with_collision_resolution(:upsert)
      end

      def create_new_token_for(document)
        @create_new_token.call(document)
      end

      private

      def alias_method_with_collision_resolution(method)
        handler = self
        klass.send(:define_method, :"#{method}_with_#{handler.field_name}_safety") do |method_options = {}|
          resolve_token_collisions handler do
            send(:"#{method}_without_#{handler.field_name}_safety", method_options)
          end
        end
        # klass.alias_method_chain method.to_sym, :"#{handler.field_name}_safety"

        klass.alias_method :"#{method}_without_#{handler.field_name}_safety", method.to_sym
        klass.alias_method method.to_sym, :"#{method}_with_#{handler.field_name}_safety"
      end
    end
  end
end
