defmodule SearchApi do
  @base_url  "https://ssb.cc.nd.edu/StudentRegistrationSsb/ssb"
  @term_url  "#{@base_url}/classSearch"
  @search_result_url  "#{@base_url}/searchResults"
  #  @cookie_agent = elem(CookieAgent.start_link(''), 1)

    def fetch_everything do
    cookie = authenticate_request 
    fetch_terms
    |> Enum.map(fn(term) -> fetch_term_departments(term["code"], cookie) end)
    |> Enum.map(fn({k, v}) -> Enum.map(v, fn(item) ->
      IO.puts(item["code"])
      fetch_term_department_courses(cookie, k, item["code"], 0) end)
    end) 
  end

  def fetch_terms do
    # Let's only fetch for the five most recent terms, for simplicity.
    HTTPoison.get!("#{@term_url}/getTerms?searchTerm=&offset=1&max=1").body
    |> Poison.decode!
     
    # Returns it as a JSON object.
  end

  def parse_for_terms(term) do
  end

  def fetch_term_departments(term, cookie) do
    # Term Object!
    IO.puts "https://ssb.cc.nd.edu/StudentRegistrationSsb/ssb/classSearch/get_subject?searchTerm=&term=#{term}&offset=1&max=200"
    final_value = HTTPoison.get!("https://ssb.cc.nd.edu/StudentRegistrationSsb/ssb/classSearch/get_subject?searchTerm=&term=#{term}&offset=1&max=200").body
    |> Poison.decode!
    
    {term, final_value}
  end

  def authenticate_request(header_cookie \\ "") do
    map_header = %{'Set-Cookie' => header_cookie, 'Content-type' =>
      'mulitpart/form_data'}

    if(header_cookie == "") do
      headers = ['Content-Type': 'application/x-www-form-urlencoded']
    end

    resp = HTTPoison.post!("#{@base_url}/term/search?mode=search&term=201510", 
    "{\"term\": 201510}", ["Set-Cookie": header_cookie, "Content-Type":
      "application/x-www-form-urlencoded;charset=UTF-8"])
   
    IO.puts(header_cookie) 
    resp_body =  Poison.decode! resp.body 
    IO.puts(resp.body)

    resp_headers = Enum.at(resp.headers, 3)
    resp_body
    
    cookie = (Tuple.to_list(resp_headers)) |> List.last;

    actual_cookie = String.split(cookie, ";", trim: true) |> List.first; 
    IO.puts(actual_cookie)
    # Check length of the dictionary keys 
    #IO.puts length Dict.keys(resp)
    #IO.puts(resp.headers)
    #resp_headers
  
    if(header_cookie == "") do
      IO.puts("Blank header cookie!")
      #authenticate_request(actual_cookie)
    end

    
    case CookieAgent.start_link(actual_cookie) do
      {:ok, cookie_agent} -> IO.puts 'Successfully started Cookie Agent'
      {:error, reason} -> IO.puts 'Error starting the cookie agent.'
                          CookieAgent.set(:cookie, actual_cookie)
    end

    
    actual_cookie
  end

  def fetch_term_department_courses(cookie, term, department_code, offset) do
    # Gonna have to recursively call this one, probably, in order to get every
    # single department that we need.
    cookie_header = CookieAgent.get(:cookie)

    IO.puts CookieAgent.get(:cookie)
    json_response =
    HTTPoison.get!("#{@search_result_url}/searchResults?txt_subject=#{department_code}&txt_term=#{term}&startDatepicker=&endDatepicker=&pageOffset=#{offset}&pageMaxSize=299&sortColumn=subjectDescription&sortDirection=asc",
    ['Cookie': cookie_header]).body 
    |> Poison.decode!

    #Enum.map(json_response, fn {k,v} -> IO.puts "%{k}: #{v}" end)
    
    if(!json_response["success"]) do
      # The call failed for some reason, probably unauthenticated.
      IO.puts("The API call failed. Reauthenticate.")
      authenticate_request 
      fetch_term_department_courses(cookie, term, department_code, offset)
       # Reauthenticate and retry the same request.
    end

    json_response
  end

  def fetch_departments do
    HTTPoison.get!("https://ssb.cc.nd.edu/StudentRegistrationSsb/ssb/classSearch/get_subject?searchTerm=&term=201510&offset=1&max=200").body
    |> Poison.decode!
  end
end

