# Add routes and match routes
#
# 'T' is the type of the 'payload'. The 'payload' is what will be returned
# if the route matches.
#
# ## Example
#
# ```crystal
# # 'T' will be 'Symbol'
# router = LuckyRouter::Matcher(Symbol).new
#
# # Tell the router what payload to return if matched
# router.add("get", "/users", :index)
#
# # This will return :index
# router.match("get", "/users").payload # :index
# ```
class LuckyRouter::Matcher(T)
  # starting point from which all fragments are located
  getter root = Fragment(T).new(path_part: PathPart.new(""))

  def add(method : String, path : String, payload : T)
    all_path_parts = PathPart.split_path(path)
    validate!(path, all_path_parts)
    optional_parts = all_path_parts.select(&.optional?)

    path_without_optional_params = all_path_parts.reject(&.optional?)

    process_and_add_path(method, path_without_optional_params, payload)
    optional_parts.each do |optional_part|
      path_without_optional_params << optional_part
      process_and_add_path(method, path_without_optional_params, payload)
    end
  end

  private def process_and_add_path(method : String, parts : Array(PathPart), payload : T)
    if method.downcase == "get"
      root.process_parts(parts, "head", payload)
    end

    root.process_parts(parts, method, payload)
  end

  def match(method : String, path_to_match : String) : Match(T)?
    parts = path_to_match.split('/')
    parts.pop if parts.last.blank?
    match = root.find(parts, method)

    if match.is_a?(Match)
      match
    end
  end

  def match!(method : String, path_to_match : String) : Match(T)
    match(method, path_to_match) || raise "No matching route found for: #{path_to_match}"
  end

  private def validate!(path : String, parts : Array(PathPart))
    last_index = parts.size - 1
    parts.each_with_index do |part, idx|
      if part.glob? && idx != last_index
        raise InvalidPathError.new("`#{path}` must only contain a glob at the end")
      end
    end
  end
end
