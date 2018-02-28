# frozen_string_literal: true

module Csvable
  extend ActiveSupport::Concern

  def create_csv(objects)
    CSV.open("/users/dm023177/Documents/Zillow/zillow.csv", "wb") do |csv|
      csv << objects[0].class.attribute_names
      objects.each do |obj|
        csv << obj.attributes.values
      end
    end
  end
end
