class Zillow
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Csvable

  attr_accessor :address, :bed, :bath, :sqft, :description, :price

  validates_presence_of :address,  on: :new

  def attributes
    {'address' => self.address,
      'bed' => self.bed,
      'bath' => self.bath,
      'sqft' => self.sqft,
      'description' => self.description,
      'price' => self.price
    }
  end

  class << self
    def where
      url = 'https://www.zillow.com/search/GetResults.htm?spt=homes&status=110001&lt=111101&ht=001000&pr=,&mp=,&bd=0%2C&ba=0%2C&sf=,&lot=0%2C&yr=,&singlestory=0&hoa=0%2C&pho=0&pets=0&parking=0&laundry=0&income-restricted=0&fr-bldg=0&furnished-apartments=0&cheap-apartments=0&studio-apartments=0&pnd=0&red=0&zso=0&days=any&ds=all&pmf=1&pf=1&sch=100111&zoom=9&rect=-98722458,26066652,-97697983,26297109&p=1&sort=globalrelevanceex&search=maplist&listright=true&isMapSearch=1&zoom=9'
      # zpids = get_zpids(url)
      zpids = [2090941319, 81462259, 50765482, 2090955023, 2090982917, 63447667, 52812274, 2095041334, 81455735, 52708438, 52708439, 2091067823, 81451153, 2091281828, 81450662, 81452530, 81443919, 99370661, 80074503, 2091280494, 80079367, 2093620374, 52796521, 52756909, 2094674537, 81466053, 52734988, 87774053, 80080178, 96751660, 52757301, 81444686, 69714276, 80081865, 87776714, 81451180, 87777588, 120084477, 63447130, 55002059, 2092920776, 121123413, 2097329424, 123712709, 123712930, 87778136, 52754081, 2091418636, 2091918704, 2091413328, 52752230, 87773721, 87775162, 2091469704, 2091475554, 81455119, 2094487179, 52788264, 2092290525, 2099981384, 2094180305, 2094653235, 69700202, 2092844917, 2092860718, 2094058811, 108842252, 2091956451, 2097801680, 52741917, 81454290, 2094890675, 2094890674, 2094337752, 2094487173, 2091739856, 81444450, 2094209518, 2094058854, 2092276236, 2091455312, 2094191436, 2091802031]
      zpid_urls = get_zpids_urls(zpids)

      objs = []
      zpid_urls.map { |zpid_url|
        html = call_zillow(zpid_url)
        new_obj = new(
          address: html.at('meta[property="og:zillow_fb:address"]').try(:[], 'content'),
          bed: html.at('meta[property="zillow_fb:beds"]').try(:[], 'content'),
          bath: html.at('meta[property="zillow_fb:baths"]').try(:[], 'content'),
          sqft: html.css('span.addr_bbs')[2].text.split[0].delete(','),
          description: html.at('meta[property="og:description"]').try(:[], 'content'),
          price: html.at('meta[property="product:price:amount"]').try(:[], 'content')
        )
        objs.push(new_obj)
      }
      return objs
    end

    def generate_csv
      objects = where
      # create_csv(objects)

      CSV.open("/users/dm023177/Documents/Zillow/zillow.csv", "wb") do |csv|
        csv << objects[0].attributes.keys
        objects.each do |obj|
          csv << obj.attributes.values
        end
      end
    end

    def call_zillow(url)
      retries = 12
      loop do
        html = Nokogiri::HTML(open(url))
        if html.children[1].children[1].text == "Please verify you're a human to continue."
          puts "Retrying #{url}..."
          retries -= 1
          if retries == 0
            return nil
          end
        else
          return html
        end
      end
    end

    def get_zpids(url)
      uri = URI(url)

      zpids = []
      page = 1
      loop do
        sleep(5)
        body = Net::HTTP.get(uri)
        parsed = JSON.parse(body)

        num_of_pages = parsed['list']['numPages'] || 1
        zpids.concat(parsed['list']['zpids'])

        if page == num_of_pages
          break
        end

        hquery = CGI::parse(uri.query)
        page = page + 1
        hquery['p'] = [page]
        uri.query = URI.encode_www_form(hquery)
      end

      zpids
    end

    def get_zpids_urls(zpids)
      base_url = "https://www.zillow.com/homes/%{zpid}_zpid/"

      zpids.map {|zpid| base_url % {zpid: zpid} }
    end
  end
end
