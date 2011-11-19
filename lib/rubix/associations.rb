module Rubix
  module Associations
    
    autoload :HasManyHosts,         'rubix/associations/has_many_hosts'
    autoload :HasManyTemplates,     'rubix/associations/has_many_templates'
    autoload :HasManyHostGroups,    'rubix/associations/has_many_host_groups'
    autoload :HasManyUserMacros,    'rubix/associations/has_many_user_macros'
    autoload :HasManyApplications,  'rubix/associations/has_many_applications'
    
    autoload :BelongsToHost, 'rubix/associations/belongs_to_host'
    
  end
end

