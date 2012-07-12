module Maxmind
  class Request
    mattr_accessor :proxy_addr, :proxy_port, :proxy_user, :proxy_pass
    # Required Fields
    attr_accessor :client_ip, :city, :region, :postal, :country, :license_key, :http

    # Optional Fields
    attr_accessor :domain, :bin, :bin_name, :bin_phone, :cust_phone, :requested_type,
      :forwarded_ip, :email, :username, :password, :transaction_id, :session_id,
      :shipping_address, :shipping_city, :shipping_region, :shipping_postal,
      :shipping_country, :user_agent, :accept_language

    def initialize(license_key, options = {}, http_settings = {})
      @license_key = license_key

      options.each do |k, v|
        self.instance_variable_set("@#{k}", v)
      end

      {:use_ssl => true}.merge(http_settings).each_pair do |k, v|
        http.send("#{k.to_s}=", v)
      end
    end

    def url
      @url ||= URI.parse("https://minfraud1.maxmind.com/app/ccv2r")
    end

    def http
      @http ||=
        begin
          proxy = [proxy_addr, proxy_port, proxy_user, proxy_pass]
          Net::HTTP.new(url.host, url.port, *proxy)
        end
    end

    def query(string = false)
      validate

      required_fields = {
        :i                => @client_ip,
        :city             => @city,
        :region           => @region,
        :postal           => @postal,
        :country          => @country,
        :license_key      => @license_key
      }

      optional_fields = {
        :domain           => @domain,
        :bin              => @bin,
        :binName          => @bin_name,
        :binPhone         => @bin_phone,
        :custPhone        => @cust_phone,
        :requested_type   => @requested_type,
        :forwardedIP      => @forwarded_ip,
        :emailMD5         => @email,
        :usernameMD5      => @username,
        :passwordMD5      => @password,
        :shipAddr         => @shipping_address,
        :shipCity         => @shipping_city,
        :shipRegion       => @shipping_region,
        :shipPostal       => @shipping_postal,
        :shipCountry      => @shipping_country,
        :txnID            => @transaction_id,
        :sessionID        => @session_id,
        :user_agent       => @user_agent,
        :accept_language  => @accept_langage
      }

      query = required_fields.merge(optional_fields)
      if string == false
        return get(query.reject {|k, v| v.nil? }.to_query)
      else
        return query.reject {|k, v| v.nil? }.to_query
      end
    end

    def get(query)
      req = Net::HTTP::Get.new("#{url.path}?#{query}")
      response = http.start { |h| h.request(req) }
      return response.body
    end

    def email=(email)
      @email = Digest::MD5.hexdigest(email.downcase)
    end

    def username=(username)
      @username = Digest::MD5.hexdigest(username.downcase)
    end

    def password=(password)
      @password = Digest::MD5.hexdigest(password.downcase)
    end

    protected
    def validate
      raise ArgumentError, 'license key required' if @license_key.nil?
      raise ArgumentError, 'IP address required' if @client_ip.nil?
      raise ArgumentError, 'city required' if @city.nil?
      raise ArgumentError, 'region required' if @region.nil?
      raise ArgumentError, 'postal code required' if @postal.nil?
      raise ArgumentError, 'country required' if @country.nil?
    end
  end
end
