module Rubix
  module Associations
    
    autoload :HasManyHosts,         'rubix/associations/has_many_hosts'
    autoload :HasManyTemplates,     'rubix/associations/has_many_templates'
    autoload :HasManyHostGroups,    'rubix/associations/has_many_host_groups'
    autoload :HasManyUserMacros,    'rubix/associations/has_many_user_macros'
    autoload :HasManyApplications,  'rubix/associations/has_many_applications'
    autoload :HasManyItems,         'rubix/associations/has_many_items'
    
    autoload :BelongsToHost,        'rubix/associations/belongs_to_host'
    autoload :BelongsToTemplate,    'rubix/associations/belongs_to_template'
    autoload :BelongsToItem,        'rubix/associations/belongs_to_item'
    
  end
end

