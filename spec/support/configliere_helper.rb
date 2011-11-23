module Rubix
  module ConfigliereHelper
    def mock_settings options={}, rest=[]
      param = options
      param.stub!(:rest).and_return(rest)
      param.stub!(:stringify_keys).and_return(param) # FIXME...
      param
    end
  end
end


