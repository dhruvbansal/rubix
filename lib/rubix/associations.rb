module Rubix
  module Associations
    
    autoload :HasManyHosts,         'rubix/associations/has_many_hosts'
    autoload :HasManyTemplates,     'rubix/associations/has_many_templates'
    autoload :HasManyHostGroups,    'rubix/associations/has_many_host_groups'
    autoload :HasManyUserMacros,    'rubix/associations/has_many_user_macros'
    autoload :HasManyApplications,  'rubix/associations/has_many_applications'
    autoload :HasManyItems,         'rubix/associations/has_many_items'
    autoload :HasManyUsers,         'rubix/associations/has_many_users'
    autoload :HasManyUserGroups,    'rubix/associations/has_many_user_groups'
    autoload :HasManyConditions,    'rubix/associations/has_many_conditions'
    autoload :HasManyInterfaces,    'rubix/associations/has_many_interfaces'
    autoload :HasManyScreenItems,   'rubix/associations/has_many_screen_items'
    autoload :HasInventory,         'rubix/associations/has_inventory'
    
    autoload :BelongsToHost,        'rubix/associations/belongs_to_host'
    autoload :BelongsToTemplate,    'rubix/associations/belongs_to_template'
    autoload :BelongsToItem,        'rubix/associations/belongs_to_item'
    autoload :BelongsToAction,      'rubix/associations/belongs_to_action'
    autoload :BelongsToUser,        'rubix/associations/belongs_to_user'
    autoload :BelongsToUserGroup,   'rubix/associations/belongs_to_user_group'
    autoload :BelongsToMediaType,   'rubix/associations/belongs_to_media_type'
    autoload :BelongsToInterface,   'rubix/associations/belongs_to_interface'
  end
end

