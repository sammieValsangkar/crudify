require "crudify/engine"
require 'responders'
require "ransack"
require 'kaminari'

module Crudify
  # Your code goes here...
end

ActiveRecord::Base.class_eval do
  def self.foreign_key?(key)
    self.reflect_on_all_associations(:belongs_to).map(&:foreign_key).include?(key)
  end

   def self.foreign_klass_for(key)
    self.reflect_on_all_associations(:belongs_to).select{ |a| a.foreign_key == key }.first.klass
  end
end