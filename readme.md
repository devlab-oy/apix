## Apix-ruby

Ruby bindings for [Apix Messaging API](http://www.apix.fi/home-en.html)

[API Documentation](https://wiki.apix.fi/display/IAD/Rest+API+for+external+usage)


## Installation

```ruby
gem install 'apix-ruby'
```

## Usage

You can retrieve your transfer id and key with:

```ruby
Apix::Client.retrieve_transfer_id(id: "1111222-3", uid: "yourname@example.org", password: "badpassword")
```

and then configure your client

```ruby
Apix.configure do |config|
  config.soft = "Software name"
  config.ver = "1.0"
  config.transfer_id = "1234567890"
  config.transfer_key = "0987654321"
end
```

**Send invoice zip**

```ruby
Apix::Client.send_invoice_zip(path_to_zipfile)
```
