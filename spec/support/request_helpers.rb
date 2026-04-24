module RequestHelpers
  def json_body
    parsed = JSON.parse(response.body)
    parsed.respond_to?(:with_indifferent_access) ? parsed.with_indifferent_access : parsed
  rescue JSON::ParserError
    {}
  end
end
