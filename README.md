# Dalziel

Convenience library for testing JSON API calls in RSpec.
Uses [WebMock](https://github.com/bblimke/webmock) and
[JSON Expressions](https://github.com/chancancode/json_expressions).

* Easily specify JSON responses for stubbed calls with WebMock.
* Verify that the request you've sent contains the right data.
* Verify that you respond as a proper JSON API.
* Easy to read failure messages

## Usage

Testing outgoing requests:

``` ruby

it "makes the right request" do

  # lightweight wrapper around webmock for stubbing JSON calls
  request = stub_json_request(
    :put,
    "http://some-api-call"
    user: {
      id: 5,
      name: "Pascoe"
    }
  )

  call_your_code

  # make sure you sent the right data to the external service
  expect(request).to match_json_request(
    user: {
      name: "Pascoe",
      password: String,
    }.ignore_extra_keys!
  )
end
```

The other side of the request, verify that you behave as a JSON API:

``` ruby
it "creates a user" do
  post "/users", user: { name: "Pascoe" }

  expect(User.count).to eq 1

  expect(last_response).to match_json_response(
    user: {
      id: Integer,
      name: String,
    }.ignore_extra_keys!
  ).status(201) # defaults to 200
end
```

This tests your headers too.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dalziel', group: :test
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git tag
for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
