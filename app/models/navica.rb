class Navica
  include ActiveModel::Model

  attr_accessor :address, :price

  # validates_presence_of :address,  on: :new

  class << self
    def where
      html = Nokogiri::HTML(open('https://navicamls.net/displays/?n=247&i=9400615&k=SJLZX49FHUZ7'))
      addresses = html.css('td#expanded-address-label')
      prices = html.css('td#expanded-mls-label')

      count = addresses.count
      listings = []
      (0..count-1).each do |i|
        listings.push(
          new(
            address: addresses[i].children.text,
            price: prices[i].children[3].text
          )
        )
      end
      listings
    end
  end

end
