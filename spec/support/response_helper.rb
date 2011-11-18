module Rubix
  module ResponseSpecs
    def mock_response result={}, code=200
      response = mock("Net::HTTPResponse")
      response.stub!(:body).and_return({"jsonrpc" => "2.0", "result" => result}.to_json)
      response.stub!(:code).and_return(code.to_s)
      Rubix::Response.new(response)
    end

    def mock_error message='', code=200
      response = mock("Net::HTTPResponse")
      response.stub!(:body).and_return({"jsonrpc" => "2.0", "error" => message}.to_json)
      response.stub!(:code).and_return(code.to_s)
      Rubix::Response.new(response)
    end
  end
end
